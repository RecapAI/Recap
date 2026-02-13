import Foundation

enum LLMProvider: String, CaseIterable, Identifiable {
  case ollama = "ollama"
  case openRouter = "openrouter"
  case openAI = "openai"

  var id: String { rawValue }

  var providerName: String {
    switch self {
    case .ollama:
      return "Ollama"
    case .openRouter:
      return "OpenRouter"
    case .openAI:
      return "OpenAI"
    }
  }

  static var `default`: LLMProvider {
    .ollama
  }
}
