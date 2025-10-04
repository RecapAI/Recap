import Foundation

struct OpenAIModel: LLMModelType {
  let id: String
  let name: String
  let provider: String = "openai"
  let contextLength: Int32?

  init(id: String, name: String, contextLength: Int? = nil) {
    self.id = "openai-\(id)"
    self.name = name
    self.contextLength = contextLength.map(Int32.init)
  }
}

extension OpenAIModel {
  init(from apiModel: OpenAIAPIModel) {
    self.init(
      id: apiModel.id,
      name: apiModel.id,
      contextLength: apiModel.contextWindow
    )
  }
}
