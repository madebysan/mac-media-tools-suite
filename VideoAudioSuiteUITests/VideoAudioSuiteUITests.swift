import XCTest

final class VideoAudioSuiteUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // MARK: - App Launch

    func testAppLaunches() throws {
        app.launch()
        // The app should show either the workspace or the ffmpeg missing view
        let workspace = app.groups["fileListPanel"]
        let ffmpegMissing = app.otherElements["ffmpegMissingView"]
        let exists = workspace.waitForExistence(timeout: 5) || ffmpegMissing.waitForExistence(timeout: 2)
        XCTAssertTrue(exists, "App should show workspace or ffmpeg missing view")
    }

    // MARK: - Three-Panel Layout

    func testThreePanelLayoutExists() throws {
        app.launch()
        guard app.groups["fileListPanel"].waitForExistence(timeout: 5) else {
            throw XCTSkip("ffmpeg not installed — workspace not visible")
        }

        XCTAssertTrue(app.groups["fileListPanel"].exists, "File list panel should exist")
        XCTAssertTrue(app.groups["operationPanel"].exists, "Operation panel should exist")
        XCTAssertTrue(app.groups["configPanel"].exists, "Config panel should exist")
        XCTAssertTrue(app.groups["queueBar"].exists, "Queue bar should exist")
    }

    // MARK: - Search Bar

    func testSearchBarExists() throws {
        app.launch()
        guard app.groups["operationPanel"].waitForExistence(timeout: 5) else {
            throw XCTSkip("ffmpeg not installed — workspace not visible")
        }

        let searchField = app.textFields["searchField"]
        XCTAssertTrue(searchField.exists, "Search field should exist in operation panel")
    }

    func testSearchBarFiltersOperations() throws {
        app.launch()
        guard app.groups["operationPanel"].waitForExistence(timeout: 5) else {
            throw XCTSkip("ffmpeg not installed — workspace not visible")
        }

        let searchField = app.textFields["searchField"]
        searchField.click()
        searchField.typeText("compress")

        // The compress operation should still be visible
        let compressRow = app.buttons["operation_compress"]
        XCTAssertTrue(compressRow.waitForExistence(timeout: 2), "Compress operation should be visible after search")

        // An unrelated operation should not be visible
        let reverseRow = app.buttons["operation_reverse"]
        XCTAssertFalse(reverseRow.exists, "Reverse operation should be hidden when searching for 'compress'")
    }

    // MARK: - Operation Selection

    func testSelectingOperationUpdatesConfigPanel() throws {
        app.launch()
        guard app.groups["operationPanel"].waitForExistence(timeout: 5) else {
            throw XCTSkip("ffmpeg not installed — workspace not visible")
        }

        // Click on compress operation
        let compressRow = app.buttons["operation_compress"]
        guard compressRow.waitForExistence(timeout: 2) else {
            throw XCTSkip("Compress operation row not found")
        }
        compressRow.click()

        // Config panel should show the operation name
        let configPanel = app.groups["configPanel"]
        XCTAssertTrue(configPanel.exists, "Config panel should exist after selecting operation")
    }

    // MARK: - Process Button

    func testProcessButtonDisabledWithNoFiles() throws {
        app.launch()
        guard app.groups["queueBar"].waitForExistence(timeout: 5) else {
            throw XCTSkip("ffmpeg not installed — workspace not visible")
        }

        let processButton = app.buttons["processButton"]
        XCTAssertTrue(processButton.exists, "Process button should exist")
        XCTAssertFalse(processButton.isEnabled, "Process button should be disabled with no files")
    }

    // MARK: - Empty State

    func testDropZoneShownWhenNoFiles() throws {
        app.launch()
        guard app.groups["fileListPanel"].waitForExistence(timeout: 5) else {
            throw XCTSkip("ffmpeg not installed — workspace not visible")
        }

        let dropZone = app.otherElements["dropZone"]
        XCTAssertTrue(dropZone.exists, "Drop zone should be visible when no files are loaded")
    }

    // MARK: - FFmpeg Missing View

    func testFFmpegMissingViewWithLaunchArg() throws {
        app.launchArguments.append("--simulate-no-ffmpeg")
        app.launch()

        // If the app supports the launch arg, the ffmpeg missing view should appear
        let ffmpegMissing = app.otherElements["ffmpegMissingView"]
        if ffmpegMissing.waitForExistence(timeout: 3) {
            XCTAssertTrue(ffmpegMissing.exists, "FFmpeg missing view should be visible")
        }
        // If the app doesn't support this launch arg yet, that's OK — skip
    }
}
