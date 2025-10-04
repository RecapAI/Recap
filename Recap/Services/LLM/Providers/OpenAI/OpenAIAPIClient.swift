import Foundation
import OpenAI

@MainActor
final class OpenAIAPIClient {
  private let openAI: OpenAI
  private let apiKey: String?
  private let endpoint: String

  init(apiKey: String? = nil, endpoint: String = "https://api.openai.com/v1") {
    self.apiKey = apiKey
    self.endpoint = endpoint

    let configuration = OpenAI.Configuration(
      token: apiKey ?? "",
      host: endpoint
    )
    self.openAI = OpenAI(configuration: configuration)
  }

  func checkAvailability() async -> Bool {
    guard apiKey != nil && !apiKey!.isEmpty else {
      return false
    }

    do {
      _ = try await listModels()
      return true
    } catch {
      return false
    }
  }

  func listModels() async throws -> [OpenAIAPIModel] {
    guard let apiKey = apiKey, !apiKey.isEmpty else {
      throw LLMError.configurationError("API key is required")
    }

    let modelsResult = try await openAI.models()

    // Filter for GPT models and map to our model type
    return modelsResult.data.compactMap { model in
      // Only include chat models (GPT models)
      guard model.id.contains("gpt") else { return nil }

      return OpenAIAPIModel(
        id: model.id,
        contextWindow: getContextWindow(for: model.id)
      )
    }
  }

  func generateChatCompletion(
    modelName: String,
    messages: [LLMMessage],
    options: LLMOptions
  ) async throws -> String {
    guard let apiKey = apiKey, !apiKey.isEmpty else {
      throw LLMError.configurationError("API key is required")
    }

    let chatMessages: [ChatQuery.ChatCompletionMessageParam] = messages.map { message in
      switch message.role {
      case .system:
        return .system(.init(content: .textContent(message.content)))
      case .user:
        return .user(.init(content: .string(message.content)))
      case .assistant:
        return .assistant(.init(content: .textContent(message.content)))
      }
    }

    let query = ChatQuery(
      messages: chatMessages,
      model: .init(modelName),
      stop: options.stopSequences?.isEmpty == false ? .stringList(options.stopSequences!) : nil,
      temperature: options.temperature,
      topP: options.topP
    )

    let result = try await openAI.chats(query: query)

    guard let choice = result.choices.first,
      let content = choice.message.content
    else {
      throw LLMError.invalidResponse
    }

    return content
  }

  private func getContextWindow(for modelId: String) -> Int? {
    // Common OpenAI model context windows
    if modelId.contains("gpt-4-turbo") || modelId.contains("gpt-4-1106")
      || modelId.contains("gpt-4-0125") {
      return 128000
    } else if modelId.contains("gpt-4-32k") {
      return 32768
    } else if modelId.contains("gpt-4") {
      return 8192
    } else if modelId.contains("gpt-3.5-turbo-16k") {
      return 16384
    } else if modelId.contains("gpt-3.5-turbo") {
      return 4096
    }
    return nil
  }
}

struct OpenAIAPIModel: Codable {
  let id: String
  let contextWindow: Int?
}
