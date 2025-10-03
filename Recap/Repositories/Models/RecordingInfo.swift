import Foundation

struct RecordingInfo: Identifiable, Equatable {
    let id: String
    let startDate: Date
    let endDate: Date?
    let state: RecordingProcessingState
    let errorMessage: String?
    let recordingURL: URL
    let microphoneURL: URL?
    let hasMicrophoneAudio: Bool
    let applicationName: String?
    let transcriptionText: String?
    let summaryText: String?
    let timestampedTranscription: TimestampedTranscription?
    let createdAt: Date
    let modifiedAt: Date
    
    var duration: TimeInterval? {
        guard let endDate = endDate else { return nil }
        return endDate.timeIntervalSince(startDate)
    }
    
    var isComplete: Bool {
        state == .completed
    }
    
    var isProcessing: Bool {
        state.isProcessing
    }
    
    var hasFailed: Bool {
        state.isFailed
    }
    
    var canRetry: Bool {
        state.canRetry
    }
}

extension RecordingInfo {
    init(from entity: UserRecording) {
        self.id = entity.id ?? UUID().uuidString
        self.startDate = entity.startDate ?? Date()
        self.endDate = entity.endDate
        self.state = RecordingProcessingState(rawValue: entity.state) ?? .recording
        self.errorMessage = entity.errorMessage
        self.recordingURL = URL(fileURLWithPath: entity.recordingURL ?? "")
        self.microphoneURL = entity.microphoneURL.map { URL(fileURLWithPath: $0) }
        self.hasMicrophoneAudio = entity.hasMicrophoneAudio
        self.applicationName = entity.applicationName
        self.transcriptionText = entity.transcriptionText
        self.summaryText = entity.summaryText
        
        // Decode timestamped transcription data if available
        if let data = entity.timestampedTranscriptionData {
            self.timestampedTranscription = try? JSONDecoder().decode(TimestampedTranscription.self, from: data)
        } else {
            self.timestampedTranscription = nil
        }
        self.createdAt = entity.createdAt ?? Date()
        self.modifiedAt = entity.modifiedAt ?? Date()
    }
}