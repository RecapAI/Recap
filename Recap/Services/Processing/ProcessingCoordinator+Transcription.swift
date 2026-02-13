import Foundation
import OSLog

@MainActor
extension ProcessingCoordinator {
  func performTranscriptionPhase(_ recording: RecordingInfo) async throws -> String {
    try await updateRecordingState(recording.id, state: .transcribing)

    let transcriptionResult = try await performTranscription(recording)

    try await saveTranscriptionResults(recording: recording, result: transcriptionResult)

    try await updateRecordingState(recording.id, state: .transcribed)

    return transcriptionResult.combinedText
  }

  func saveTranscriptionResults(
    recording: RecordingInfo,
    result: TranscriptionResult
  ) async throws {
    try await recordingRepository.updateRecordingTranscription(
      id: recording.id,
      transcriptionText: result.combinedText
    )

    if let timestampedTranscription = result.timestampedTranscription {
      try await recordingRepository.updateRecordingTimestampedTranscription(
        id: recording.id,
        timestampedTranscription: timestampedTranscription
      )

      await exportTranscriptionToMarkdown(
        recording: recording,
        timestampedTranscription: timestampedTranscription
      )
    }
  }

  func performTranscription(_ recording: RecordingInfo) async throws
    -> TranscriptionResult {
    do {
      let microphoneURL = recording.hasMicrophoneAudio ? recording.microphoneURL : nil
      return try await transcriptionService.transcribe(
        audioURL: recording.recordingURL,
        microphoneURL: microphoneURL
      )
    } catch let error as TranscriptionError {
      throw ProcessingError.transcriptionFailed(error.localizedDescription)
    } catch {
      throw ProcessingError.transcriptionFailed(error.localizedDescription)
    }
  }

  /// Export transcription to markdown file in the same directory as the recording
  func exportTranscriptionToMarkdown(
    recording: RecordingInfo,
    timestampedTranscription: TimestampedTranscription
  ) async {
    do {
      // Get the directory containing the recording files
      let recordingDirectory = recording.recordingURL.deletingLastPathComponent()

      // Fetch the updated recording with timestamped transcription
      guard
        let updatedRecording = try? await recordingRepository.fetchRecording(
          id: recording.id)
      else {
        logger.warning("Could not fetch updated recording for markdown export")
        return
      }

      // Export to markdown
      let markdownURL = try TranscriptionMarkdownExporter.exportToMarkdown(
        recording: updatedRecording,
        destinationDirectory: recordingDirectory
      )

      logger.info("Exported transcription to markdown: \(markdownURL.path)")
    } catch {
      logger.error(
        "Failed to export transcription to markdown: \(error.localizedDescription)")
    }
  }
}
