import Foundation

extension DependencyContainer {

  func makeWhisperModelsViewModel() -> WhisperModelsViewModel {
    WhisperModelsViewModel(repository: whisperModelRepository)
  }

  func makeAppSelectionViewModel() -> AppSelectionViewModel {
    AppSelectionViewModel(audioProcessController: audioProcessController)
  }

  func makePreviousRecapsViewModel() -> PreviousRecapsViewModel {
    PreviousRecapsViewModel(recordingRepository: recordingRepository)
  }

  func makeGeneralSettingsViewModel() -> GeneralSettingsViewModel {
    GeneralSettingsViewModel(
      llmService: llmService,
      userPreferencesRepository: userPreferencesRepository,
      keychainAPIValidator: keychainAPIValidator,
      keychainService: keychainService,
      warningManager: warningManager,
      fileManagerHelper: recordingFileManagerHelper
    )
  }

  func makeMeetingDetectionSettingsViewModel() -> MeetingDetectionSettingsViewModel {
    MeetingDetectionSettingsViewModel(
      detectionService: meetingDetectionService,
      userPreferencesRepository: userPreferencesRepository,
      permissionsHelper: makePermissionsHelper()
    )
  }

  func makeOnboardingViewModel() -> OnboardingViewModel {
    OnboardingViewModel(
      permissionsHelper: PermissionsHelper(),
      userPreferencesRepository: userPreferencesRepository
    )
  }

  func makeDragDropViewModel() -> DragDropViewModel {
    DragDropViewModel(
      transcriptionService: transcriptionService,
      llmService: llmService,
      userPreferencesRepository: userPreferencesRepository,
      recordingFileManagerHelper: recordingFileManagerHelper
    )
  }
}
