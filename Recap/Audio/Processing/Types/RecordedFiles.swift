import Foundation

struct RecordedFiles {
  let microphoneURL: URL?
  let systemAudioURL: URL?
  let applicationName: String?

  init(microphoneURL: URL?, systemAudioURL: URL?, applicationName: String? = nil) {
    self.microphoneURL = microphoneURL
    self.systemAudioURL = systemAudioURL
    self.applicationName = applicationName
  }
}
