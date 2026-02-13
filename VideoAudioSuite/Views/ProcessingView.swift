import SwiftUI

// Shows progress while an operation is running
struct ProcessingView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var executor = OperationExecutor.shared

    let file: MediaFile
    let operation: Operation

    var body: some View {
        VStack(spacing: 24) {
            // File being processed
            HStack(spacing: 12) {
                Image(systemName: file.isVideo ? "film" : "waveform")
                    .font(.title2)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading) {
                    Text(file.filename)
                        .font(.headline)
                    Text(operation.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()

            // Progress indicator
            VStack(spacing: 16) {
                // Animated icon
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .rotationEffect(.degrees(executor.progress * 360))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: executor.isProcessing)

                Text("Processing...")
                    .font(.title3)

                // Progress bar
                VStack(spacing: 8) {
                    ProgressView(value: executor.progress)
                        .progressViewStyle(.linear)
                        .frame(width: 200)

                    Text("\(Int(executor.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Estimated time (if we have duration info)
                if let duration = file.duration, executor.progress > 0.05 {
                    let elapsed = duration * executor.progress
                    let remaining = duration - elapsed
                    Text("About \(formatTime(remaining)) remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Cancel button
            Button("Cancel") {
                executor.cancel()
                appState.processingState = .idle
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
    }

    private func formatTime(_ seconds: Double) -> String {
        if seconds < 60 {
            return "\(Int(seconds)) seconds"
        } else if seconds < 3600 {
            let mins = Int(seconds / 60)
            return "\(mins) minute\(mins == 1 ? "" : "s")"
        } else {
            let hours = Int(seconds / 3600)
            let mins = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(mins)m"
        }
    }
}

#Preview {
    ProcessingView(
        file: MediaFile(
            url: URL(fileURLWithPath: "/test/video.mp4"),
            filename: "My Video",
            fileExtension: "mp4",
            fileSize: 125_400_000,
            duration: 155.0,
            isVideo: true
        ),
        operation: .compress
    )
    .environmentObject(AppState())
    .frame(width: 400, height: 350)
}
