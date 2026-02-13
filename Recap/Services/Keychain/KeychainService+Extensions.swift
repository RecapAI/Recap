import Foundation

extension KeychainServiceType {
  func storeOpenRouterAPIKey(_ apiKey: String) throws {
    try store(key: KeychainKey.openRouterApiKey.key, value: apiKey)
  }

  func retrieveOpenRouterAPIKey() throws -> String? {
    try retrieve(key: KeychainKey.openRouterApiKey.key)
  }

  func deleteOpenRouterAPIKey() throws {
    try delete(key: KeychainKey.openRouterApiKey.key)
  }

  func hasOpenRouterAPIKey() -> Bool {
    exists(key: KeychainKey.openRouterApiKey.key)
  }

  func storeOpenAIAPIKey(_ apiKey: String) throws {
    try store(key: KeychainKey.openAIApiKey.key, value: apiKey)
  }

  func retrieveOpenAIAPIKey() throws -> String? {
    try retrieve(key: KeychainKey.openAIApiKey.key)
  }

  func deleteOpenAIAPIKey() throws {
    try delete(key: KeychainKey.openAIApiKey.key)
  }

  func hasOpenAIAPIKey() -> Bool {
    exists(key: KeychainKey.openAIApiKey.key)
  }

  func storeOpenAIEndpoint(_ endpoint: String) throws {
    try store(key: KeychainKey.openAIEndpoint.key, value: endpoint)
  }

  func retrieveOpenAIEndpoint() throws -> String? {
    try retrieve(key: KeychainKey.openAIEndpoint.key)
  }

  func deleteOpenAIEndpoint() throws {
    try delete(key: KeychainKey.openAIEndpoint.key)
  }

  func hasOpenAIEndpoint() -> Bool {
    exists(key: KeychainKey.openAIEndpoint.key)
  }
}
