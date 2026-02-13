import Foundation
import SwiftUI

// Represents the current state of the application
class AppState: ObservableObject {
    // Whether ffmpeg is installed on the system
    @Published var ffmpegInstalled: Bool = false

    // Whether we've checked for ffmpeg yet
    @Published var hasCheckedFFmpeg: Bool = false

    // MARK: - Batch Processing State

    // Files loaded for batch processing
    @Published var files: [BatchFile] = []

    // Currently selected operation
    @Published var selectedOperation: Operation? = nil

    // Configuration for the selected operation
    @Published var operationConfig = OperationConfig()

    // Search query for filtering operations
    @Published var searchQuery: String = ""

    // Current processing state (for batch processing)
    @Published var processingState: ProcessingState = .idle

    // Progress of current operation (0.0 to 1.0)
    @Published var progress: Double = 0.0

    // Error message to display (if any)
    @Published var errorMessage: String? = nil

    // MARK: - Legacy single-file support (for backwards compatibility)

    // The currently loaded file (if any) - returns first file for backwards compatibility
    var currentFile: MediaFile? {
        files.first?.mediaFile
    }

    // MARK: - Computed Properties

    // Selected files for processing
    var selectedFiles: [BatchFile] {
        files.filter { $0.isSelected }
    }

    // Count of selected files
    var selectedCount: Int {
        selectedFiles.count
    }

    // Whether any files are loaded
    var hasFiles: Bool {
        !files.isEmpty
    }

    // Whether we can process (have selected files and operation)
    var canProcess: Bool {
        guard selectedCount > 0, let operation = selectedOperation else {
            return false
        }

        // Operations requiring a second file only work with single selection
        if operation.requiresSecondFile && selectedCount > 1 {
            return false
        }

        return true
    }

    // Check if an operation is available (disabled for multi-file if it requires secondary file)
    func isOperationAvailable(_ operation: Operation) -> Bool {
        // Operations requiring a second file are only available in single-file mode
        if operation.requiresSecondFile && selectedCount > 1 {
            return false
        }
        return true
    }

    // Check if an operation is compatible with the current file types
    func isOperationCompatible(_ operation: Operation) -> Bool {
        guard hasFiles else { return true }  // Show all when no files

        // Get the primary file type (video vs audio)
        let hasVideoFiles = files.contains { $0.mediaFile.isVideo }
        let hasAudioFiles = files.contains { !$0.mediaFile.isVideo }

        // Check each category and what operations it provides for the file type
        for category in OperationCategory.allCases {
            let dummyVideoFile = MediaFile(
                url: URL(fileURLWithPath: "/test.mp4"),
                filename: "test",
                fileExtension: "mp4",
                fileSize: 0,
                duration: nil,
                isVideo: true
            )
            let dummyAudioFile = MediaFile(
                url: URL(fileURLWithPath: "/test.mp3"),
                filename: "test",
                fileExtension: "mp3",
                fileSize: 0,
                duration: nil,
                isVideo: false
            )

            let videoOps = category.operations(for: dummyVideoFile)
            let audioOps = category.operations(for: dummyAudioFile)

            // If we have video files, check if operation is in video operations
            if hasVideoFiles && videoOps.contains(operation) {
                return true
            }

            // If we have audio files, check if operation is in audio operations
            if hasAudioFiles && audioOps.contains(operation) {
                return true
            }
        }

        return false
    }

    init() {
        checkFFmpegInstallation()
    }

    // MARK: - File Management

    // Add files to the batch
    func addFiles(_ urls: [URL]) {
        for url in urls {
            // Skip if already added
            guard !files.contains(where: { $0.mediaFile.url == url }) else { continue }

            // Try to create MediaFile
            if let mediaFile = MediaFile(url: url) {
                let batchFile = BatchFile(mediaFile: mediaFile)
                files.append(batchFile)

                // Fetch duration asynchronously
                fetchDuration(for: batchFile)
            }
        }
    }

    // Add files from a folder (recursively finds media files)
    func addFilesFromFolder(_ folderURL: URL) {
        let fileManager = FileManager.default
        let videoExtensions = ["mp4", "mov", "mkv", "avi", "webm", "m4v"]
        let audioExtensions = ["mp3", "wav", "aac", "m4a", "flac", "ogg"]
        let allExtensions = Set(videoExtensions + audioExtensions)

        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        var foundURLs: [URL] = []

        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            if allExtensions.contains(ext) {
                foundURLs.append(fileURL)
            }
        }

        addFiles(foundURLs)
    }

    // Remove a file from the batch
    func removeFile(_ file: BatchFile) {
        files.removeAll { $0.id == file.id }
    }

    // Remove all files
    func clearFiles() {
        files.removeAll()
        selectedOperation = nil
        operationConfig = OperationConfig()
        processingState = .idle
        progress = 0.0
        errorMessage = nil
    }

    // Toggle selection for a file
    func toggleSelection(_ file: BatchFile) {
        if let index = files.firstIndex(where: { $0.id == file.id }) {
            files[index].isSelected.toggle()
        }
    }

    // Select all files
    func selectAll() {
        for index in files.indices {
            files[index].isSelected = true
        }
    }

    // Deselect all files
    func deselectAll() {
        for index in files.indices {
            files[index].isSelected = false
        }
    }

    // Update file status
    func updateFileStatus(_ file: BatchFile, status: BatchFileStatus, outputURL: URL? = nil, error: FFmpegError? = nil) {
        if let index = files.firstIndex(where: { $0.id == file.id }) {
            files[index].status = status
            files[index].outputURL = outputURL
            files[index].error = error
        }
    }

    // Reset all file statuses to pending
    func resetFileStatuses() {
        for index in files.indices {
            files[index].status = .pending
            files[index].outputURL = nil
            files[index].error = nil
        }
    }

    // MARK: - Legacy Support

    // Clear the current file and reset state (legacy method)
    func clearFile() {
        clearFiles()
    }

    // MARK: - FFmpeg Detection

    // Check if ffmpeg is available on this system
    func checkFFmpegInstallation() {
        // Check common installation paths directly
        let possiblePaths = [
            "/opt/homebrew/bin/ffmpeg",     // Apple Silicon Homebrew
            "/usr/local/bin/ffmpeg",         // Intel Homebrew
            "/usr/bin/ffmpeg"                // System
        ]

        let found = possiblePaths.contains { path in
            FileManager.default.fileExists(atPath: path)
        }

        DispatchQueue.main.async {
            self.ffmpegInstalled = found
            self.hasCheckedFFmpeg = true
        }
    }

    // MARK: - Duration Fetching

    // Fetch duration for a file asynchronously
    private func fetchDuration(for batchFile: BatchFile) {
        let service = FFmpegService.shared

        service.getMediaDuration(url: batchFile.mediaFile.url) { [weak self] duration in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let index = self.files.firstIndex(where: { $0.id == batchFile.id }) {
                    // Update the MediaFile with duration
                    let oldFile = self.files[index].mediaFile
                    let updatedMediaFile = MediaFile(
                        url: oldFile.url,
                        filename: oldFile.filename,
                        fileExtension: oldFile.fileExtension,
                        fileSize: oldFile.fileSize,
                        duration: duration,
                        isVideo: oldFile.isVideo
                    )

                    self.files[index] = BatchFile(
                        mediaFile: updatedMediaFile,
                        isSelected: self.files[index].isSelected
                    )
                }
            }
        }
    }
}

// Possible states during file processing
enum ProcessingState {
    case idle           // No operation in progress
    case processing     // Currently processing a file
    case completed      // Operation completed successfully
    case error          // Operation failed
}
