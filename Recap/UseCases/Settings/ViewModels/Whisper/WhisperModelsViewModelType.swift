import SwiftUI

@MainActor
protocol WhisperModelsViewModelType: ObservableObject {
  var selectedModel: String? { get }
  var downloadedModels: Set<String> { get }
  var downloadingModels: Set<String> { get }
  var downloadProgress: [String: Double] { get }
  var showingTooltipForModel: String? { get }
  var tooltipPosition: CGPoint { get }
  var errorMessage: String? { get }
  var showingError: Bool { get }
  var recommendedModels: [String] { get }
  var otherModels: [String] { get }

  func selectModel(_ modelName: String)
  func downloadModel(_ modelName: String)
  func toggleTooltip(for modelName: String, at position: CGPoint)
  func getModelInfo(_ name: String) -> ModelInfo?
  func modelDisplayName(_ name: String) -> String
}
