import Foundation
import OSLog

extension RecapViewModel {
  func handleRecordingFailure(recordingID: String, error: Error) async {
    do {
      try await recordingRepository.deleteRecording(id: recordingID)
      currentRecordings.removeAll { $0.id == recordingID }

      logger.error("Recording failed and cleaned up: \(error)")
    } catch {
      logger.error("Failed to clean up failed recording: \(error)")
    }
  }
}
