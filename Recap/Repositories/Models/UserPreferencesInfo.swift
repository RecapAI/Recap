import CoreData
import Foundation

struct UserPreferencesInfo: Identifiable {
  let id: String
  let selectedLLMModelID: String?
  let selectedProvider: LLMProvider
  let autoSummarizeEnabled: Bool
  let autoTranscribeEnabled: Bool
  let autoDetectMeetings: Bool
  let autoStopRecording: Bool
  let onboarded: Bool
  let summaryPromptTemplate: String?
  let microphoneEnabled: Bool
  let globalShortcutKeyCode: Int32
  let globalShortcutModifiers: Int32
  let customTmpDirectoryPath: String?
  let customTmpDirectoryBookmark: Data?
  let createdAt: Date
  let modifiedAt: Date

  init(from managedObject: UserPreferences) {
    self.id = managedObject.id ?? UUID().uuidString
    self.selectedLLMModelID = managedObject.selectedLLMModelID
    self.selectedProvider =
      LLMProvider(
        rawValue: managedObject.selectedProvider ?? LLMProvider.default.rawValue
      ) ?? LLMProvider.default
    self.autoSummarizeEnabled = managedObject.autoSummarizeEnabled
    self.autoTranscribeEnabled = managedObject.autoTranscribeEnabled
    self.autoDetectMeetings = managedObject.autoDetectMeetings
    self.autoStopRecording = managedObject.autoStopRecording
    self.onboarded = managedObject.onboarded
    self.summaryPromptTemplate = managedObject.summaryPromptTemplate
    self.microphoneEnabled = managedObject.microphoneEnabled
    self.globalShortcutKeyCode = managedObject.globalShortcutKeyCode
    self.globalShortcutModifiers = managedObject.globalShortcutModifiers
    self.customTmpDirectoryPath = managedObject.customTmpDirectoryPath
    self.customTmpDirectoryBookmark = managedObject.customTmpDirectoryBookmark
    self.createdAt = managedObject.createdAt ?? Date()
    self.modifiedAt = managedObject.modifiedAt ?? Date()
  }

  init(
    id: String = UUID().uuidString,
    selectedLLMModelID: String? = nil,
    selectedProvider: LLMProvider = .default,
    autoSummarizeEnabled: Bool = true,
    autoTranscribeEnabled: Bool = true,
    autoDetectMeetings: Bool = false,
    autoStopRecording: Bool = false,
    onboarded: Bool = false,
    summaryPromptTemplate: String? = nil,
    microphoneEnabled: Bool = false,
    globalShortcutKeyCode: Int32 = 15,  // 'R' key
    globalShortcutModifiers: Int32 = 1_048_840,  // Cmd key
    customTmpDirectoryPath: String? = nil,
    customTmpDirectoryBookmark: Data? = nil,
    createdAt: Date = Date(),
    modifiedAt: Date = Date()
  ) {
    self.id = id
    self.selectedLLMModelID = selectedLLMModelID
    self.selectedProvider = selectedProvider
    self.autoSummarizeEnabled = autoSummarizeEnabled
    self.autoTranscribeEnabled = autoTranscribeEnabled
    self.autoDetectMeetings = autoDetectMeetings
    self.autoStopRecording = autoStopRecording
    self.onboarded = onboarded
    self.summaryPromptTemplate = summaryPromptTemplate
    self.microphoneEnabled = microphoneEnabled
    self.globalShortcutKeyCode = globalShortcutKeyCode
    self.globalShortcutModifiers = globalShortcutModifiers
    self.customTmpDirectoryPath = customTmpDirectoryPath
    self.customTmpDirectoryBookmark = customTmpDirectoryBookmark
    self.createdAt = createdAt
    self.modifiedAt = modifiedAt
  }

  static var defaultPromptTemplate: String {
    """
    Please provide a concise summary of the following meeting transcript. \
    Focus on key points, decisions made, and action items. \
    Format the summary with clear sections for Main Topics, Decisions, and Action Items.
    """
  }
}
