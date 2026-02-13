import Foundation

// Executes ffmpeg operations and reports progress
class OperationExecutor: ObservableObject {
    static let shared = OperationExecutor()

    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var currentOperation: String = ""
    @Published var outputURL: URL? = nil
    @Published var error: FFmpegError? = nil

    private var currentProcess: Process? = nil
    private var totalDuration: Double = 0

    private init() {}

    // Cancel the current operation
    func cancel() {
        currentProcess?.terminate()
        currentProcess = nil
        isProcessing = false
        progress = 0
        currentOperation = ""

        // Clean up partial output file
        if let output = outputURL {
            try? FileManager.default.removeItem(at: output)
        }
        outputURL = nil
    }

    // Execute an operation on a file
    func execute(
        operation: Operation,
        file: MediaFile,
        config: OperationConfig,
        completion: @escaping (Result<URL, FFmpegError>) -> Void
    ) {
        isProcessing = true
        progress = 0
        currentOperation = operation.name
        error = nil
        outputURL = nil
        totalDuration = file.duration ?? 0

        // Build the ffmpeg arguments for this operation
        let arguments: [String]
        let output: URL

        do {
            (arguments, output) = try buildArguments(operation: operation, file: file, config: config)
        } catch let err as FFmpegError {
            isProcessing = false
            error = err
            completion(.failure(err))
            return
        } catch {
            isProcessing = false
            let err = FFmpegError.unknownError(error.localizedDescription)
            self.error = err
            completion(.failure(err))
            return
        }

        outputURL = output

        // Execute ffmpeg
        currentProcess = FFmpegService.shared.execute(
            arguments: arguments,
            progressHandler: { [weak self] seconds in
                guard let self = self, self.totalDuration > 0 else { return }
                self.progress = min(seconds / self.totalDuration, 1.0)
            },
            completion: { [weak self] result in
                self?.isProcessing = false
                self?.currentProcess = nil

                switch result {
                case .success(let url):
                    self?.outputURL = url
                    completion(.success(url))
                case .failure(let err):
                    self?.error = err
                    // Clean up partial file on error
                    if let output = self?.outputURL {
                        try? FileManager.default.removeItem(at: output)
                    }
                    completion(.failure(err))
                }
            }
        )
    }

