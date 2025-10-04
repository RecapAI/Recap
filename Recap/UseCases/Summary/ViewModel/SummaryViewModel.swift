import Combine
import SwiftUI

@MainActor
final class SummaryViewModel: SummaryViewModelType {
  @Published var currentRecording: RecordingInfo?
  @Published private(set) var isLoadingRecording = false
  @Published private(set) var errorMessage: String?
  @Published var showingCopiedToast = false
  @Published private(set) var userPreferences: UserPreferencesInfo?

  private let recordingRepository: RecordingRepositoryType
  private let processingCoordinator: ProcessingCoordinatorType
  private let userPreferencesRepository: UserPreferencesRepositoryType
  private var cancellables = Set<AnyCancellable>()
  private var refreshTimer: Timer?

  init(
    recordingRepository: RecordingRepositoryType,
    processingCoordinator: ProcessingCoordinatorType,
    userPreferencesRepository: UserPreferencesRepositoryType
  ) {
    self.recordingRepository = recordingRepository
    self.processingCoordinator = processingCoordinator
    self.userPreferencesRepository = userPreferencesRepository

    Task {
      await loadUserPreferences()
    }
  }

  func loadUserPreferences() async {
    do {
      userPreferences = try await userPreferencesRepository.getOrCreatePreferences()
    } catch {
      // If we can't load preferences, assume defaults (auto-summarize enabled)
      userPreferences = nil
    }
  }

  func loadRecording(withID recordingID: String) {
    isLoadingRecording = true
    errorMessage = nil

    Task {
      do {
        let recording = try await recordingRepository.fetchRecording(id: recordingID)
        currentRecording = recording
      } catch {
        errorMessage = "Failed to load recording: \(error.localizedDescription)"
      }
      isLoadingRecording = false
    }
  }

  func loadLatestRecording() {
    isLoadingRecording = true
    errorMessage = nil

    Task {
      do {
        let recordings = try await recordingRepository.fetchAllRecordings()
        currentRecording = recordings.first
      } catch {
        errorMessage = "Failed to load recordings: \(error.localizedDescription)"
      }
      isLoadingRecording = false
    }
  }

  var processingStage: ProcessingStatesCard.ProcessingStage? {
    guard let recording = currentRecording else { return nil }

    switch recording.state {
    case .recorded:
      return .recorded
    case .transcribing, .transcribed:
      return .transcribing
    case .summarizing:
      return .summarizing
    default:
      return nil
    }
  }

  var isProcessing: Bool {
    guard let recording = currentRecording else { return false }
    return recording.state.isProcessing
  }

  var hasSummary: Bool {
    guard let recording = currentRecording else { return false }
    return recording.state == .completed && recording.summaryText != nil
  }

  var isRecordingReady: Bool {
    guard let recording = currentRecording else { return false }
    guard recording.state == .completed else { return false }

    // If auto-summarize is enabled, we need summary text
    if userPreferences?.autoSummarizeEnabled == true {
      return recording.summaryText != nil
    }

    // If auto-summarize is disabled, the recording is valid when completed
    return true
  }

  func retryProcessing() async {
    guard let recording = currentRecording else { return }

    if recording.state == .transcriptionFailed {
      await processingCoordinator.retryProcessing(recordingID: recording.id)
    } else {
      do {
        try await recordingRepository.updateRecordingState(
          id: recording.id,
          state: .summarizing,
          errorMessage: nil
        )
        await processingCoordinator.startProcessing(recordingInfo: recording)
      } catch {
        errorMessage = "Failed to retry summarization: \(error.localizedDescription)"
      }
    }

    loadRecording(withID: recording.id)
  }

  func fixStuckRecording() async {
    guard let recording = currentRecording else { return }

    do {
      // Update to transcribing state to show processing feedback
      try await recordingRepository.updateRecordingState(
        id: recording.id,
        state: .transcribing,
        errorMessage: nil
      )

      // Reload the recording to reflect the change
      loadRecording(withID: recording.id)

      // Fetch the updated recording and trigger processing
      if let updatedRecording = try await recordingRepository.fetchRecording(id: recording.id) {
        await processingCoordinator.startProcessing(recordingInfo: updatedRecording)
      }
    } catch {
      errorMessage = "Failed to fix recording state: \(error.localizedDescription)"
    }
  }

  func markAsCompleted() async {
    guard let recording = currentRecording else { return }

    do {
      // Mark recording as completed without processing
      try await recordingRepository.updateRecordingState(
        id: recording.id,
        state: .completed,
        errorMessage: nil
      )

      // Reload the recording to reflect the change
      loadRecording(withID: recording.id)
    } catch {
      errorMessage = "Failed to mark recording as completed: \(error.localizedDescription)"
    }
  }

  func startAutoRefresh() {
    stopAutoRefresh()

    refreshTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
      Task { @MainActor in
        await self?.refreshCurrentRecording()
      }
    }
  }

  func stopAutoRefresh() {
    refreshTimer?.invalidate()
    refreshTimer = nil
  }

  private func refreshCurrentRecording() async {
    guard let recordingID = currentRecording?.id else { return }

    do {
      let recording = try await recordingRepository.fetchRecording(id: recordingID)
      currentRecording = recording
    } catch {
      errorMessage = "Failed to refresh recording: \(error.localizedDescription)"
    }
  }

  func copySummary() {
    guard let summaryText = currentRecording?.summaryText else { return }

    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(summaryText, forType: .string)

    showingCopiedToast = true

    Task {
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      showingCopiedToast = false
    }
  }

  func copyTranscription() {
    guard let recording = currentRecording else { return }
    guard let transcriptionText = recording.transcriptionText else { return }

    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(transcriptionText, forType: .string)

    showingCopiedToast = true

    Task {
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      showingCopiedToast = false
    }
  }

  deinit {
    Task { @MainActor [weak self] in
      self?.stopAutoRefresh()
    }
  }
}
