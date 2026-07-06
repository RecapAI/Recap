import Foundation

enum LLMProvider: String, CaseIterable, Identifiable {
    case ollama = "ollama"
    case openRouter = "openrouter"
    case requesty = "requesty"
    
    var id: String { rawValue }
    
    var providerName: String {
        switch self {
        case .ollama:
            return "Ollama"
        case .openRouter:
            return "OpenRouter"
        case .requesty:
            return "Requesty"
        }
    }
    
    static var `default`: LLMProvider {
        .ollama
    }
}
