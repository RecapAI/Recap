import Foundation

@MainActor
protocol SummaryViewModelType: ObservableObject {
  var currentRecording: RecordingInfo? { get }
  var isLoadingRecording: Bool { get }
  var errorMessage: String? { get }
  var processingStage: ProcessingStatesCard.ProcessingStage? { get }
  var isProcessing: Bool { get }
  var hasSummary: Bool { get }
  var isRecordingReady: Bool { get }
  var showingCopiedToast: Bool { get }

  func loadRecording(withID recordingID: String)
  func loadLatestRecording()
  func retryProcessing() async
  func fixStuckRecording() async
  func markAsCompleted() async
  func startAutoRefresh()
  func stopAutoRefresh()
  func copySummary()
  func copyTranscription()
}
