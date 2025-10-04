import Combine
import Foundation

@MainActor
protocol LLMModelsViewModelType: ObservableObject {
  var availableModels: [LLMModelInfo] { get }
  var selectedModelId: String? { get }
  var isLoading: Bool { get }
  var errorMessage: String? { get }
  var providerStatus: ProviderStatus { get }
  var isProviderAvailable: Bool { get }

  func refreshModels() async
  func selectModel(_ model: LLMModelInfo) async
}
