import Foundation

// Categories of operations
enum OperationCategory: String, CaseIterable {
    case audio = "Audio"
    case format = "Format"
    case edit = "Edit"
    case split = "Split"
    case export = "Export"
    case overlay = "Overlay"

    var icon: String {
        switch self {
        case .audio: return "speaker.wave.2"
        case .format: return "arrow.triangle.2.circlepath"
        case .edit: return "slider.horizontal.3"
        case .split: return "scissors"
        case .export: return "square.and.arrow.up"
        case .overlay: return "square.on.square"
        }
    }

    // Check if this category is available for the given file
    func isAvailable(for file: MediaFile) -> Bool {
        switch self {
        case .audio:
            return true  // Available for both video and audio
        case .format:
            return true  // Available for both
        case .edit:
            return file.isVideo  // Only for video files
        case .split:
            return file.isVideo  // Only for video files
        case .export:
            return file.isVideo  // Only for video files
        case .overlay:
            return file.isVideo  // Only for video files
        }
    }

    // Get operations available for this category and file type
    func operations(for file: MediaFile) -> [Operation] {
        switch self {
        case .audio:
            if file.isVideo {
                return [.removeAudio, .extractAudio, .replaceAudio, .addAudioLayer, .adjustVolume, .removeSilence, .enhanceAudio]
            } else {
                return [.normalizeAudio, .convertAudioFormat, .adjustVolume, .removeSilence, .enhanceAudio]
            }
        case .format:
            if file.isVideo {
                return [.changeContainer, .compress, .convertToProRes, .resizeVideo, .createProxy]
            } else {
                return [.convertAudioFormat]
            }
        case .edit:
            return [.trim, .speedChange, .reverse, .rotate, .flip, .cropToVertical, .grayscale]
        case .split:
            return [.splitByParts, .splitBySeconds, .splitBySize]
        case .export:
            return [.extractFrames, .createGIF, .videoSummary, .contactSheet]
        case .overlay:
            return [.mergeVideos, .burnSubtitles, .pictureInPicture]
        }
    }
}

// Individual operations
enum Operation: String, CaseIterable {
    // Audio operations
    case removeAudio
    case extractAudio
    case replaceAudio
    case addAudioLayer
    case normalizeAudio
    case convertAudioFormat
    case adjustVolume
    case removeSilence
    case enhanceAudio

    // Format operations
    case changeContainer
    case compress
    case convertToProRes
    case resizeVideo
    case createProxy

    // Edit operations
    case trim
    case speedChange
    case reverse
    case rotate
    case flip
    case cropToVertical
    case grayscale

    // Split operations
    case splitByParts
    case splitBySeconds
    case splitBySize

    // Export operations
    case extractFrames
    case createGIF
    case videoSummary
    case contactSheet

    // Overlay operations
    case mergeVideos
    case burnSubtitles
    case pictureInPicture

    var name: String {
        switch self {
        case .removeAudio: return "Remove Audio"
        case .extractAudio: return "Extract Audio"
        case .replaceAudio: return "Replace Audio"
        case .addAudioLayer: return "Add Audio Layer"
        case .normalizeAudio: return "Normalize Volume"
        case .convertAudioFormat: return "Convert Format"
        case .adjustVolume: return "Adjust Volume"
        case .removeSilence: return "Remove Silence"
        case .enhanceAudio: return "Enhance Audio"
        case .changeContainer: return "Change Container"
        case .compress: return "Compress"
        case .convertToProRes: return "Convert to ProRes"
        case .resizeVideo: return "Resize Video"
        case .createProxy: return "Create Proxy"
        case .trim: return "Trim Video"
        case .speedChange: return "Change Speed"
        case .reverse: return "Reverse"
        case .rotate: return "Rotate"
        case .flip: return "Flip / Mirror"
        case .cropToVertical: return "Crop to Vertical"
        case .grayscale: return "Black & White"
        case .splitByParts: return "Split into Parts"
        case .splitBySeconds: return "Split by Duration"
        case .splitBySize: return "Split by File Size"
        case .extractFrames: return "Extract Frames"
        case .createGIF: return "Create GIF"
        case .videoSummary: return "Video Summary"
        case .contactSheet: return "Contact Sheet"
        case .mergeVideos: return "Merge Videos"
        case .burnSubtitles: return "Burn Subtitles"
        case .pictureInPicture: return "Picture in Picture"
        }
    }

