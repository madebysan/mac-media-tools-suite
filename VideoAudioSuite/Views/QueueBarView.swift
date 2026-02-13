import SwiftUI
import UniformTypeIdentifiers

// Bottom bar showing queue status and process button
struct QueueBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var favoritesStore: FavoritesStore
    @ObservedObject var batchExecutor = BatchExecutor.shared

    var body: some View {
        HStack(spacing: 16) {
            if batchExecutor.isRunning {
                // Processing state
                processingContent
            } else {
                // Ready state
                readyContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.windowBackgroundColor))
    }

    // Content when ready to process
    private var readyContent: some View {
        Group {
            // Queue summary or action needed message
            if let actionNeeded = actionNeededMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.orange)
                    Text(actionNeeded)
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            } else if appState.selectedCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)

                    Text("\(appState.selectedCount) file\(appState.selectedCount == 1 ? "" : "s")")
                        .font(.subheadline)

                    if let operation = appState.selectedOperation {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(operation.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            } else {
                Text("Select files and an operation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Process button
            Button {
                startProcessing()
            } label: {
                Label("Process", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canProcess)
            .accessibilityIdentifier("processButton")
        }
    }

    // Message showing what action is needed before processing
    private var actionNeededMessage: String? {
        guard appState.selectedCount > 0, let operation = appState.selectedOperation else {
            return nil
        }

        switch operation {
        // These operations prompt for file when clicking Process - no message needed
        case .replaceAudio, .addAudioLayer:
            return nil
        case .burnSubtitles:
            if appState.operationConfig.subtitleFile == nil {
                return "Select a subtitle file (.srt) above"
            }
        case .pictureInPicture:
            if appState.operationConfig.pipVideo == nil {
                return "Select an overlay video above"
            }
        case .mergeVideos:
            if appState.operationConfig.videosToMerge.isEmpty {
                return "Add videos to merge above"
            }
        default:
            break
        }

        return nil
    }

    // Content when processing
    private var processingContent: some View {
        Group {
            // Progress info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)

                    Text("Processing \(batchExecutor.currentIndex + 1) of \(batchExecutor.totalFiles)")
                        .font(.subheadline)
                }

                Text(batchExecutor.currentFileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Progress bar
            ProgressView(value: batchExecutor.overallProgress)
                .frame(width: 120)

            Text("\(Int(batchExecutor.overallProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40)

            // Cancel button
            Button {
                cancelProcessing()
            } label: {
                Label("Cancel", systemImage: "xmark")
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("cancelButton")
        }
    }

    // Check if we can process
    private var canProcess: Bool {
        guard appState.selectedCount > 0, let operation = appState.selectedOperation else {
            return false
        }

        // Check if secondary file is required and provided
        if operation.requiresSecondFile {
            if appState.selectedCount > 1 {
                return false  // Multi-file not supported for these operations
            }

            switch operation {
            // These operations will prompt for file when clicking Process
            case .replaceAudio, .addAudioLayer:
                return true
            case .burnSubtitles:
                return appState.operationConfig.subtitleFile != nil
            case .pictureInPicture:
                return appState.operationConfig.pipVideo != nil
            case .mergeVideos:
                return !appState.operationConfig.videosToMerge.isEmpty
            default:
                return true
            }
        }

        return true
    }

    // Start batch processing
    private func startProcessing() {
        guard canProcess, let operation = appState.selectedOperation else { return }

        // For operations that need an external file, prompt for it first
        switch operation {
        case .replaceAudio, .addAudioLayer:
            promptForAudioFile { audioURL in
                guard let audioURL = audioURL else { return }
                appState.operationConfig.secondaryFile = audioURL
                executeProcessing(operation: operation)
            }
            return

        default:
            executeProcessing(operation: operation)
        }
    }

    // Execute the actual processing
    private func executeProcessing(operation: Operation) {
        appState.processingState = .processing

        batchExecutor.execute(
            files: appState.selectedFiles,
            operation: operation,
            config: appState.operationConfig,
            appState: appState
        ) {
            // Processing complete
            appState.processingState = batchExecutor.failureCount > 0 ? .error : .completed
        }
    }

    // Prompt user to select an audio file
    private func promptForAudioFile(completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "Select Audio File"
        panel.message = "Choose the audio file to use"
        panel.allowedContentTypes = [.audio, .mp3, .wav, .aiff, UTType(filenameExtension: "m4a")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            completion(panel.url)
        } else {
            completion(nil)
        }
    }

    // Cancel processing
    private func cancelProcessing() {
        batchExecutor.cancel()
        appState.processingState = .idle
    }
}

#Preview {
    VStack {
        QueueBarView()
            .environmentObject({
                let state = AppState()
                state.files = [
                    BatchFile(mediaFile: MediaFile(
                        url: URL(fileURLWithPath: "/test/video1.mp4"),
                        filename: "video1",
                        fileExtension: "mp4",
                        fileSize: 1000000,
                        duration: 120,
                        isVideo: true
                    )),
                    BatchFile(mediaFile: MediaFile(
                        url: URL(fileURLWithPath: "/test/video2.mp4"),
                        filename: "video2",
                        fileExtension: "mp4",
                        fileSize: 2000000,
                        duration: 240,
                        isVideo: true
                    ))
                ]
                state.selectedOperation = .compress
                return state
            }())
            .environmentObject(FavoritesStore())
    }
}
