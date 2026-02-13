import Foundation
@testable import Media_Tools_Suite

// Resolve ambiguity: Media_Tools_Suite.Operation vs Foundation.Operation
typealias Operation = Media_Tools_Suite.Operation
typealias OperationCategory = Media_Tools_Suite.OperationCategory

// Shared test fixtures for all test files
enum TestFixtures {

    // Standard MP4 video file — 120 seconds, ~100 MB
    static var videoFile: MediaFile {
        MediaFile(
            url: URL(fileURLWithPath: "/tmp/test-video.mp4"),
            filename: "test-video",
            fileExtension: "mp4",
            fileSize: 104_857_600,
            duration: 120.0,
            isVideo: true
        )
    }

    // Standard MP3 audio file — 180 seconds, ~5 MB
    static var audioFile: MediaFile {
        MediaFile(
            url: URL(fileURLWithPath: "/tmp/test-audio.mp3"),
            filename: "test-audio",
            fileExtension: "mp3",
            fileSize: 5_242_880,
            duration: 180.0,
            isVideo: false
        )
    }

    // MKV video for format-specific tests
    static var mkvFile: MediaFile {
        MediaFile(
            url: URL(fileURLWithPath: "/tmp/test-video.mkv"),
            filename: "test-video",
            fileExtension: "mkv",
            fileSize: 209_715_200,
            duration: 300.0,
            isVideo: true
        )
    }

    // AVI video for format-specific tests
    static var aviFile: MediaFile {
        MediaFile(
            url: URL(fileURLWithPath: "/tmp/test-video.avi"),
            filename: "test-video",
            fileExtension: "avi",
            fileSize: 157_286_400,
            duration: 240.0,
            isVideo: true
        )
    }

    // Short 5-second clip for edge case testing
    static var shortVideo: MediaFile {
        MediaFile(
            url: URL(fileURLWithPath: "/tmp/short-clip.mp4"),
            filename: "short-clip",
            fileExtension: "mp4",
            fileSize: 2_097_152,
            duration: 5.0,
            isVideo: true
        )
    }

    // Video with no duration (nil) for error path testing
    static var noDurationVideo: MediaFile {
        MediaFile(
            url: URL(fileURLWithPath: "/tmp/no-duration.mp4"),
            filename: "no-duration",
            fileExtension: "mp4",
            fileSize: 50_000_000,
            duration: nil,
            isVideo: true
        )
    }

    // WAV audio file
    static var wavFile: MediaFile {
        MediaFile(
            url: URL(fileURLWithPath: "/tmp/test-audio.wav"),
            filename: "test-audio",
            fileExtension: "wav",
            fileSize: 44_100_000,
            duration: 60.0,
            isVideo: false
        )
    }

    // Default operation config
    static var defaultConfig: OperationConfig {
        OperationConfig()
    }

    // Secondary file URL for operations that need one
    static var secondaryAudioURL: URL {
        URL(fileURLWithPath: "/tmp/secondary-audio.mp3")
    }

    static var secondaryVideoURL: URL {
        URL(fileURLWithPath: "/tmp/secondary-video.mp4")
    }

    static var subtitleURL: URL {
        URL(fileURLWithPath: "/tmp/subtitles.srt")
    }
}
