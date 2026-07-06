import Foundation

struct RequestyModel: LLMModelType {
    let id: String
    let name: String
    let provider: String = "requesty"
    let contextLength: Int32?
    let maxCompletionTokens: Int32?
    
    init(apiModelId: String, displayName: String, contextLength: Int?, maxCompletionTokens: Int?) {
        self.id = "requesty-\(apiModelId)"
        self.name = apiModelId
        self.contextLength = contextLength.map(Int32.init)
        self.maxCompletionTokens = maxCompletionTokens.map(Int32.init)
    }
}

extension RequestyModel {
    init(from apiModel: RequestyAPIModel) {
        self.init(
            apiModelId: apiModel.id,
            displayName: apiModel.name ?? apiModel.id,
            contextLength: apiModel.contextWindow,
            maxCompletionTokens: apiModel.maxOutputTokens
        )
    }
}
