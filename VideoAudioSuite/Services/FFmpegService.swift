import Foundation

// Handles all ffmpeg command execution
class FFmpegService {
    static let shared = FFmpegService()

    private init() {}

    // Get the path to ffmpeg
    private var ffmpegPath: String {
        // Try common locations
        let paths = [
            "/opt/homebrew/bin/ffmpeg",     // Apple Silicon Homebrew
            "/usr/local/bin/ffmpeg",         // Intel Homebrew
            "/usr/bin/ffmpeg"                // System
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        return "ffmpeg"  // Fall back to PATH
    }

    // Get the path to ffprobe
    private var ffprobePath: String {
        return ffmpegPath.replacingOccurrences(of: "ffmpeg", with: "ffprobe")
    }

    // Get media duration using ffprobe
    func getMediaDuration(url: URL, completion: @escaping (Double?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.launchPath = self.ffprobePath
            task.arguments = [
                "-v", "error",
                "-show_entries", "format=duration",
                "-of", "default=noprint_wrappers=1:nokey=1",
                url.path
            ]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = FileHandle.nullDevice

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   let duration = Double(output) {
                    DispatchQueue.main.async {
                        completion(duration)
                    }
                    return
                }
            } catch {
                // Ignore errors
            }

            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }

    // Execute an ffmpeg command
    func execute(
        arguments: [String],
        progressHandler: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, FFmpegError>) -> Void
    ) -> Process {
        let task = Process()
        task.launchPath = ffmpegPath
        task.arguments = arguments

        let errorPipe = Pipe()
        task.standardError = errorPipe
        task.standardOutput = FileHandle.nullDevice

        // Monitor progress from stderr (ffmpeg outputs progress there)
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8) {
                // Parse progress from ffmpeg output
                // Example: "frame= 100 fps=30 ... time=00:00:03.33 ..."
                if let timeRange = output.range(of: "time="),
                   let endRange = output.range(of: " ", range: timeRange.upperBound..<output.endIndex) {
                    let timeString = String(output[timeRange.upperBound..<endRange.lowerBound])
                    if let seconds = self.parseTimeString(timeString) {
                        DispatchQueue.main.async {
                            progressHandler(seconds)
                        }
                    }
                }
            }
        }

        task.terminationHandler = { process in
            errorPipe.fileHandleForReading.readabilityHandler = nil

            DispatchQueue.main.async {
                if process.terminationStatus == 0 {
                    // Find output file from arguments (usually last argument)
                    if let outputPath = arguments.last {
                        completion(.success(URL(fileURLWithPath: outputPath)))
                    } else {
                        completion(.failure(.unknownError("No output file specified")))
                    }
                } else {
                    // Read error output
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    completion(.failure(.processingFailed(errorString)))
                }
            }
        }

        do {
            try task.run()
        } catch {
            completion(.failure(.launchFailed(error.localizedDescription)))
        }

        return task
    }

    // Parse time string like "00:01:23.45" to seconds
    private func parseTimeString(_ time: String) -> Double? {
        let parts = time.split(separator: ":")
        guard parts.count == 3,
              let hours = Double(parts[0]),
              let minutes = Double(parts[1]),
              let seconds = Double(parts[2]) else {
            return nil
        }
        return hours * 3600 + minutes * 60 + seconds
    }

    // Generate output path with suffix
    func generateOutputPath(from inputURL: URL, suffix: String, newExtension: String? = nil) -> URL {
        let directory = inputURL.deletingLastPathComponent()
        let filename = inputURL.deletingPathExtension().lastPathComponent
        let ext = newExtension ?? inputURL.pathExtension

        var outputURL = directory.appendingPathComponent("\(filename)\(suffix).\(ext)")

        // Handle filename conflicts
        var counter = 2
        while FileManager.default.fileExists(atPath: outputURL.path) {
            outputURL = directory.appendingPathComponent("\(filename)\(suffix)-\(counter).\(ext)")
            counter += 1
        }

        return outputURL
    }
}

// Error types for ffmpeg operations
enum FFmpegError: Error, LocalizedError {
    case launchFailed(String)
    case processingFailed(String)
    case unsupportedFormat
    case diskSpaceFull
    case permissionDenied
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .launchFailed:
            return "Couldn't start ffmpeg"
        case .processingFailed(let details):
            // Try to provide a user-friendly message
            if details.contains("No such file") {
                return "The file couldn't be found"
            } else if details.contains("Invalid data") || details.contains("Invalid") {
                return "This file appears to be corrupted"
            } else if details.contains("codec") || details.contains("Codec") {
                return "This file format isn't fully supported"
            }
            return "Something went wrong processing this file"
        case .unsupportedFormat:
            return "This file format isn't supported"
        case .diskSpaceFull:
            return "Not enough disk space"
        case .permissionDenied:
            return "Can't write to this location"
        case .unknownError(let message):
            return message
        }
    }

    // Detailed error for "Show details" view
    var technicalDetails: String {
        switch self {
        case .launchFailed(let details),
             .processingFailed(let details),
             .unknownError(let details):
            return details
        case .unsupportedFormat:
            return "The file format is not recognized by ffmpeg"
        case .diskSpaceFull:
            return "Insufficient disk space for output file"
        case .permissionDenied:
            return "Write permission denied for output directory"
        }
    }
}
