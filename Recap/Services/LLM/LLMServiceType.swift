import Combine
import Foundation

#if MOCKING
  import Mockable
#endif

@MainActor
#if MOCKING
  @Mockable
#endif
protocol LLMServiceType: AnyObject {
  var currentProvider: (any LLMProviderType)? { get }
  var availableProviders: [any LLMProviderType] { get }
  var isProviderAvailable: Bool { get }
  var providerAvailabilityPublisher: AnyPublisher<Bool, Never> { get }

  func initializeProviders()
  func reinitializeProviders()
  func refreshModelsFromProviders() async throws
  func getAvailableModels() async throws -> [LLMModelInfo]
  func getSelectedModel() async throws -> LLMModelInfo?
  func selectModel(id: String) async throws
  func selectProvider(_ provider: LLMProvider) async throws
  func getUserPreferences() async throws -> UserPreferencesInfo
  func generateSummarization(
    text: String,
    options: LLMOptions?
  ) async throws -> String
  func cancelCurrentTask()
}
