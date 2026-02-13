import CoreData
import Foundation

@MainActor
final class WhisperModelRepository: WhisperModelRepositoryType {
  private let coreDataManager: CoreDataManagerType

  init(coreDataManager: CoreDataManagerType) {
    self.coreDataManager = coreDataManager
  }

  func getAllModels() async throws -> [WhisperModelData] {
    let context = coreDataManager.viewContext
    let request = WhisperModel.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

    let models = try context.fetch(request)
    return models.map { mapToData($0) }
  }

  func getDownloadedModels() async throws -> [WhisperModelData] {
    let context = coreDataManager.viewContext
    let request = WhisperModel.fetchRequest()
    request.predicate = NSPredicate(format: "isDownloaded == YES")
    request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

    let models = try context.fetch(request)
    return models.map { mapToData($0) }
  }

  func getSelectedModel() async throws -> WhisperModelData? {
    let context = coreDataManager.viewContext
    let request = WhisperModel.fetchRequest()
    request.predicate = NSPredicate(format: "isSelected == YES")
    request.fetchLimit = 1

    let models = try context.fetch(request)
    return models.first.map { mapToData($0) }
  }

  func saveModel(_ model: WhisperModelData) async throws {
    let context = coreDataManager.viewContext

    let whisperModel = WhisperModel(context: context)
    whisperModel.name = model.name
    whisperModel.isDownloaded = model.isDownloaded
    whisperModel.isSelected = model.isSelected
    whisperModel.downloadedAt = Int64(model.downloadedAt?.timeIntervalSince1970 ?? 0)
    whisperModel.fileSizeInMB = model.fileSizeInMB ?? 0
    whisperModel.variant = model.variant

    try coreDataManager.save()
  }

  func updateModel(_ model: WhisperModelData) async throws {
    let context = coreDataManager.viewContext
    let request = WhisperModel.fetchRequest()
    request.predicate = NSPredicate(format: "name == %@", model.name)
    request.fetchLimit = 1

    guard let existingModel = try context.fetch(request).first else {
      throw WhisperModelRepositoryError.modelNotFound(model.name)
    }

    existingModel.isDownloaded = model.isDownloaded
    existingModel.isSelected = model.isSelected
    existingModel.downloadedAt = Int64(model.downloadedAt?.timeIntervalSince1970 ?? 0)
    existingModel.fileSizeInMB = model.fileSizeInMB ?? 0
    existingModel.variant = model.variant

    try coreDataManager.save()
  }

  func deleteModel(name: String) async throws {
    let context = coreDataManager.viewContext
    let request = WhisperModel.fetchRequest()
    request.predicate = NSPredicate(format: "name == %@", name)

    let models = try context.fetch(request)
    models.forEach { context.delete($0) }

    try coreDataManager.save()
  }

  func setSelectedModel(name: String) async throws {
    let context = coreDataManager.viewContext

    let deselectRequest = WhisperModel.fetchRequest()
    deselectRequest.predicate = NSPredicate(format: "isSelected == YES")
    let selectedModels = try context.fetch(deselectRequest)
    selectedModels.forEach { $0.isSelected = false }

    let selectRequest = WhisperModel.fetchRequest()
    selectRequest.predicate = NSPredicate(format: "name == %@ AND isDownloaded == YES", name)
    selectRequest.fetchLimit = 1

    guard let modelToSelect = try context.fetch(selectRequest).first else {
      throw WhisperModelRepositoryError.modelNotDownloaded(name)
    }

    modelToSelect.isSelected = true
    try coreDataManager.save()
  }

  func markAsDownloaded(name: String, sizeInMB: Int64?) async throws {
    let context = coreDataManager.viewContext
    let request = WhisperModel.fetchRequest()
    request.predicate = NSPredicate(format: "name == %@", name)
    request.fetchLimit = 1

    if let existingModel = try context.fetch(request).first {
      existingModel.isDownloaded = true
      existingModel.downloadedAt = Int64(Date().timeIntervalSince1970)
      if let size = sizeInMB {
        existingModel.fileSizeInMB = size
      }
    } else {
      let newModel = WhisperModel(context: context)
      newModel.name = name
      newModel.isDownloaded = true
      newModel.downloadedAt = Int64(Date().timeIntervalSince1970)
      newModel.fileSizeInMB = sizeInMB ?? 0
      newModel.isSelected = false
    }

    try coreDataManager.save()
  }

  private func mapToData(_ model: WhisperModel) -> WhisperModelData {
    WhisperModelData(
      name: model.name ?? "",
      isDownloaded: model.isDownloaded,
      isSelected: model.isSelected,
      downloadedAt: model.downloadedAt > 0
        ? Date(timeIntervalSince1970: TimeInterval(model.downloadedAt)) : nil,
      fileSizeInMB: model.fileSizeInMB > 0 ? model.fileSizeInMB : nil,
      variant: model.variant
    )
  }
}

enum WhisperModelRepositoryError: LocalizedError {
  case modelNotFound(String)
  case modelNotDownloaded(String)

  var errorDescription: String? {
    switch self {
    case .modelNotFound(let name):
      return "Model '\(name)' not found"
    case .modelNotDownloaded(let name):
      return "Model '\(name)' is not downloaded"
    }
  }
}
