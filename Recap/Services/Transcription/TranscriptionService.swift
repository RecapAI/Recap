import Foundation
import WhisperKit

@MainActor
final class TranscriptionService: TranscriptionServiceType {
    private let whisperModelRepository: WhisperModelRepositoryType
    private var whisperKit: WhisperKit?
    private var loadedModelName: String?
    
    init(whisperModelRepository: WhisperModelRepositoryType) {
        self.whisperModelRepository = whisperModelRepository
    }
    
    func transcribe(audioURL: URL, microphoneURL: URL?) async throws -> TranscriptionResult {
        let startTime = Date()
        
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw TranscriptionError.audioFileNotFound
        }
        
        try await ensureModelLoaded()
        
        guard let whisperKit = self.whisperKit,
              let modelName = self.loadedModelName else {
            throw TranscriptionError.modelNotAvailable
        }
        
        // Get both text and timestamped segments
        let systemAudioText = try await transcribeAudioFile(audioURL, with: whisperKit)
        let systemAudioSegments = try await transcribeAudioFileWithTimestamps(audioURL, with: whisperKit, source: .systemAudio)
        
        var microphoneText: String?
        var microphoneSegments: [TranscriptionSegment] = []
        
        if let microphoneURL = microphoneURL,
           FileManager.default.fileExists(atPath: microphoneURL.path) {
            microphoneText = try await transcribeAudioFile(microphoneURL, with: whisperKit)
            microphoneSegments = try await transcribeAudioFileWithTimestamps(microphoneURL, with: whisperKit, source: .microphone)
        }
        
        let combinedText = buildCombinedText(
            systemAudioText: systemAudioText,
            microphoneText: microphoneText
        )
        
        // Create timestamped transcription by merging segments
        let allSegments = systemAudioSegments + microphoneSegments
        let timestampedTranscription = TimestampedTranscription(segments: allSegments)
        
        let duration = Date().timeIntervalSince(startTime)
        
        return TranscriptionResult(
            systemAudioText: systemAudioText,
            microphoneText: microphoneText,
            combinedText: combinedText,
            transcriptionDuration: duration,
            modelUsed: modelName,
            timestampedTranscription: timestampedTranscription
        )
    }
    
    func ensureModelLoaded() async throws {
        let selectedModel = try await whisperModelRepository.getSelectedModel()
        
        guard let model = selectedModel else {
            throw TranscriptionError.modelNotAvailable
        }
        
        if loadedModelName != model.name || whisperKit == nil {
            try await loadModel(model.name, isDownloaded: model.isDownloaded)
        }
    }
    
    func getCurrentModel() async -> String? {
        loadedModelName
    }
    
    private func loadModel(_ modelName: String, isDownloaded: Bool) async throws {
        do {
            print("Loading WhisperKit model: \(modelName), isDownloaded: \(isDownloaded)")
            
            // Always try to download/load the model, as WhisperKit will handle caching
            // The isDownloaded flag is just for UI purposes, but WhisperKit manages its own cache
            let newWhisperKit = try await WhisperKit.createWithProgress(
                model: modelName,
                modelRepo: "argmaxinc/whisperkit-coreml",
                modelFolder: nil,
                download: true, // Always allow download, WhisperKit will use cache if available
                progressCallback: { progress in
                    print("WhisperKit download progress: \(progress.fractionCompleted)")
                }
            )

            print("WhisperKit model loaded successfully: \(modelName)")
            self.whisperKit = newWhisperKit
            self.loadedModelName = modelName
            
            // Mark as downloaded in our repository if not already marked
            if !isDownloaded {
                let modelInfo = await WhisperKit.getModelSizeInfo(for: modelName)
                try await whisperModelRepository.markAsDownloaded(name: modelName, sizeInMB: Int64(modelInfo.totalSizeMB))
                print("Model marked as downloaded: \(modelName), size: \(modelInfo.totalSizeMB) MB")
            }
            
        } catch {
            print("Failed to load WhisperKit model \(modelName): \(error)")
            throw TranscriptionError.modelLoadingFailed("Failed to load model \(modelName): \(error.localizedDescription)")
        }
    }
    
    private func transcribeAudioFile(_ url: URL, with whisperKit: WhisperKit) async throws -> String {
        do {
            let options = DecodingOptions(
                task: .transcribe,
                language: nil, // Auto-detect language
                withoutTimestamps: false, // We want timestamps
                wordTimestamps: false // We don't need word-level timestamps for basic transcription
            )
            
            let results = try await whisperKit.transcribe(audioPath: url.path, decodeOptions: options)
            let result = results.first
            
            guard let segments = result?.segments else {
                return ""
            }
            
            let text = segments
                .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            
            return text
            
        } catch {
            throw TranscriptionError.transcriptionFailed(error.localizedDescription)
        }
    }
    
    private func transcribeAudioFileWithTimestamps(_ url: URL, with whisperKit: WhisperKit, source: TranscriptionSegment.AudioSource) async throws -> [TranscriptionSegment] {
        do {
            let options = DecodingOptions(
                task: .transcribe,
                language: nil, // Auto-detect language
                withoutTimestamps: false, // We want timestamps
                wordTimestamps: true // Enable word timestamps for precise timing
            )
            
            let results = try await whisperKit.transcribe(audioPath: url.path, decodeOptions: options)
            let result = results.first
            
            guard let segments = result?.segments else {
                return []
            }
            
            // Convert WhisperKit segments to our TranscriptionSegment format
            let transcriptionSegments = segments.compactMap { segment -> TranscriptionSegment? in
                let text = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return nil }
                
                return TranscriptionSegment(
                    text: text,
                    startTime: TimeInterval(segment.start),
                    endTime: TimeInterval(segment.end),
                    source: source
                )
            }
            
            return transcriptionSegments
            
        } catch {
            throw TranscriptionError.transcriptionFailed(error.localizedDescription)
        }
    }
    
    private func buildCombinedText(systemAudioText: String, microphoneText: String?) -> String {
        var combinedText = systemAudioText
        
        if let microphoneText = microphoneText, !microphoneText.isEmpty {
            combinedText += "\n\n[User Audio Note: The following was spoken by the user during this recording. Please incorporate this context when creating the meeting summary:]\n\n"
            combinedText += microphoneText
            combinedText += "\n\n[End of User Audio Note. Please align the above user input with the meeting content for a comprehensive summary.]"
        }
        
        return combinedText
    }
}
