import SwiftUI
import UniformTypeIdentifiers

// The main drop zone where users drag files (legacy view, kept for reference)
struct DropZoneView: View {
    @EnvironmentObject var appState: AppState
    @State private var isDragOver = false
    @State private var showError = false
    @State private var errorText = ""

    var body: some View {
        VStack(spacing: 20) {
            // Drop zone area
            ZStack {
                // Border
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isDragOver ? Color.accentColor : Color.secondary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isDragOver ? Color.accentColor.opacity(0.1) : Color.clear)
                    )

                // Content
                VStack(spacing: 16) {
                    Image(systemName: isDragOver ? "arrow.down.circle.fill" : "film")
                        .font(.system(size: 48))
                        .foregroundColor(isDragOver ? .accentColor : .secondary)
                        .animation(.easeInOut(duration: 0.2), value: isDragOver)

                    Text(isDragOver ? "Drop to load" : "Drag video or audio files here")
                        .font(.title3)
                        .foregroundColor(isDragOver ? .accentColor : .primary)

                    Text("MP4, MOV, MKV, AVI, MP3, WAV, AAC, M4A, FLAC")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
            .onDrop(of: [.fileURL], isTargeted: $isDragOver, perform: handleDrop)

            // Error message
            if showError {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text(errorText)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showError)
    }

    // Handle file drop
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                guard let url = url else { return }

                DispatchQueue.main.async {
                    var isDirectory: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                        if isDirectory.boolValue {
                            // It's a folder - add all media files from it
                            appState.addFilesFromFolder(url)
                        } else {
                            // Single file
                            appState.addFiles([url])
                        }
                    }
                }
            }
        }
        return true
    }

    private func showErrorMessage(_ message: String) {
        errorText = message
        showError = true

        // Hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
        }
    }
}

#Preview {
    DropZoneView()
        .environmentObject(AppState())
        .frame(width: 500, height: 400)
}
