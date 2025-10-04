import AppKit
import Foundation

struct SelectableApp: Identifiable, Hashable {
  let id: pid_t
  let name: String
  let icon: NSImage
  let isMeetingApp: Bool
  let isAudioActive: Bool
  let isSystemWide: Bool
  private let originalAudioProcess: AudioProcess?

  init(from audioProcess: AudioProcess) {
    self.id = audioProcess.id
    self.name = audioProcess.name
    self.icon = audioProcess.icon
    self.isMeetingApp = audioProcess.isMeetingApp
    self.isAudioActive = audioProcess.audioActive
    self.isSystemWide = false
    self.originalAudioProcess = audioProcess
  }

  private init(systemWide: Bool) {
    self.id = -1
    self.name = "All Apps"
    self.icon = NSWorkspace.shared.icon(for: .wav)
    self.isMeetingApp = false
    self.isAudioActive = true
    self.isSystemWide = true
    self.originalAudioProcess = nil
  }

  static let allApps = SelectableApp(systemWide: true)

  var audioProcess: AudioProcess {
    guard let originalAudioProcess = originalAudioProcess else {
      return AudioProcess(
        id: -1,
        kind: .app,
        name: "All Apps",
        audioActive: true,
        bundleID: nil,
        bundleURL: nil,
        objectID: .unknown
      )
    }
    return originalAudioProcess
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(name)
  }

  static func == (lhs: SelectableApp, rhs: SelectableApp) -> Bool {
    lhs.id == rhs.id && lhs.name == rhs.name
  }
}

enum AppSelectionState {
  case noSelection
  case selected(SelectableApp)
  case showingDropdown
}

extension AppSelectionState {
  var selectedApp: SelectableApp? {
    if case .selected(let app) = self {
      return app
    }
    return nil
  }

  var isShowingDropdown: Bool {
    if case .showingDropdown = self {
      return true
    }
    return false
  }

  var hasSelection: Bool {
    if case .selected = self {
      return true
    }
    return false
  }
}
