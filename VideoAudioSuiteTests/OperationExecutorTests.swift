import XCTest
@testable import Media_Tools_Suite

final class OperationExecutorTests: XCTestCase {

    let executor = OperationExecutor.shared

    // MARK: - Helper

    /// Builds arguments for the given operation and returns (args, outputURL)
    func build(
        _ operation: Operation,
        file: MediaFile? = nil,
        config: OperationConfig? = nil
    ) throws -> ([String], URL) {
        try executor.buildArguments(
            operation: operation,
            file: file ?? TestFixtures.videoFile,
            config: config ?? TestFixtures.defaultConfig
        )
    }

    // MARK: - Tier 1: Simple operations

    func testRemoveAudio() throws {
        let (args, output) = try build(.removeAudio)
        XCTAssertTrue(args.contains("-an"), "Should strip audio")
        XCTAssertTrue(args.contains("-c:v"), "Should have video codec flag")
        XCTAssertTrue(args.contains("copy"), "Should copy video stream")
        XCTAssertTrue(args.contains("-y"), "Should overwrite output")
        XCTAssertTrue(output.lastPathComponent.contains("-noaudio"), "Output should have -noaudio suffix")
        XCTAssertEqual(output.pathExtension, "mp4")
    }

    func testExtractAudio() throws {
        let (args, output) = try build(.extractAudio)
        XCTAssertTrue(args.contains("-vn"), "Should strip video")
        XCTAssertTrue(args.contains("-acodec"), "Should have audio codec flag")
        XCTAssertTrue(output.lastPathComponent.contains("-audio"), "Output should have -audio suffix")
        // Default MP4 should extract to AAC
        XCTAssertEqual(output.pathExtension, "aac")
    }

    func testExtractAudioFromMKV() throws {
        let (_, output) = try build(.extractAudio, file: TestFixtures.mkvFile)
        XCTAssertEqual(output.pathExtension, "aac", "MKV should extract to AAC")
    }

    func testExtractAudioFromAVI() throws {
        let (_, output) = try build(.extractAudio, file: TestFixtures.aviFile)
        XCTAssertEqual(output.pathExtension, "mp3", "AVI should extract to MP3")
    }

    func testChangeContainer() throws {
        var config = TestFixtures.defaultConfig
        config.targetFormat = "mkv"
        let (args, output) = try build(.changeContainer, config: config)
        XCTAssertTrue(args.contains("-c"), "Should have codec flag")
        XCTAssertTrue(args.contains("copy"), "Should stream copy")
        XCTAssertEqual(output.pathExtension, "mkv", "Output should be MKV")
    }

    func testChangeContainerDefaultMP4() throws {
        var config = TestFixtures.defaultConfig
        config.targetFormat = nil
        let (_, output) = try build(.changeContainer, config: config)
        XCTAssertEqual(output.pathExtension, "mp4", "Default format should be MP4")
    }

    func testCompress() throws {
        var config = TestFixtures.defaultConfig
        config.compressionPreset = .medium
        let (args, _) = try build(.compress, config: config)
        XCTAssertTrue(args.contains("libx264"), "Should use H.264 encoder")
        XCTAssertTrue(args.contains("23"), "Medium preset should have CRF 23")
        XCTAssertTrue(args.contains("-preset"), "Should have encoding preset")
        XCTAssertTrue(args.contains("medium"), "Should use medium preset")
        XCTAssertTrue(args.contains("aac"), "Should use AAC audio")
        XCTAssertTrue(args.contains("128k"), "Should have 128k audio bitrate")
    }

    func testCompressLow() throws {
        var config = TestFixtures.defaultConfig
        config.compressionPreset = .low
        let (args, _) = try build(.compress, config: config)
        XCTAssertTrue(args.contains("28"), "Low preset should have CRF 28")
    }

    func testCompressHigh() throws {
        var config = TestFixtures.defaultConfig
        config.compressionPreset = .high
        let (args, _) = try build(.compress, config: config)
        XCTAssertTrue(args.contains("18"), "High preset should have CRF 18")
    }

