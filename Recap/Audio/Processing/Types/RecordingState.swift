import Foundation

enum RecordingState {
  case idle
  case starting
  case recording(AudioRecordingCoordinatorType)
  case stopping
  case failed(Error)
}
