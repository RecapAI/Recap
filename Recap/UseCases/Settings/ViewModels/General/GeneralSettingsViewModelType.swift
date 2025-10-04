import Combine
import Foundation
import SwiftUI

@MainActor
protocol GeneralSettingsViewModelType: ObservableObject {
  var availableModels: [LLMModelInfo] { get }
  var selectedModel: LLMModelInfo? { get }
  var selectedProvider: LLMProvider { get }
  var autoDetectMeetings: Bool { get }
  var isAutoStopRecording: Bool { get }
  var isAutoSummarizeEnabled: Bool { get }
  var isAutoTranscribeEnabled: Bool { get }
  var isLoading: Bool { get }
  var errorMessage: String? { get }
  var hasModels: Bool { get }
  var currentSelection: LLMModelInfo? { get }
  var showToast: Bool { get }
  var toastMessage: String { get }
  var activeWarnings: [WarningItem] { get }
  var customPromptTemplate: Binding<String> { get }
  var showAPIKeyAlert: Bool { get }
  var existingAPIKey: String? { get }
  var showOpenAIAlert: Bool { get }
  var existingOpenAIKey: String? { get }
  var existingOpenAIEndpoint: String? { get }
  var globalShortcutKeyCode: Int32 { get }
  var globalShortcutModifiers: Int32 { get }
  var folderSettingsViewModel: FolderSettingsViewModelType { get }
  var manualModelName: Binding<String> { get }
  var isTestingProvider: Bool { get }
  var testResult: String? { get }

  func loadModels() async
  func selectModel(_ model: LLMModelInfo) async
  func selectManualModel(_ modelName: String) async
  func selectProvider(_ provider: LLMProvider) async
  func toggleAutoDetectMeetings(_ enabled: Bool) async
  func toggleAutoStopRecording(_ enabled: Bool) async
  func toggleAutoSummarize(_ enabled: Bool) async
  func toggleAutoTranscribe(_ enabled: Bool) async
  func updateCustomPromptTemplate(_ template: String) async
  func resetToDefaultPrompt() async
  func saveAPIKey(_ apiKey: String) async throws
  func dismissAPIKeyAlert()
  func saveOpenAIConfiguration(apiKey: String, endpoint: String) async throws
  func dismissOpenAIAlert()
  func updateGlobalShortcut(keyCode: Int32, modifiers: Int32) async
  func testLLMProvider() async
}
