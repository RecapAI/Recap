import Foundation
import OSLog

protocol RecordingSessionManaging {
  func startSession(configuration: RecordingConfiguration) async throws
    -> AudioRecordingCoordinatorType
}

final class RecordingSessionManager: RecordingSessionManaging {
  private let logger = Logger(
    subsystem: AppConstants.Logging.subsystem,
    category: String(describing: RecordingSessionManager.self)
  )
  private let microphoneCapture: any MicrophoneCaptureType
  private let permissionsHelper: PermissionsHelperType

  init(
    microphoneCapture: any MicrophoneCaptureType,
    permissionsHelper: PermissionsHelperType
  ) {
    self.microphoneCapture = microphoneCapture
    self.permissionsHelper = permissionsHelper
  }

  func startSession(configuration: RecordingConfiguration) async throws
    -> AudioRecordingCoordinatorType {
    let microphoneCaptureToUse = configuration.enableMicrophone ? microphoneCapture : nil

    if configuration.enableMicrophone {
      let hasPermission = await permissionsHelper.checkMicrophonePermissionStatus()
      guard hasPermission == .authorized else {
        throw AudioCaptureError.microphonePermissionDenied
      }
    }

    let coordinator: AudioRecordingCoordinator

    if configuration.audioProcess.id == -1 {
      let systemWideTap = SystemWideTap()
      await MainActor.run {
        systemWideTap.activate()
      }

      if let errorMessage = systemWideTap.errorMessage {
        logger.error("System-wide tap failed: \(errorMessage)")
        throw AudioCaptureError.coreAudioError(
          "Failed to tap system audio: \(errorMessage)")
      }

      coordinator = AudioRecordingCoordinator(
        configuration: configuration,
        microphoneCapture: microphoneCaptureToUse,
        systemWideTap: systemWideTap
      )

      logger.info(
        "Recording session started for system-wide audio with microphone: \(configuration.enableMicrophone)"
      )
    } else {
      let processTap = ProcessTap(process: configuration.audioProcess)
      await MainActor.run {
        processTap.activate()
      }

      if let errorMessage = processTap.errorMessage {
        logger.error("Process tap failed: \(errorMessage)")
        throw AudioCaptureError.coreAudioError(
          "Failed to tap system audio: \(errorMessage)")
      }

      coordinator = AudioRecordingCoordinator(
        configuration: configuration,
        microphoneCapture: microphoneCaptureToUse,
        processTap: processTap
      )

      logger.info(
        """
        Recording session started for \(configuration.audioProcess.name)
        with microphone: \(configuration.enableMicrophone)
        """)
    }

    try await coordinator.start()
    return coordinator
  }
}
