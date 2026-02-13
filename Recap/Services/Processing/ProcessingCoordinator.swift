import Combine
import Foundation
import OSLog

@MainActor
final class ProcessingCoordinator: ProcessingCoordinatorType {
  let logger = Logger(
    subsystem: AppConstants.Logging.subsystem,
    category: String(describing: ProcessingCoordinator.self))
  weak var delegate: ProcessingCoordinatorDelegate?

  @Published private(set) var currentProcessingState: ProcessingState = .idle

  let recordingRepository: RecordingRepositoryType
  private let summarizationService: SummarizationServiceType
  let transcriptionService: TranscriptionServiceType
  let userPreferencesRepository: UserPreferencesRepositoryType
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
      currentID == recordingID
    else { return }

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
      recording.canRetry
    else { return }

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
      let autoTranscribeEnabled = await checkAutoTranscribeEnabled()

      if !autoTranscribeEnabled {
        await completeProcessingWithoutTranscription(recording: recording, startTime: startTime)
        return
      }

      let transcriptionText = try await performTranscriptionPhase(recording)
      guard !Task.isCancelled else { throw ProcessingError.cancelled }

      try await processSummarizationIfEnabled(
        recording: recording,
        transcriptionText: transcriptionText,
        startTime: startTime
      )

    } catch let error as ProcessingError {
      await handleProcessingError(error, for: recording)
    } catch {
      await handleProcessingError(
        ProcessingError.coreDataError(error.localizedDescription), for: recording)
    }
  }

  private func processSummarizationIfEnabled(
    recording: RecordingInfo,
    transcriptionText: String,
    startTime: Date
  ) async throws {
    let autoSummarizeEnabled = await checkAutoSummarizeEnabled()

    if autoSummarizeEnabled {
      let summaryText = try await performSummarizationPhase(
        recording, transcriptionText: transcriptionText)
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
  }

  private func performSummarizationPhase(_ recording: RecordingInfo, transcriptionText: String)
    async throws -> String {
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

  func handleProcessingError(_ error: ProcessingError, for recording: RecordingInfo) async {
    let failureState: RecordingProcessingState

    switch error {
    case .transcriptionFailed:
      failureState = .transcriptionFailed
    case .summarizationFailed:
      failureState = .summarizationFailed
    default:
      failureState =
        recording.state == .transcribing ? .transcriptionFailed : .summarizationFailed
    }

    do {
      try await recordingRepository.updateRecordingState(
        id: recording.id,
        state: failureState,
        errorMessage: error.localizedDescription
      )
      delegate?.processingStateDidChange(recordingID: recording.id, newState: failureState)
    } catch {
      logger.error(
        "Failed to update recording state after error: \(error.localizedDescription, privacy: .public)"
      )
    }

    delegate?.processingDidFail(recordingID: recording.id, error: error)
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
