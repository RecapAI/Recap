import Foundation

protocol AudioRecordingCoordinatorType {
  var currentMicrophoneLevel: Float { get }
  var currentSystemAudioLevel: Float { get }
  var hasDualAudio: Bool { get }
  var recordedFiles: RecordedFiles { get }

  func start() async throws
  func stop()
}