    // Build ffmpeg arguments for each operation type
    func buildArguments(
        operation: Operation,
        file: MediaFile,
        config: OperationConfig
    ) throws -> ([String], URL) {
        let input = file.url.path
        let ffmpeg = FFmpegService.shared

        switch operation {

        // MARK: - Audio Operations

        case .removeAudio:
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-noaudio")
            return ([
                "-i", input,
                "-an",              // Remove audio
                "-c:v", "copy",     // Copy video stream (no re-encoding)
                "-y",               // Overwrite output
                output.path
            ], output)

        case .extractAudio:
            // Determine output format based on source
            let audioExt = detectAudioFormat(from: file.url)
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-audio", newExtension: audioExt)
            return ([
                "-i", input,
                "-vn",              // Remove video
                "-acodec", "copy",  // Copy audio stream
                "-y",
                output.path
            ], output)

        case .replaceAudio:
            guard let audioFile = config.secondaryFile else {
                throw FFmpegError.unknownError("No audio file selected")
            }
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-newaudio")
            return ([
                "-i", input,
                "-i", audioFile.path,
                "-c:v", "copy",         // Copy video
                "-map", "0:v:0",        // Use video from first input
                "-map", "1:a:0",        // Use audio from second input
                "-shortest",            // End when shortest stream ends
                "-y",
                output.path
            ], output)

        case .addAudioLayer:
            guard let audioFile = config.secondaryFile else {
                throw FFmpegError.unknownError("No audio file selected")
            }
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-mixed")
            return ([
                "-i", input,
                "-i", audioFile.path,
                "-c:v", "copy",
                "-filter_complex", "amix=inputs=2:duration=first",
                "-y",
                output.path
            ], output)

        // MARK: - Format Operations

        case .changeContainer:
            let targetFormat = config.targetFormat ?? "mp4"
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "", newExtension: targetFormat)
            return ([
                "-i", input,
                "-c", "copy",       // Copy all streams
                "-y",
                output.path
            ], output)

        case .compress:
            let crf = config.compressionPreset.crfValue
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-compressed")
            return ([
                "-i", input,
                "-c:v", "libx264",
                "-crf", String(crf),
                "-preset", "medium",
                "-c:a", "aac",
                "-b:a", "128k",
                "-y",
                output.path
            ], output)

        case .convertToProRes:
            let profile = config.proresProfile.profileValue
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-prores", newExtension: "mov")
            return ([
                "-i", input,
                "-c:v", "prores_ks",
                "-profile:v", String(profile),
                "-c:a", "pcm_s16le",
                "-y",
                output.path
            ], output)

        // MARK: - Split Operations

        case .splitByParts:
            let parts = config.splitParts
            guard let duration = file.duration, parts > 0 else {
                throw FFmpegError.unknownError("Cannot determine video duration")
            }
            let segmentTime = duration / Double(parts)
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-part%03d")
            return ([
                "-i", input,
                "-c", "copy",
                "-map", "0",
                "-segment_time", String(format: "%.2f", segmentTime),
                "-f", "segment",
                "-reset_timestamps", "1",
                "-y",
                output.path
            ], output)

        case .splitBySeconds:
            let seconds = config.splitSeconds
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-part%03d")
            return ([
                "-i", input,
                "-c", "copy",
                "-map", "0",
                "-segment_time", String(seconds),
                "-f", "segment",
                "-reset_timestamps", "1",
                "-y",
                output.path
            ], output)

        case .splitBySize:
            // Estimate segment duration based on file size and bitrate
            let targetMB = config.splitSizeMB
            let fileSizeMB = Double(file.fileSize) / (1024 * 1024)
            guard let duration = file.duration, fileSizeMB > 0 else {
                throw FFmpegError.unknownError("Cannot determine video duration or size")
            }
            let ratio = Double(targetMB) / fileSizeMB
            let segmentTime = duration * ratio
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-part%03d")
            return ([
                "-i", input,
                "-c", "copy",
                "-map", "0",
                "-segment_time", String(format: "%.2f", segmentTime),
                "-f", "segment",
                "-reset_timestamps", "1",
                "-y",
                output.path
            ], output)

        // MARK: - Audio-only Operations

        case .normalizeAudio:
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-normalized")
            return ([
                "-i", input,
                "-af", "loudnorm=I=-16:TP=-1.5:LRA=11",
                "-y",
                output.path
            ], output)

        case .convertAudioFormat:
            let targetFormat = config.targetAudioFormat ?? "mp3"
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "", newExtension: targetFormat)

            var args = ["-i", input]

            // Add format-specific encoding
            switch targetFormat {
            case "mp3":
                args += ["-c:a", "libmp3lame", "-q:a", "2"]
            case "aac", "m4a":
                args += ["-c:a", "aac", "-b:a", "192k"]
            case "wav":
                args += ["-c:a", "pcm_s16le"]
            case "flac":
                args += ["-c:a", "flac"]
            default:
                args += ["-c:a", "copy"]
            }

            args += ["-y", output.path]
            return (args, output)

        // MARK: - Edit Operations

        case .trim:
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-trimmed")
            var args = ["-i", input]

            // Add start time if specified
            if config.trimStart > 0 {
                args = ["-ss", formatTime(config.trimStart)] + args
            }

            // Add end time/duration
            if config.trimEnd > config.trimStart {
                args += ["-to", formatTime(config.trimEnd)]
            }

            args += ["-c", "copy", "-y", output.path]
            return (args, output)

        case .speedChange:
            let speed = config.speedMultiplier
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-\(speed)x")

            // Video speed filter: setpts=PTS/speed (higher speed = shorter video)
            // Audio speed filter: atempo (can only go 0.5-2x, so we chain for higher speeds)
            let videoFilter = "setpts=PTS/\(speed)"
            let audioFilter = buildAtempoFilter(speed: speed)

            return ([
                "-i", input,
                "-filter_complex", "[\(0):v]\(videoFilter)[v];[0:a]\(audioFilter)[a]",
                "-map", "[v]",
                "-map", "[a]",
                "-y",
                output.path
            ], output)

        case .reverse:
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-reversed")
            return ([
                "-i", input,
                "-vf", "reverse",
                "-af", "areverse",
                "-y",
                output.path
            ], output)

        // MARK: - Export Operations

        case .extractFrames:
            let outputDir = file.url.deletingLastPathComponent()
            let baseName = file.url.deletingPathExtension().lastPathComponent
            let output = outputDir.appendingPathComponent("\(baseName)-frame%04d.png")

            let videoFilter: String

