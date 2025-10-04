import Foundation
import OSLog

extension RecapViewModel {
  func startRecording() async {
    syncRecordingStateWithCoordinator()
    guard !isRecording else { return }
    guard let selectedApp = selectedApp else { return }

    do {
      errorMessage = nil

      let recordingID = generateRecordingID()
      currentRecordingID = recordingID

      let configuration = try await createRecordingConfiguration(
        recordingID: recordingID,
        audioProcess: selectedApp
      )

      let recordedFiles = try await recordingCoordinator.startRecording(
        configuration: configuration)

      try await createRecordingEntity(
        recordingID: recordingID,
        recordedFiles: recordedFiles
      )

      updateRecordingUIState(started: true)

      logger.info(
        """
        Recording started successfully - System: \(recordedFiles.systemAudioURL?.path ?? "none"), \
        Microphone: \(recordedFiles.microphoneURL?.path ?? "none")
        """
      )
    } catch {
      handleRecordingStartError(error)
    }
  }

  private func generateRecordingID() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
    formatter.timeZone = TimeZone.current
    return formatter.string(from: Date())
  }

  private func createRecordingConfiguration(
    recordingID: String,
    audioProcess: AudioProcess
  ) async throws -> RecordingConfiguration {
    try fileManager.ensureRecordingsDirectoryExists()

    let baseURL = fileManager.createRecordingBaseURL(for: recordingID)

    return RecordingConfiguration(
      id: recordingID,
      audioProcess: audioProcess,
      enableMicrophone: isMicrophoneEnabled,
      baseURL: baseURL
    )
  }

  private func createRecordingEntity(
    recordingID: String,
    recordedFiles: RecordedFiles
  ) async throws {
    let parameters = RecordingCreationParameters(
      id: recordingID,
      startDate: Date(),
      recordingURL: recordedFiles.systemAudioURL
        ?? fileManager.createRecordingBaseURL(for: recordingID),
      microphoneURL: recordedFiles.microphoneURL,
      hasMicrophoneAudio: isMicrophoneEnabled,
      applicationName: recordedFiles.applicationName ?? selectedApp?.name
    )
    let recordingInfo = try await recordingRepository.createRecording(parameters)
    currentRecordings.insert(recordingInfo, at: 0)
  }

  private func handleRecordingStartError(_ error: Error) {
    errorMessage = error.localizedDescription
    logger.error("Failed to start recording: \(error)")
    currentRecordingID = nil
    updateRecordingUIState(started: false)
    showErrorToast = true
  }
}
