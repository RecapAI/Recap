import Combine
import Foundation

@MainActor
final class OpenRouterProvider: LLMProviderType, LLMTaskManageable {
  typealias Model = OpenRouterModel

  let name = "OpenRouter"

  var isAvailable: Bool {
    availabilityHelper.isAvailable
  }

  var availabilityPublisher: AnyPublisher<Bool, Never> {
    availabilityHelper.availabilityPublisher
  }

  var currentTask: Task<Void, Never>?

  private let apiClient: OpenRouterAPIClient
  private let availabilityHelper: AvailabilityHelper

  init(apiKey: String? = nil) {
    let resolvedApiKey = apiKey ?? ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]
    self.apiClient = OpenRouterAPIClient(apiKey: resolvedApiKey)
    self.availabilityHelper = AvailabilityHelper(
      checkInterval: 60.0,
      availabilityCheck: { [weak apiClient] in
        await apiClient?.checkAvailability() ?? false
      }
    )
    availabilityHelper.startMonitoring()
  }

  deinit {
    Task { [weak self] in
      await self?.cancelCurrentTask()
    }
  }

  func checkAvailability() async -> Bool {
    await availabilityHelper.checkAvailabilityNow()
  }

  func listModels() async throws -> [OpenRouterModel] {
    guard isAvailable else {
      throw LLMError.providerNotAvailable
    }

    return try await executeWithTaskManagement {
      let apiModels = try await self.apiClient.listModels()
      return apiModels.map { OpenRouterModel.init(from: $0) }
    }
  }

  func generateChatCompletion(
    modelName: String,
    messages: [LLMMessage],
    options: LLMOptions
  ) async throws -> String {
    try validateProviderAvailable()
    try validateMessages(messages)

    return try await executeWithTaskManagement {
      try await self.apiClient.generateChatCompletion(
        modelName: modelName,
        messages: messages,
        options: options
      )
    }
  }

  private func validateProviderAvailable() throws {
    guard isAvailable else {
      throw LLMError.providerNotAvailable
    }
  }

  private func validateMessages(_ messages: [LLMMessage]) throws {
    guard !messages.isEmpty else {
      throw LLMError.invalidPrompt
    }
  }
}
