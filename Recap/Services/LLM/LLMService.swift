import Combine
import Foundation

@MainActor
final class LLMService: LLMServiceType {
  @Published private(set) var isProviderAvailable: Bool = false
  var providerAvailabilityPublisher: AnyPublisher<Bool, Never> {
    $isProviderAvailable.eraseToAnyPublisher()
  }

  private(set) var currentProvider: (any LLMProviderType)?
  private(set) var availableProviders: [any LLMProviderType] = []

  private let llmModelRepository: LLMModelRepositoryType
  private let userPreferencesRepository: UserPreferencesRepositoryType
  private var cancellables = Set<AnyCancellable>()
  private var modelRefreshTimer: Timer?

  init(
    llmModelRepository: LLMModelRepositoryType,
    userPreferencesRepository: UserPreferencesRepositoryType
  ) {
    self.llmModelRepository = llmModelRepository
    self.userPreferencesRepository = userPreferencesRepository
    initializeProviders()
    startModelRefreshTimer()
  }

  deinit {
    modelRefreshTimer?.invalidate()
  }

  func initializeProviders() {
    let ollamaProvider = OllamaProvider()

    // Get credentials from keychain
    let keychainService = KeychainService()
    let openRouterApiKey = try? keychainService.retrieveOpenRouterAPIKey()
    let openAIApiKey = try? keychainService.retrieveOpenAIAPIKey()
    let openAIEndpoint = try? keychainService.retrieveOpenAIEndpoint()

    let openRouterProvider = OpenRouterProvider(apiKey: openRouterApiKey)
    let openAIProvider = OpenAIProvider(
      apiKey: openAIApiKey,
      endpoint: openAIEndpoint ?? "https://api.openai.com/v1"
    )

    availableProviders = [ollamaProvider, openRouterProvider, openAIProvider]

    Task {
      do {
        let preferences = try await userPreferencesRepository.getOrCreatePreferences()
        setCurrentProvider(preferences.selectedProvider)
      } catch {
        setCurrentProvider(.default)
      }
    }

    Publishers.CombineLatest3(
      ollamaProvider.availabilityPublisher,
      openRouterProvider.availabilityPublisher,
      openAIProvider.availabilityPublisher
    )
    .map { ollamaAvailable, openRouterAvailable, openAIAvailable in
      ollamaAvailable || openRouterAvailable || openAIAvailable
    }
    .sink { [weak self] isAnyProviderAvailable in
      self?.isProviderAvailable = isAnyProviderAvailable
    }
    .store(in: &cancellables)

    Task {
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      try? await refreshModelsFromProviders()
    }
  }

  func reinitializeProviders() {
    // Cancel any existing subscriptions
    cancellables.removeAll()

    // Get fresh credentials from keychain
    let keychainService = KeychainService()
    let openRouterApiKey = try? keychainService.retrieveOpenRouterAPIKey()
    let openAIApiKey = try? keychainService.retrieveOpenAIAPIKey()
    let openAIEndpoint = try? keychainService.retrieveOpenAIEndpoint()

    // Create new provider instances with updated credentials
    let ollamaProvider = OllamaProvider()
    let openRouterProvider = OpenRouterProvider(apiKey: openRouterApiKey)
    let openAIProvider = OpenAIProvider(
      apiKey: openAIApiKey,
      endpoint: openAIEndpoint ?? "https://api.openai.com/v1"
    )

    availableProviders = [ollamaProvider, openRouterProvider, openAIProvider]

    // Update current provider
    Task {
      do {
        let preferences = try await userPreferencesRepository.getOrCreatePreferences()
        setCurrentProvider(preferences.selectedProvider)
      } catch {
        setCurrentProvider(.default)
      }
    }

    // Re-setup availability monitoring
    Publishers.CombineLatest3(
      ollamaProvider.availabilityPublisher,
      openRouterProvider.availabilityPublisher,
      openAIProvider.availabilityPublisher
    )
    .map { ollamaAvailable, openRouterAvailable, openAIAvailable in
      ollamaAvailable || openRouterAvailable || openAIAvailable
    }
    .sink { [weak self] isAnyProviderAvailable in
      self?.isProviderAvailable = isAnyProviderAvailable
    }
    .store(in: &cancellables)

    // Refresh models from providers
    Task {
      try? await refreshModelsFromProviders()
    }
  }