    var description: String {
        switch self {
        case .removeAudio: return "Strip audio track, keep video only"
        case .extractAudio: return "Save audio as separate file"
        case .replaceAudio: return "Swap audio with a different file"
        case .addAudioLayer: return "Mix additional audio with existing"
        case .normalizeAudio: return "Make volume consistent"
        case .convertAudioFormat: return "Change to MP3, WAV, AAC, etc."
        case .adjustVolume: return "Boost or reduce audio level"
        case .removeSilence: return "Cut silent sections from audio"
        case .enhanceAudio: return "Denoise, EQ, and normalize for cleaner voice"
        case .changeContainer: return "Convert to MP4, MOV, MKV (fast, no re-encoding)"
        case .compress: return "Reduce file size with quality presets"
        case .convertToProRes: return "High-quality format for editing"
        case .resizeVideo: return "Scale to 1080p, 720p, 480p, or custom"
        case .createProxy: return "Low-res copy for smoother editing"
        case .trim: return "Cut from start time to end time"
        case .speedChange: return "Speed up (2x, 4x) or slow down (0.5x)"
        case .reverse: return "Play video backwards"
        case .rotate: return "Rotate 90°, 180°, or 270°"
        case .flip: return "Mirror horizontally or vertically"
        case .cropToVertical: return "Convert 16:9 to 9:16 for social media"
        case .grayscale: return "Convert to black and white"
        case .splitByParts: return "Divide into equal segments"
        case .splitBySeconds: return "Create clips of specific length"
        case .splitBySize: return "Create files of target size"
        case .extractFrames: return "Save evenly-spaced screenshots as PNGs"
        case .createGIF: return "Convert to animated GIF"
        case .videoSummary: return "Condense into a short preview"
        case .contactSheet: return "Grid of thumbnails from video"
        case .mergeVideos: return "Combine multiple videos into one"
        case .burnSubtitles: return "Hardcode .srt subtitles into video"
        case .pictureInPicture: return "Overlay a small video on larger video"
        }
    }

    // Suffix added to output filename
    var outputSuffix: String {
        switch self {
        case .removeAudio: return "-noaudio"
        case .extractAudio: return "-audio"
        case .replaceAudio: return "-newaudio"
        case .addAudioLayer: return "-mixed"
        case .normalizeAudio: return "-normalized"
        case .convertAudioFormat: return "-converted"
        case .adjustVolume: return "-volume"
        case .removeSilence: return "-nosilence"
        case .enhanceAudio: return "-enhanced"
        case .changeContainer: return ""  // Extension changes instead
        case .compress: return "-compressed"
        case .convertToProRes: return "-prores"
        case .resizeVideo: return "-resized"
        case .createProxy: return "-proxy"
        case .trim: return "-trimmed"
        case .speedChange: return "-speed"
        case .reverse: return "-reversed"
        case .rotate: return "-rotated"
        case .flip: return "-flipped"
        case .cropToVertical: return "-vertical"
        case .grayscale: return "-bw"
        case .splitByParts: return "-part"
        case .splitBySeconds: return "-part"
        case .splitBySize: return "-part"
        case .extractFrames: return "-frame"
        case .createGIF: return ""
        case .videoSummary: return "-summary"
        case .contactSheet: return "-contact"
        case .mergeVideos: return "-merged"
        case .burnSubtitles: return "-subtitled"
        case .pictureInPicture: return "-pip"
        }
    }

    // Whether this operation requires a second file
    var requiresSecondFile: Bool {
        switch self {
        case .replaceAudio, .addAudioLayer, .mergeVideos, .burnSubtitles, .pictureInPicture:
            return true
        default:
            return false
        }
    }

    // Whether this operation requires configuration
    var requiresConfiguration: Bool {
        switch self {
        case .compress, .convertToProRes, .changeContainer, .convertAudioFormat,
             .splitByParts, .splitBySeconds, .splitBySize,
             .trim, .speedChange, .extractFrames, .createGIF, .videoSummary,
             .adjustVolume, .resizeVideo, .rotate, .flip, .cropToVertical,
             .contactSheet, .mergeVideos, .burnSubtitles, .pictureInPicture,
             .enhanceAudio, .createProxy:
            return true
        default:
            return false
        }
    }
}
