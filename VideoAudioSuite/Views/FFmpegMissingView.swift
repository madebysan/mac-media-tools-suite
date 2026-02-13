import SwiftUI

// Shown when ffmpeg is not installed
struct FFmpegMissingView: View {
    @EnvironmentObject var appState: AppState
    @State private var copied = false

    private let installCommand = "brew install ffmpeg"

    var body: some View {
        VStack(spacing: 24) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            // Title
            Text("ffmpeg Required")
                .font(.title2)
                .fontWeight(.semibold)

            // Explanation
            Text("Video Audio Suite uses ffmpeg to process files.\nInstall it with Homebrew to get started.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            // Install command
            HStack {
                Text(installCommand)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                Button(action: copyCommand) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .foregroundColor(copied ? .green : .primary)
                }
                .buttonStyle(.borderless)
                .padding(.trailing, 12)
            }
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)

            // Retry button
            Button("Check Again") {
                appState.checkFFmpegInstallation()
            }
            .buttonStyle(.borderedProminent)

            // Help link
            Link("Don't have Homebrew?", destination: URL(string: "https://brew.sh")!)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }

    private func copyCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(installCommand, forType: .string)
        copied = true

        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}

#Preview {
    FFmpegMissingView()
        .environmentObject(AppState())
        .frame(width: 500, height: 400)
}
