import Foundation

@MainActor
protocol LLMModelRepositoryType {
  func getAllModels() async throws -> [LLMModelInfo]
  func getModel(byId id: String) async throws -> LLMModelInfo?
  func saveModels(_ models: [LLMModelInfo]) async throws
}
