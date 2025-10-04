import Foundation

extension RecapViewModel: ProcessingCoordinatorDelegate {
  func processingDidStart(recordingID: String) {
    Task { @MainActor in
      logger.info("Processing started for recording: \(recordingID)")
      updateRecordingsFromRepository()
    }
  }

  func processingDidComplete(recordingID: String, result: ProcessingResult) {
    Task { @MainActor in
      logger.info("Processing completed for recording: \(recordingID)")
      updateRecordingsFromRepository()

      showProcessingCompleteNotification(for: result)
    }
  }

  func processingDidFail(recordingID: String, error: ProcessingError) {
    Task { @MainActor in
      logger.error(
        "Processing failed for recording \(recordingID): \(error.localizedDescription)")
      updateRecordingsFromRepository()

      if error.isRetryable {
        errorMessage =
          "\(error.localizedDescription). You can retry from the recordings list."
      } else {
        errorMessage = error.localizedDescription
      }
    }
  }

  func processingStateDidChange(recordingID: String, newState: RecordingProcessingState) {
    Task { @MainActor in
      logger.info("Processing state changed for \(recordingID): \(newState.displayName)")
      updateRecordingsFromRepository()
    }
  }

  private func updateRecordingsFromRepository() {
    Task {
      do {
        currentRecordings = try await recordingRepository.fetchAllRecordings()
      } catch {
        logger.error("Failed to fetch recordings: \(error)")
      }
    }
  }

  private func showProcessingCompleteNotification(for result: ProcessingResult) {
    // Future enhancement: Implement rich notification when Notification Center integration is added
    logger.info("Summary ready for recording \(result.recordingID)")
  }
}
