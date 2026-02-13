import Foundation

@MainActor
protocol AppSelectionDelegate: AnyObject {
  func didSelectApp(_ app: AudioProcess)
  func didClearAppSelection()
}

@MainActor
protocol AppAutoSelectionDelegate: AnyObject {
  func autoSelectApp(_ app: AudioProcess)
}

@MainActor
protocol AppSelectionViewModelType: ObservableObject {
  var state: AppSelectionState { get }
  var availableApps: [SelectableApp] { get }
  var meetingApps: [SelectableApp] { get }
  var otherApps: [SelectableApp] { get }
  var isAudioFilterEnabled: Bool { get set }
  var audioProcessController: any AudioProcessControllerType { get }

  func toggleDropdown()
  func selectApp(_ app: SelectableApp)
  func clearSelection()
  func toggleAudioFilter()
  func refreshAvailableApps()

  var delegate: AppSelectionDelegate? { get set }
}
