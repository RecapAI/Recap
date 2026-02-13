import Foundation

@MainActor
extension GeneralSettingsViewModel {
  func validateProviderCredentials(_ provider: LLMProvider) async -> Bool {
    switch provider {
    case .openRouter:
      return validateOpenRouterCredentials()
    case .openAI:
      return validateOpenAICredentials()
    default:
      return true
    }
  }

  func validateOpenRouterCredentials() -> Bool {
    let validation = keychainAPIValidator.validateOpenRouterAPI()

    if !validation.isValid {
      do {
        existingAPIKey = try keychainService.retrieveOpenRouterAPIKey()
      } catch {
        existingAPIKey = nil
      }
      showAPIKeyAlert = true
      return false
    }
    return true
  }

  func validateOpenAICredentials() -> Bool {
    let validation = keychainAPIValidator.validateOpenAIAPI()

    if !validation.isValid {
      do {
        existingOpenAIKey = try keychainService.retrieveOpenAIAPIKey()
        existingOpenAIEndpoint = try keychainService.retrieveOpenAIEndpoint()
      } catch {
        existingOpenAIKey = nil
        existingOpenAIEndpoint = nil
      }
      showOpenAIAlert = true
      return false
    }
    return true
  }
}
