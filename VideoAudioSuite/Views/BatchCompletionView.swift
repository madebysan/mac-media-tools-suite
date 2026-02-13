import SwiftUI

// View shown after batch processing completes
struct BatchCompletionView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var batchExecutor = BatchExecutor.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Summary icon
            summaryIcon

            // Summary text
            VStack(spacing: 8) {
                Text(summaryTitle)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(summarySubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Results list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(appState.files.filter { $0.status != .pending }) { file in
                        ResultRow(file: file)
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 200)

            Spacer()

            // Action buttons
            HStack(spacing: 16) {
                // Reveal in Finder (if any succeeded)
                if batchExecutor.successCount > 0 {
                    Button {
                        revealFirstOutput()
                    } label: {
                        Label("Reveal in Finder", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                // Process more
                Button {
                    processMore()
                } label: {
                    Label("Process More", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }

    // Summary icon based on results
    @ViewBuilder
    private var summaryIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor.opacity(0.15))
                .frame(width: 80, height: 80)

            Image(systemName: iconName)
                .font(.system(size: 36))
                .foregroundColor(iconBackgroundColor)
        }
    }

    private var iconName: String {
        if batchExecutor.failureCount == 0 {
            return "checkmark.circle.fill"
        } else if batchExecutor.successCount == 0 {
            return "xmark.circle.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconBackgroundColor: Color {
        if batchExecutor.failureCount == 0 {
            return .green
        } else if batchExecutor.successCount == 0 {
            return .red
        } else {
            return .orange
        }
    }

    private var summaryTitle: String {
        if batchExecutor.failureCount == 0 {
            return "All Done!"
        } else if batchExecutor.successCount == 0 {
            return "Processing Failed"
        } else {
            return "Completed with Errors"
        }
    }

    private var summarySubtitle: String {
        let total = batchExecutor.successCount + batchExecutor.failureCount
        if batchExecutor.failureCount == 0 {
            return "\(total) file\(total == 1 ? "" : "s") processed successfully"
        } else if batchExecutor.successCount == 0 {
            return "All \(total) file\(total == 1 ? "" : "s") failed to process"
        } else {
            return "\(batchExecutor.successCount) succeeded, \(batchExecutor.failureCount) failed"
        }
    }

    // Reveal the first successful output in Finder
    private func revealFirstOutput() {
        if let firstSuccess = appState.files.first(where: { $0.status == .completed }),
           let outputURL = firstSuccess.outputURL {
            NSWorkspace.shared.selectFile(outputURL.path, inFileViewerRootedAtPath: outputURL.deletingLastPathComponent().path)
        }
    }

    // Reset and process more files
    private func processMore() {
        batchExecutor.reset()
        appState.resetFileStatuses()
        appState.processingState = .idle
    }
}

// Individual result row
struct ResultRow: View {
    let file: BatchFile

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: file.status == .completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(file.status == .completed ? .green : .red)

            // File name
            VStack(alignment: .leading, spacing: 2) {
                Text(file.mediaFile.filename)
                    .font(.subheadline)
                    .lineLimit(1)

                if file.status == .completed, let outputURL = file.outputURL {
                    Text(outputURL.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else if let error = file.error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Reveal button (for successful files)
            if file.status == .completed, let outputURL = file.outputURL {
                Button {
                    NSWorkspace.shared.selectFile(outputURL.path, inFileViewerRootedAtPath: outputURL.deletingLastPathComponent().path)
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Reveal in Finder")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    BatchCompletionView()
        .environmentObject({
            let state = AppState()
            state.files = [
                {
                    var file = BatchFile(mediaFile: MediaFile(
                        url: URL(fileURLWithPath: "/test/video1.mp4"),
                        filename: "video1",
                        fileExtension: "mp4",
                        fileSize: 1000000,
                        duration: 120,
                        isVideo: true
                    ))
                    file.status = .completed
                    file.outputURL = URL(fileURLWithPath: "/test/video1-compressed.mp4")
                    return file
                }(),
                {
                    var file = BatchFile(mediaFile: MediaFile(
                        url: URL(fileURLWithPath: "/test/video2.mp4"),
                        filename: "video2",
                        fileExtension: "mp4",
                        fileSize: 2000000,
                        duration: 240,
                        isVideo: true
                    ))
                    file.status = .failed
                    file.error = .processingFailed("Test error")
                    return file
                }()
            ]
            return state
        }())
        .frame(width: 500, height: 450)
}
