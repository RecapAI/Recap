import Foundation
import Combine
import SwiftUI

@MainActor
final class GeneralSettingsViewModel: GeneralSettingsViewModelType {
    @Published private(set) var availableModels: [LLMModelInfo] = []
    @Published private(set) var selectedModel: LLMModelInfo?
    @Published private(set) var selectedProvider: LLMProvider = .default
    @Published private(set) var autoDetectMeetings: Bool = false
    @Published private(set) var isAutoStopRecording: Bool = false
    @Published private var customPromptTemplateValue: String = ""
    
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

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var showToast = false
    @Published private(set) var toastMessage = ""
    @Published private(set) var activeWarnings: [WarningItem] = []
    @Published private(set) var showAPIKeyAlert = false
    @Published private(set) var existingAPIKey: String?
    @Published private(set) var pendingAPIKeyProvider: LLMProvider?
    
    var hasModels: Bool {
        !availableModels.isEmpty
    }
    
    var currentSelection: LLMModelInfo? {
        selectedModel
    }
    
    private let llmService: LLMServiceType
    private let userPreferencesRepository: UserPreferencesRepositoryType
    private let keychainAPIValidator: KeychainAPIValidatorType
    private let keychainService: KeychainServiceType
    private let warningManager: any WarningManagerType
    private var cancellables = Set<AnyCancellable>()
    
    init(
        llmService: LLMServiceType,
        userPreferencesRepository: UserPreferencesRepositoryType,
        keychainAPIValidator: KeychainAPIValidatorType,
        keychainService: KeychainServiceType,
        warningManager: any WarningManagerType
    ) {
        self.llmService = llmService
        self.userPreferencesRepository = userPreferencesRepository
        self.keychainAPIValidator = keychainAPIValidator
        self.keychainService = keychainService
        self.warningManager = warningManager
        
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
            customPromptTemplateValue = preferences.summaryPromptTemplate ?? UserPreferencesInfo.defaultPromptTemplate
        } catch {
            selectedProvider = .default
            autoDetectMeetings = false
            isAutoStopRecording = false
            customPromptTemplateValue = UserPreferencesInfo.defaultPromptTemplate
        }
        await loadModels()
    }
    
    func loadModels() async {
        isLoading = true
        errorMessage = nil
        
        do {
            availableModels = try await llmService.getAvailableModels()
            selectedModel = try await llmService.getSelectedModel()
            
            if selectedModel == nil, let firstModel = availableModels.first {
                await selectModel(firstModel)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func selectModel(_ model: LLMModelInfo) async {
        errorMessage = nil
        selectedModel = model
        
        do {
            try await llmService.selectModel(id: model.id)
        } catch {
            errorMessage = error.localizedDescription
            selectedModel = nil
        }
    }
    
    func selectProvider(_ provider: LLMProvider) async {
        errorMessage = nil
        
        if provider == .openRouter {
            let validation = keychainAPIValidator.validateOpenRouterAPI()
            
            if !validation.isValid {
                do {
                    existingAPIKey = try keychainService.retrieveOpenRouterAPIKey()
                } catch {
                    existingAPIKey = nil
                }
                pendingAPIKeyProvider = .openRouter
                showAPIKeyAlert = true
                return
            }
        }
        
        if provider == .requesty {
            let validation = keychainAPIValidator.validateRequestyAPI()
            
            if !validation.isValid {
                do {
                    existingAPIKey = try keychainService.retrieveRequestyAPIKey()
                } catch {
                    existingAPIKey = nil
                }
                pendingAPIKeyProvider = .requesty
                showAPIKeyAlert = true
                return
            }
        }
        
        selectedProvider = provider
        
        do {
            try await llmService.selectProvider(provider)
            
            let newModels = try await llmService.getAvailableModels()
            availableModels = newModels
            
            let currentSelection = try await llmService.getSelectedModel()
            let isCurrentModelAvailable = newModels.contains { $0.id == currentSelection?.id }
            
            if !isCurrentModelAvailable, let firstModel = newModels.first {
                await selectModel(firstModel)
            } else {
                selectedModel = currentSelection
            }
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
    
    func saveAPIKey(_ apiKey: String) async throws {
        let provider = pendingAPIKeyProvider ?? .openRouter
        
        switch provider {
        case .requesty:
            try keychainService.storeRequestyAPIKey(apiKey)
        case .openRouter, .ollama:
            try keychainService.storeOpenRouterAPIKey(apiKey)
        }
        
        existingAPIKey = apiKey
        showAPIKeyAlert = false
        pendingAPIKeyProvider = nil
        
        await selectProvider(provider)
    }
    
    func dismissAPIKeyAlert() {
        showAPIKeyAlert = false
        existingAPIKey = nil
        pendingAPIKeyProvider = nil
    }
}
