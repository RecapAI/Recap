import SwiftUI
import WhisperKit

@MainActor
final class WhisperModelsViewModel: WhisperModelsViewModelType {
  @Published var selectedModel: String?
  @Published var downloadedModels: Set<String> = []
  @Published var downloadingModels: Set<String> = []
  @Published var downloadProgress: [String: Double] = [:]
  @Published var showingTooltipForModel: String?
  @Published var tooltipPosition: CGPoint = .zero
  @Published var errorMessage: String?
  @Published var showingError = false

  private let repository: WhisperModelRepositoryType

  init(repository: WhisperModelRepositoryType) {
    self.repository = repository
    Task {
      await loadModelsFromRepository()
    }
  }

  var recommendedModels: [String] {
    ModelVariant.multilingualCases
      .filter { $0.isRecommended }
      .map { $0.description }
  }

  var otherModels: [String] {
    ModelVariant.multilingualCases
      .filter { !$0.isRecommended }
      .map { $0.description }
  }

  func selectModel(_ modelName: String) {
    guard downloadedModels.contains(modelName) else { return }

    Task {
      do {
        if selectedModel == modelName {
          selectedModel = nil
          let models = try await repository.getAllModels()
          for model in models where model.isSelected {
            var updatedModel = model
            updatedModel.isSelected = false
            try await repository.updateModel(updatedModel)
          }
        } else {
          try await repository.setSelectedModel(name: modelName)
          selectedModel = modelName
        }
      } catch {
        showError("Failed to select model: \(error.localizedDescription)")
      }
    }
  }

  func downloadModel(_ modelName: String) {
    Task {
      do {
        downloadingModels.insert(modelName)
        downloadProgress[modelName] = 0.0

        _ = try await WhisperKit.createWithProgress(
          model: modelName,
          modelRepo: "argmaxinc/whisperkit-coreml",
          modelFolder: nil,
          download: true,
          progressCallback: { [weak self] progress in
            Task { @MainActor in
              guard let self = self, self.downloadingModels.contains(modelName) else {
                return
              }
              self.downloadProgress[modelName] = progress.fractionCompleted
            }
          }
        )

        let modelInfo = await WhisperKit.getModelSizeInfo(for: modelName)
        try await repository.markAsDownloaded(
          name: modelName,
          sizeInMB: Int64(modelInfo.totalSizeMB)
        )

        downloadedModels.insert(modelName)
        downloadingModels.remove(modelName)
        downloadProgress[modelName] = 1.0
      } catch {
        downloadingModels.remove(modelName)
        downloadProgress.removeValue(forKey: modelName)
        showError("Failed to download model: \(error.localizedDescription)")
      }
    }
  }

  func toggleTooltip(for modelName: String, at position: CGPoint) {
    if showingTooltipForModel == modelName {
      showingTooltipForModel = nil
    } else {
      showingTooltipForModel = modelName
      tooltipPosition = position
    }
  }

  func getModelInfo(_ name: String) -> ModelInfo? {
    let baseModelName = name.replacingOccurrences(of: "-v2", with: "").replacingOccurrences(
      of: "-v3", with: "")
    return String.modelInfoData[baseModelName]
  }

  func modelDisplayName(_ name: String) -> String {
    switch name {
    case "large-v2":
      return "Large v2"
    case "large-v3":
      return "Large v3"
    case "distil-whisper_distil-large-v3_turbo":
      return "Distil Large v3 Turbo"
    default:
      return name.capitalized
    }
  }

  private func showError(_ message: String) {
    errorMessage = message
    showingError = true
  }

  private func loadModelsFromRepository() async {
    do {
      let models = try await repository.getAllModels()
      let downloaded = models.filter { $0.isDownloaded }
      downloadedModels = Set(downloaded.map { $0.name })

      if let selected = models.first(where: { $0.isSelected }) {
        selectedModel = selected.name
      }
    } catch {
      showError("Failed to load models: \(error.localizedDescription)")
    }
  }
}

extension ModelVariant {
  static var multilingualCases: [ModelVariant] {
    return allCases.filter { $0.isMultilingual }
  }

  var isRecommended: Bool {
    switch self {
    case .largev3, .medium, .small:
      return true
    default:
      return false
    }
  }
}
