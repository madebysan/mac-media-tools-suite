import SwiftUI

// Flat list of all operations with search filtering and favorites
struct OperationListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var favoritesStore: FavoritesStore

    // All operations that are compatible with current file types
    private var compatibleOperations: [Operation] {
        Operation.allCases.filter { appState.isOperationCompatible($0) }
    }

    // Filtered operations based on search query and file compatibility
    private var filteredOperations: [Operation] {
        let ops = compatibleOperations

        if appState.searchQuery.isEmpty {
            return ops
        }

        let query = appState.searchQuery.lowercased()
        return ops.filter { operation in
            operation.name.lowercased().contains(query) ||
            operation.description.lowercased().contains(query)
        }
    }

    // Group operations by category
    private var groupedOperations: [(category: OperationCategory, operations: [Operation])] {
        OperationCategory.allCases.compactMap { category in
            let ops = filteredOperations.filter { operation in
                categoryForOperation(operation) == category
            }
            return ops.isEmpty ? nil : (category, ops)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if filteredOperations.isEmpty {
                // No results
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No operations found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
            } else {
                // Operations grouped by category
                ForEach(groupedOperations, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 6) {
                        // Category header
                        HStack(spacing: 6) {
                            Image(systemName: group.category.icon)
                                .font(.caption)
                            Text(group.category.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                        // Operations in this category
                        ForEach(group.operations, id: \.self) { operation in
                            OperationListRow(
                                operation: operation,
                                isSelected: appState.selectedOperation == operation,
                                isFavorite: favoritesStore.isFavorite(operation),
                                isDisabled: !appState.isOperationAvailable(operation),
                                onSelect: {
                                    selectOperation(operation)
                                },
                                onToggleFavorite: {
                                    favoritesStore.toggleFavorite(operation)
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    // Determine which category an operation belongs to
    private func categoryForOperation(_ operation: Operation) -> OperationCategory? {
        for category in OperationCategory.allCases {
            // Check both video and audio operation lists for each category
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

            if category.operations(for: dummyVideoFile).contains(operation) ||
               category.operations(for: dummyAudioFile).contains(operation) {
                return category
            }
        }
        return nil
    }

    // Select an operation
    private func selectOperation(_ operation: Operation) {
        guard appState.isOperationAvailable(operation) else { return }
        appState.selectedOperation = operation
        appState.operationConfig = OperationConfig()
    }
}

// Individual operation row
struct OperationListRow: View {
    let operation: Operation
    let isSelected: Bool
    let isFavorite: Bool
    let isDisabled: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Favorite star
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundColor(isFavorite ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .opacity(isHovered || isFavorite ? 1.0 : 0.3)

                // Operation info
                VStack(alignment: .leading, spacing: 2) {
                    Text(operation.name)
                        .fontWeight(isSelected ? .medium : .regular)
                        .foregroundColor(isDisabled ? .secondary : .primary)

                    Text(operation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Selected indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }

                // Disabled indicator (for multi-file selection)
                if isDisabled {
                    Text("1 file only")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : (isHovered ? Color.secondary.opacity(0.1) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
        .accessibilityIdentifier("operation_\(operation.rawValue)")
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    ScrollView {
        OperationListView()
            .padding()
    }
    .environmentObject(AppState())
    .environmentObject(FavoritesStore())
    .frame(width: 350, height: 500)
}
