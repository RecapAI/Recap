import Foundation

@MainActor
final class OpenRouterAPIClient {
  private let baseURL: String
  private let apiKey: String?
  private let session: URLSession

  init(baseURL: String = "https://openrouter.ai/api/v1", apiKey: String? = nil) {
    self.baseURL = baseURL
    self.apiKey = apiKey
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 60.0
    configuration.timeoutIntervalForResource = 300.0
    self.session = URLSession(configuration: configuration)
  }

  func checkAvailability() async -> Bool {
    do {
      _ = try await listModels()
      return true
    } catch {
      return false
    }
  }

  func listModels() async throws -> [OpenRouterAPIModel] {
    guard let url = URL(string: "\(baseURL)/models") else {
      throw LLMError.configurationError("Invalid base URL")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    addHeaders(&request)

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw LLMError.apiError("Invalid response type")
    }

    guard httpResponse.statusCode == 200 else {
      throw LLMError.apiError("HTTP \(httpResponse.statusCode)")
    }

    let modelsResponse = try JSONDecoder().decode(OpenRouterModelsResponse.self, from: data)
    return modelsResponse.data
  }

  func generateChatCompletion(
    modelName: String,
    messages: [LLMMessage],
    options: LLMOptions
  ) async throws -> String {
    guard let url = URL(string: "\(baseURL)/chat/completions") else {
      throw LLMError.configurationError("Invalid base URL")
    }

    let requestBody = OpenRouterChatRequest(
      model: modelName,
      messages: messages.map { OpenRouterMessage(role: $0.role.rawValue, content: $0.content) },
      temperature: options.temperature,
      maxTokens: options.maxTokens,
      topP: options.topP,
      stop: options.stopSequences
    )

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    addHeaders(&request)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    request.httpBody = try encoder.encode(requestBody)

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw LLMError.apiError("Invalid response type")
    }

    guard httpResponse.statusCode == 200 else {
      if let errorData = try? JSONDecoder().decode(OpenRouterErrorResponse.self, from: data) {
        throw LLMError.apiError(errorData.error.message)
      }
      throw LLMError.apiError("HTTP \(httpResponse.statusCode)")
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let chatResponse = try decoder.decode(OpenRouterChatResponse.self, from: data)

    guard let choice = chatResponse.choices.first else {
      throw LLMError.invalidResponse
    }

    let content = choice.message.content
    guard !content.isEmpty else {
      throw LLMError.invalidResponse
    }

    return content
  }

  private func addHeaders(_ request: inout URLRequest) {
    if let apiKey = apiKey {
      request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    }
    request.setValue("Recap/1.0", forHTTPHeaderField: "HTTP-Referer")
    request.setValue("Recap iOS App", forHTTPHeaderField: "X-Title")
  }
}

struct OpenRouterModelsResponse: Codable {
  let data: [OpenRouterAPIModel]
}

struct OpenRouterAPIModel: Codable {
  let id: String
  let name: String
  let description: String?
  let pricing: OpenRouterPricing?
  let contextLength: Int?
  let architecture: OpenRouterArchitecture?
  let topProvider: OpenRouterTopProvider?

  private enum CodingKeys: String, CodingKey {
    case id
    case name
    case description
    case pricing
    case contextLength = "context_length"
    case architecture
    case topProvider = "top_provider"
  }
}

struct OpenRouterPricing: Codable {
  let prompt: String?
  let completion: String?
}

struct OpenRouterArchitecture: Codable {
  let modality: String?
  let tokenizer: String?
  let instructType: String?

  private enum CodingKeys: String, CodingKey {
    case modality
    case tokenizer
    case instructType = "instruct_type"
  }
}

struct OpenRouterTopProvider: Codable {
  let maxCompletionTokens: Int?
  let isModerated: Bool?

  private enum CodingKeys: String, CodingKey {
    case maxCompletionTokens = "max_completion_tokens"
    case isModerated = "is_moderated"
  }
}

struct OpenRouterChatRequest: Codable {
  let model: String
  let messages: [OpenRouterMessage]
  let temperature: Double?
  let maxTokens: Int?
  let topP: Double?
  let stop: [String]?

  private enum CodingKeys: String, CodingKey {
    case model
    case messages
    case temperature
    case maxTokens = "max_tokens"
    case topP = "top_p"
    case stop
  }
}

struct OpenRouterMessage: Codable {
  let role: String
  let content: String
}

struct OpenRouterChatResponse: Codable {
  let choices: [OpenRouterChoice]
  let usage: OpenRouterUsage?
}

struct OpenRouterChoice: Codable {
  let message: OpenRouterMessage
  let finishReason: String?

  private enum CodingKeys: String, CodingKey {
    case message
    case finishReason = "finish_reason"
  }
}

struct OpenRouterUsage: Codable {
  let promptTokens: Int?
  let completionTokens: Int?
  let totalTokens: Int?

  private enum CodingKeys: String, CodingKey {
    case promptTokens = "prompt_tokens"
    case completionTokens = "completion_tokens"
    case totalTokens = "total_tokens"
  }
}

struct OpenRouterErrorResponse: Codable {
  let error: OpenRouterError
}

struct OpenRouterError: Codable {
  let message: String
  let type: String?
  let code: String?
}
