import SwiftUI

// Middle panel showing operations and favorites
struct OperationPanel: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var favoritesStore: FavoritesStore

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar
                .padding()
                .background(Color(.windowBackgroundColor))

            Divider()

            // Operations list
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Favorites section (if any)
                    if !favoritesStore.favorites.isEmpty && appState.searchQuery.isEmpty {
                        favoritesSection
                    }

                    // All operations list
                    operationsSection
                }
                .padding()
            }
        }
        .background(Color(.controlBackgroundColor).opacity(0.5))
    }

    // Search bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search operations...", text: $appState.searchQuery)
                .textFieldStyle(.plain)
                .accessibilityIdentifier("searchField")

            if !appState.searchQuery.isEmpty {
                Button {
                    appState.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }

    // Favorites section with horizontal chips
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Favorites", systemImage: "star.fill")
                .font(.subheadline)
                .foregroundColor(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(favoritesStore.favorites, id: \.self) { operation in
                    FavoriteChip(
                        operation: operation,
                        isSelected: appState.selectedOperation == operation,
                        isDisabled: !appState.isOperationAvailable(operation)
                    ) {
                        if appState.isOperationAvailable(operation) {
                            selectOperation(operation)
                        }
                    }
                }
            }
        }
    }

    // All operations section
    private var operationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All Operations")
                .font(.subheadline)
                .foregroundColor(.secondary)

            OperationListView()
                .environmentObject(favoritesStore)
        }
    }

    // Select an operation
    private func selectOperation(_ operation: Operation) {
        appState.selectedOperation = operation
        appState.operationConfig = OperationConfig()
    }
}

// Favorite operation chip
struct FavoriteChip: View {
    let operation: Operation
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(operation.name)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.accentColor : Color(.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : (isDisabled ? .secondary : .primary))
                .cornerRadius(16)
                .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// Simple flow layout for horizontal wrapping
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)

        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (height: CGFloat, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (currentY + lineHeight, frames)
    }
}

#Preview {
    OperationPanel()
        .environmentObject(AppState())
        .environmentObject(FavoritesStore())
        .frame(width: 400, height: 500)
}
