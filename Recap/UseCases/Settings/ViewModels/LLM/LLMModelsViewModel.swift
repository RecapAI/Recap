import Combine
import Foundation

@MainActor
final class LLMModelsViewModel: ObservableObject, LLMModelsViewModelType {
  @Published private(set) var availableModels: [LLMModelInfo] = []
  @Published private(set) var selectedModelId: String?
  @Published private(set) var isLoading = false
  @Published private(set) var errorMessage: String?
  @Published private(set) var providerStatus: ProviderStatus
  @Published private(set) var isProviderAvailable = false

  private let llmService: LLMServiceType
  private let llmModelRepository: LLMModelRepositoryType
  private let userPreferencesRepository: UserPreferencesRepositoryType
  private var cancellables = Set<AnyCancellable>()

  init(
    llmService: LLMServiceType,
    llmModelRepository: LLMModelRepositoryType,
    userPreferencesRepository: UserPreferencesRepositoryType
  ) {
    self.llmService = llmService
    self.llmModelRepository = llmModelRepository
    self.userPreferencesRepository = userPreferencesRepository
    self.providerStatus = .ollama(isAvailable: false)

    setupBindings()
    Task {
      await loadInitialData()
    }
  }

  func refreshModels() async {
    isLoading = true
    errorMessage = nil

    do {
      availableModels = try await llmService.getAvailableModels()

      let preferences = try await userPreferencesRepository.getOrCreatePreferences()
      selectedModelId = preferences.selectedLLMModelID
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func selectModel(_ model: LLMModelInfo) async {
    errorMessage = nil

    do {
      try await llmService.selectModel(id: model.id)
      selectedModelId = model.id
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func setupBindings() {
    llmService.providerAvailabilityPublisher
      .sink { [weak self] isAvailable in
        self?.isProviderAvailable = isAvailable
        self?.providerStatus = .ollama(isAvailable: isAvailable)

        if isAvailable {
          Task {
            await self?.refreshModels()
          }
        }
      }
      .store(in: &cancellables)
  }

  private func loadInitialData() async {
    isLoading = true

    do {
      availableModels = try await llmService.getAvailableModels()

      let preferences = try await userPreferencesRepository.getOrCreatePreferences()
      selectedModelId = preferences.selectedLLMModelID
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }
}
