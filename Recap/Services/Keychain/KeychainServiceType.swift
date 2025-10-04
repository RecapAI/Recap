import Foundation

#if MOCKING
  import Mockable
#endif

#if MOCKING
  @Mockable
#endif
protocol KeychainServiceType {
  func store(key: String, value: String) throws
  func retrieve(key: String) throws -> String?
  func delete(key: String) throws
  func exists(key: String) -> Bool
}

enum KeychainError: Error, LocalizedError {
  case invalidData
  case itemNotFound
  case duplicateItem
  case unexpectedStatus(OSStatus)

  var errorDescription: String? {
    switch self {
    case .invalidData:
      return "Invalid data provided for keychain operation"
    case .itemNotFound:
      return "Item not found in keychain"
    case .duplicateItem:
      return "Item already exists in keychain"
    case .unexpectedStatus(let status):
      return "Keychain operation failed with status: \(status)"
    }
  }
}

enum KeychainKey: String, CaseIterable {
  case openRouterApiKey = "openrouter_api_key"
  case openAIApiKey = "openai_api_key"
  case openAIEndpoint = "openai_endpoint"

  var key: String {
    return "com.recap.\(rawValue)"
  }
}
