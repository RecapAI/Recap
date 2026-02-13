import Foundation

@MainActor
extension ProcessingCoordinator {
  func completeProcessing(
    recording: RecordingInfo,
    transcriptionText: String,
    summaryText: String,
    startTime: Date
  ) async {
    do {
      try await updateRecordingState(recording.id, state: .completed)

      let result = ProcessingResult(
        recordingID: recording.id,
        transcriptionText: transcriptionText,
        summaryText: summaryText,
        processingDuration: Date().timeIntervalSince(startTime)
      )

      delegate?.processingDidComplete(recordingID: recording.id, result: result)
    } catch {
      await handleProcessingError(
        ProcessingError.coreDataError(error.localizedDescription), for: recording)
    }
  }

  func completeProcessingWithoutSummary(
    recording: RecordingInfo,
    transcriptionText: String,
    startTime: Date
  ) async {
    do {
      try await updateRecordingState(recording.id, state: .completed)

      let result = ProcessingResult(
        recordingID: recording.id,
        transcriptionText: transcriptionText,
        summaryText: "",
        processingDuration: Date().timeIntervalSince(startTime)
      )

      delegate?.processingDidComplete(recordingID: recording.id, result: result)
    } catch {
      await handleProcessingError(
        ProcessingError.coreDataError(error.localizedDescription), for: recording)
    }
  }

  func completeProcessingWithoutTranscription(
    recording: RecordingInfo,
    startTime: Date
  ) async {
    do {
      try await updateRecordingState(recording.id, state: .completed)

      let result = ProcessingResult(
        recordingID: recording.id,
        transcriptionText: "",
        summaryText: "",
        processingDuration: Date().timeIntervalSince(startTime)
      )

      delegate?.processingDidComplete(recordingID: recording.id, result: result)
    } catch {
      await handleProcessingError(
        ProcessingError.coreDataError(error.localizedDescription), for: recording)
    }
  }
}
