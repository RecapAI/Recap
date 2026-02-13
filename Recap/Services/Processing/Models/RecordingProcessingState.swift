import Foundation

enum RecordingProcessingState: Int16, CaseIterable {
  case recording = 0
  case recorded = 1
  case transcribing = 2
  case transcribed = 3
  case summarizing = 4
  case completed = 5
  case transcriptionFailed = 6
  case summarizationFailed = 7
}

extension RecordingProcessingState {
  var isProcessing: Bool {
    switch self {
    case .transcribing, .summarizing:
      return true
    default:
      return false
    }
  }

  var isFailed: Bool {
    switch self {
    case .transcriptionFailed, .summarizationFailed:
      return true
    default:
      return false
    }
  }

  var canRetry: Bool {
    isFailed
  }

  var displayName: String {
    switch self {
    case .recording:
      return "Recording"
    case .recorded:
      return "Recorded"
    case .transcribing:
      return "Transcribing"
    case .transcribed:
      return "Transcribed"
    case .summarizing:
      return "Summarizing"
    case .completed:
      return "Completed"
    case .transcriptionFailed:
      return "Transcription Failed"
    case .summarizationFailed:
      return "Summarization Failed"
    }
  }
}