    func testCompressLossless() throws {
        var config = TestFixtures.defaultConfig
        config.compressionPreset = .lossless
        let (args, _) = try build(.compress, config: config)
        XCTAssertTrue(args.contains("0"), "Lossless preset should have CRF 0")
    }

    func testConvertToProRes() throws {
        var config = TestFixtures.defaultConfig
        config.proresProfile = .standard
        let (args, output) = try build(.convertToProRes, config: config)
        XCTAssertTrue(args.contains("prores_ks"), "Should use ProRes encoder")
        XCTAssertTrue(args.contains("2"), "Standard profile value should be 2")
        XCTAssertTrue(args.contains("pcm_s16le"), "Should use PCM audio")
        XCTAssertEqual(output.pathExtension, "mov", "ProRes should output MOV")
        XCTAssertTrue(output.lastPathComponent.contains("-prores"), "Output should have -prores suffix")
    }

    func testConvertToProResProxy() throws {
        var config = TestFixtures.defaultConfig
        config.proresProfile = .proxy
        let (args, _) = try build(.convertToProRes, config: config)
        XCTAssertTrue(args.contains("0"), "Proxy profile value should be 0")
    }

    func testNormalizeAudio() throws {
        let (args, output) = try build(.normalizeAudio, file: TestFixtures.audioFile)
        XCTAssertTrue(args.contains("-af"), "Should have audio filter")
        // Check for loudnorm filter
        let afIndex = args.firstIndex(of: "-af")!
        let filterValue = args[args.index(after: afIndex)]
        XCTAssertTrue(filterValue.contains("loudnorm"), "Should use loudnorm filter")
        XCTAssertTrue(output.lastPathComponent.contains("-normalized"))
    }

    func testReverse() throws {
        let (args, output) = try build(.reverse)
        XCTAssertTrue(args.contains("-vf"), "Should have video filter")
        XCTAssertTrue(args.contains("reverse"), "Should have reverse video filter")
        XCTAssertTrue(args.contains("-af"), "Should have audio filter")
        XCTAssertTrue(args.contains("areverse"), "Should have areverse audio filter")
        XCTAssertTrue(output.lastPathComponent.contains("-reversed"))
    }

    func testGrayscale() throws {
        let (args, output) = try build(.grayscale)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertEqual(filterValue, "format=gray", "Should use gray format filter")
        XCTAssertTrue(args.contains("-c:a"), "Should copy audio")
        XCTAssertTrue(output.lastPathComponent.contains("-bw"))
    }

    func testAdjustVolume() throws {
        var config = TestFixtures.defaultConfig
        config.volumeAdjustment = 2.0
        let (args, output) = try build(.adjustVolume, config: config)
        let afIndex = args.firstIndex(of: "-af")!
        let filterValue = args[args.index(after: afIndex)]
        XCTAssertEqual(filterValue, "volume=2.0", "Should set volume to 2.0")
        XCTAssertTrue(output.lastPathComponent.contains("-volume"))
    }

    func testRemoveSilence() throws {
        let (args, output) = try build(.removeSilence)
        let afIndex = args.firstIndex(of: "-af")!
        let filterValue = args[args.index(after: afIndex)]
        XCTAssertTrue(filterValue.contains("silenceremove"), "Should use silenceremove filter")
        XCTAssertTrue(output.lastPathComponent.contains("-nosilence"))
    }

