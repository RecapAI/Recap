import Foundation

@MainActor
final class DependencyContainer {
  let inMemory: Bool

  lazy var coreDataManager: CoreDataManagerType = makeCoreDataManager()
  lazy var whisperModelRepository: WhisperModelRepositoryType = makeWhisperModelRepository()
  lazy var whisperModelsViewModel: WhisperModelsViewModel = makeWhisperModelsViewModel()
  lazy var statusBarManager: StatusBarManagerType = makeStatusBarManager()
  lazy var audioProcessController: AudioProcessController = makeAudioProcessController()
  lazy var appSelectionViewModel: AppSelectionViewModel = makeAppSelectionViewModel()
  lazy var previousRecapsViewModel: PreviousRecapsViewModel = makePreviousRecapsViewModel()
  lazy var recordingCoordinator: RecordingCoordinator = makeRecordingCoordinator()
  lazy var recordingRepository: RecordingRepositoryType = makeRecordingRepository()
  lazy var llmModelRepository: LLMModelRepositoryType = makeLLMModelRepository()
  lazy var userPreferencesRepository: UserPreferencesRepositoryType =
    makeUserPreferencesRepository()
  lazy var recordingFileManagerHelper: RecordingFileManagerHelperType =
    makeRecordingFileManagerHelper()
  lazy var llmService: LLMServiceType = makeLLMService()
  lazy var summarizationService: SummarizationServiceType = makeSummarizationService()
  lazy var processingCoordinator: ProcessingCoordinator = makeProcessingCoordinator()
  lazy var recordingFileManager: RecordingFileManaging = makeRecordingFileManager()
  lazy var generalSettingsViewModel: GeneralSettingsViewModel = makeGeneralSettingsViewModel()
  lazy var recapViewModel: RecapViewModel = createRecapViewModel()
  lazy var onboardingViewModel: OnboardingViewModel = makeOnboardingViewModel()
  lazy var summaryViewModel: SummaryViewModel = createSummaryViewModel()
  lazy var transcriptionService: TranscriptionServiceType = makeTranscriptionService()
  lazy var warningManager: any WarningManagerType = makeWarningManager()
  lazy var providerWarningCoordinator: ProviderWarningCoordinator = makeProviderWarningCoordinator()
  lazy var meetingDetectionService: any MeetingDetectionServiceType = makeMeetingDetectionService()
  lazy var meetingAppDetectionService: MeetingAppDetecting = makeMeetingAppDetectionService()
  lazy var recordingSessionManager: RecordingSessionManaging = makeRecordingSessionManager()
  lazy var microphoneCapture: any MicrophoneCaptureType = makeMicrophoneCapture()
  lazy var notificationService: NotificationServiceType = makeNotificationService()
  lazy var appSelectionCoordinator: AppSelectionCoordinatorType = makeAppSelectionCoordinator()
  lazy var keychainService: KeychainServiceType = makeKeychainService()
  lazy var keychainAPIValidator: KeychainAPIValidatorType = makeKeychainAPIValidator()
  lazy var dragDropViewModel: DragDropViewModel = makeDragDropViewModel()

  init(inMemory: Bool = false) {
    self.inMemory = inMemory
  }

  // MARK: - Public Factory Methods

  func createMenuBarPanelManager() -> MenuBarPanelManager {
    providerWarningCoordinator.startMonitoring()
    return MenuBarPanelManager(
      statusBarManager: statusBarManager,
      whisperModelsViewModel: whisperModelsViewModel,
      coreDataManager: coreDataManager,
      audioProcessController: audioProcessController,
      appSelectionViewModel: appSelectionViewModel,
      previousRecapsViewModel: previousRecapsViewModel,
      recapViewModel: recapViewModel,
      onboardingViewModel: onboardingViewModel,
      summaryViewModel: summaryViewModel,
      generalSettingsViewModel: generalSettingsViewModel,
      dragDropViewModel: dragDropViewModel,
      userPreferencesRepository: userPreferencesRepository,
      meetingDetectionService: meetingDetectionService
    )
  }

  func createRecapViewModel() -> RecapViewModel {
    RecapViewModel(
      recordingCoordinator: recordingCoordinator,
      processingCoordinator: processingCoordinator,
      recordingRepository: recordingRepository,
      appSelectionViewModel: appSelectionViewModel,
      fileManager: recordingFileManager,
      warningManager: warningManager,
      meetingDetectionService: meetingDetectionService,
      userPreferencesRepository: userPreferencesRepository,
      notificationService: notificationService,
      appSelectionCoordinator: appSelectionCoordinator,
      permissionsHelper: makePermissionsHelper()
    )
  }

  func createGeneralSettingsViewModel() -> GeneralSettingsViewModel {
    generalSettingsViewModel
  }

  func createSummaryViewModel() -> SummaryViewModel {
    SummaryViewModel(
      recordingRepository: recordingRepository,
      processingCoordinator: processingCoordinator,
      userPreferencesRepository: userPreferencesRepository
    )
  }
}

extension DependencyContainer {
  static func createForAppDelegate() async -> DependencyContainer {
    await MainActor.run {
      DependencyContainer()
    }
  }
}

extension DependencyContainer {
  static func createForPreview() -> DependencyContainer {
    DependencyContainer(inMemory: true)
  }

  static func createForTesting(inMemory: Bool = true) -> DependencyContainer {
    DependencyContainer(inMemory: inMemory)
  }
}
