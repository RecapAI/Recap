import Foundation
import Security

final class KeychainService: KeychainServiceType {
  private let service: String

  init(service: String = Bundle.main.bundleIdentifier ?? "com.recap.app") {
    self.service = service
  }

  func store(key: String, value: String) throws {
    guard let data = value.data(using: .utf8) else {
      throw KeychainError.invalidData
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecValueData as String: data
    ]

    let status = SecItemAdd(query as CFDictionary, nil)

    switch status {
    case errSecSuccess:
      break
    case errSecDuplicateItem:
      try update(key: key, value: value)
    default:
      throw KeychainError.unexpectedStatus(status)
    }
  }

  func retrieve(key: String) throws -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    switch status {
    case errSecSuccess:
      guard let data = result as? Data,
        let string = String(data: data, encoding: .utf8)
      else {
        throw KeychainError.invalidData
      }
      return string
    case errSecItemNotFound:
      return nil
    default:
      throw KeychainError.unexpectedStatus(status)
    }
  }

  func delete(key: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key
    ]

    let status = SecItemDelete(query as CFDictionary)

    switch status {
    case errSecSuccess, errSecItemNotFound:
      break
    default:
      throw KeychainError.unexpectedStatus(status)
    }
  }

  func exists(key: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecReturnData as String: false,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    let status = SecItemCopyMatching(query as CFDictionary, nil)
    return status == errSecSuccess
  }

  private func update(key: String, value: String) throws {
    guard let data = value.data(using: .utf8) else {
      throw KeychainError.invalidData
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key
    ]

    let attributes: [String: Any] = [
      kSecValueData as String: data
    ]

    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

    switch status {
    case errSecSuccess:
      break
    default:
      throw KeychainError.unexpectedStatus(status)
    }
  }
}
