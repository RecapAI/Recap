import Combine
import Foundation

@MainActor
final class OllamaProvider: LLMProviderType, LLMTaskManageable {
  typealias Model = OllamaModel

  let name = "Ollama"

  var isAvailable: Bool {
    availabilityHelper.isAvailable
  }

  var availabilityPublisher: AnyPublisher<Bool, Never> {
    availabilityHelper.availabilityPublisher
  }

  var currentTask: Task<Void, Never>?

  private let apiClient: OllamaAPIClient
  private let availabilityHelper: AvailabilityHelper

  init(baseURL: String = "http://localhost", port: Int = 11434) {
    self.apiClient = OllamaAPIClient(baseURL: baseURL, port: port)

    self.availabilityHelper = AvailabilityHelper(
      checkInterval: 30.0,
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

  func listModels() async throws -> [OllamaModel] {
    guard isAvailable else {
      throw LLMError.providerNotAvailable
    }

    return try await executeWithTaskManagement {
      let apiModels = try await self.apiClient.listModels()
      return apiModels.map { OllamaModel(from: $0) }
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