            switch config.frameExtractionMode {
            case .totalFrames:
                // Extract N frames evenly spaced
                guard let duration = file.duration, config.frameCount > 0 else {
                    throw FFmpegError.unknownError("Cannot determine video duration")
                }
                let fps = Double(config.frameCount) / duration
                videoFilter = "fps=\(fps)"

            case .everyNSeconds:
                // Extract one frame every N seconds
                let fps = 1.0 / config.frameIntervalSeconds
                videoFilter = "fps=\(fps)"

            case .everyNFrames:
                // Extract every Nth frame using select filter
                videoFilter = "select='not(mod(n\\,\(config.frameIntervalFrames)))',setpts='N/(FRAME_RATE*TB)'"
            }

            return ([
                "-i", input,
                "-vf", videoFilter,
                "-vsync", "vfr",
                "-y",
                output.path
            ], output)

        case .createGIF:
            let start = config.gifStart
            let duration = config.gifDuration
            let fps = config.gifFPS
            let width = config.gifWidth

            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "", newExtension: "gif")

            // Two-pass GIF creation for better quality
            let filters = "fps=\(fps),scale=\(width):-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"

            return ([
                "-ss", formatTime(start),
                "-t", String(duration),
                "-i", input,
                "-filter_complex", filters,
                "-y",
                output.path
            ], output)

        case .videoSummary:
            let targetDuration = config.summaryDuration
            guard let duration = file.duration, duration > 0 else {
                throw FFmpegError.unknownError("Cannot determine video duration")
            }

            // Calculate how much to speed up
            let speedFactor = duration / Double(targetDuration)
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-summary")

            if speedFactor <= 1 {
                // Video is already short enough, just copy
                return ([
                    "-i", input,
                    "-c", "copy",
                    "-y",
                    output.path
                ], output)
            }

            // Speed up the video
            let videoFilter = "setpts=PTS/\(speedFactor)"
            let audioFilter = buildAtempoFilter(speed: speedFactor)

            return ([
                "-i", input,
                "-filter_complex", "[0:v]\(videoFilter)[v];[0:a]\(audioFilter)[a]",
                "-map", "[v]",
                "-map", "[a]",
                "-y",
                output.path
            ], output)

        // MARK: - Additional Audio Operations

        case .adjustVolume:
            let volume = config.volumeAdjustment
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-volume")
            return ([
                "-i", input,
                "-af", "volume=\(volume)",
                "-c:v", "copy",
                "-y",
                output.path
            ], output)

        case .removeSilence:
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-nosilence")
            // silenceremove: remove silence at start and end, then remove internal silence
            return ([
                "-i", input,
                "-af", "silenceremove=start_periods=1:start_silence=0.5:start_threshold=-50dB:detection=peak,areverse,silenceremove=start_periods=1:start_silence=0.5:start_threshold=-50dB:detection=peak,areverse",
                "-c:v", "copy",
                "-y",
                output.path
            ], output)

        case .enhanceAudio:
            let preset = config.enhanceAudioPreset
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-enhanced")

            // Check if arnndn models exist
            let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
            let modelPath = "\(homeDir)/arnndn-models/bd.rnnn"
            guard FileManager.default.fileExists(atPath: modelPath) else {
                throw FFmpegError.unknownError("RNN model not found. Run: git clone https://github.com/richardpl/arnndn-models.git ~/arnndn-models")
            }

            // For video files, copy video stream and process audio
            // For audio files, just process audio
            if file.isVideo {
                return ([
                    "-i", input,
                    "-af", preset.audioFilter,
                    "-c:v", "copy",
                    "-y",
                    output.path
                ], output)
            } else {
                return ([
                    "-i", input,
                    "-af", preset.audioFilter,
                    "-y",
                    output.path
                ], output)
            }

        // MARK: - Additional Format Operations

        case .resizeVideo:
            let resolution = config.targetResolution

            // Check if it's a custom resolution
            if resolution.hasPrefix("custom:") {
                let widthStr = resolution.replacingOccurrences(of: "custom:", with: "")
                guard let width = Int(widthStr) else {
                    throw FFmpegError.unknownError("Invalid custom resolution")
                }

                let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-\(width)w")

                // Scale to width, maintain aspect ratio (-2 ensures even height)
                return ([
                    "-i", input,
                    "-vf", "scale=\(width):-2",
                    "-c:a", "copy",
                    "-y",
                    output.path
                ], output)
            }

            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-\(resolution)")

            let scale: String
            switch resolution {
            case "2160p", "4K":
                scale = "3840:2160"
            case "1080p":
                scale = "1920:1080"
            case "720p":
                scale = "1280:720"
            case "480p":
                scale = "854:480"
            case "360p":
                scale = "640:360"
            default:
                scale = "1920:1080"
            }

            return ([
                "-i", input,
                "-vf", "scale=\(scale):force_original_aspect_ratio=decrease,pad=\(scale):(ow-iw)/2:(oh-ih)/2",
                "-c:a", "copy",
                "-y",
                output.path
            ], output)

        case .createProxy:
            let resolution = config.proxyResolution
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-proxy")

            // Determine scale based on resolution
            let scale: String
            switch resolution {
            case "720p":
                scale = "1280:-2"
            case "540p":
                scale = "960:-2"
            case "480p":
                scale = "854:-2"
            default:
                scale = "1280:-2"
            }

            // Fast encoding with ultrafast preset for quick proxy creation
            return ([
                "-i", input,
                "-vf", "scale=\(scale)",
                "-c:v", "libx264",
                "-preset", "ultrafast",
                "-crf", "23",
                "-c:a", "aac",
                "-b:a", "128k",
                "-y",
                output.path
            ], output)

        // MARK: - Additional Edit Operations

        case .rotate:
            let angle = config.rotationAngle
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-rotated\(angle)")

            let transpose: String
            switch angle {
            case 90:
                transpose = "transpose=1"  // 90 clockwise
            case 180:
                transpose = "transpose=1,transpose=1"  // 180
            case 270:
                transpose = "transpose=2"  // 90 counter-clockwise
            default:
                transpose = "transpose=1"
            }

            return ([
                "-i", input,
                "-vf", transpose,
                "-c:a", "copy",
                "-y",
                output.path
            ], output)

        case .flip:
            let direction = config.flipDirection
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-\(direction)")

            let filter = direction == "horizontal" ? "hflip" : "vflip"

            return ([
                "-i", input,
                "-vf", filter,
                "-c:a", "copy",
                "-y",
                output.path
            ], output)

        case .cropToVertical:
            let position = config.verticalCropPosition
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-vertical")

            // Crop 16:9 to 9:16: take vertical slice from horizontal video
            // Input aspect 16:9, output aspect 9:16
            // If input is 1920x1080, output should be 607x1080 (9:16 ratio)
            let cropX: String
            switch position {
            case "left":
                cropX = "0"
            case "right":
                cropX = "in_w-out_w"
            default:  // center
                cropX = "(in_w-out_w)/2"
            }

            // crop=width:height:x:y - width = height * 9/16
            return ([
                "-i", input,
                "-vf", "crop=ih*9/16:ih:\(cropX):0",
                "-c:a", "copy",
                "-y",
                output.path
            ], output)

        case .grayscale:
            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-bw")
            return ([
                "-i", input,
                "-vf", "format=gray",
                "-c:a", "copy",
                "-y",
                output.path
            ], output)

        // MARK: - Additional Export Operations

        case .contactSheet:
            let cols = config.contactSheetColumns
            let rows = config.contactSheetRows
            let totalFrames = cols * rows
            guard let duration = file.duration, duration > 0 else {
                throw FFmpegError.unknownError("Cannot determine video duration")
            }

            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-contact", newExtension: "jpg")

            // Calculate fps to get totalFrames evenly distributed
            let fps = Double(totalFrames) / duration

            return ([
                "-i", input,
                "-vf", "fps=\(fps),scale=320:-1,tile=\(cols)x\(rows)",
                "-frames:v", "1",
                "-y",
                output.path
            ], output)

        // MARK: - Overlay Operations

        case .mergeVideos:
            let videos = config.videosToMerge
            guard !videos.isEmpty else {
                throw FFmpegError.unknownError("No videos selected to merge")
            }

            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-merged")

            // Create a temporary concat file
            let tempDir = FileManager.default.temporaryDirectory
            let concatFile = tempDir.appendingPathComponent("concat_\(UUID().uuidString).txt")

            var concatContent = "file '\(file.url.path)'\n"
            for video in videos {
                concatContent += "file '\(video.path)'\n"
            }

            try? concatContent.write(to: concatFile, atomically: true, encoding: .utf8)

            return ([
                "-f", "concat",
                "-safe", "0",
                "-i", concatFile.path,
                "-c", "copy",
                "-y",
                output.path
            ], output)

        case .burnSubtitles:
            guard let subtitleFile = config.subtitleFile else {
                throw FFmpegError.unknownError("No subtitle file selected")
            }

            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-subtitled")

            // Escape special characters in path for ffmpeg filter
            let escapedPath = subtitleFile.path
                .replacingOccurrences(of: ":", with: "\\:")
                .replacingOccurrences(of: "'", with: "\\'")

            return ([
                "-i", input,
                "-vf", "subtitles='\(escapedPath)'",
                "-c:a", "copy",
                "-y",
                output.path
            ], output)

        case .pictureInPicture:
            guard let pipVideo = config.pipVideo else {
                throw FFmpegError.unknownError("No overlay video selected")
            }

            let output = ffmpeg.generateOutputPath(from: file.url, suffix: "-pip")

            // Calculate size based on config
            let sizeRatio: String
            switch config.pipSize {
            case "large":
                sizeRatio = "iw/2"  // 50%
            case "medium":
                sizeRatio = "iw/3"  // 33%
            default:
                sizeRatio = "iw/4"  // 25%
            }

            // Calculate position
            let position: String
            switch config.pipPosition {
            case "top-left":
                position = "10:10"
            case "top-right":
                position = "main_w-overlay_w-10:10"
            case "bottom-left":
                position = "10:main_h-overlay_h-10"
            default:  // bottom-right
                position = "main_w-overlay_w-10:main_h-overlay_h-10"
            }

            return ([
                "-i", input,
                "-i", pipVideo.path,
                "-filter_complex", "[1:v]scale=\(sizeRatio):-1[pip];[0:v][pip]overlay=\(position)",
                "-c:a", "copy",
                "-y",
                output.path
            ], output)
        }
    }

    // Format seconds to HH:MM:SS.mmm
    func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = seconds.truncatingRemainder(dividingBy: 60)
        return String(format: "%02d:%02d:%06.3f", hours, minutes, secs)
    }

    // Build atempo filter chain for speed changes
    // atempo only supports 0.5-2.0x, so we chain multiple for higher speeds
    func buildAtempoFilter(speed: Double) -> String {
        if speed >= 0.5 && speed <= 2.0 {
            return "atempo=\(speed)"
        } else if speed > 2.0 {
            // Chain multiple atempo filters
            var remaining = speed
            var filters: [String] = []
            while remaining > 2.0 {
                filters.append("atempo=2.0")
                remaining /= 2.0
            }
            if remaining > 0.5 {
                filters.append("atempo=\(remaining)")
            }
            return filters.joined(separator: ",")
        } else {
            // speed < 0.5
            var remaining = speed
            var filters: [String] = []
            while remaining < 0.5 {
                filters.append("atempo=0.5")
                remaining *= 2.0
            }
            if remaining < 2.0 {
                filters.append("atempo=\(remaining)")
            }
            return filters.joined(separator: ",")
        }
    }

    // Detect audio format from video file
    func detectAudioFormat(from url: URL) -> String {
        // Default to AAC for most video files
        // In a real implementation, we'd use ffprobe to detect the actual codec
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "mkv":
            return "aac"  // MKV often has AAC or AC3
        case "avi":
            return "mp3"  // AVI often has MP3
        default:
            return "aac"  // Default to AAC
        }
    }
}

