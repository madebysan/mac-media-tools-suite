import SwiftUI
import UniformTypeIdentifiers

// Left panel showing the list of files for batch processing
struct FileListPanel: View {
    @EnvironmentObject var appState: AppState
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Files", systemImage: "folder")
                    .font(.headline)
                Spacer()
                Text("\(appState.selectedCount) of \(appState.files.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.windowBackgroundColor))

            Divider()

            // File list or drop zone
            if appState.files.isEmpty {
                // Empty state: drop zone
                dropZone
            } else {
                // File list
                VStack(spacing: 0) {
                    fileList

                    Divider()

                    // Selection controls
                    selectionControls
                }
            }
        }
        .background(Color(.controlBackgroundColor))
    }

    // Drop zone when no files are loaded
    private var dropZone: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "arrow.down.doc")
                .font(.system(size: 40))
                .foregroundColor(isTargeted ? .accentColor : .secondary)

            Text("Drop files here")
                .font(.headline)
                .foregroundColor(isTargeted ? .accentColor : .secondary)

            Text("or folders with media files")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .padding(12)
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop)
        .accessibilityIdentifier("dropZone")
    }

    // List of files
    private var fileList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(appState.files) { file in
                    FileRow(file: file)
                }

                // Add more files area
                addFilesArea
            }
            .padding(8)
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop)
        .accessibilityIdentifier("fileList")
    }

    // Add more files area at bottom of list
    private var addFilesArea: some View {
        HStack {
            Image(systemName: "plus.circle.dashed")
                .foregroundColor(.secondary)
            Text("Drop more files")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.2),
                    style: StrokeStyle(lineWidth: 1, dash: [4])
                )
        )
        .padding(.top, 8)
    }

    // Selection controls at bottom
    private var selectionControls: some View {
        HStack(spacing: 12) {
            Button("Select All") {
                appState.selectAll()
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .accessibilityIdentifier("selectAllButton")

            Button("Deselect All") {
                appState.deselectAll()
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .accessibilityIdentifier("deselectAllButton")

            Spacer()

            Button {
                appState.clearFiles()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundColor(.secondary)
            .help("Clear all files")
            .accessibilityIdentifier("clearFilesButton")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.windowBackgroundColor))
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
}

// Individual file row in the list
struct FileRow: View {
    @EnvironmentObject var appState: AppState
    let file: BatchFile

    var body: some View {
        HStack(spacing: 10) {
            // Checkbox
            Button {
                appState.toggleSelection(file)
            } label: {
                Image(systemName: file.isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(file.isSelected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)

            // File icon
            Image(systemName: file.mediaFile.isVideo ? "film" : "waveform")
                .foregroundColor(.secondary)
                .frame(width: 16)

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.mediaFile.filename)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 8) {
                    Text(file.mediaFile.fileExtension.uppercased())
                    Text(file.mediaFile.formattedSize)
                    if let _ = file.mediaFile.duration {
                        Text(file.mediaFile.formattedDuration)
                    }
                }
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            }

            Spacer()

            // Status indicator
            statusIcon
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(file.isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            appState.toggleSelection(file)
        }
        .contextMenu {
            Button("Remove") {
                appState.removeFile(file)
            }

            if let outputURL = file.outputURL {
                Divider()
                Button("Reveal in Finder") {
                    NSWorkspace.shared.selectFile(outputURL.path, inFileViewerRootedAtPath: outputURL.deletingLastPathComponent().path)
                }
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch file.status {
        case .pending:
            EmptyView()
        case .processing:
            ProgressView()
                .controlSize(.small)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        }
    }
}

#Preview {
    FileListPanel()
        .environmentObject(AppState())
        .frame(width: 280, height: 400)
}
