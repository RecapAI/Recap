import Foundation

@MainActor
final class RequestyAPIClient {
    private let baseURL: String
    private let apiKey: String?
    private let session: URLSession
    
    init(baseURL: String = "https://router.requesty.ai/v1", apiKey: String? = nil) {
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
    
    func listModels() async throws -> [RequestyAPIModel] {
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
        
        let modelsResponse = try JSONDecoder().decode(RequestyModelsResponse.self, from: data)
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
        
        let requestBody = RequestyChatRequest(
            model: modelName,
            messages: messages.map { RequestyMessage(role: $0.role.rawValue, content: $0.content) },
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
            if let errorData = try? JSONDecoder().decode(RequestyErrorResponse.self, from: data) {
                throw LLMError.apiError(errorData.error.message)
            }
            throw LLMError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let chatResponse = try decoder.decode(RequestyChatResponse.self, from: data)
        
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

struct RequestyModelsResponse: Codable {
    let data: [RequestyAPIModel]
}

// Requesty's /v1/models is OpenAI-shaped but exposes capability metadata via
// `context_window` and boolean `supports_*` fields (NOT context_length /
// supported_parameters). Pricing may be absent. All fields are decoded
// defensively as optionals so missing metadata degrades gracefully.
struct RequestyAPIModel: Codable {
    let id: String
    let name: String?
    let description: String?
    let pricing: RequestyPricing?
    let contextWindow: Int?
    let maxOutputTokens: Int?
    let supportsToolCalling: Bool?
    let supportsReasoning: Bool?
    let supportsVision: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case pricing
        case contextWindow = "context_window"
        case maxOutputTokens = "max_output_tokens"
        case supportsToolCalling = "supports_tool_calling"
        case supportsReasoning = "supports_reasoning"
        case supportsVision = "supports_vision"
    }
}

struct RequestyPricing: Codable {
    let prompt: String?
    let completion: String?
}

struct RequestyChatRequest: Codable {
    let model: String
    let messages: [RequestyMessage]
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

struct RequestyMessage: Codable {
    let role: String
    let content: String
}

struct RequestyChatResponse: Codable {
    let choices: [RequestyChoice]
    let usage: RequestyUsage?
}

struct RequestyChoice: Codable {
    let message: RequestyMessage
    let finishReason: String?
    
    private enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct RequestyUsage: Codable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
    
    private enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

struct RequestyErrorResponse: Codable {
    let error: RequestyError
}

struct RequestyError: Codable {
    let message: String
    let type: String?
    let code: String?
}
