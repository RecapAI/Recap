import Combine
import Foundation
import OSLog
import SwiftUI

@MainActor
protocol RecapViewModelDelegate: AnyObject {
  func didRequestSettingsOpen()
  func didRequestViewOpen()
  func didRequestPreviousRecapsOpen()
  func didRequestPanelClose()
}

@MainActor
final class RecapViewModel: ObservableObject {
  @Published var isRecording = false
  @Published var recordingDuration: TimeInterval = 0
  @Published var microphoneLevel: Float = 0.0
  @Published var systemAudioLevel: Float = 0.0
  @Published var errorMessage: String?
  @Published var isMicrophoneEnabled = false
  @Published var currentRecordings: [RecordingInfo] = []
  @Published var showErrorToast = false

  @Published private(set) var processingState: ProcessingState = .idle
  @Published private(set) var activeWarnings: [WarningItem] = []
  @Published private(set) var selectedApp: AudioProcess?

  let recordingCoordinator: RecordingCoordinator
  let processingCoordinator: ProcessingCoordinator
  let recordingRepository: RecordingRepositoryType
  let appSelectionViewModel: AppSelectionViewModel
  let fileManager: RecordingFileManaging
  let warningManager: any WarningManagerType
  let meetingDetectionService: any MeetingDetectionServiceType
  let userPreferencesRepository: UserPreferencesRepositoryType
  let notificationService: any NotificationServiceType
  var appSelectionCoordinator: any AppSelectionCoordinatorType
  let permissionsHelper: any PermissionsHelperType

  var timer: Timer?
  var levelTimer: Timer?
  let logger = Logger(
    subsystem: AppConstants.Logging.subsystem, category: String(describing: RecapViewModel.self))

  weak var delegate: RecapViewModelDelegate?

  var currentRecordingID: String?
  var lastNotifiedMeetingKey: String?

  var cancellables = Set<AnyCancellable>()
  init(
    recordingCoordinator: RecordingCoordinator,
    processingCoordinator: ProcessingCoordinator,
    recordingRepository: RecordingRepositoryType,
    appSelectionViewModel: AppSelectionViewModel,
    fileManager: RecordingFileManaging,
    warningManager: any WarningManagerType,
    meetingDetectionService: any MeetingDetectionServiceType,
    userPreferencesRepository: UserPreferencesRepositoryType,
    notificationService: any NotificationServiceType,
    appSelectionCoordinator: any AppSelectionCoordinatorType,
    permissionsHelper: any PermissionsHelperType
  ) {
    self.recordingCoordinator = recordingCoordinator
    self.processingCoordinator = processingCoordinator
    self.recordingRepository = recordingRepository
    self.appSelectionViewModel = appSelectionViewModel
    self.fileManager = fileManager
    self.warningManager = warningManager
    self.meetingDetectionService = meetingDetectionService
    self.userPreferencesRepository = userPreferencesRepository
    self.notificationService = notificationService
    self.appSelectionCoordinator = appSelectionCoordinator
    self.permissionsHelper = permissionsHelper

    setupBindings()
    setupWarningObserver()
    setupMeetingDetection()
    setupDelegates()

    Task {
      await loadRecordings()
      await loadMicrophonePreference()
    }
  }

  func selectApp(_ app: AudioProcess) {
    selectedApp = app
  }

  func clearError() {
    errorMessage = nil
  }

  func refreshApps() {
    appSelectionViewModel.refreshAvailableApps()
  }

  private func setupDelegates() {
    appSelectionCoordinator.delegate = self
    processingCoordinator.delegate = self
  }

  var currentRecordingLevel: Float {
    recordingCoordinator.currentAudioLevel
  }

  var hasAvailableApps: Bool {
    !appSelectionViewModel.availableApps.isEmpty
  }

  var canStartRecording: Bool {
    selectedApp != nil
  }

  func toggleMicrophone() {
    isMicrophoneEnabled.toggle()

    // Save the preference
    Task {
      do {
        try await userPreferencesRepository.updateMicrophoneEnabled(isMicrophoneEnabled)
      } catch {
        logger.error("Failed to save microphone preference: \(error)")
      }
    }
  }

  var systemAudioHeatmapLevel: Float {
    guard isRecording else { return 0 }
    return systemAudioLevel
  }

  var microphoneHeatmapLevel: Float {
    guard isRecording && isMicrophoneEnabled else { return 0 }
    return microphoneLevel
  }

  private func setupBindings() {
    appSelectionViewModel.refreshAvailableApps()
  }

  private func setupWarningObserver() {
    warningManager.activeWarningsPublisher
      .assign(to: \.activeWarnings, on: self)
      .store(in: &cancellables)
  }

  private func loadRecordings() async {
    do {
      currentRecordings = try await recordingRepository.fetchAllRecordings()
    } catch {
      logger.error("Failed to load recordings: \(error)")
    }
  }

  private func loadMicrophonePreference() async {
    do {
      let preferences = try await userPreferencesRepository.getOrCreatePreferences()
      await MainActor.run {
        isMicrophoneEnabled = preferences.microphoneEnabled
      }
    } catch {
      logger.error("Failed to load microphone preference: \(error)")
    }
  }

  func retryProcessing(for recordingID: String) async {
    await processingCoordinator.retryProcessing(recordingID: recordingID)
  }

  func updateRecordingUIState(started: Bool) {
    isRecording = started
    if started {
      recordingDuration = 0
      startTimers()
    } else {
      stopTimers()
      recordingDuration = 0
      microphoneLevel = 0.0
      systemAudioLevel = 0.0
    }
  }

  func syncRecordingStateWithCoordinator() {
    let coordinatorIsRecording = recordingCoordinator.isRecording
    if isRecording != coordinatorIsRecording {
      updateRecordingUIState(started: coordinatorIsRecording)
      if !coordinatorIsRecording {
        currentRecordingID = nil
      }
    }
  }

  deinit {
    Task { [weak self] in
      await self?.stopTimers()
    }
  }
}

extension RecapViewModel: AppSelectionCoordinatorDelegate {
  func didSelectApp(_ app: AudioProcess) {
    selectApp(app)
  }

  func didClearAppSelection() {
    selectedApp = nil
  }
}

extension RecapViewModel {
  func openSettings() {
    delegate?.didRequestSettingsOpen()
  }

  func openView() {
    delegate?.didRequestViewOpen()
  }

  func openPreviousRecaps() {
    delegate?.didRequestPreviousRecapsOpen()
  }

  func closePanel() {
    delegate?.didRequestPanelClose()
  }
}

extension RecapViewModel {
  static func createForPreview() -> RecapViewModel {
    let container = DependencyContainer.createForPreview()
    return container.createRecapViewModel()
  }
}
