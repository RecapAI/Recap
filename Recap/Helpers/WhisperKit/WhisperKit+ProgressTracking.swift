import Foundation
import Hub
import WhisperKit

struct ModelSizeInfo {
  let modelName: String
  let totalSizeMB: Double
  let fileCount: Int
  let isEstimate: Bool
}

// whisperkit has builtin progress tracking, yet the source code does not expose callback, workaround
extension WhisperKit {

  static func getModelSizeInfo(for modelName: String) async -> ModelSizeInfo {
    do {
      let hubApi = HubApi()
      let repo = Hub.Repo(id: "argmaxinc/whisperkit-coreml", type: .models)
      let modelSearchPath = "*\(modelName)*/*"

      let fileMetadata = try await hubApi.getFileMetadata(
        from: repo, matching: [modelSearchPath])

      let totalBytes = fileMetadata.reduce(0) { total, metadata in
        total + (metadata.size ?? 0)
      }
      let totalSizeMB = Double(totalBytes) / Constants.bytesToMBDivisor

      return ModelSizeInfo(
        modelName: modelName,
        totalSizeMB: totalSizeMB,
        fileCount: fileMetadata.count,
        isEstimate: false
      )
    } catch {
      let size = Constants.fallbackModelSizes[modelName] ?? Constants.defaultModelSizeMB
      return ModelSizeInfo(
        modelName: modelName,
        totalSizeMB: size,
        fileCount: Constants.defaultFileCount,
        isEstimate: true
      )
    }
  }

  static func createWithProgress(
    model: String?,
    downloadBase: URL? = nil,
    modelRepo: String? = nil,
    modelToken: String? = nil,
    modelFolder: String? = nil,
    download: Bool = true,
    progressCallback: @escaping (Progress) -> Void
  ) async throws -> WhisperKit {

    var actualModelFolder = modelFolder

    if actualModelFolder == nil && download {
      let repo = modelRepo ?? "argmaxinc/whisperkit-coreml"
      let modelSupport = await WhisperKit.recommendedRemoteModels(
        from: repo, downloadBase: downloadBase)
      let modelVariant = model ?? modelSupport.default

      do {
        let downloadedFolder = try await WhisperKit.download(
          variant: modelVariant,
          downloadBase: downloadBase,
          useBackgroundSession: false,
          from: repo,
          token: modelToken,
          progressCallback: progressCallback
        )
        actualModelFolder = downloadedFolder.path
      } catch {
        throw WhisperError.modelsUnavailable(
          """
          Model not found. Please check the model or repo name and try again.
          Error: \(error)
          """)
      }
    }

    let config = WhisperKitConfig(
      model: model,
      downloadBase: downloadBase,
      modelRepo: modelRepo,
      modelToken: modelToken,
      modelFolder: actualModelFolder,
      download: false
    )

    return try await WhisperKit(config)
  }
}

extension WhisperKit {
  fileprivate enum Constants {
    // estimates from official repo
    static let fallbackModelSizes: [String: Double] = [
      "tiny": 218,
      "base": 279,
      "small": 1342,
      "medium": 2917,
      "large-v2": 7812,
      "large-v3": 16793,
      "distil-whisper_distil-large-v3_turbo": 2035
    ]

    static let defaultModelSizeMB: Double = 500.0
    static let defaultFileCount: Int = 6
    static let bytesToMBDivisor: Double = 1024 * 1024
  }
}
