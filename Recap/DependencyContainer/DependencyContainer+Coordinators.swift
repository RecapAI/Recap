import Foundation

extension DependencyContainer {

  func makeRecordingCoordinator() -> RecordingCoordinator {
    let coordinator = RecordingCoordinator(
      appDetectionService: meetingAppDetectionService,
      sessionManager: recordingSessionManager,
      fileManager: recordingFileManager,
      microphoneCapture: microphoneCapture
    )
    coordinator.setupProcessController()
    return coordinator
  }

  func makeProcessingCoordinator() -> ProcessingCoordinator {
    ProcessingCoordinator(
      recordingRepository: recordingRepository,
      summarizationService: summarizationService,
      transcriptionService: transcriptionService,
      userPreferencesRepository: userPreferencesRepository
    )
  }

  func makeProviderWarningCoordinator() -> ProviderWarningCoordinator {
    ProviderWarningCoordinator(
      warningManager: warningManager,
      llmService: llmService
    )
  }

  func makeAppSelectionCoordinator() -> AppSelectionCoordinatorType {
    AppSelectionCoordinator(appSelectionViewModel: appSelectionViewModel)
  }
}
