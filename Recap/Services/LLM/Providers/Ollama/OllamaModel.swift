import Foundation

struct OllamaModel: LLMModelType {
  let id: String
  let name: String
  let provider: String = "ollama"
  let contextLength: Int32? = nil

  init(name: String) {
    self.id = "ollama-\(name)"
    self.name = name
  }
}

extension OllamaModel {
  init(from apiModel: OllamaAPIModel) {
    self.init(name: apiModel.name)
  }
}
