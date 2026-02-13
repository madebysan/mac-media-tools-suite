import Foundation

// Represents a video or audio file loaded into the app
struct MediaFile: Identifiable {
    let id = UUID()
    let url: URL
    let filename: String
    let fileExtension: String
    let fileSize: Int64
    let duration: Double?      // Duration in seconds (nil if can't be determined)
    let isVideo: Bool

    // Formatted file size for display (e.g., "125.4 MB")
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    // Formatted duration for display (e.g., "2:35")
    var formattedDuration: String {
        guard let duration = duration else { return "Unknown" }

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%d:%02d:%02d", hours, remainingMinutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }

    // Create from a file URL
    init?(url: URL) {
        self.url = url
        self.filename = url.deletingPathExtension().lastPathComponent
        self.fileExtension = url.pathExtension.lowercased()

        // Check if this is a supported format
        let videoExtensions = ["mp4", "mov", "mkv", "avi", "webm", "m4v"]
        let audioExtensions = ["mp3", "wav", "aac", "m4a", "flac", "ogg"]

        let isVideo = videoExtensions.contains(fileExtension)
        let isAudio = audioExtensions.contains(fileExtension)

        guard isVideo || isAudio else {
            return nil  // Unsupported format
        }

        self.isVideo = isVideo

        // Get file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            self.fileSize = attributes[.size] as? Int64 ?? 0
        } catch {
            self.fileSize = 0
        }

        // Duration will be fetched asynchronously using ffprobe
        self.duration = nil
    }

    // Create with all properties (used when duration is known)
    init(url: URL, filename: String, fileExtension: String, fileSize: Int64, duration: Double?, isVideo: Bool) {
        self.url = url
        self.filename = filename
        self.fileExtension = fileExtension
        self.fileSize = fileSize
        self.duration = duration
        self.isVideo = isVideo
    }
}
