import Foundation

struct RecordingCreationParameters {
  let id: String
  let startDate: Date
  let recordingURL: URL
  let microphoneURL: URL?
  let hasMicrophoneAudio: Bool
  let applicationName: String?
}

#if MOCKING
  import Mockable
#endif

#if MOCKING
  @Mockable
#endif
protocol RecordingRepositoryType {
  func createRecording(_ parameters: RecordingCreationParameters) async throws -> RecordingInfo
  func fetchRecording(id: String) async throws -> RecordingInfo?
  func fetchAllRecordings() async throws -> [RecordingInfo]
  func fetchRecordings(withState state: RecordingProcessingState) async throws -> [RecordingInfo]
  func updateRecordingState(id: String, state: RecordingProcessingState, errorMessage: String?)
    async throws
  func updateRecordingEndDate(id: String, endDate: Date) async throws
  func updateRecordingTranscription(id: String, transcriptionText: String) async throws
  func updateRecordingTimestampedTranscription(
    id: String, timestampedTranscription: TimestampedTranscription) async throws
  func updateRecordingSummary(id: String, summaryText: String) async throws
  func updateRecordingURLs(id: String, recordingURL: URL?, microphoneURL: URL?) async throws
  func deleteRecording(id: String) async throws
  func deleteAllRecordings() async throws
}
