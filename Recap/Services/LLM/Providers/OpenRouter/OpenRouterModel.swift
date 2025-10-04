import Foundation

struct OpenRouterModel: LLMModelType {
  let id: String
  let name: String
  let provider: String = "openrouter"
  let contextLength: Int32?
  let maxCompletionTokens: Int32?

  init(apiModelId: String, displayName: String, contextLength: Int?, maxCompletionTokens: Int?) {
    self.id = "openrouter-\(apiModelId)"
    self.name = apiModelId
    self.contextLength = contextLength.map(Int32.init)
    self.maxCompletionTokens = maxCompletionTokens.map(Int32.init)
  }
}

extension OpenRouterModel {
  init(from apiModel: OpenRouterAPIModel) {
    self.init(
      apiModelId: apiModel.id,
      displayName: apiModel.name,
      contextLength: apiModel.contextLength,
      maxCompletionTokens: apiModel.topProvider?.maxCompletionTokens
    )
  }
}
