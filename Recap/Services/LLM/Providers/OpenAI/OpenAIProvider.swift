import Combine
import Foundation

@MainActor
final class OpenAIProvider: LLMProviderType, LLMTaskManageable {
  typealias Model = OpenAIModel

  let name = "OpenAI"

  var isAvailable: Bool {
    availabilityHelper.isAvailable
  }

  var availabilityPublisher: AnyPublisher<Bool, Never> {
    availabilityHelper.availabilityPublisher
  }

  var currentTask: Task<Void, Never>?

  private let apiClient: OpenAIAPIClient
  private let availabilityHelper: AvailabilityHelper

  init(apiKey: String? = nil, endpoint: String = "https://api.openai.com/v1") {
    let resolvedApiKey = apiKey ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    self.apiClient = OpenAIAPIClient(apiKey: resolvedApiKey, endpoint: endpoint)
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

  func listModels() async throws -> [OpenAIModel] {
    guard isAvailable else {
      throw LLMError.providerNotAvailable
    }

    return try await executeWithTaskManagement {
      let apiModels = try await self.apiClient.listModels()
      return apiModels.map { OpenAIModel.init(from: $0) }
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
