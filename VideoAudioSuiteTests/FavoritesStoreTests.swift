import XCTest
@testable import Media_Tools_Suite

final class FavoritesStoreTests: XCTestCase {

    // Use a unique defaults suite per test to avoid cross-contamination
    var store: FavoritesStore!

    override func setUp() {
        super.setUp()
        // Clear any existing favorites before each test
        UserDefaults.standard.removeObject(forKey: "favoriteOperations")
        store = FavoritesStore()
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "favoriteOperations")
        store = nil
        super.tearDown()
    }

    // MARK: - Initial state

    func testInitiallyEmpty() {
        XCTAssertTrue(store.favorites.isEmpty, "Favorites should start empty")
    }

    // MARK: - Toggle favorite

    func testToggleFavoriteOn() {
        store.toggleFavorite(.compress)
        XCTAssertTrue(store.isFavorite(.compress))
        XCTAssertEqual(store.favorites.count, 1)
    }

    func testToggleFavoriteOff() {
        store.toggleFavorite(.compress)
        XCTAssertTrue(store.isFavorite(.compress))

        store.toggleFavorite(.compress)
        XCTAssertFalse(store.isFavorite(.compress))
        XCTAssertEqual(store.favorites.count, 0)
    }

    func testToggleMultiple() {
        store.toggleFavorite(.compress)
        store.toggleFavorite(.trim)
        store.toggleFavorite(.reverse)
        XCTAssertEqual(store.favorites.count, 3)
        XCTAssertTrue(store.isFavorite(.compress))
        XCTAssertTrue(store.isFavorite(.trim))
        XCTAssertTrue(store.isFavorite(.reverse))
    }

    // MARK: - addFavorite / removeFavorite

    func testAddFavorite() {
        store.addFavorite(.compress)
        XCTAssertTrue(store.isFavorite(.compress))
    }

    func testAddFavoriteDuplicate() {
        store.addFavorite(.compress)
        store.addFavorite(.compress)
        XCTAssertEqual(store.favorites.count, 1, "Adding duplicate should not increase count")
    }

    func testRemoveFavorite() {
        store.addFavorite(.compress)
        store.removeFavorite(.compress)
        XCTAssertFalse(store.isFavorite(.compress))
        XCTAssertTrue(store.favorites.isEmpty)
    }

    func testRemoveNonExistent() {
        store.removeFavorite(.compress)
        XCTAssertTrue(store.favorites.isEmpty, "Removing non-existent should not crash")
    }

    // MARK: - isFavorite

    func testIsFavoriteReturnsFalseForNonFavorite() {
        XCTAssertFalse(store.isFavorite(.compress))
    }

    // MARK: - Persistence

    func testPersistence() {
        store.toggleFavorite(.compress)
        store.toggleFavorite(.trim)

        // Create a new store — should load from UserDefaults
        let newStore = FavoritesStore()
        XCTAssertTrue(newStore.isFavorite(.compress), "compress should persist")
        XCTAssertTrue(newStore.isFavorite(.trim), "trim should persist")
        XCTAssertEqual(newStore.favorites.count, 2)
    }

    func testPersistenceAfterRemoval() {
        store.toggleFavorite(.compress)
        store.toggleFavorite(.trim)
        store.toggleFavorite(.compress)  // Remove compress

        let newStore = FavoritesStore()
        XCTAssertFalse(newStore.isFavorite(.compress), "compress should not persist after removal")
        XCTAssertTrue(newStore.isFavorite(.trim), "trim should persist")
        XCTAssertEqual(newStore.favorites.count, 1)
    }
}
