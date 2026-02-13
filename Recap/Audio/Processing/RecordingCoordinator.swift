import AVFoundation
import Foundation
import OSLog

final class RecordingCoordinator: ObservableObject {
  private let logger = Logger(
    subsystem: AppConstants.Logging.subsystem,
    category: String(describing: RecordingCoordinator.self)
  )

  private(set) var state: RecordingState = .idle
  private(set) var detectedMeetingApps: [AudioProcess] = []

  private let appDetectionService: MeetingAppDetecting
  private let sessionManager: RecordingSessionManaging
  private let fileManager: RecordingFileManaging
  private let microphoneCapture: any MicrophoneCaptureType

  private var currentRecordingURL: URL?

  init(
    appDetectionService: MeetingAppDetecting,
    sessionManager: RecordingSessionManaging,
    fileManager: RecordingFileManaging,
    microphoneCapture: any MicrophoneCaptureType
  ) {

    self.appDetectionService = appDetectionService
    self.sessionManager = sessionManager
    self.fileManager = fileManager
    self.microphoneCapture = microphoneCapture
  }

  func setupProcessController() {
    Task { @MainActor in
      let processController = AudioProcessController()
      processController.activate()
      (appDetectionService as? MeetingAppDetectionService)?.setProcessController(
        processController)
    }
  }

  func detectMeetingApps() async -> [AudioProcess] {
    let meetingApps = await appDetectionService.detectMeetingApps()
    self.detectedMeetingApps = meetingApps
    return meetingApps
  }

  func getAllAudioProcesses() async -> [AudioProcess] {
    await appDetectionService.getAllAudioProcesses()
  }

  func startRecording(configuration: RecordingConfiguration) async throws -> RecordedFiles {
    guard case .idle = state else {
      throw AudioCaptureError.coreAudioError("Recording already in progress")
    }

    state = .starting

    do {
      let coordinator = try await sessionManager.startSession(configuration: configuration)

      state = .recording(coordinator)
      currentRecordingURL = configuration.baseURL

      logger.info(
        """
        Recording started successfully for \(configuration.audioProcess.name) \
        with microphone: \(configuration.enableMicrophone)
        """)

      return configuration.expectedFiles

    } catch {
      state = .failed(error)
      logger.error("Failed to start recording: \(error)")
      throw error
    }
  }

  func stopRecording() async -> RecordedFiles? {
    guard case .recording(let coordinator) = state else {
      logger.warning("No active recording to stop")
      return nil
    }

    state = .stopping

    coordinator.stop()

    let recordedFiles = coordinator.recordedFiles
    currentRecordingURL = nil
    state = .idle

    logger.info("Recording stopped successfully")
    return recordedFiles
  }

  var isRecording: Bool {
    if case .recording = state {
      return true
    }
    return false
  }

  var isIdle: Bool {
    if case .idle = state {
      return true
    }
    return false
  }

  var errorMessage: String? {
    if case .failed(let error) = state {
      return error.localizedDescription
    }
    return nil
  }

  var currentAudioLevel: Float {
    microphoneCapture.audioLevel
  }

  var hasDetectedMeetingApps: Bool {
    !detectedMeetingApps.isEmpty
  }

  func getCurrentRecordingCoordinator() -> AudioRecordingCoordinatorType? {
    if case .recording(let coordinator) = state {
      return coordinator
    }
    return nil
  }

  deinit {
    if case .recording(let coordinator) = state {
      coordinator.stop()
    }
  }
}
