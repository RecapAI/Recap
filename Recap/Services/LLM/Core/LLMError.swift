import Foundation

enum LLMError: Error, LocalizedError {
  case providerNotAvailable
  case modelNotFound(String)
  case modelNotDownloaded(String)
  case invalidResponse
  case networkError(Error)
  case configurationError(String)
  case taskCancelled
  case invalidPrompt
  case tokenLimitExceeded
  case rateLimitExceeded
  case insufficientMemory
  case unsupportedModel(String)
  case dataAccessError(String)
  case apiError(String)

  var errorDescription: String? {
    switch self {
    case .providerNotAvailable:
      return "LLM provider is not available. Please ensure it is installed and running."
    case .modelNotFound(let modelName):
      return "Model '\(modelName)' not found."
    case .modelNotDownloaded(let modelName):
      return "Model '\(modelName)' is not downloaded locally."
    case .invalidResponse:
      return "Received invalid response from LLM provider."
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .configurationError(let message):
      return "Configuration error: \(message)"
    case .taskCancelled:
      return "Task was cancelled."
    case .invalidPrompt:
      return "Invalid prompt provided."
    case .tokenLimitExceeded:
      return "Token limit exceeded for this request."
    case .rateLimitExceeded:
      return "Rate limit exceeded. Please try again later."
    case .insufficientMemory:
      return "Insufficient memory to load model."
    case .unsupportedModel(let modelName):
      return "Model '\(modelName)' is not supported by this provider."
    case .dataAccessError(let message):
      return "Data access error: \(message)"
    case .apiError(let message):
      return "API error: \(message)"
    }
  }
}
