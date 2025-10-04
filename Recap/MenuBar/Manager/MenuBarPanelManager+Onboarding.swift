import AppKit
import SwiftUI

extension MenuBarPanelManager {
  @MainActor
  func createOnboardingPanel() -> SlidingPanel {
    onboardingViewModel.delegate = self
    let contentView = OnboardingView(viewModel: onboardingViewModel)
    let hostingController = NSHostingController(rootView: contentView)
    hostingController.view.wantsLayer = true
    hostingController.view.layer?.cornerRadius = 12

    let newPanel = SlidingPanel(contentViewController: hostingController)
    newPanel.panelDelegate = self
    return newPanel
  }
}
