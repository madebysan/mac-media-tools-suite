import SwiftUI

// Shown after a file is loaded - displays file info and operation options
struct FileLoadedView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var executor = OperationExecutor.shared
    let file: MediaFile

    @State private var selectedCategory: OperationCategory = .audio
    @State private var selectedOperation: Operation? = nil
    @State private var config = OperationConfig()

    var body: some View {
        VStack(spacing: 0) {
            // File info header
            FileInfoHeader(file: file)
                .padding()
                .background(Color(.windowBackgroundColor))

            Divider()

            // Main content
            HStack(spacing: 0) {
                // Category sidebar
                VStack(spacing: 4) {
                    ForEach(OperationCategory.allCases, id: \.self) { category in
                        // Filter categories based on file type
                        if category.isAvailable(for: file) {
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                                selectedOperation = nil
                                config = OperationConfig()
                            }
                        }
                    }

                    Spacer()

                    // Clear file button
                    Button(action: { appState.clearFile() }) {
                        Label("Start Over", systemImage: "arrow.uturn.left")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.secondary)
                }
                .padding()
                .frame(width: 140)
                .background(Color(.controlBackgroundColor))

                Divider()

                // Operations list and config
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedCategory.rawValue)
                            .font(.headline)
                            .padding(.bottom, 4)

                        ForEach(selectedCategory.operations(for: file), id: \.self) { operation in
                            OperationRow(
                                operation: operation,
                                isSelected: selectedOperation == operation
                            ) {
                                selectedOperation = operation
                                config = OperationConfig()  // Reset config
                            }
                        }

                        // Configuration for selected operation
                        if let operation = selectedOperation, operation.requiresConfiguration || operation.requiresSecondFile {
                            Divider()
                                .padding(.vertical, 8)

                            Text("Options")
                                .font(.headline)

                            OperationConfigView(
                                operation: operation,
                                config: $config
                            )
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Process button (fixed at bottom right)
                if selectedOperation != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: executeOperation) {
                                Label("Process", systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(!canProcess)
                        }
                        .padding()
                    }
                }
            }
        }
    }

    // Check if we can start processing
    private var canProcess: Bool {
        guard let operation = selectedOperation else { return false }

        // Check if secondary file is required and selected
        if operation.requiresSecondFile && config.secondaryFile == nil {
            return false
        }

        return true
    }

    // Start the operation
    private func executeOperation() {
        guard let operation = selectedOperation else { return }

        appState.processingState = .processing

        executor.execute(operation: operation, file: file, config: config) { result in
            switch result {
            case .success:
                appState.processingState = .completed
            case .failure:
                appState.processingState = .error
            }
        }
    }
}

// File info displayed at the top
struct FileInfoHeader: View {
    let file: MediaFile

    var body: some View {
        HStack(spacing: 16) {
            // File icon
            Image(systemName: file.isVideo ? "film" : "waveform")
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
                .frame(width: 48, height: 48)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)

            // File details
            VStack(alignment: .leading, spacing: 4) {
                Text(file.filename)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label(file.fileExtension.uppercased(), systemImage: "doc")
                    Label(file.formattedSize, systemImage: "internaldrive")
                    Label(file.formattedDuration, systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// Sidebar category button
struct CategoryButton: View {
    let category: OperationCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.icon)
                    .frame(width: 20)
                Text(category.rawValue)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .accentColor : .primary)
    }
}

// Individual operation row
struct OperationRow: View {
    let operation: Operation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(operation.name)
                        .fontWeight(isSelected ? .medium : .regular)
                    Text(operation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(12)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FileLoadedView(file: MediaFile(
        url: URL(fileURLWithPath: "/test/video.mp4"),
        filename: "My Cool Video",
        fileExtension: "mp4",
        fileSize: 125_400_000,
        duration: 155.0,
        isVideo: true
    ))
    .environmentObject(AppState())
    .frame(width: 600, height: 450)
}
