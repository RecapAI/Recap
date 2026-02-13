import AppKit
import SwiftUI

extension MenuBarPanelManager {
  func createSummaryPanel(recordingID: String? = nil) -> SlidingPanel? {
    let contentView = SummaryView(
      onClose: { [weak self] in
        self?.hideSummaryPanel()
      },
      viewModel: summaryViewModel,
      recordingID: recordingID
    )
    let hostingController = NSHostingController(rootView: contentView)
    hostingController.view.wantsLayer = true
    hostingController.view.layer?.cornerRadius = 12

    let newPanel = SlidingPanel(contentViewController: hostingController)
    newPanel.panelDelegate = self
    return newPanel
  }

  func positionSummaryPanel(_ panel: NSPanel) {
    guard let statusButton = statusBarManager.statusButton,
      let statusWindow = statusButton.window,
      let screen = statusWindow.screen
    else { return }

    let screenFrame = screen.frame
    let summaryWidth: CGFloat = 600
    let summaryX =
      screenFrame.maxX - initialSize.width - summaryWidth - (panelOffset * 2) - panelSpacing
    let panelY = screenFrame.maxY - menuBarHeight - initialSize.height - panelSpacing

    panel.setFrame(
      NSRect(x: summaryX, y: panelY, width: summaryWidth, height: initialSize.height),
      display: false
    )
  }

  func showSummaryPanel(recordingID: String? = nil) {
    if summaryPanel == nil {
      summaryPanel = createSummaryPanel(recordingID: recordingID)
    }

    guard let summaryPanel = summaryPanel else { return }

    positionSummaryPanel(summaryPanel)
    summaryPanel.contentView?.wantsLayer = true

    PanelAnimator.slideIn(panel: summaryPanel) { [weak self] in
      self?.isSummaryVisible = true
    }
  }

  func hideSummaryPanel() {
    guard let summaryPanel = summaryPanel else { return }

    PanelAnimator.slideOut(panel: summaryPanel) { [weak self] in
      self?.isSummaryVisible = false
    }
  }
}
