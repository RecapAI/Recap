import Foundation

enum RecordingError: LocalizedError {
  case failedToStop

  var errorDescription: String? {
    switch self {
    case .failedToStop:
      return "Failed to stop recording properly"
    }
  }
}