    func testRotate90() throws {
        var config = TestFixtures.defaultConfig
        config.rotationAngle = 90
        let (args, output) = try build(.rotate, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertEqual(filterValue, "transpose=1", "90 degrees should be transpose=1")
        XCTAssertTrue(output.lastPathComponent.contains("-rotated90"))
    }

    func testRotate180() throws {
        var config = TestFixtures.defaultConfig
        config.rotationAngle = 180
        let (args, output) = try build(.rotate, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertEqual(filterValue, "transpose=1,transpose=1", "180 degrees should chain two transposes")
        XCTAssertTrue(output.lastPathComponent.contains("-rotated180"))
    }

    func testRotate270() throws {
        var config = TestFixtures.defaultConfig
        config.rotationAngle = 270
        let (args, _) = try build(.rotate, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertEqual(filterValue, "transpose=2", "270 degrees should be transpose=2")
    }

    func testFlipHorizontal() throws {
        var config = TestFixtures.defaultConfig
        config.flipDirection = "horizontal"
        let (args, output) = try build(.flip, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertEqual(filterValue, "hflip", "Horizontal flip should use hflip")
        XCTAssertTrue(output.lastPathComponent.contains("-horizontal"))
    }

    func testFlipVertical() throws {
        var config = TestFixtures.defaultConfig
        config.flipDirection = "vertical"
        let (args, _) = try build(.flip, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertEqual(filterValue, "vflip", "Vertical flip should use vflip")
    }

    // MARK: - Tier 2: Config-heavy operations

    func testTrimWithStartAndEnd() throws {
        var config = TestFixtures.defaultConfig
        config.trimStart = 10.0
        config.trimEnd = 30.0
        let (args, output) = try build(.trim, config: config)
        // -ss should come before -i for fast seeking
        let ssIndex = args.firstIndex(of: "-ss")!
        let iIndex = args.firstIndex(of: "-i")!
        XCTAssertTrue(ssIndex < iIndex, "-ss should come before -i for fast seeking")
        XCTAssertTrue(args.contains("-to"), "Should have -to flag")
        XCTAssertTrue(args.contains("-c"), "Should have codec flag")
        XCTAssertTrue(output.lastPathComponent.contains("-trimmed"))
    }

    func testTrimNoStart() throws {
        var config = TestFixtures.defaultConfig
        config.trimStart = 0
        config.trimEnd = 30.0
        let (args, _) = try build(.trim, config: config)
        XCTAssertFalse(args.contains("-ss"), "Should not have -ss when start is 0")
        XCTAssertTrue(args.contains("-to"), "Should have -to flag")
    }

    func testSpeedChange() throws {
        var config = TestFixtures.defaultConfig
        config.speedMultiplier = 2.0
        let (args, output) = try build(.speedChange, config: config)
        XCTAssertTrue(args.contains("-filter_complex"), "Should use filter_complex")
        let fcIndex = args.firstIndex(of: "-filter_complex")!
        let filterValue = args[args.index(after: fcIndex)]
        XCTAssertTrue(filterValue.contains("setpts=PTS/2.0"), "Should have video speed filter")
        XCTAssertTrue(filterValue.contains("atempo=2.0"), "Should have audio speed filter")
        XCTAssertTrue(output.lastPathComponent.contains("-2.0x"))
    }

    func testResizeVideo1080p() throws {
        var config = TestFixtures.defaultConfig
        config.targetResolution = "1080p"
        let (args, output) = try build(.resizeVideo, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertTrue(filterValue.contains("1920:1080"), "Should scale to 1920:1080")
        XCTAssertTrue(filterValue.contains("force_original_aspect_ratio"), "Should preserve aspect ratio")
        XCTAssertTrue(output.lastPathComponent.contains("-1080p"))
    }

    func testResizeVideo720p() throws {
        var config = TestFixtures.defaultConfig
        config.targetResolution = "720p"
        let (args, _) = try build(.resizeVideo, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertTrue(filterValue.contains("1280:720"), "Should scale to 1280:720")
    }

    func testResizeVideoCustom() throws {
        var config = TestFixtures.defaultConfig
        config.targetResolution = "custom:1440"
        let (args, output) = try build(.resizeVideo, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertEqual(filterValue, "scale=1440:-2", "Custom should scale to width with auto height")
        XCTAssertTrue(output.lastPathComponent.contains("-1440w"))
    }

    func testResizeVideoInvalidCustom() throws {
        var config = TestFixtures.defaultConfig
        config.targetResolution = "custom:abc"
        XCTAssertThrowsError(try build(.resizeVideo, config: config), "Invalid custom resolution should throw")
    }

    func testCreateProxy720p() throws {
        var config = TestFixtures.defaultConfig
        config.proxyResolution = "720p"
        let (args, output) = try build(.createProxy, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertEqual(filterValue, "scale=1280:-2")
        XCTAssertTrue(args.contains("ultrafast"), "Should use ultrafast preset")
        XCTAssertTrue(output.lastPathComponent.contains("-proxy"))
    }

    func testCreateProxy480p() throws {
        var config = TestFixtures.defaultConfig
        config.proxyResolution = "480p"
        let (args, _) = try build(.createProxy, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertEqual(filterValue, "scale=854:-2")
    }

    func testCropToVerticalCenter() throws {
        var config = TestFixtures.defaultConfig
        config.verticalCropPosition = "center"
        let (args, output) = try build(.cropToVertical, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertTrue(filterValue.contains("ih*9/16"), "Should crop to 9:16 ratio")
        XCTAssertTrue(filterValue.contains("(in_w-out_w)/2"), "Center should center the crop")
        XCTAssertTrue(output.lastPathComponent.contains("-vertical"))
    }

    func testCropToVerticalLeft() throws {
        var config = TestFixtures.defaultConfig
        config.verticalCropPosition = "left"
        let (args, _) = try build(.cropToVertical, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertTrue(filterValue.contains(":0:0"), "Left should start at x=0")
    }

    func testSplitByParts() throws {
        var config = TestFixtures.defaultConfig
        config.splitParts = 4
        let (args, output) = try build(.splitByParts, config: config)
        // 120s / 4 parts = 30s segments
        XCTAssertTrue(args.contains("-segment_time"), "Should have segment_time")
        let stIndex = args.firstIndex(of: "-segment_time")!
        let segTime = args[args.index(after: stIndex)]
        XCTAssertEqual(segTime, "30.00", "120s / 4 parts = 30.00s segments")
        XCTAssertTrue(args.contains("-f"), "Should have format flag")
        XCTAssertTrue(args.contains("segment"), "Should use segment format")
        XCTAssertTrue(output.lastPathComponent.contains("-part%03d"))
    }

    func testSplitByPartsNoDuration() throws {
        var config = TestFixtures.defaultConfig
        config.splitParts = 4
        XCTAssertThrowsError(
            try build(.splitByParts, file: TestFixtures.noDurationVideo, config: config),
            "Should throw when duration is nil"
        )
    }

    func testSplitBySeconds() throws {
        var config = TestFixtures.defaultConfig
        config.splitSeconds = 60
        let (args, _) = try build(.splitBySeconds, config: config)
        let stIndex = args.firstIndex(of: "-segment_time")!
        let segTime = args[args.index(after: stIndex)]
        XCTAssertEqual(segTime, "60", "Should split every 60 seconds")
    }

    func testSplitBySize() throws {
        var config = TestFixtures.defaultConfig
        config.splitSizeMB = 50
        // File is 100MB, 120s — 50MB target → ratio 0.5 → segment 60s
        let (args, _) = try build(.splitBySize, config: config)
        let stIndex = args.firstIndex(of: "-segment_time")!
        let segTime = args[args.index(after: stIndex)]
        XCTAssertEqual(segTime, "60.00", "50MB target from 100MB file should give 60s segments")
    }

    func testSplitBySizeNoDuration() throws {
        var config = TestFixtures.defaultConfig
        config.splitSizeMB = 50
        XCTAssertThrowsError(
            try build(.splitBySize, file: TestFixtures.noDurationVideo, config: config),
            "Should throw when duration is nil"
        )
    }

    func testExtractFramesTotalFrames() throws {
        var config = TestFixtures.defaultConfig
        config.frameExtractionMode = .totalFrames
        config.frameCount = 10
        let (args, output) = try build(.extractFrames, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        // 10 frames from 120s = fps=0.083...
        XCTAssertTrue(filterValue.hasPrefix("fps="), "Should have fps filter")
        XCTAssertTrue(args.contains("-vsync"), "Should have vsync flag")
        XCTAssertEqual(output.pathExtension, "png")
    }

    func testExtractFramesEveryNSeconds() throws {
        var config = TestFixtures.defaultConfig
        config.frameExtractionMode = .everyNSeconds
        config.frameIntervalSeconds = 5.0
        let (args, _) = try build(.extractFrames, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        // 1/5 = 0.2 fps
        XCTAssertTrue(filterValue.contains("fps=0.2"), "Should extract at 0.2 fps")
    }

    func testExtractFramesEveryNFrames() throws {
        var config = TestFixtures.defaultConfig
        config.frameExtractionMode = .everyNFrames
        config.frameIntervalFrames = 30
        let (args, _) = try build(.extractFrames, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertTrue(filterValue.contains("select="), "Should use select filter")
        XCTAssertTrue(filterValue.contains("mod(n"), "Should use modulo for frame selection")
    }

    func testExtractFramesTotalFramesNoDuration() throws {
        var config = TestFixtures.defaultConfig
        config.frameExtractionMode = .totalFrames
        config.frameCount = 10
        XCTAssertThrowsError(
            try build(.extractFrames, file: TestFixtures.noDurationVideo, config: config),
            "Should throw when duration is nil for totalFrames mode"
        )
    }

    func testCreateGIF() throws {
        var config = TestFixtures.defaultConfig
        config.gifStart = 5.0
        config.gifDuration = 3
        config.gifFPS = 15
        config.gifWidth = 320
        let (args, output) = try build(.createGIF, config: config)
        XCTAssertTrue(args.contains("-ss"), "Should have start time")
        XCTAssertTrue(args.contains("-t"), "Should have duration")
        let fcIndex = args.firstIndex(of: "-filter_complex")!
        let filterValue = args[args.index(after: fcIndex)]
        XCTAssertTrue(filterValue.contains("fps=15"), "Should set FPS to 15")
        XCTAssertTrue(filterValue.contains("scale=320"), "Should scale to 320 width")
        XCTAssertTrue(filterValue.contains("palettegen"), "Should generate palette")
        XCTAssertTrue(filterValue.contains("paletteuse"), "Should use palette")
        XCTAssertEqual(output.pathExtension, "gif")
    }

    func testVideoSummary() throws {
        var config = TestFixtures.defaultConfig
        config.summaryDuration = 30
        // 120s video, target 30s → speedFactor = 4.0
        let (args, _) = try build(.videoSummary, config: config)
        XCTAssertTrue(args.contains("-filter_complex"), "Should use filter_complex for speed")
        let fcIndex = args.firstIndex(of: "-filter_complex")!
        let filterValue = args[args.index(after: fcIndex)]
        XCTAssertTrue(filterValue.contains("setpts=PTS/4.0"), "Should speed up 4x")
    }

    func testVideoSummaryAlreadyShort() throws {
        var config = TestFixtures.defaultConfig
        config.summaryDuration = 10
        // 5s video, target 10s → speedFactor <= 1 → just copy
        let (args, _) = try build(.videoSummary, file: TestFixtures.shortVideo, config: config)
        XCTAssertTrue(args.contains("-c"), "Should copy streams")
        XCTAssertTrue(args.contains("copy"))
        XCTAssertFalse(args.contains("-filter_complex"), "Should not speed up short video")
    }

    func testVideoSummaryNoDuration() throws {
        var config = TestFixtures.defaultConfig
        config.summaryDuration = 30
        XCTAssertThrowsError(
            try build(.videoSummary, file: TestFixtures.noDurationVideo, config: config),
            "Should throw when duration is nil"
        )
    }

    func testContactSheet() throws {
        var config = TestFixtures.defaultConfig
        config.contactSheetColumns = 4
        config.contactSheetRows = 4
        let (args, output) = try build(.contactSheet, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertTrue(filterValue.contains("tile=4x4"), "Should tile 4x4")
        XCTAssertTrue(filterValue.contains("scale=320:-1"), "Should scale thumbnails")
        XCTAssertTrue(args.contains("-frames:v"), "Should limit to 1 frame")
        XCTAssertEqual(output.pathExtension, "jpg")
        XCTAssertTrue(output.lastPathComponent.contains("-contact"))
    }

    func testContactSheetNoDuration() throws {
        XCTAssertThrowsError(
            try build(.contactSheet, file: TestFixtures.noDurationVideo),
            "Should throw when duration is nil"
        )
    }

    func testConvertAudioFormatToMP3() throws {
        var config = TestFixtures.defaultConfig
        config.targetAudioFormat = "mp3"
        let (args, output) = try build(.convertAudioFormat, file: TestFixtures.audioFile, config: config)
        XCTAssertTrue(args.contains("libmp3lame"), "Should use MP3 encoder")
        XCTAssertEqual(output.pathExtension, "mp3")
    }

    func testConvertAudioFormatToWAV() throws {
        var config = TestFixtures.defaultConfig
        config.targetAudioFormat = "wav"
        let (args, output) = try build(.convertAudioFormat, file: TestFixtures.audioFile, config: config)
        XCTAssertTrue(args.contains("pcm_s16le"), "Should use PCM codec for WAV")
        XCTAssertEqual(output.pathExtension, "wav")
    }

    func testConvertAudioFormatToFLAC() throws {
        var config = TestFixtures.defaultConfig
        config.targetAudioFormat = "flac"
        let (args, output) = try build(.convertAudioFormat, file: TestFixtures.audioFile, config: config)
        XCTAssertTrue(args.contains("flac"), "Should use FLAC codec")
        XCTAssertEqual(output.pathExtension, "flac")
    }

    func testConvertAudioFormatToAAC() throws {
        var config = TestFixtures.defaultConfig
        config.targetAudioFormat = "aac"
        let (args, output) = try build(.convertAudioFormat, file: TestFixtures.audioFile, config: config)
        XCTAssertTrue(args.contains("aac"), "Should use AAC codec")
        XCTAssertTrue(args.contains("192k"), "Should use 192k bitrate")
        XCTAssertEqual(output.pathExtension, "aac")
    }

    func testConvertAudioFormatDefault() throws {
        var config = TestFixtures.defaultConfig
        config.targetAudioFormat = nil
        let (_, output) = try build(.convertAudioFormat, file: TestFixtures.audioFile, config: config)
        XCTAssertEqual(output.pathExtension, "mp3", "Default should be MP3")
    }

    func testEnhanceAudioThrowsWithoutModel() throws {
        // This should throw because the arnndn model file won't exist at ~/arnndn-models/bd.rnnn in CI
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let modelPath = "\(homeDir)/arnndn-models/bd.rnnn"

        if !FileManager.default.fileExists(atPath: modelPath) {
            XCTAssertThrowsError(
                try build(.enhanceAudio),
                "Should throw when RNN model is missing"
            )
        }
        // If model exists, the test still passes — we just can't verify the throw
    }

    // MARK: - Tier 3: Secondary file operations

    func testReplaceAudioThrowsWithoutSecondaryFile() throws {
        var config = TestFixtures.defaultConfig
        config.secondaryFile = nil
        XCTAssertThrowsError(
            try build(.replaceAudio, config: config),
            "Should throw when no audio file selected"
        )
    }

    func testReplaceAudioWithSecondaryFile() throws {
        var config = TestFixtures.defaultConfig
        config.secondaryFile = TestFixtures.secondaryAudioURL
        let (args, output) = try build(.replaceAudio, config: config)
        // Should have two -i inputs
        let iIndices = args.indices.filter { args[$0] == "-i" }
        XCTAssertEqual(iIndices.count, 2, "Should have two input files")
        XCTAssertTrue(args.contains("-map"), "Should have mapping")
        XCTAssertTrue(args.contains("0:v:0"), "Should map video from first input")
        XCTAssertTrue(args.contains("1:a:0"), "Should map audio from second input")
        XCTAssertTrue(args.contains("-shortest"), "Should use shortest flag")
        XCTAssertTrue(output.lastPathComponent.contains("-newaudio"))
    }

    func testAddAudioLayerThrowsWithoutSecondaryFile() throws {
        var config = TestFixtures.defaultConfig
        config.secondaryFile = nil
        XCTAssertThrowsError(
            try build(.addAudioLayer, config: config),
            "Should throw when no audio file selected"
        )
    }

    func testAddAudioLayerWithSecondaryFile() throws {
        var config = TestFixtures.defaultConfig
        config.secondaryFile = TestFixtures.secondaryAudioURL
        let (args, output) = try build(.addAudioLayer, config: config)
        XCTAssertTrue(args.contains("-filter_complex"), "Should use filter_complex for mixing")
        let fcIndex = args.firstIndex(of: "-filter_complex")!
        let filterValue = args[args.index(after: fcIndex)]
        XCTAssertTrue(filterValue.contains("amix=inputs=2"), "Should mix 2 audio inputs")
        XCTAssertTrue(output.lastPathComponent.contains("-mixed"))
    }

    func testMergeVideosThrowsWithoutVideos() throws {
        var config = TestFixtures.defaultConfig
        config.videosToMerge = []
        XCTAssertThrowsError(
            try build(.mergeVideos, config: config),
            "Should throw when no videos to merge"
        )
    }

    func testMergeVideosWithVideos() throws {
        var config = TestFixtures.defaultConfig
        config.videosToMerge = [TestFixtures.secondaryVideoURL]
        let (args, output) = try build(.mergeVideos, config: config)
        XCTAssertTrue(args.contains("-f"), "Should have format flag")
        XCTAssertTrue(args.contains("concat"), "Should use concat format")
        XCTAssertTrue(args.contains("-safe"), "Should have safe flag")
        XCTAssertTrue(args.contains("0"), "Safe should be 0")
        XCTAssertTrue(output.lastPathComponent.contains("-merged"))
    }

    func testBurnSubtitlesThrowsWithoutFile() throws {
        var config = TestFixtures.defaultConfig
        config.subtitleFile = nil
        XCTAssertThrowsError(
            try build(.burnSubtitles, config: config),
            "Should throw when no subtitle file selected"
        )
    }

    func testBurnSubtitlesWithFile() throws {
        var config = TestFixtures.defaultConfig
        config.subtitleFile = TestFixtures.subtitleURL
        let (args, output) = try build(.burnSubtitles, config: config)
        let vfIndex = args.firstIndex(of: "-vf")!
        let filterValue = args[args.index(after: vfIndex)]
        XCTAssertTrue(filterValue.contains("subtitles="), "Should use subtitles filter")
        XCTAssertTrue(output.lastPathComponent.contains("-subtitled"))
    }

    func testPictureInPictureThrowsWithoutVideo() throws {
        var config = TestFixtures.defaultConfig
        config.pipVideo = nil
        XCTAssertThrowsError(
            try build(.pictureInPicture, config: config),
            "Should throw when no overlay video selected"
        )
    }

    func testPictureInPictureBottomRight() throws {
        var config = TestFixtures.defaultConfig
        config.pipVideo = TestFixtures.secondaryVideoURL
        config.pipPosition = "bottom-right"
        config.pipSize = "small"
        let (args, output) = try build(.pictureInPicture, config: config)
        let fcIndex = args.firstIndex(of: "-filter_complex")!
        let filterValue = args[args.index(after: fcIndex)]
        XCTAssertTrue(filterValue.contains("overlay="), "Should have overlay filter")
        XCTAssertTrue(filterValue.contains("main_w-overlay_w-10:main_h-overlay_h-10"), "Bottom-right position")
        XCTAssertTrue(filterValue.contains("scale=iw/4"), "Small size should be iw/4")
        XCTAssertTrue(output.lastPathComponent.contains("-pip"))
    }

    func testPictureInPictureTopLeft() throws {
        var config = TestFixtures.defaultConfig
        config.pipVideo = TestFixtures.secondaryVideoURL
        config.pipPosition = "top-left"
        config.pipSize = "large"
        let (args, _) = try build(.pictureInPicture, config: config)
        let fcIndex = args.firstIndex(of: "-filter_complex")!
        let filterValue = args[args.index(after: fcIndex)]
        XCTAssertTrue(filterValue.contains("10:10"), "Top-left position")
        XCTAssertTrue(filterValue.contains("scale=iw/2"), "Large size should be iw/2")
    }

    // MARK: - Helper method tests

    func testFormatTime() {
        XCTAssertEqual(executor.formatTime(0), "00:00:00.000")
        XCTAssertEqual(executor.formatTime(61.5), "00:01:01.500")
        XCTAssertEqual(executor.formatTime(3661.123), "01:01:01.123")
    }

    func testBuildAtempoFilterNormalRange() {
        XCTAssertEqual(executor.buildAtempoFilter(speed: 1.0), "atempo=1.0")
        XCTAssertEqual(executor.buildAtempoFilter(speed: 2.0), "atempo=2.0")
        XCTAssertEqual(executor.buildAtempoFilter(speed: 0.5), "atempo=0.5")
    }

    func testBuildAtempoFilterHighSpeed() {
        // 4x speed: needs to chain 2.0,2.0
        let filter = executor.buildAtempoFilter(speed: 4.0)
        XCTAssertTrue(filter.contains("atempo=2.0"), "Should chain atempo=2.0")
        let parts = filter.split(separator: ",")
        XCTAssertGreaterThanOrEqual(parts.count, 2, "Should chain multiple atempo filters")
    }

    func testBuildAtempoFilterLowSpeed() {
        // 0.25x speed: needs to chain 0.5,0.5
        let filter = executor.buildAtempoFilter(speed: 0.25)
        XCTAssertTrue(filter.contains("atempo=0.5"), "Should chain atempo=0.5")
        let parts = filter.split(separator: ",")
        XCTAssertGreaterThanOrEqual(parts.count, 2, "Should chain multiple atempo filters")
    }

    func testDetectAudioFormat() {
        XCTAssertEqual(executor.detectAudioFormat(from: URL(fileURLWithPath: "/test.mp4")), "aac")
        XCTAssertEqual(executor.detectAudioFormat(from: URL(fileURLWithPath: "/test.mkv")), "aac")
        XCTAssertEqual(executor.detectAudioFormat(from: URL(fileURLWithPath: "/test.avi")), "mp3")
        XCTAssertEqual(executor.detectAudioFormat(from: URL(fileURLWithPath: "/test.mov")), "aac")
    }

    // MARK: - All operations produce -y flag

    func testAllOperationsHaveOverwriteFlag() throws {
        // Simple operations that don't need special config or secondary files
        let simpleOps: [Operation] = [
            .removeAudio, .extractAudio, .changeContainer, .compress,
            .convertToProRes, .normalizeAudio, .reverse, .grayscale,
            .adjustVolume, .removeSilence, .rotate, .flip, .trim,
            .speedChange, .resizeVideo, .createProxy, .cropToVertical,
            .splitBySeconds, .createGIF, .contactSheet
        ]

        for op in simpleOps {
            let (args, _) = try build(op)
            XCTAssertTrue(args.contains("-y"), "\(op.name) should have -y flag")
        }
    }
}
