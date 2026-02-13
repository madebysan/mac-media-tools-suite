import XCTest
@testable import Media_Tools_Suite

final class MediaFileTests: XCTestCase {

    // MARK: - Failable initializer (format validation)

    func testAcceptsMP4() {
        // Need a real file for the failable init, so use /tmp
        let url = URL(fileURLWithPath: "/tmp/test.mp4")
        // Create a tiny file so FileManager can read it
        FileManager.default.createFile(atPath: url.path, contents: Data([0x00]), attributes: nil)
        defer { try? FileManager.default.removeItem(at: url) }

        let file = MediaFile(url: url)
        XCTAssertNotNil(file, "Should accept .mp4")
        XCTAssertTrue(file!.isVideo)
        XCTAssertEqual(file!.fileExtension, "mp4")
    }

    func testAcceptsMOV() {
        let url = URL(fileURLWithPath: "/tmp/test.mov")
        FileManager.default.createFile(atPath: url.path, contents: Data([0x00]), attributes: nil)
        defer { try? FileManager.default.removeItem(at: url) }

        let file = MediaFile(url: url)
        XCTAssertNotNil(file, "Should accept .mov")
        XCTAssertTrue(file!.isVideo)
    }

    func testAcceptsMP3() {
        let url = URL(fileURLWithPath: "/tmp/test.mp3")
        FileManager.default.createFile(atPath: url.path, contents: Data([0x00]), attributes: nil)
        defer { try? FileManager.default.removeItem(at: url) }

        let file = MediaFile(url: url)
        XCTAssertNotNil(file, "Should accept .mp3")
        XCTAssertFalse(file!.isVideo)
    }

    func testAcceptsWAV() {
        let url = URL(fileURLWithPath: "/tmp/test.wav")
        FileManager.default.createFile(atPath: url.path, contents: Data([0x00]), attributes: nil)
        defer { try? FileManager.default.removeItem(at: url) }

        let file = MediaFile(url: url)
        XCTAssertNotNil(file, "Should accept .wav")
        XCTAssertFalse(file!.isVideo)
    }

    func testRejectsTXT() {
        let url = URL(fileURLWithPath: "/tmp/test.txt")
        FileManager.default.createFile(atPath: url.path, contents: Data([0x00]), attributes: nil)
        defer { try? FileManager.default.removeItem(at: url) }

        let file = MediaFile(url: url)
        XCTAssertNil(file, "Should reject .txt")
    }

    func testRejectsPDF() {
        let url = URL(fileURLWithPath: "/tmp/test.pdf")
        FileManager.default.createFile(atPath: url.path, contents: Data([0x00]), attributes: nil)
        defer { try? FileManager.default.removeItem(at: url) }

        let file = MediaFile(url: url)
        XCTAssertNil(file, "Should reject .pdf")
    }

    func testRejectsJPG() {
        let url = URL(fileURLWithPath: "/tmp/test.jpg")
        FileManager.default.createFile(atPath: url.path, contents: Data([0x00]), attributes: nil)
        defer { try? FileManager.default.removeItem(at: url) }

        let file = MediaFile(url: url)
        XCTAssertNil(file, "Should reject .jpg")
    }

    // MARK: - All supported formats accepted

    func testAllVideoFormatsAccepted() {
        let videoExts = ["mp4", "mov", "mkv", "avi", "webm", "m4v"]
        for ext in videoExts {
            let url = URL(fileURLWithPath: "/tmp/formattest.\(ext)")
            FileManager.default.createFile(atPath: url.path, contents: Data([0x00]), attributes: nil)
            defer { try? FileManager.default.removeItem(at: url) }

            let file = MediaFile(url: url)
            XCTAssertNotNil(file, "Should accept .\(ext)")
            XCTAssertTrue(file!.isVideo, ".\(ext) should be video")
        }
    }

    func testAllAudioFormatsAccepted() {
        let audioExts = ["mp3", "wav", "aac", "m4a", "flac", "ogg"]
        for ext in audioExts {
            let url = URL(fileURLWithPath: "/tmp/formattest.\(ext)")
            FileManager.default.createFile(atPath: url.path, contents: Data([0x00]), attributes: nil)
            defer { try? FileManager.default.removeItem(at: url) }

            let file = MediaFile(url: url)
            XCTAssertNotNil(file, "Should accept .\(ext)")
            XCTAssertFalse(file!.isVideo, ".\(ext) should be audio")
        }
    }

    // MARK: - Formatted duration

    func testFormattedDurationShort() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/tmp/test.mp4"),
            filename: "test", fileExtension: "mp4",
            fileSize: 0, duration: 65.0, isVideo: true
        )
        XCTAssertEqual(file.formattedDuration, "1:05")
    }

    func testFormattedDurationLong() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/tmp/test.mp4"),
            filename: "test", fileExtension: "mp4",
            fileSize: 0, duration: 3661.0, isVideo: true
        )
        XCTAssertEqual(file.formattedDuration, "1:01:01")
    }

    func testFormattedDurationZero() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/tmp/test.mp4"),
            filename: "test", fileExtension: "mp4",
            fileSize: 0, duration: 0.0, isVideo: true
        )
        XCTAssertEqual(file.formattedDuration, "0:00")
    }

    func testFormattedDurationNil() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/tmp/test.mp4"),
            filename: "test", fileExtension: "mp4",
            fileSize: 0, duration: nil, isVideo: true
        )
        XCTAssertEqual(file.formattedDuration, "Unknown")
    }

    // MARK: - Formatted size

    func testFormattedSize() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/tmp/test.mp4"),
            filename: "test", fileExtension: "mp4",
            fileSize: 104_857_600, duration: nil, isVideo: true
        )
        // ByteCountFormatter with .file style should produce something like "104.9 MB"
        XCTAssertFalse(file.formattedSize.isEmpty, "formattedSize should not be empty")
        XCTAssertTrue(file.formattedSize.contains("MB"), "~100MB file should show MB")
    }

    func testFormattedSizeSmall() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/tmp/test.mp3"),
            filename: "test", fileExtension: "mp3",
            fileSize: 500_000, duration: nil, isVideo: false
        )
        XCTAssertTrue(file.formattedSize.contains("KB") || file.formattedSize.contains("kB"),
                      "500KB file should show KB")
    }

    // MARK: - Direct initializer

    func testDirectInitializer() {
        let file = MediaFile(
            url: URL(fileURLWithPath: "/tmp/test.mp4"),
            filename: "my-video",
            fileExtension: "mp4",
            fileSize: 1000,
            duration: 60.0,
            isVideo: true
        )
        XCTAssertEqual(file.filename, "my-video")
        XCTAssertEqual(file.fileExtension, "mp4")
        XCTAssertEqual(file.fileSize, 1000)
        XCTAssertEqual(file.duration, 60.0)
        XCTAssertTrue(file.isVideo)
    }

    // MARK: - Identity

    func testUniqueIDs() {
        let file1 = TestFixtures.videoFile
        let file2 = TestFixtures.videoFile
        XCTAssertNotEqual(file1.id, file2.id, "Each MediaFile should have a unique ID")
    }
}
