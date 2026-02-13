import Foundation
import OSLog

extension RecapViewModel {
  func stopRecording() async {
    guard isRecording else { return }
    guard let recordingID = currentRecordingID else { return }

    stopTimers()

    if let recordedFiles = await recordingCoordinator.stopRecording() {
      await handleSuccessfulRecordingStop(
        recordingID: recordingID,
        recordedFiles: recordedFiles
      )
    } else {
      await handleRecordingFailure(
        recordingID: recordingID,
        error: RecordingError.failedToStop
      )
    }

    updateRecordingUIState(started: false)
    currentRecordingID = nil
  }

  private func handleSuccessfulRecordingStop(
    recordingID: String,
    recordedFiles: RecordedFiles
  ) async {
    logRecordedFiles(recordedFiles)

    do {
      try await updateRecordingInRepository(
        recordingID: recordingID,
        recordedFiles: recordedFiles
      )

      if let updatedRecording = try await recordingRepository.fetchRecording(id: recordingID) {
        await processingCoordinator.startProcessing(recordingInfo: updatedRecording)
      }
    } catch {
      logger.error("Failed to update recording after stop: \(error)")
      await handleRecordingFailure(recordingID: recordingID, error: error)
    }
  }

  private func updateRecordingInRepository(
    recordingID: String,
    recordedFiles: RecordedFiles
  ) async throws {
    if let systemAudioURL = recordedFiles.systemAudioURL {
      try await recordingRepository.updateRecordingURLs(
        id: recordingID,
        recordingURL: systemAudioURL,
        microphoneURL: recordedFiles.microphoneURL
      )
    }

    try await recordingRepository.updateRecordingEndDate(
      id: recordingID,
      endDate: Date()
    )

    try await recordingRepository.updateRecordingState(
      id: recordingID,
      state: .recorded,
      errorMessage: nil
    )
  }

  private func logRecordedFiles(_ recordedFiles: RecordedFiles) {
    if let systemAudioURL = recordedFiles.systemAudioURL {
      logger.info("Recording stopped successfully - System audio: \(systemAudioURL.path)")
    }
    if let microphoneURL = recordedFiles.microphoneURL {
      logger.info("Recording stopped successfully - Microphone: \(microphoneURL.path)")
    }
  }
}
