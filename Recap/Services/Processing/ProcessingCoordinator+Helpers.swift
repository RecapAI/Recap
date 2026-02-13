import Foundation

@MainActor
extension ProcessingCoordinator {
  func checkAutoSummarizeEnabled() async -> Bool {
    do {
      let preferences = try await userPreferencesRepository.getOrCreatePreferences()
      return preferences.autoSummarizeEnabled
    } catch {
      return true
    }
  }

  func checkAutoTranscribeEnabled() async -> Bool {
    do {
      let preferences = try await userPreferencesRepository.getOrCreatePreferences()
      return preferences.autoTranscribeEnabled
    } catch {
      return true
    }
  }

  func buildSummarizationRequest(recording: RecordingInfo, transcriptionText: String)
    -> SummarizationRequest {
    let metadata = TranscriptMetadata(
      duration: recording.duration ?? 0,
      participants: recording.hasMicrophoneAudio
        ? ["User", "System Audio"] : ["System Audio"],
      recordingDate: recording.startDate,
      applicationName: recording.applicationName
    )

    return SummarizationRequest(
      transcriptText: transcriptionText,
      metadata: metadata,
      options: .default
    )
  }

  func updateRecordingState(_ recordingID: String, state: RecordingProcessingState)
    async throws {
    try await recordingRepository.updateRecordingState(
      id: recordingID,
      state: state,
      errorMessage: nil
    )
    delegate?.processingStateDidChange(recordingID: recordingID, newState: state)
  }
}
