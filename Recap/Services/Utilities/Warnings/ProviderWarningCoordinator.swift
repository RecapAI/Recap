import Foundation
import Combine

final class ProviderWarningCoordinator {
    private let warningManager: any WarningManagerType
    private let llmService: LLMServiceType
    private var cancellables = Set<AnyCancellable>()
    
    private let ollamaWarningId = "ollama_connectivity"
    private let openRouterWarningId = "openrouter_connectivity"
    private let requestyWarningId = "requesty_connectivity"
    
    init(warningManager: any WarningManagerType, llmService: LLMServiceType) {
        self.warningManager = warningManager
        self.llmService = llmService
    }
    
    func startMonitoring() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            setupProviderMonitoring()
        }
    }
    
    @MainActor
    private func setupProviderMonitoring() {
        guard let ollamaProvider = llmService.availableProviders.first(where: { $0.name == "Ollama" }),
              let openRouterProvider = llmService.availableProviders.first(where: { $0.name == "OpenRouter" }),
              let requestyProvider = llmService.availableProviders.first(where: { $0.name == "Requesty" }) else {
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                setupProviderMonitoring()
            }
            return
        }
        
        Publishers.CombineLatest3(
            ollamaProvider.availabilityPublisher,
            openRouterProvider.availabilityPublisher,
            requestyProvider.availabilityPublisher
        )
        .sink { [weak self] ollamaAvailable, openRouterAvailable, requestyAvailable in
            Task { @MainActor in
                await self?.updateProviderWarnings(
                    ollamaAvailable: ollamaAvailable,
                    openRouterAvailable: openRouterAvailable,
                    requestyAvailable: requestyAvailable
                )
            }
        }
        .store(in: &cancellables)
    }
    
    @MainActor
    private func updateProviderWarnings(
        ollamaAvailable: Bool,
        openRouterAvailable: Bool,
        requestyAvailable: Bool
    ) async {
        do {
            let preferences = try await llmService.getUserPreferences()
            let selectedProvider = preferences.selectedProvider
            
            switch selectedProvider {
            case .ollama:
                handleOllamaWarning(isAvailable: ollamaAvailable)
                warningManager.removeWarning(withId: openRouterWarningId)
                warningManager.removeWarning(withId: requestyWarningId)
                
            case .openRouter:
                handleOpenRouterWarning(isAvailable: openRouterAvailable)
                warningManager.removeWarning(withId: ollamaWarningId)
                warningManager.removeWarning(withId: requestyWarningId)
                
            case .requesty:
                handleRequestyWarning(isAvailable: requestyAvailable)
                warningManager.removeWarning(withId: ollamaWarningId)
                warningManager.removeWarning(withId: openRouterWarningId)
            }
        } catch {
            warningManager.removeWarning(withId: ollamaWarningId)
            warningManager.removeWarning(withId: openRouterWarningId)
            warningManager.removeWarning(withId: requestyWarningId)
        }
    }
    
    @MainActor
    private func handleOllamaWarning(isAvailable: Bool) {
        if isAvailable {
            warningManager.removeWarning(withId: ollamaWarningId)
        } else {
            let warning = WarningItem(
                id: ollamaWarningId,
                title: "Ollama Not Running",
                message: "Please start Ollama to use local AI models for summarization.",
                icon: "server.rack",
                severity: .error
            )
            warningManager.updateWarning(warning)
        }
    }
    
    @MainActor
    private func handleOpenRouterWarning(isAvailable: Bool) {
        if isAvailable {
            warningManager.removeWarning(withId: openRouterWarningId)
        } else {
            let warning = WarningItem(
                id: openRouterWarningId,
                title: "OpenRouter Unavailable",
                message: "Cannot connect to OpenRouter. Check your internet connection and API key.",
                icon: "network.slash",
                severity: .warning
            )
            warningManager.updateWarning(warning)
        }
    }
    
    @MainActor
    private func handleRequestyWarning(isAvailable: Bool) {
        if isAvailable {
            warningManager.removeWarning(withId: requestyWarningId)
        } else {
            let warning = WarningItem(
                id: requestyWarningId,
                title: "Requesty Unavailable",
                message: "Cannot connect to Requesty. Check your internet connection and API key.",
                icon: "network.slash",
                severity: .warning
            )
            warningManager.updateWarning(warning)
        }
    }
}
