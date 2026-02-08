import Foundation

@MainActor
protocol TranscriptionServiceType {
    func transcribe(audioURL: URL, microphoneURL: URL?) async throws -> TranscriptionResult
    func ensureModelLoaded() async throws
    func getCurrentModel() async -> String?
}

struct TranscriptionResult: Equatable {
    let systemAudioText: String
    let microphoneText: String?
    let combinedText: String
    let transcriptionDuration: TimeInterval
    let modelUsed: String
    
    // New timestamped transcription data
    let timestampedTranscription: TimestampedTranscription?
    
    init(
        systemAudioText: String,
        microphoneText: String?,
        combinedText: String,
        transcriptionDuration: TimeInterval,
        modelUsed: String,
        timestampedTranscription: TimestampedTranscription? = nil
    ) {
        self.systemAudioText = systemAudioText
        self.microphoneText = microphoneText
        self.combinedText = combinedText
        self.transcriptionDuration = transcriptionDuration
        self.modelUsed = modelUsed
        self.timestampedTranscription = timestampedTranscription
    }
}

enum TranscriptionError: LocalizedError {
    case modelNotAvailable
    case modelLoadingFailed(String)
    case audioFileNotFound
    case transcriptionFailed(String)
    case invalidAudioFormat
    
    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "No Whisper model is selected or available"
        case .modelLoadingFailed(let reason):
            return "Failed to load Whisper model: \(reason)"
        case .audioFileNotFound:
            return "Audio file not found at specified path"
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        case .invalidAudioFormat:
            return "Invalid audio format for transcription"
        }
    }
}