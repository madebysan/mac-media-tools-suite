import XCTest
@testable import Media_Tools_Suite

final class OperationTests: XCTestCase {

    // MARK: - Enum completeness

    func testAllOperationsExist() {
        // Verify expected count — update if operations are added
        XCTAssertEqual(Operation.allCases.count, 31, "Should have 31 operations")
    }

    func testAllCategoriesExist() {
        XCTAssertEqual(OperationCategory.allCases.count, 6, "Should have 6 categories")
    }

    // MARK: - Every operation has metadata

    func testAllOperationsHaveNames() {
        for op in Operation.allCases {
            XCTAssertFalse(op.name.isEmpty, "\(op.rawValue) should have a name")
        }
    }

    func testAllOperationsHaveDescriptions() {
        for op in Operation.allCases {
            XCTAssertFalse(op.description.isEmpty, "\(op.rawValue) should have a description")
        }
    }

    func testAllCategoriesHaveIcons() {
        for category in OperationCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category.rawValue) should have an icon")
        }
    }

    // MARK: - requiresSecondFile

    func testRequiresSecondFileOperations() {
        let expectedSecondFile: Set<Operation> = [
            .replaceAudio, .addAudioLayer, .mergeVideos, .burnSubtitles, .pictureInPicture
        ]
        for op in Operation.allCases {
            if expectedSecondFile.contains(op) {
                XCTAssertTrue(op.requiresSecondFile, "\(op.rawValue) should require second file")
            } else {
                XCTAssertFalse(op.requiresSecondFile, "\(op.rawValue) should NOT require second file")
            }
        }
    }

    func testExactlyFiveOperationsRequireSecondFile() {
        let count = Operation.allCases.filter { $0.requiresSecondFile }.count
        XCTAssertEqual(count, 5, "Exactly 5 operations should require a second file")
    }

    // MARK: - Category filtering for video files

    func testAudioCategoryForVideoFile() {
        let file = TestFixtures.videoFile
        let ops = OperationCategory.audio.operations(for: file)
        XCTAssertTrue(ops.contains(.removeAudio), "Video should have removeAudio")
        XCTAssertTrue(ops.contains(.extractAudio), "Video should have extractAudio")
        XCTAssertTrue(ops.contains(.replaceAudio), "Video should have replaceAudio")
        XCTAssertTrue(ops.contains(.addAudioLayer), "Video should have addAudioLayer")
        XCTAssertFalse(ops.contains(.normalizeAudio), "Video should NOT have normalizeAudio (audio-only)")
        XCTAssertFalse(ops.contains(.convertAudioFormat), "Video should NOT have convertAudioFormat in audio category")
    }

    func testAudioCategoryForAudioFile() {
        let file = TestFixtures.audioFile
        let ops = OperationCategory.audio.operations(for: file)
        XCTAssertTrue(ops.contains(.normalizeAudio), "Audio should have normalizeAudio")
        XCTAssertTrue(ops.contains(.convertAudioFormat), "Audio should have convertAudioFormat")
        XCTAssertTrue(ops.contains(.adjustVolume), "Audio should have adjustVolume")
        XCTAssertFalse(ops.contains(.removeAudio), "Audio should NOT have removeAudio")
        XCTAssertFalse(ops.contains(.extractAudio), "Audio should NOT have extractAudio")
    }

    func testFormatCategoryForVideoFile() {
        let file = TestFixtures.videoFile
        let ops = OperationCategory.format.operations(for: file)
        XCTAssertTrue(ops.contains(.changeContainer))
        XCTAssertTrue(ops.contains(.compress))
        XCTAssertTrue(ops.contains(.convertToProRes))
        XCTAssertTrue(ops.contains(.resizeVideo))
        XCTAssertTrue(ops.contains(.createProxy))
    }

    func testFormatCategoryForAudioFile() {
        let file = TestFixtures.audioFile
        let ops = OperationCategory.format.operations(for: file)
        XCTAssertEqual(ops, [.convertAudioFormat], "Audio format category should only have convertAudioFormat")
    }

    func testEditCategoryOnlyForVideo() {
        let ops = OperationCategory.edit.operations(for: TestFixtures.videoFile)
        XCTAssertTrue(ops.contains(.trim))
        XCTAssertTrue(ops.contains(.speedChange))
        XCTAssertTrue(ops.contains(.reverse))
        XCTAssertTrue(ops.contains(.rotate))
        XCTAssertTrue(ops.contains(.flip))
        XCTAssertTrue(ops.contains(.cropToVertical))
        XCTAssertTrue(ops.contains(.grayscale))
    }

    func testSplitCategoryOnlyForVideo() {
        let ops = OperationCategory.split.operations(for: TestFixtures.videoFile)
        XCTAssertEqual(ops.count, 3)
        XCTAssertTrue(ops.contains(.splitByParts))
        XCTAssertTrue(ops.contains(.splitBySeconds))
        XCTAssertTrue(ops.contains(.splitBySize))
    }

    func testExportCategoryOnlyForVideo() {
        let ops = OperationCategory.export.operations(for: TestFixtures.videoFile)
        XCTAssertEqual(ops.count, 4)
        XCTAssertTrue(ops.contains(.extractFrames))
        XCTAssertTrue(ops.contains(.createGIF))
        XCTAssertTrue(ops.contains(.videoSummary))
        XCTAssertTrue(ops.contains(.contactSheet))
    }

    func testOverlayCategoryOnlyForVideo() {
        let ops = OperationCategory.overlay.operations(for: TestFixtures.videoFile)
        XCTAssertEqual(ops.count, 3)
        XCTAssertTrue(ops.contains(.mergeVideos))
        XCTAssertTrue(ops.contains(.burnSubtitles))
        XCTAssertTrue(ops.contains(.pictureInPicture))
    }

    // MARK: - Category availability

    func testCategoryAvailabilityForVideo() {
        let file = TestFixtures.videoFile
        for category in OperationCategory.allCases {
            XCTAssertTrue(category.isAvailable(for: file), "\(category.rawValue) should be available for video")
        }
    }

    func testCategoryAvailabilityForAudio() {
        let file = TestFixtures.audioFile
        XCTAssertTrue(OperationCategory.audio.isAvailable(for: file))
        XCTAssertTrue(OperationCategory.format.isAvailable(for: file))
        XCTAssertFalse(OperationCategory.edit.isAvailable(for: file))
        XCTAssertFalse(OperationCategory.split.isAvailable(for: file))
        XCTAssertFalse(OperationCategory.export.isAvailable(for: file))
        XCTAssertFalse(OperationCategory.overlay.isAvailable(for: file))
    }

    // MARK: - Every operation belongs to at least one category

    func testEveryOperationIsInACategory() {
        let videoFile = TestFixtures.videoFile
        let audioFile = TestFixtures.audioFile

        for op in Operation.allCases {
            var found = false
            for category in OperationCategory.allCases {
                let videoOps = category.operations(for: videoFile)
                let audioOps = category.operations(for: audioFile)
                if videoOps.contains(op) || audioOps.contains(op) {
                    found = true
                    break
                }
            }
            XCTAssertTrue(found, "\(op.rawValue) should belong to at least one category")
        }
    }

    // MARK: - Compression presets

    func testCompressionPresetCRFValues() {
        XCTAssertEqual(CompressionPreset.low.crfValue, 28)
        XCTAssertEqual(CompressionPreset.medium.crfValue, 23)
        XCTAssertEqual(CompressionPreset.high.crfValue, 18)
        XCTAssertEqual(CompressionPreset.lossless.crfValue, 0)
    }

    // MARK: - ProRes profiles

    func testProResProfileValues() {
        XCTAssertEqual(ProResProfile.proxy.profileValue, 0)
        XCTAssertEqual(ProResProfile.lt.profileValue, 1)
        XCTAssertEqual(ProResProfile.standard.profileValue, 2)
        XCTAssertEqual(ProResProfile.hq.profileValue, 3)
    }
}
