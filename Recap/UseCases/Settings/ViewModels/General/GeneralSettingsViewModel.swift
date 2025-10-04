import Combine
import Foundation
import SwiftUI

@MainActor
final class GeneralSettingsViewModel: GeneralSettingsViewModelType {
  @Published var availableModels: [LLMModelInfo] = []
  @Published var selectedModel: LLMModelInfo?
  @Published private(set) var selectedProvider: LLMProvider = .default
  @Published private(set) var autoDetectMeetings: Bool = false
  @Published private(set) var isAutoStopRecording: Bool = false
  @Published private(set) var isAutoSummarizeEnabled: Bool = true
  @Published private(set) var isAutoTranscribeEnabled: Bool = true
  @Published var customPromptTemplateValue: String = ""
  @Published var manualModelNameValue: String = ""
  @Published private(set) var globalShortcutKeyCode: Int32 = 15  // 'R' key
  @Published private(set) var globalShortcutModifiers: Int32 = 1_048_840  // Cmd key

  var customPromptTemplate: Binding<String> {
    Binding(
      get: { self.customPromptTemplateValue },
      set: { newValue in
        Task {
          await self.updateCustomPromptTemplate(newValue)
        }
      }
    )
  }

  var manualModelName: Binding<String> {
    Binding(
      get: { self.manualModelNameValue },
      set: { newValue in
        Task {
          await self.selectManualModel(newValue)
        }
      }
    )
  }

  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published private(set) var showToast = false
  @Published private(set) var toastMessage = ""
  @Published private(set) var activeWarnings: [WarningItem] = []
  @Published var showAPIKeyAlert = false
  @Published var existingAPIKey: String?
  @Published var showOpenAIAlert = false
  @Published var existingOpenAIKey: String?
  @Published var existingOpenAIEndpoint: String?

  var hasModels: Bool {
    !availableModels.isEmpty
  }

  var currentSelection: LLMModelInfo? {
    selectedModel
  }

  let llmService: LLMServiceType
  let userPreferencesRepository: UserPreferencesRepositoryType
  let keychainAPIValidator: KeychainAPIValidatorType
  let keychainService: KeychainServiceType
  private let warningManager: any WarningManagerType
  private let fileManagerHelper: RecordingFileManagerHelperType
  private var cancellables = Set<AnyCancellable>()

  lazy var folderSettingsViewModel: FolderSettingsViewModelType = {
    FolderSettingsViewModel(
      userPreferencesRepository: userPreferencesRepository,
      fileManagerHelper: fileManagerHelper
    )
  }()

  init(
    llmService: LLMServiceType,
    userPreferencesRepository: UserPreferencesRepositoryType,
    keychainAPIValidator: KeychainAPIValidatorType,
    keychainService: KeychainServiceType,
    warningManager: any WarningManagerType,
    fileManagerHelper: RecordingFileManagerHelperType
  ) {
    self.llmService = llmService
    self.userPreferencesRepository = userPreferencesRepository
    self.keychainAPIValidator = keychainAPIValidator
    self.keychainService = keychainService
    self.warningManager = warningManager
    self.fileManagerHelper = fileManagerHelper

    setupWarningObserver()

    Task {
      await loadInitialState()
    }
  }

  private func setupWarningObserver() {
    warningManager.activeWarningsPublisher
      .assign(to: \.activeWarnings, on: self)
      .store(in: &cancellables)
  }

  private func loadInitialState() async {
    do {
      let preferences = try await llmService.getUserPreferences()
      selectedProvider = preferences.selectedProvider
      autoDetectMeetings = preferences.autoDetectMeetings
      isAutoStopRecording = preferences.autoStopRecording
      isAutoSummarizeEnabled = preferences.autoSummarizeEnabled
      isAutoTranscribeEnabled = preferences.autoTranscribeEnabled
      customPromptTemplateValue =
        preferences.summaryPromptTemplate ?? UserPreferencesInfo.defaultPromptTemplate
      globalShortcutKeyCode = preferences.globalShortcutKeyCode
      globalShortcutModifiers = preferences.globalShortcutModifiers
    } catch {
      selectedProvider = .default
      autoDetectMeetings = false
      isAutoStopRecording = false
      isAutoSummarizeEnabled = true
      isAutoTranscribeEnabled = true
      customPromptTemplateValue = UserPreferencesInfo.defaultPromptTemplate
      globalShortcutKeyCode = 15  // 'R' key
      globalShortcutModifiers = 1_048_840  // Cmd key
    }
    await loadModels()
  }

  func selectProvider(_ provider: LLMProvider) async {
    errorMessage = nil

    guard await validateProviderCredentials(provider) else {
      return
    }

    selectedProvider = provider

    do {
      try await llmService.selectProvider(provider)
      await updateModelsForNewProvider()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func showValidationToast(_ message: String) {
    toastMessage = message
    showToast = true

    Task {
      try? await Task.sleep(nanoseconds: 3_000_000_000)
      showToast = false
    }
  }

  func toggleAutoDetectMeetings(_ enabled: Bool) async {
    errorMessage = nil
    autoDetectMeetings = enabled

    do {
      try await userPreferencesRepository.updateAutoDetectMeetings(enabled)
    } catch {
      errorMessage = error.localizedDescription
      autoDetectMeetings = !enabled
    }
  }

  func updateCustomPromptTemplate(_ template: String) async {
    customPromptTemplateValue = template

    do {
      let templateToSave = template.isEmpty ? nil : template
      try await userPreferencesRepository.updateSummaryPromptTemplate(templateToSave)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func resetToDefaultPrompt() async {
    await updateCustomPromptTemplate(UserPreferencesInfo.defaultPromptTemplate)
  }

  func toggleAutoStopRecording(_ enabled: Bool) async {
    errorMessage = nil
    isAutoStopRecording = enabled

    do {
      try await userPreferencesRepository.updateAutoStopRecording(enabled)
    } catch {
      errorMessage = error.localizedDescription
      isAutoStopRecording = !enabled
    }
  }

  func toggleAutoSummarize(_ enabled: Bool) async {
    errorMessage = nil
    isAutoSummarizeEnabled = enabled

    do {
      try await userPreferencesRepository.updateAutoSummarize(enabled)
    } catch {
      errorMessage = error.localizedDescription
      isAutoSummarizeEnabled = !enabled
    }
  }

  func toggleAutoTranscribe(_ enabled: Bool) async {
    errorMessage = nil
    isAutoTranscribeEnabled = enabled

    do {
      try await userPreferencesRepository.updateAutoTranscribe(enabled)
    } catch {
      errorMessage = error.localizedDescription
      isAutoTranscribeEnabled = !enabled
    }
  }

  func updateGlobalShortcut(keyCode: Int32, modifiers: Int32) async {
    errorMessage = nil
    globalShortcutKeyCode = keyCode
    globalShortcutModifiers = modifiers

    do {
      try await userPreferencesRepository.updateGlobalShortcut(
        keyCode: keyCode, modifiers: modifiers)
    } catch {
      errorMessage = error.localizedDescription
      // Revert on error - we'd need to reload from preferences
      let preferences = try? await userPreferencesRepository.getOrCreatePreferences()
      globalShortcutKeyCode = preferences?.globalShortcutKeyCode ?? 15
      globalShortcutModifiers = preferences?.globalShortcutModifiers ?? 1_048_840
    }
  }

}