// Configuration for operations
struct OperationConfig {
    // For operations requiring a second file (replace/add audio)
    var secondaryFile: URL? = nil

    // For format conversion
    var targetFormat: String? = nil
    var targetAudioFormat: String? = nil

    // For compression
    var compressionPreset: CompressionPreset = .medium

    // For ProRes
    var proresProfile: ProResProfile = .standard

    // For splitting
    var splitParts: Int = 2
    var splitSeconds: Int = 30
    var splitSizeMB: Int = 100

    // For trim
    var trimStart: Double = 0
    var trimEnd: Double = 0

    // For speed change
    var speedMultiplier: Double = 2.0

    // For extract frames
    var frameExtractionMode: FrameExtractionMode = .everyNSeconds
    var frameCount: Int = 10
    var frameIntervalSeconds: Double = 1.0  // Extract every N seconds
    var frameIntervalFrames: Int = 30       // Extract every N frames

    // For GIF creation
    var gifStart: Double = 0
    var gifDuration: Int = 5
    var gifFPS: Int = 10
    var gifWidth: Int = 480

    // For video summary
    var summaryDuration: Int = 30

    // For adjust volume
    var volumeAdjustment: Double = 1.5  // 1.0 = no change, 2.0 = double, 0.5 = half

    // For resize video
    var targetResolution: String = "1080p"

