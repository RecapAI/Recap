import Foundation

@MainActor
final class AppSelectionCoordinator: AppSelectionCoordinatorType {
  private let appSelectionViewModel: AppSelectionViewModel
  weak var delegate: AppSelectionCoordinatorDelegate?

  init(appSelectionViewModel: AppSelectionViewModel) {
    self.appSelectionViewModel = appSelectionViewModel
    self.appSelectionViewModel.delegate = self
  }

  func autoSelectApp(_ app: AudioProcess) {
    let selectableApp = SelectableApp(from: app)
    appSelectionViewModel.selectApp(selectableApp)
  }
}

extension AppSelectionCoordinator: AppSelectionDelegate {
  func didSelectApp(_ app: AudioProcess) {
    delegate?.didSelectApp(app)
  }

  func didClearAppSelection() {
    delegate?.didClearAppSelection()
  }
}
