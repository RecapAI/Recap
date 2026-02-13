import Foundation

@testable import Recap

extension UserPreferencesInfo {
  static func createForTesting(
    id: String = "test-id",
    selectedLLMModelID: String? = nil,
    selectedProvider: LLMProvider = .ollama,
    autoSummarizeEnabled: Bool = false,
    autoDetectMeetings: Bool = false,
    autoStopRecording: Bool = false,
    onboarded: Bool = true,
    summaryPromptTemplate: String? = nil,
    createdAt: Date = Date(),
    modifiedAt: Date = Date()
  ) -> UserPreferencesInfo {
    return UserPreferencesInfo(
      id: id,
      selectedLLMModelID: selectedLLMModelID,
      selectedProvider: selectedProvider,
      autoSummarizeEnabled: autoSummarizeEnabled,
      autoDetectMeetings: autoDetectMeetings,
      autoStopRecording: autoStopRecording,
      onboarded: onboarded,
      summaryPromptTemplate: summaryPromptTemplate,
      createdAt: createdAt,
      modifiedAt: modifiedAt
    )
  }
}