    // For rotate
    var rotationAngle: Int = 90  // 90, 180, 270

    // For flip
    var flipDirection: String = "horizontal"  // horizontal or vertical

    // For crop to vertical
    var verticalCropPosition: String = "center"  // left, center, right

    // For contact sheet
    var contactSheetColumns: Int = 4
    var contactSheetRows: Int = 4

    // For merge videos
    var videosToMerge: [URL] = []

    // For burn subtitles
    var subtitleFile: URL? = nil

    // For picture in picture
    var pipVideo: URL? = nil
    var pipPosition: String = "bottom-right"  // top-left, top-right, bottom-left, bottom-right
    var pipSize: String = "small"  // small (25%), medium (33%), large (50%)

    // For enhance audio
    var enhanceAudioPreset: EnhanceAudioPreset = .standard

    // For create proxy
    var proxyResolution: String = "720p"  // 720p, 540p, 480p

    static let `default` = OperationConfig()
}

// Frame extraction modes
enum FrameExtractionMode: String, CaseIterable {
    case totalFrames = "Total Frames"
    case everyNSeconds = "Every N Seconds"
    case everyNFrames = "Every N Frames"

    var description: String {
        switch self {
        case .totalFrames: return "Extract a specific number of frames, evenly spaced"
        case .everyNSeconds: return "Extract one frame every N seconds"
        case .everyNFrames: return "Extract one frame every N video frames"
        }
    }
}

