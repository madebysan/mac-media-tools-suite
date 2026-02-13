import SwiftUI

// Main workspace with three-panel layout for batch processing
struct MainWorkspaceView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var favoritesStore = FavoritesStore()
    @ObservedObject var batchExecutor = BatchExecutor.shared

    var body: some View {
        VStack(spacing: 0) {
            // Main content area - three columns
            HSplitView {
                // Left panel: File list
                FileListPanel()
                    .frame(minWidth: 180, idealWidth: 220, maxWidth: 300)
                    .accessibilityIdentifier("fileListPanel")

                // Middle panel: Operations
                OperationPanel()
                    .environmentObject(favoritesStore)
                    .frame(minWidth: 250, idealWidth: 280)
                    .accessibilityIdentifier("operationPanel")

                // Right panel: Configuration
                ConfigPanel()
                    .frame(minWidth: 200, idealWidth: 280, maxWidth: 400)
                    .accessibilityIdentifier("configPanel")
            }

            Divider()

            // Bottom bar: Queue status and process button
            QueueBarView()
                .environmentObject(favoritesStore)
                .accessibilityIdentifier("queueBar")
        }
    }
}

// Right panel showing configuration options for selected operation
struct ConfigPanel: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Options")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(.windowBackgroundColor))

            Divider()

            // Content
            if let operation = appState.selectedOperation {
                if operation.requiresConfiguration || operation.requiresSecondFile {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Operation name
                            VStack(alignment: .leading, spacing: 4) {
                                Text(operation.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(operation.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            // Configuration
                            OperationConfigView(
                                operation: operation,
                                config: $appState.operationConfig
                            )
                        }
                        .padding()
                    }
                } else {
                    // No configuration needed
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "checkmark.circle")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        Text(operation.name)
                            .font(.headline)
                        Text("No options needed")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Click Process to start")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                // No operation selected
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "slider.horizontal.3")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Select an operation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }
}

#Preview {
    MainWorkspaceView()
        .environmentObject(AppState())
        .frame(width: 900, height: 500)
}
