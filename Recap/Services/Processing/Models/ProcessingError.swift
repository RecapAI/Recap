import Foundation

enum ProcessingError: LocalizedError {
  case transcriptionFailed(String)
  case summarizationFailed(String)
  case fileNotFound(String)
  case coreDataError(String)
  case networkError(String)
  case cancelled

  var errorDescription: String? {
    switch self {
    case .transcriptionFailed(let message):
      return "Transcription failed: \(message)"
    case .summarizationFailed(let message):
      return "Summarization failed: \(message)"
    case .fileNotFound(let path):
      return "Recording file not found at: \(path)"
    case .coreDataError(let message):
      return "Database error: \(message)"
    case .networkError(let message):
      return "Network error: \(message)"
    case .cancelled:
      return "Processing was cancelled"
    }
  }

  var isRetryable: Bool {
    switch self {
    case .fileNotFound, .cancelled:
      return false
    default:
      return true
    }
  }
}
