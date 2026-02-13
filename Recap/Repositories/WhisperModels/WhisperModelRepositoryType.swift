import Foundation

#if MOCKING
  import Mockable
#endif

#if MOCKING
  @Mockable
#endif
@MainActor
protocol WhisperModelRepositoryType {
  func getAllModels() async throws -> [WhisperModelData]
  func getDownloadedModels() async throws -> [WhisperModelData]
  func getSelectedModel() async throws -> WhisperModelData?
  func saveModel(_ model: WhisperModelData) async throws
  func updateModel(_ model: WhisperModelData) async throws
  func deleteModel(name: String) async throws
  func setSelectedModel(name: String) async throws
  func markAsDownloaded(name: String, sizeInMB: Int64?) async throws
}

struct WhisperModelData: Equatable {
  let name: String
  var isDownloaded: Bool
  var isSelected: Bool
  var downloadedAt: Date?
  var fileSizeInMB: Int64?
  var variant: String?
}
