import Foundation
import Ollama

@MainActor
final class OllamaAPIClient {
  private let client: Client

  init(baseURL: String = "http://localhost", port: Int = 11434) {
    let url = URL(string: "\(baseURL):\(port)")!
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 3600
    configuration.timeoutIntervalForResource = 3600
    let session = URLSession(configuration: configuration)
    self.client = Client(session: session, host: url)
  }

  func checkAvailability() async -> Bool {
    do {
      _ = try await client.listModels()
      return true
    } catch {
      return false
    }
  }

  func listModels() async throws -> [OllamaAPIModel] {
    let response = try await client.listModels()
    return response.models.map { model in
      OllamaAPIModel(
        name: model.name,
        size: model.size,
        digest: model.digest,
        modifiedAt: nil,
        details: OllamaModelDetails(
          format: model.details.format,
          family: model.details.family,
          families: model.details.families,
          parameterSize: model.details.parameterSize,
          quantizationLevel: model.details.quantizationLevel
        )
      )
    }
  }

  func generateChatCompletion(
    modelName: String,
    messages: [LLMMessage],
    options: LLMOptions
  ) async throws -> String {
    guard let modelId = createModelID(from: modelName) else {
      throw LLMError.modelNotFound("Model \(modelName) not found")
    }

    let response = try await client.chat(
      model: modelId,
      messages: mapMessagesToClient(messages),
      options: mapOptionsToClient(options),
      keepAlive: createKeepAlive(from: options)
    )
    return response.message.content
  }

  private func createModelID(from modelName: String) -> Model.ID? {
    Model.ID(rawValue: modelName)
  }

  private func createKeepAlive(from options: LLMOptions) -> KeepAlive {
    options.keepAliveMinutes.map { KeepAlive.minutes($0) } ?? .default
  }

  private func mapOptionsToClient(_ options: LLMOptions) -> [String: Value] {
    var clientOptions: [String: Value] = [:]
    clientOptions["temperature"] = .double(options.temperature)

    if let maxTokens = options.maxTokens {
      clientOptions["num_predict"] = .double(Double(maxTokens))
    }

    if let topP = options.topP {
      clientOptions["top_p"] = .double(topP)
    }
    if let topK = options.topK {
      clientOptions["top_k"] = .double(Double(topK))
    }
    if let repeatPenalty = options.repeatPenalty {
      clientOptions["repeat_penalty"] = .double(repeatPenalty)
    }
    if let seed = options.seed {
      clientOptions["seed"] = .double(Double(seed))
    }
    if let stopSequences = options.stopSequences {
      clientOptions["stop"] = .array(stopSequences.map { .string($0) })
    }

    return clientOptions
  }

  private func mapMessagesToClient(_ messages: [LLMMessage]) -> [Chat.Message] {
    messages.map { message in
      switch message.role {
      case .system:
        return Chat.Message.system(message.content)
      case .user:
        return Chat.Message.user(message.content)
      case .assistant:
        return Chat.Message.assistant(message.content)
      }
    }
  }
}

struct OllamaAPIModel: Codable {
  let name: String
  let size: Int64
  let digest: String
  let modifiedAt: Date?
  let details: OllamaModelDetails?

  private enum CodingKeys: String, CodingKey {
    case name
    case size
    case digest
    case modifiedAt = "modified_at"
    case details
  }
}

struct OllamaModelDetails: Codable {
  let format: String?
  let family: String?
  let families: [String]?
  let parameterSize: String?
  let quantizationLevel: String?

  private enum CodingKeys: String, CodingKey {
    case format
    case family
    case families
    case parameterSize = "parameter_size"
    case quantizationLevel = "quantization_level"
  }
}
