import Foundation

// Represents a file in the batch processing queue with its selection and processing status
struct BatchFile: Identifiable, Hashable {
    let id = UUID()
    let mediaFile: MediaFile
    var isSelected: Bool = true
    var status: BatchFileStatus = .pending
    var outputURL: URL? = nil
    var error: FFmpegError? = nil

    // Convenience initializer from MediaFile
    init(mediaFile: MediaFile, isSelected: Bool = true) {
        self.mediaFile = mediaFile
        self.isSelected = isSelected
    }

    // Hashable conformance (only compare by id)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: BatchFile, rhs: BatchFile) -> Bool {
        lhs.id == rhs.id
    }
}

// Status of a file in the batch processing queue
enum BatchFileStatus: Equatable {
    case pending      // Waiting to be processed
    case processing   // Currently being processed
    case completed    // Successfully processed
    case failed       // Processing failed

    var icon: String {
        switch self {
        case .pending: return "circle"
        case .processing: return "arrow.trianglehead.2.clockwise.rotate.90"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .pending: return "secondary"
        case .processing: return "blue"
        case .completed: return "green"
        case .failed: return "red"
        }
    }
}
