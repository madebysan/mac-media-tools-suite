import Foundation
import SwiftUI

// Manages favorite operations with persistence to UserDefaults
class FavoritesStore: ObservableObject {
    private static let favoritesKey = "favoriteOperations"

    @Published var favorites: [Operation] = []

    init() {
        loadFavorites()
    }

    // Check if an operation is favorited
    func isFavorite(_ operation: Operation) -> Bool {
        favorites.contains(operation)
    }

    // Toggle favorite status for an operation
    func toggleFavorite(_ operation: Operation) {
        if let index = favorites.firstIndex(of: operation) {
            favorites.remove(at: index)
        } else {
            favorites.append(operation)
        }
        saveFavorites()
    }

    // Add an operation to favorites (if not already there)
    func addFavorite(_ operation: Operation) {
        guard !favorites.contains(operation) else { return }
        favorites.append(operation)
        saveFavorites()
    }

    // Remove an operation from favorites
    func removeFavorite(_ operation: Operation) {
        favorites.removeAll { $0 == operation }
        saveFavorites()
    }

    // Load favorites from UserDefaults
    private func loadFavorites() {
        guard let savedRawValues = UserDefaults.standard.array(forKey: Self.favoritesKey) as? [String] else {
            return
        }

        favorites = savedRawValues.compactMap { rawValue in
            Operation(rawValue: rawValue)
        }
    }

    // Save favorites to UserDefaults
    private func saveFavorites() {
        let rawValues = favorites.map { $0.rawValue }
        UserDefaults.standard.set(rawValues, forKey: Self.favoritesKey)
    }
}
