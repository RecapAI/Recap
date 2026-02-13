import Foundation

@MainActor
final class AppSelectionViewModel: AppSelectionViewModelType {
  @Published private(set) var state: AppSelectionState = .noSelection
  @Published private(set) var availableApps: [SelectableApp] = []
  @Published private(set) var meetingApps: [SelectableApp] = []
  @Published private(set) var otherApps: [SelectableApp] = []
  @Published var isAudioFilterEnabled = true

  private(set) var audioProcessController: any AudioProcessControllerType
  weak var delegate: AppSelectionDelegate?
  weak var autoSelectionDelegate: AppAutoSelectionDelegate?
  private var selectedApp: SelectableApp?

  init(audioProcessController: any AudioProcessControllerType) {
    self.audioProcessController = audioProcessController

    setupBindings()
    audioProcessController.activate()
  }

  func toggleDropdown() {
    switch state {
    case .noSelection:
      state = .showingDropdown
    case .selected(let app):
      selectedApp = app
      state = .showingDropdown
    case .showingDropdown:
      if let app = selectedApp {
        state = .selected(app)
      } else {
        state = .noSelection
      }
    }
  }

  func selectApp(_ app: SelectableApp) {
    selectedApp = app
    state = .selected(app)
    delegate?.didSelectApp(app.audioProcess)
  }

  func clearSelection() {
    selectedApp = nil
    state = .noSelection
    delegate?.didClearAppSelection()
  }

  func closeDropdown() {
    if case .showingDropdown = state {
      state = .noSelection
    }
  }

  func toggleAudioFilter() {
    isAudioFilterEnabled.toggle()
    updateAvailableApps()
  }

  private func setupBindings() {
    updateAvailableApps()
  }

  func refreshAvailableApps() {
    updateAvailableApps()
  }

  private func updateAvailableApps() {
    let filteredProcesses =
      isAudioFilterEnabled
      ? audioProcessController.processes.filter(\.audioActive)
      : audioProcessController.processes

    let sortedApps =
      filteredProcesses
      .map(SelectableApp.init)
      .sorted { lhs, rhs in
        if lhs.isMeetingApp != rhs.isMeetingApp {
          return lhs.isMeetingApp
        }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
      }

    availableApps = [SelectableApp.allApps] + sortedApps
    meetingApps = sortedApps.filter(\.isMeetingApp)
    otherApps = sortedApps.filter { !$0.isMeetingApp }
  }
}
