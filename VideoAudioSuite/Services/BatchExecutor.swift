import Foundation
import SwiftUI

// Executes operations on multiple files sequentially
class BatchExecutor: ObservableObject {
    static let shared = BatchExecutor()

    // Published state for UI binding
    @Published var isRunning = false
    @Published var currentIndex = 0
    @Published var totalFiles = 0
    @Published var currentProgress: Double = 0.0  // Progress of current file (0.0 to 1.0)
    @Published var overallProgress: Double = 0.0  // Overall batch progress (0.0 to 1.0)
    @Published var currentFileName: String = ""
    @Published var results: [UUID: BatchResult] = [:]

    private var currentProcess: Process? = nil
    private var isCancelled = false
    private var filesToProcess: [BatchFile] = []
    private var operation: Operation? = nil
    private var config: OperationConfig = OperationConfig()

    private init() {}

    // Result for a single file in the batch
    struct BatchResult {
        let success: Bool
        let outputURL: URL?
        let error: FFmpegError?
    }

    // Start batch processing
    func execute(
        files: [BatchFile],
        operation: Operation,
        config: OperationConfig,
        appState: AppState,
        completion: @escaping () -> Void
    ) {
        guard !files.isEmpty else {
            completion()
            return
        }

        // Reset state
        isRunning = true
        isCancelled = false
        currentIndex = 0
        totalFiles = files.count
        currentProgress = 0.0
        overallProgress = 0.0
        results = [:]

        self.filesToProcess = files
        self.operation = operation
        self.config = config

        // Process files sequentially
        processNextFile(appState: appState, completion: completion)
    }

    // Process the next file in the queue
    private func processNextFile(appState: AppState, completion: @escaping () -> Void) {
        guard !isCancelled, currentIndex < filesToProcess.count else {
            // All done or cancelled
            isRunning = false
            completion()
            return
        }

        let batchFile = filesToProcess[currentIndex]
        let file = batchFile.mediaFile

        currentFileName = file.filename
        currentProgress = 0.0

        // Update file status to processing
        appState.updateFileStatus(batchFile, status: .processing)

        guard let operation = self.operation else {
            // Should never happen, but handle gracefully
            recordFailure(for: batchFile, error: .unknownError("No operation selected"), appState: appState)
            currentIndex += 1
            updateOverallProgress()
            processNextFile(appState: appState, completion: completion)
            return
        }

        // Use the existing OperationExecutor to build arguments
        let executor = OperationExecutor.shared

        executor.execute(operation: operation, file: file, config: config) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let outputURL):
                self.recordSuccess(for: batchFile, outputURL: outputURL, appState: appState)
            case .failure(let error):
                self.recordFailure(for: batchFile, error: error, appState: appState)
            }

            // Move to next file
            self.currentIndex += 1
            self.updateOverallProgress()
            self.processNextFile(appState: appState, completion: completion)
        }

        // Monitor progress from OperationExecutor
        observeProgress(executor: executor)
    }

    // Observe progress from OperationExecutor
    private func observeProgress(executor: OperationExecutor) {
        // Poll progress periodically since OperationExecutor publishes to its own progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            // Stop polling when we move to next file or finish
            if !executor.isProcessing || self.isCancelled {
                timer.invalidate()
                return
            }

            DispatchQueue.main.async {
                self.currentProgress = executor.progress
                self.updateOverallProgress()
            }
        }
    }

    // Update overall progress based on current file and progress
    private func updateOverallProgress() {
        guard totalFiles > 0 else {
            overallProgress = 0.0
            return
        }

        let completedFiles = Double(currentIndex)
        let currentFileProgress = currentProgress

        overallProgress = (completedFiles + currentFileProgress) / Double(totalFiles)
    }

    // Record a successful result
    private func recordSuccess(for file: BatchFile, outputURL: URL, appState: AppState) {
        results[file.id] = BatchResult(success: true, outputURL: outputURL, error: nil)
        appState.updateFileStatus(file, status: .completed, outputURL: outputURL)
    }

    // Record a failure result
    private func recordFailure(for file: BatchFile, error: FFmpegError, appState: AppState) {
        results[file.id] = BatchResult(success: false, outputURL: nil, error: error)
        appState.updateFileStatus(file, status: .failed, error: error)
    }

    // Cancel the current batch
    func cancel() {
        isCancelled = true

        // Cancel current operation
        OperationExecutor.shared.cancel()

        // Update remaining files as pending (not processed)
        isRunning = false
    }

    // Get summary of results
    var successCount: Int {
        results.values.filter { $0.success }.count
    }

    var failureCount: Int {
        results.values.filter { !$0.success }.count
    }

    // Reset for next batch
    func reset() {
        isRunning = false
        currentIndex = 0
        totalFiles = 0
        currentProgress = 0.0
        overallProgress = 0.0
        currentFileName = ""
        results = [:]
        isCancelled = false
        filesToProcess = []
        operation = nil
        config = OperationConfig()
    }
}