// Compression quality presets
enum CompressionPreset: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case lossless = "Lossless"

    var crfValue: Int {
        switch self {
        case .low: return 28       // Smaller file, lower quality
        case .medium: return 23    // Balanced
        case .high: return 18      // Larger file, higher quality
        case .lossless: return 0   // No compression
        }
    }

    var description: String {
        switch self {
        case .low: return "Smallest file size, visible quality loss"
        case .medium: return "Good balance of size and quality"
        case .high: return "Larger file, minimal quality loss"
        case .lossless: return "No quality loss, largest file"
        }
    }
}

// ProRes profile options
enum ProResProfile: String, CaseIterable {
    case proxy = "Proxy"
    case lt = "LT"
    case standard = "422"
    case hq = "422 HQ"

    var profileValue: Int {
        switch self {
        case .proxy: return 0
        case .lt: return 1
        case .standard: return 2
        case .hq: return 3
        }
    }

    var description: String {
        switch self {
        case .proxy: return "Smallest, for offline editing"
        case .lt: return "Light, good for most editing"
        case .standard: return "Standard broadcast quality"
        case .hq: return "High quality, for color grading"
        }
    }
}

// Audio enhancement presets
enum EnhanceAudioPreset: String, CaseIterable {
    case light = "Light"
    case standard = "Standard"
    case podcast = "Podcast"

    var description: String {
        switch self {
        case .light: return "Gentle cleanup, preserves natural sound"
        case .standard: return "Balanced denoise, EQ, and compression"
        case .podcast: return "Maximum cleanup for noisy recordings"
        }
    }

    // Denoise mix (0.0-1.0, higher = more aggressive)
    var denoiseMix: Double {
        switch self {
        case .light: return 0.6
        case .standard: return 1.0
        case .podcast: return 1.0
        }
    }

    // Nasal cut at 2000Hz (negative dB)
    var nasalCutGain: Int {
        switch self {
        case .light: return -3
        case .standard: return -6
        case .podcast: return -6
        }
    }

    // Presence boost at 4500Hz (positive dB)
    var presenceBoostGain: Int {
        switch self {
        case .light: return 2
        case .standard: return 4
        case .podcast: return 5
        }
    }

    // Compressor threshold (dB)
    var compressorThreshold: Int {
        switch self {
        case .light: return -12
        case .standard: return -15
        case .podcast: return -18
        }
    }

    // Compressor ratio
    var compressorRatio: Int {
        switch self {
        case .light: return 3
        case .standard: return 6
        case .podcast: return 8
        }
    }

    // Build the full audio filter chain
    var audioFilter: String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let modelPath = "\(homeDir)/arnndn-models/bd.rnnn"

        return [
            "arnndn=m=\(modelPath):mix=\(denoiseMix)",
            "equalizer=f=2000:t=q:w=1.5:g=\(nasalCutGain)",
            "equalizer=f=4500:t=q:w=2:g=\(presenceBoostGain)",
            "acompressor=threshold=\(compressorThreshold)dB:ratio=\(compressorRatio):attack=3:release=40",
            "loudnorm"
        ].joined(separator: ",")
    }
}
