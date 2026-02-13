import Foundation

protocol RecordingFileManaging {
  func createRecordingURL() -> URL
  func createRecordingBaseURL(for recordingID: String) -> URL
  func ensureRecordingsDirectoryExists() throws
}

final class RecordingFileManager: RecordingFileManaging {
  private let recordingsDirectoryName = "Recordings"
  private let fileManagerHelper: RecordingFileManagerHelperType?

  init(fileManagerHelper: RecordingFileManagerHelperType? = nil) {
    self.fileManagerHelper = fileManagerHelper
  }

  func createRecordingURL() -> URL {
    let timestamp = Date().timeIntervalSince1970
    let filename = "recap_recording_\(Int(timestamp))"

    return FileManager.default.temporaryDirectory
      .appendingPathComponent(filename)
      .appendingPathExtension("wav")
  }

  func createRecordingBaseURL(for recordingID: String) -> URL {
    if let fileManagerHelper = fileManagerHelper {
      do {
        let recordingDirectory = try fileManagerHelper.createRecordingDirectory(
          for: recordingID)
        return recordingDirectory
      } catch {
        // Fallback to default system
        return recordingsDirectory.appendingPathComponent(recordingID)
      }
    } else {
      // Use default system
      return recordingsDirectory.appendingPathComponent(recordingID)
    }
  }

  func ensureRecordingsDirectoryExists() throws {
    try FileManager.default.createDirectory(
      at: recordingsDirectory,
      withIntermediateDirectories: true
    )
  }

  private var recordingsDirectory: URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent(recordingsDirectoryName)
  }
}
