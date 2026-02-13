import Foundation

@MainActor
protocol DragDropViewModelType: ObservableObject {
  var transcriptEnabled: Bool { get set }
  var summarizeEnabled: Bool { get set }
  var isProcessing: Bool { get }
  var errorMessage: String? { get }
  var successMessage: String? { get }

  func handleDroppedFile(url: URL) async
}