  func refreshModelsFromProviders() async throws {
    var allModelInfos: [LLMModelInfo] = []

    for provider in availableProviders {
      guard provider.isAvailable else { continue }

      do {
        let providerModels = try await provider.listModels()
        let modelInfos = providerModels.map { model in
          LLMModelInfo(
            id: model.id,
            name: model.name,
            provider: model.provider,
            maxTokens: model.contextLength ?? 8192
          )
        }
        allModelInfos.append(contentsOf: modelInfos)
      } catch {
        continue
      }
    }

    try await llmModelRepository.saveModels(allModelInfos)
  }

  func getAvailableModels() async throws -> [LLMModelInfo] {
    let allModels = try await llmModelRepository.getAllModels()
    let preferences = try await userPreferencesRepository.getOrCreatePreferences()
    return allModels.filter {
      $0.provider.lowercased() == preferences.selectedProvider.providerName.lowercased()
    }
  }

  func getSelectedModel() async throws -> LLMModelInfo? {
    let preferences = try await userPreferencesRepository.getOrCreatePreferences()
    guard let modelId = preferences.selectedLLMModelID else { return nil }
    return try await llmModelRepository.getModel(byId: modelId)
  }

  func selectModel(id: String) async throws {
    guard (try await llmModelRepository.getModel(byId: id)) != nil else {
      throw LLMError.modelNotFound(id)
    }

    try await userPreferencesRepository.updateSelectedLLMModel(id: id)
  }

  func getUserPreferences() async throws -> UserPreferencesInfo {
    try await userPreferencesRepository.getOrCreatePreferences()
  }

  func generateSummarization(
    text: String,
    options: LLMOptions? = nil
  ) async throws -> String {
    guard let selectedModel = try await getSelectedModel() else {
      throw LLMError.configurationError("No model selected")
    }

    guard let provider = findProvider(for: selectedModel.provider) else {
      throw LLMError.providerNotAvailable
    }

    guard provider.isAvailable else {
      throw LLMError.providerNotAvailable
    }

    let preferences = try await userPreferencesRepository.getOrCreatePreferences()
    let promptTemplate =
      preferences.summaryPromptTemplate ?? UserPreferencesInfo.defaultPromptTemplate

    let effectiveOptions =
      options
      ?? LLMOptions(
        temperature: selectedModel.temperature ?? 0.7,
        maxTokens: Int(selectedModel.maxTokens),
        keepAliveMinutes: selectedModel.keepAliveMinutes.map(Int.init)
      )

    let messages = [
      LLMMessage(role: .system, content: promptTemplate),
      LLMMessage(role: .user, content: text)
    ]

    return try await provider.generateChatCompletion(
      modelName: selectedModel.name,
      messages: messages,
      options: effectiveOptions
    )
  }

  private func findProvider(for providerName: String) -> (any LLMProviderType)? {
    availableProviders.first { provider in
      provider.name.lowercased() == providerName.lowercased()
    }
  }

  func cancelCurrentTask() {
    availableProviders.forEach { $0.cancelCurrentTask() }
  }

  func setCurrentProvider(_ provider: LLMProvider) {
    currentProvider = findProvider(for: provider.providerName)
  }

  func selectProvider(_ provider: LLMProvider) async throws {
    try await userPreferencesRepository.updateSelectedProvider(provider)
    setCurrentProvider(provider)
  }

  private func startModelRefreshTimer() {
    modelRefreshTimer?.invalidate()
    modelRefreshTimer = Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { [weak self] _ in
      Task { @MainActor [weak self] in
        try? await self?.refreshModelsFromProviders()
      }
    }
  }
}
