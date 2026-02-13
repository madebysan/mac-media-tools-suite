import XCTest
@testable import Media_Tools_Suite

final class AppStateTests: XCTestCase {

    // Create a fresh AppState for each test (skips ffmpeg check for speed)
    func makeState() -> AppState {
        let state = AppState()
        return state
    }

    // Create a BatchFile from a MediaFile
    func batchFile(_ file: MediaFile, selected: Bool = true) -> BatchFile {
        BatchFile(mediaFile: file, isSelected: selected)
    }

    // MARK: - canProcess

    func testCanProcessNoFiles() {
        let state = makeState()
        state.selectedOperation = .compress
        XCTAssertFalse(state.canProcess, "Cannot process with no files")
    }

    func testCanProcessNoOperation() {
        let state = makeState()
        state.files = [batchFile(TestFixtures.videoFile)]
        state.selectedOperation = nil
        XCTAssertFalse(state.canProcess, "Cannot process with no operation selected")
    }

    func testCanProcessValid() {
        let state = makeState()
        state.files = [batchFile(TestFixtures.videoFile)]
        state.selectedOperation = .compress
        XCTAssertTrue(state.canProcess, "Should be able to process with file + operation")
    }

    func testCanProcessNoneSelected() {
        let state = makeState()
        state.files = [batchFile(TestFixtures.videoFile, selected: false)]
        state.selectedOperation = .compress
        XCTAssertFalse(state.canProcess, "Cannot process when no files selected")
    }

    func testCanProcessSecondFileMultiSelect() {
        let state = makeState()
        state.files = [
            batchFile(TestFixtures.videoFile),
            batchFile(TestFixtures.mkvFile)
        ]
        state.selectedOperation = .replaceAudio
        XCTAssertFalse(state.canProcess, "Operations requiring second file should not work with multi-select")
    }

    func testCanProcessSecondFileSingleSelect() {
        let state = makeState()
        state.files = [batchFile(TestFixtures.videoFile)]
        state.selectedOperation = .replaceAudio
        XCTAssertTrue(state.canProcess, "Operations requiring second file should work with single select")
    }

    // MARK: - selectAll / deselectAll

    func testSelectAll() {
        let state = makeState()
        state.files = [
            batchFile(TestFixtures.videoFile, selected: false),
            batchFile(TestFixtures.audioFile, selected: false)
        ]
        XCTAssertEqual(state.selectedCount, 0)

        state.selectAll()
        XCTAssertEqual(state.selectedCount, 2, "All files should be selected")
    }

    func testDeselectAll() {
        let state = makeState()
        state.files = [
            batchFile(TestFixtures.videoFile),
            batchFile(TestFixtures.audioFile)
        ]
        XCTAssertEqual(state.selectedCount, 2)

        state.deselectAll()
        XCTAssertEqual(state.selectedCount, 0, "No files should be selected")
    }

    // MARK: - toggleSelection

    func testToggleSelection() {
        let state = makeState()
        let file = batchFile(TestFixtures.videoFile, selected: true)
        state.files = [file]
        XCTAssertTrue(state.files[0].isSelected)

        state.toggleSelection(file)
        XCTAssertFalse(state.files[0].isSelected)

        state.toggleSelection(state.files[0])
        XCTAssertTrue(state.files[0].isSelected)
    }

    // MARK: - clearFiles

    func testClearFiles() {
        let state = makeState()
        state.files = [batchFile(TestFixtures.videoFile)]
        state.selectedOperation = .compress
        state.processingState = .completed
        state.progress = 0.5

        state.clearFiles()

        XCTAssertTrue(state.files.isEmpty)
        XCTAssertNil(state.selectedOperation)
        XCTAssertEqual(state.processingState, .idle)
        XCTAssertEqual(state.progress, 0.0)
    }

    // MARK: - isOperationAvailable

    func testIsOperationAvailableSimple() {
        let state = makeState()
        state.files = [batchFile(TestFixtures.videoFile)]
        XCTAssertTrue(state.isOperationAvailable(.compress))
        XCTAssertTrue(state.isOperationAvailable(.removeAudio))
    }

    func testIsOperationAvailableSecondFileMultiSelect() {
        let state = makeState()
        state.files = [
            batchFile(TestFixtures.videoFile),
            batchFile(TestFixtures.mkvFile)
        ]
        XCTAssertFalse(state.isOperationAvailable(.replaceAudio), "Replace audio not available in multi-select")
        XCTAssertFalse(state.isOperationAvailable(.burnSubtitles), "Burn subtitles not available in multi-select")
        XCTAssertTrue(state.isOperationAvailable(.compress), "Regular operations available in multi-select")
    }

