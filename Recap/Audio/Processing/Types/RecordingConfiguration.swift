import Foundation

struct RecordingConfiguration {
    let id: String
    let audioProcess: AudioProcess
    let enableMicrophone: Bool
    let baseURL: URL
    
    var expectedFiles: RecordedFiles {
        let applicationName = audioProcess.id == -1 ? "All Apps" : audioProcess.name

        if enableMicrophone {
            return RecordedFiles(
                microphoneURL: baseURL.appendingPathExtension("microphone.wav"),
                systemAudioURL: baseURL.appendingPathExtension("system.wav"),
                applicationName: applicationName
            )
        } else {
            return RecordedFiles(
                microphoneURL: nil,
                systemAudioURL: baseURL.appendingPathExtension("system.wav"),
                applicationName: applicationName
            )
        }
    }
}
