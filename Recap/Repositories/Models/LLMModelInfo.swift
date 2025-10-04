import CoreData
import Foundation

struct LLMModelInfo: Identifiable, Hashable {
  let id: String
  let name: String
  let provider: String
  var keepAliveMinutes: Int32?
  var temperature: Double?
  var maxTokens: Int32

  init(from managedObject: LLMModel) {
    self.id = managedObject.id ?? UUID().uuidString
    self.name = managedObject.name ?? ""
    self.provider = managedObject.provider ?? "ollama"
    self.keepAliveMinutes = managedObject.keepAliveMinutes
    self.temperature = managedObject.temperature
    self.maxTokens = managedObject.maxTokens
  }

  init(
    id: String = UUID().uuidString,
    name: String,
    provider: String = "ollama",
    keepAliveMinutes: Int32? = nil,
    temperature: Double? = nil,
    maxTokens: Int32 = 8192
  ) {
    self.id = id
    self.name = name
    self.provider = provider
    self.keepAliveMinutes = keepAliveMinutes
    self.temperature = temperature
    self.maxTokens = maxTokens
  }
}