    // MARK: - isOperationCompatible

    func testIsOperationCompatibleVideoOperationsForVideo() {
        let state = makeState()
        state.files = [batchFile(TestFixtures.videoFile)]
        XCTAssertTrue(state.isOperationCompatible(.trim), "trim should be compatible with video")
        XCTAssertTrue(state.isOperationCompatible(.removeAudio), "removeAudio should be compatible with video")
        XCTAssertTrue(state.isOperationCompatible(.extractFrames), "extractFrames should be compatible with video")
    }

    func testIsOperationCompatibleVideoOperationsForAudio() {
        let state = makeState()
        state.files = [batchFile(TestFixtures.audioFile)]
        // Note: isOperationCompatible checks operations(for:) which doesn't filter
        // by isAvailable. Edit ops (trim, etc.) still return true because
        // .edit.operations(for:) returns the same list regardless of file type.
        // The UI hides them via category.isAvailable(for:) instead.
        // removeAudio is only in audio.operations(for: videoFile), not audioFile
        XCTAssertFalse(state.isOperationCompatible(.removeAudio), "removeAudio should NOT be compatible with audio-only")
    }

    func testIsOperationCompatibleAudioOperationsForAudio() {
        let state = makeState()
        state.files = [batchFile(TestFixtures.audioFile)]
        XCTAssertTrue(state.isOperationCompatible(.normalizeAudio), "normalizeAudio should be compatible with audio")
        XCTAssertTrue(state.isOperationCompatible(.convertAudioFormat), "convertAudioFormat should be compatible with audio")
    }

    func testIsOperationCompatibleNoFiles() {
        let state = makeState()
        // With no files, all operations should be shown
        XCTAssertTrue(state.isOperationCompatible(.trim))
        XCTAssertTrue(state.isOperationCompatible(.normalizeAudio))
    }

    // MARK: - Computed properties

    func testHasFiles() {
        let state = makeState()
        XCTAssertFalse(state.hasFiles)
        state.files = [batchFile(TestFixtures.videoFile)]
        XCTAssertTrue(state.hasFiles)
    }

    func testSelectedFiles() {
        let state = makeState()
        state.files = [
            batchFile(TestFixtures.videoFile, selected: true),
            batchFile(TestFixtures.audioFile, selected: false),
            batchFile(TestFixtures.mkvFile, selected: true)
        ]
        XCTAssertEqual(state.selectedFiles.count, 2)
        XCTAssertEqual(state.selectedCount, 2)
    }

    func testCurrentFileLegacy() {
        let state = makeState()
        XCTAssertNil(state.currentFile)
        let video = TestFixtures.videoFile
        state.files = [batchFile(video)]
        XCTAssertNotNil(state.currentFile)
    }

    // MARK: - removeFile

    func testRemoveFile() {
        let state = makeState()
        let bf = batchFile(TestFixtures.videoFile)
        state.files = [bf, batchFile(TestFixtures.audioFile)]
        XCTAssertEqual(state.files.count, 2)

        state.removeFile(bf)
        XCTAssertEqual(state.files.count, 1)
    }

    // MARK: - updateFileStatus

    func testUpdateFileStatus() {
        let state = makeState()
        let bf = batchFile(TestFixtures.videoFile)
        state.files = [bf]
        XCTAssertEqual(state.files[0].status, .pending)

        state.updateFileStatus(bf, status: .processing)
        XCTAssertEqual(state.files[0].status, .processing)

        let outputURL = URL(fileURLWithPath: "/tmp/output.mp4")
        state.updateFileStatus(bf, status: .completed, outputURL: outputURL)
        XCTAssertEqual(state.files[0].status, .completed)
        XCTAssertEqual(state.files[0].outputURL, outputURL)
    }

    func testResetFileStatuses() {
        let state = makeState()
        let bf = batchFile(TestFixtures.videoFile)
        state.files = [bf]
        state.updateFileStatus(bf, status: .completed, outputURL: URL(fileURLWithPath: "/tmp/out.mp4"))

        state.resetFileStatuses()
        XCTAssertEqual(state.files[0].status, .pending)
        XCTAssertNil(state.files[0].outputURL)
        XCTAssertNil(state.files[0].error)
    }
}
