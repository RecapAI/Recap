import Combine
import SwiftUI

#if DEBUG
  final class PreviewGeneralSettingsViewModel: GeneralSettingsViewModelType {
    init() {
      // Preview initializer - no setup needed
    }

    func updateCustomPromptTemplate(_ template: String) async {}

    func resetToDefaultPrompt() async {}

    var customPromptTemplate: Binding<String> {
      .constant(UserPreferencesInfo.defaultPromptTemplate)
    }

    @Published var availableModels: [LLMModelInfo] = [
      LLMModelInfo(name: "llama3.2", provider: "ollama"),
      LLMModelInfo(name: "codellama", provider: "ollama")
    ]
    @Published var selectedModel: LLMModelInfo?
    @Published var selectedProvider: LLMProvider = .ollama
    @Published var autoDetectMeetings: Bool = true
    @Published var isAutoStopRecording: Bool = false
    @Published var isAutoSummarizeEnabled: Bool = true
    @Published var isAutoTranscribeEnabled: Bool = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var showAPIKeyAlert = false
    @Published var existingAPIKey: String?
    @Published var showOpenAIAlert = false
    @Published var existingOpenAIKey: String?
    @Published var existingOpenAIEndpoint: String?
    @Published var globalShortcutKeyCode: Int32 = 15
    @Published var globalShortcutModifiers: Int32 = 1_048_840
    @Published var isTestingProvider = false
    @Published var testResult: String?
    @Published var activeWarnings: [WarningItem] = [
      WarningItem(
        id: "ollama",
        title: "Ollama Not Running",
        message: "Please start Ollama to use local AI models for summarization.",
        icon: "server.rack",
        severity: .warning
      )
    ]

    var hasModels: Bool {
      !availableModels.isEmpty
    }

    var currentSelection: LLMModelInfo? {
      selectedModel
    }

    var manualModelName: Binding<String> {
      .constant("")
    }

    var folderSettingsViewModel: FolderSettingsViewModelType {
      PreviewFolderSettingsViewModel()
    }

    func loadModels() async {}
    func selectModel(_ model: LLMModelInfo) async {
      selectedModel = model
    }
    func selectManualModel(_ modelName: String) async {}
    func selectProvider(_ provider: LLMProvider) async {
      selectedProvider = provider
    }
    func toggleAutoDetectMeetings(_ enabled: Bool) async {
      autoDetectMeetings = enabled
    }
    func toggleAutoStopRecording(_ enabled: Bool) async {
      isAutoStopRecording = enabled
    }
    func toggleAutoSummarize(_ enabled: Bool) async {
      isAutoSummarizeEnabled = enabled
    }
    func toggleAutoTranscribe(_ enabled: Bool) async {
      isAutoTranscribeEnabled = enabled
    }
    func saveAPIKey(_ apiKey: String) async throws {}
    func dismissAPIKeyAlert() {
      showAPIKeyAlert = false
    }
    func saveOpenAIConfiguration(apiKey: String, endpoint: String) async throws {}
    func dismissOpenAIAlert() {
      showOpenAIAlert = false
    }
    func updateGlobalShortcut(keyCode: Int32, modifiers: Int32) async {
      globalShortcutKeyCode = keyCode
      globalShortcutModifiers = modifiers
    }
    func testLLMProvider() async {
      isTestingProvider = true
      try? await Task.sleep(nanoseconds: 1_000_000_000)
      testResult = "✓ Test successful!\n\nSummary:\nPreview mode - test functionality works!"
      isTestingProvider = false
    }
  }

  final class PreviewFolderSettingsViewModel: FolderSettingsViewModelType {
    @Published var currentFolderPath: String =
      "/Users/nilleb/Library/Containers/co.nilleb.Recap/Data/tmp/"
    @Published var errorMessage: String?

    init() {
      // Preview initializer - no setup needed
    }

    func updateFolderPath(_ url: URL) async {
      currentFolderPath = url.path
    }

    func setErrorMessage(_ message: String?) {
      errorMessage = message
    }
  }
#endif
