import Foundation

@MainActor
protocol AppSelectionCoordinatorType {
  var delegate: AppSelectionCoordinatorDelegate? { get set }
  func autoSelectApp(_ app: AudioProcess)
}

@MainActor
protocol AppSelectionCoordinatorDelegate: AnyObject {
  func didSelectApp(_ app: AudioProcess)
  func didClearAppSelection()
}
