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

      let recordingInfo = try await createRecordingEntity(
        recordingID: recordingID,
        recordedFiles: recordedFiles
      )

      await prepareTranscriptionPlaceholderIfNeeded(
        recording: recordingInfo,
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
  ) async throws -> RecordingInfo {
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
    return recordingInfo
  }

  private func handleRecordingStartError(_ error: Error) {
    errorMessage = error.localizedDescription
    logger.error("Failed to start recording: \(error)")
    currentRecordingID = nil
    updateRecordingUIState(started: false)
    showErrorToast = true
  }

  private func prepareTranscriptionPlaceholderIfNeeded(
    recording: RecordingInfo,
    recordedFiles: RecordedFiles
  ) async {
    let autoTranscribeEnabled = await isAutoTranscribeEnabled()
    guard autoTranscribeEnabled else { return }

    let recordingDirectory: URL
    if let systemAudioURL = recordedFiles.systemAudioURL {
      recordingDirectory = systemAudioURL.deletingLastPathComponent()
    } else {
      recordingDirectory = fileManager.createRecordingBaseURL(for: recording.id)
    }

    do {
      let placeholderURL = try TranscriptionMarkdownExporter.preparePlaceholder(
        recording: recording,
        destinationDirectory: recordingDirectory
      )

      logger.info("Prepared transcription placeholder at \(placeholderURL.path)")
    } catch {
      logger.error(
        "Failed to prepare transcription placeholder: \(error.localizedDescription)")
    }
  }

  private func isAutoTranscribeEnabled() async -> Bool {
    do {
      let preferences = try await userPreferencesRepository.getOrCreatePreferences()
      return preferences.autoTranscribeEnabled
    } catch {
      logger.error("Failed to fetch transcription preference: \(error.localizedDescription)")
      return true
    }
  }
}
