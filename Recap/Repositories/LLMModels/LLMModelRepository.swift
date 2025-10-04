import CoreData
import Foundation

@MainActor
final class LLMModelRepository: LLMModelRepositoryType {
  private let coreDataManager: CoreDataManagerType

  init(coreDataManager: CoreDataManagerType) {
    self.coreDataManager = coreDataManager
  }

  func getAllModels() async throws -> [LLMModelInfo] {
    let context = coreDataManager.viewContext
    let request: NSFetchRequest<LLMModel> = LLMModel.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

    do {
      let models = try context.fetch(request)
      return models.map { LLMModelInfo(from: $0) }
    } catch {
      throw LLMError.dataAccessError(error.localizedDescription)
    }
  }

  func getModel(byId id: String) async throws -> LLMModelInfo? {
    let context = coreDataManager.viewContext
    let request: NSFetchRequest<LLMModel> = LLMModel.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@", id)
    request.fetchLimit = 1

    do {
      let models = try context.fetch(request)
      return models.first.map { LLMModelInfo(from: $0) }
    } catch {
      throw LLMError.dataAccessError(error.localizedDescription)
    }
  }

  func saveModels(_ models: [LLMModelInfo]) async throws {
    let context = coreDataManager.viewContext

    for modelInfo in models {
      let request: NSFetchRequest<LLMModel> = LLMModel.fetchRequest()
      request.predicate = NSPredicate(format: "id == %@", modelInfo.id)
      request.fetchLimit = 1

      do {
        let existingModels = try context.fetch(request)
        let model = existingModels.first ?? LLMModel(context: context)

        model.id = modelInfo.id
        model.name = modelInfo.name
        model.provider = modelInfo.provider
        model.keepAliveMinutes = modelInfo.keepAliveMinutes ?? 0
        model.temperature = modelInfo.temperature ?? 0.7
        model.maxTokens = modelInfo.maxTokens
      } catch {
        throw LLMError.dataAccessError(error.localizedDescription)
      }
    }

    do {
      try context.save()
    } catch {
      throw LLMError.dataAccessError(error.localizedDescription)
    }
  }
}
