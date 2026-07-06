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
    
    func storeRequestyAPIKey(_ apiKey: String) throws {
        try store(key: KeychainKey.requestyApiKey.key, value: apiKey)
    }
    
    func retrieveRequestyAPIKey() throws -> String? {
        try retrieve(key: KeychainKey.requestyApiKey.key)
    }
    
    func deleteRequestyAPIKey() throws {
        try delete(key: KeychainKey.requestyApiKey.key)
    }
    
    func hasRequestyAPIKey() -> Bool {
        exists(key: KeychainKey.requestyApiKey.key)
    }
}
