import Foundation
import Combine

@MainActor
final class ProcessingCoordinator: ProcessingCoordinatorType {
    weak var delegate: ProcessingCoordinatorDelegate?
    
    @Published private(set) var currentProcessingState: ProcessingState = .idle
    
    private let recordingRepository: RecordingRepositoryType
    private let summarizationService: SummarizationServiceType
    private let transcriptionService: TranscriptionServiceType
    private let userPreferencesRepository: UserPreferencesRepositoryType
    private var systemLifecycleManager: SystemLifecycleManager?
    
    private var processingTask: Task<Void, Never>?
    private let processingQueue = AsyncStream<RecordingInfo>.makeStream()
    private var queueTask: Task<Void, Never>?
    
    init(
        recordingRepository: RecordingRepositoryType,
        summarizationService: SummarizationServiceType,
        transcriptionService: TranscriptionServiceType,
        userPreferencesRepository: UserPreferencesRepositoryType
    ) {
        self.recordingRepository = recordingRepository
        self.summarizationService = summarizationService
        self.transcriptionService = transcriptionService
        self.userPreferencesRepository = userPreferencesRepository
        
        startQueueProcessing()
    }
    
    func setSystemLifecycleManager(_ manager: SystemLifecycleManager) {
        self.systemLifecycleManager = manager
        manager.delegate = self
    }
    
    func startProcessing(recordingInfo: RecordingInfo) async {
        processingQueue.continuation.yield(recordingInfo)
    }
    
    func cancelProcessing(recordingID: String) async {
        guard case .processing(let currentID) = currentProcessingState,
              currentID == recordingID else { return }
        
        processingTask?.cancel()
        currentProcessingState = .idle

        try? await recordingRepository.updateRecordingState(
            id: recordingID,
            state: .recorded,
            errorMessage: "Processing cancelled"
        )
        
        delegate?.processingDidFail(recordingID: recordingID, error: .cancelled)
    }
    
    func retryProcessing(recordingID: String) async {
        guard let recording = try? await recordingRepository.fetchRecording(id: recordingID),
              recording.canRetry else { return }
        
        await startProcessing(recordingInfo: recording)
    }
    
    private func startQueueProcessing() {
        queueTask = Task {
            for await recording in processingQueue.stream {
                guard !Task.isCancelled else { break }
                
                currentProcessingState = .processing(recordingID: recording.id)
                delegate?.processingDidStart(recordingID: recording.id)
                
                processingTask = Task {
                    await processRecording(recording)
                }
                
                await processingTask?.value
                currentProcessingState = .idle
            }
        }
    }
    
    private func processRecording(_ recording: RecordingInfo) async {
        let startTime = Date()
        
        do {
            let transcriptionText = try await performTranscriptionPhase(recording)
            guard !Task.isCancelled else { throw ProcessingError.cancelled }
            
            let autoSummarizeEnabled = await checkAutoSummarizeEnabled()
            
            if autoSummarizeEnabled {
                let summaryText = try await performSummarizationPhase(recording, transcriptionText: transcriptionText)
                guard !Task.isCancelled else { throw ProcessingError.cancelled }
                
                await completeProcessing(
                    recording: recording,
                    transcriptionText: transcriptionText,
                    summaryText: summaryText,
                    startTime: startTime
                )
            } else {
                await completeProcessingWithoutSummary(
                    recording: recording,
                    transcriptionText: transcriptionText,
                    startTime: startTime
                )
            }
            
        } catch let error as ProcessingError {
            await handleProcessingError(error, for: recording)
        } catch {
            let processingError = ProcessingError.coreDataError(error.localizedDescription)
            await handleProcessingError(processingError, for: recording)
        }
    }
    
