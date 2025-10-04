import Foundation

enum ProcessingState: Equatable {
  case idle
  case processing(recordingID: String)
  case paused(recordingID: String)

  var isProcessing: Bool {
    switch self {
    case .processing:
      return true
    default:
      return false
    }
  }

  var recordingID: String? {
    switch self {
    case .idle:
      return nil
    case .processing(let id), .paused(let id):
      return id
    }
  }
}
