import Foundation

@MainActor
protocol MenuBarPanelManagerType: ObservableObject {
  var isVisible: Bool { get }
  var isSettingsVisible: Bool { get }
  var isSummaryVisible: Bool { get }

  func toggleSidePanel(
    isVisible: Bool,
    show: () -> Void,
    hide: () -> Void
  )
}