    private func performTranscriptionPhase(_ recording: RecordingInfo) async throws -> String {
        try await updateRecordingState(recording.id, state: .transcribing)
        
        let transcriptionResult = try await performTranscription(recording)
        
        try await recordingRepository.updateRecordingTranscription(
            id: recording.id,
            transcriptionText: transcriptionResult.combinedText
        )
        
        // Save timestamped transcription data if available
        if let timestampedTranscription = transcriptionResult.timestampedTranscription {
            try await recordingRepository.updateRecordingTimestampedTranscription(
                id: recording.id,
                timestampedTranscription: timestampedTranscription
            )
        }
        
        try await updateRecordingState(recording.id, state: .transcribed)
        
        return transcriptionResult.combinedText
    }
    
    private func performSummarizationPhase(_ recording: RecordingInfo, transcriptionText: String) async throws -> String {
        try await updateRecordingState(recording.id, state: .summarizing)
        
        let summaryRequest = buildSummarizationRequest(
            recording: recording,
            transcriptionText: transcriptionText
        )
        
        let summaryResult = try await summarizationService.summarize(summaryRequest)
        
        try await recordingRepository.updateRecordingSummary(
            id: recording.id,
            summaryText: summaryResult.summary
        )
        
        return summaryResult.summary
    }
    
    private func buildSummarizationRequest(recording: RecordingInfo, transcriptionText: String) -> SummarizationRequest {
        let metadata = SummarizationRequest.TranscriptMetadata(
            duration: recording.duration ?? 0,
            participants: recording.hasMicrophoneAudio ? ["User", "System Audio"] : ["System Audio"],
            recordingDate: recording.startDate,
            applicationName: recording.applicationName
        )
        
        return SummarizationRequest(
            transcriptText: transcriptionText,
            metadata: metadata,
            options: .default
        )
    }
    
    private func updateRecordingState(_ recordingID: String, state: RecordingProcessingState) async throws {
        try await recordingRepository.updateRecordingState(
            id: recordingID,
            state: state,
            errorMessage: nil
        )
        delegate?.processingStateDidChange(recordingID: recordingID, newState: state)
    }
    
    private func completeProcessing(
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
            await handleProcessingError(ProcessingError.coreDataError(error.localizedDescription), for: recording)
        }
    }
    
    private func completeProcessingWithoutSummary(
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
            await handleProcessingError(ProcessingError.coreDataError(error.localizedDescription), for: recording)
        }
    }
    
    private func performTranscription(_ recording: RecordingInfo) async throws -> TranscriptionResult {
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
    
    private func handleProcessingError(_ error: ProcessingError, for recording: RecordingInfo) async {
        let failureState: RecordingProcessingState
        
        switch error {
        case .transcriptionFailed:
            failureState = .transcriptionFailed
        case .summarizationFailed:
            failureState = .summarizationFailed
        default:
            failureState = recording.state == .transcribing ? .transcriptionFailed : .summarizationFailed
        }
        
        do {
            try await recordingRepository.updateRecordingState(
                id: recording.id,
                state: failureState,
                errorMessage: error.localizedDescription
            )
            delegate?.processingStateDidChange(recordingID: recording.id, newState: failureState)
        } catch {
            print("Failed to update recording state after error: \(error)")
        }
        
        delegate?.processingDidFail(recordingID: recording.id, error: error)
    }
    
    private func checkAutoSummarizeEnabled() async -> Bool {
        do {
            let preferences = try await userPreferencesRepository.getOrCreatePreferences()
            return preferences.autoSummarizeEnabled
        } catch {
            return true
        }
    }
    
    deinit {
        queueTask?.cancel()
        processingTask?.cancel()
    }
}

extension ProcessingCoordinator: SystemLifecycleDelegate {
    func systemWillSleep() {
        guard case .processing(let recordingID) = currentProcessingState else { return }
        currentProcessingState = .paused(recordingID: recordingID)
        processingTask?.cancel()
    }
    
    func systemDidWake() {
        guard case .paused(let recordingID) = currentProcessingState else { return }
        
        Task {
            if let recording = try? await recordingRepository.fetchRecording(id: recordingID) {
                await startProcessing(recordingInfo: recording)
            }
        }
    }
}
