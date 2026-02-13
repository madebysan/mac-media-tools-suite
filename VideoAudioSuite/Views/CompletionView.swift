import SwiftUI
import AppKit

// Shows results after an operation completes
struct CompletionView: View {
    @EnvironmentObject var appState: AppState

    let file: MediaFile
    let operation: Operation
    let outputURL: URL
    let error: FFmpegError?

    @State private var showingDetails = false

    var body: some View {
        VStack(spacing: 24) {
            if let error = error {
                // Error state
                errorContent(error)
            } else {
                // Success state
                successContent
            }
        }
        .padding(32)
    }

    // Success UI
    private var successContent: some View {
        VStack(spacing: 24) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.green)

            Text("Done!")
                .font(.title2)
                .fontWeight(.semibold)

            // Output file info
            VStack(spacing: 8) {
                Text(outputURL.lastPathComponent)
                    .font(.headline)

                // Show file size comparison if we can
                FileSizeComparison(originalSize: file.fileSize, outputURL: outputURL)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            // Action buttons
            HStack(spacing: 16) {
                Button("Reveal in Finder") {
                    NSWorkspace.shared.selectFile(outputURL.path, inFileViewerRootedAtPath: outputURL.deletingLastPathComponent().path)
                }
                .buttonStyle(.bordered)

                Button("Process Another") {
                    appState.clearFile()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // Error UI
    private func errorContent(_ error: FFmpegError) -> some View {
        VStack(spacing: 24) {
            // Error icon
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.red)

            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)

            // Error message
            Text(error.errorDescription ?? "Unknown error")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Expandable details
            DisclosureGroup("Show details", isExpanded: $showingDetails) {
                ScrollView {
                    Text(error.technicalDetails)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 100)
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(4)
            }
            .frame(maxWidth: 300)

            Spacer()

            // Action buttons
            HStack(spacing: 16) {
                Button("Try Again") {
                    appState.processingState = .idle
                }
                .buttonStyle(.bordered)

                Button("Start Over") {
                    appState.clearFile()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview("Success") {
    CompletionView(
        file: MediaFile(
            url: URL(fileURLWithPath: "/test/video.mp4"),
            filename: "My Video",
            fileExtension: "mp4",
            fileSize: 125_400_000,
            duration: 155.0,
            isVideo: true
        ),
        operation: .compress,
        outputURL: URL(fileURLWithPath: "/test/video-compressed.mp4"),
        error: nil
    )
    .environmentObject(AppState())
    .frame(width: 400, height: 400)
}

#Preview("Error") {
    CompletionView(
        file: MediaFile(
            url: URL(fileURLWithPath: "/test/video.mp4"),
            filename: "My Video",
            fileExtension: "mp4",
            fileSize: 125_400_000,
            duration: 155.0,
            isVideo: true
        ),
        operation: .compress,
        outputURL: URL(fileURLWithPath: "/test/video-compressed.mp4"),
        error: .processingFailed("ffmpeg exited with error code 1: Invalid codec specified")
    )
    .environmentObject(AppState())
    .frame(width: 400, height: 400)
}

// Helper view for file size comparison
struct FileSizeComparison: View {
    let originalSize: Int64
    let outputURL: URL

    var body: some View {
        if let outputSize = try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64 {
            let formatter = ByteCountFormatter()

            HStack(spacing: 4) {
                Text(formatter.string(fromByteCount: originalSize))
                    .foregroundColor(.secondary)
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatter.string(fromByteCount: outputSize))
                    .foregroundColor(outputSize < originalSize ? .green : .primary)
            }
            .font(.caption)
        }
    }
}
