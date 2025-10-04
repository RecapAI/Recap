import Foundation

#if MOCKING
  import Mockable
#endif

#if MOCKING
  @Mockable
#endif
protocol KeychainAPIValidatorType {
  func validateOpenRouterAPI() -> APIValidationResult
  func validateOpenAIAPI() -> APIValidationResult
}

enum APIValidationResult {
  case valid
  case missingApiKey
  case invalidApiKey

  var isValid: Bool {
    switch self {
    case .valid:
      return true
    case .missingApiKey, .invalidApiKey:
      return false
    }
  }

  var errorMessage: String? {
    switch self {
    case .valid:
      return nil
    case .missingApiKey:
      return "API key not found. Please add your OpenRouter API key in settings."
    case .invalidApiKey:
      return "Invalid API key format. Please check your OpenRouter API key."
    }
  }
}
