import Foundation

#if MOCKING
  import Mockable
#endif

#if MOCKING
  @Mockable
#endif
@MainActor
protocol UserPreferencesRepositoryType {
  func getOrCreatePreferences() async throws -> UserPreferencesInfo
  func updateSelectedLLMModel(id: String?) async throws
  func updateSelectedProvider(_ provider: LLMProvider) async throws
  func updateAutoDetectMeetings(_ enabled: Bool) async throws
  func updateAutoStopRecording(_ enabled: Bool) async throws
  func updateAutoSummarize(_ enabled: Bool) async throws
  func updateAutoTranscribe(_ enabled: Bool) async throws
  func updateSummaryPromptTemplate(_ template: String?) async throws
  func updateOnboardingStatus(_ completed: Bool) async throws
  func updateMicrophoneEnabled(_ enabled: Bool) async throws
  func updateGlobalShortcut(keyCode: Int32, modifiers: Int32) async throws
  func updateCustomTmpDirectory(path: String?, bookmark: Data?) async throws
}
