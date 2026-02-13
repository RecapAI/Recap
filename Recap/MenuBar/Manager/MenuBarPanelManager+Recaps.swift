import AppKit
import SwiftUI

extension MenuBarPanelManager {
  func createRecapsPanel() -> SlidingPanel? {
    let contentView = PreviousRecapsDropdown(
      viewModel: previousRecapsViewModel,
      onRecordingSelected: { [weak self] recording in
        self?.handleRecordingSelection(recording)
      },
      onClose: { [weak self] in
        self?.hideRecapsPanel()
      }
    )
    let hostingController = NSHostingController(rootView: contentView)
    hostingController.view.wantsLayer = true
    hostingController.view.layer?.cornerRadius = 12

    let newPanel = SlidingPanel(contentViewController: hostingController)
    newPanel.panelDelegate = self
    return newPanel
  }

  func positionRecapsPanel(_ panel: NSPanel) {
    guard let statusButton = statusBarManager.statusButton,
      let statusWindow = statusButton.window,
      let screen = statusWindow.screen
    else { return }

    let screenFrame = screen.frame
    let recapsX = screenFrame.maxX - initialSize.width - panelOffset
    let panelY = screenFrame.maxY - menuBarHeight - initialSize.height - panelSpacing

    panel.setFrame(
      NSRect(x: recapsX, y: panelY, width: initialSize.width, height: initialSize.height),
      display: false
    )
  }

  func showRecapsPanel() {
    if recapsPanel == nil {
      recapsPanel = createRecapsPanel()
    }

    guard let recapsPanel = recapsPanel else { return }

    positionRecapsPanel(recapsPanel)
    recapsPanel.contentView?.wantsLayer = true

    PanelAnimator.slideIn(panel: recapsPanel) { [weak self] in
      self?.isRecapsVisible = true
    }
  }

  func hideRecapsPanel() {
    guard let recapsPanel = recapsPanel else { return }

    PanelAnimator.slideOut(panel: recapsPanel) { [weak self] in
      self?.isRecapsVisible = false
    }
  }

  private func handleRecordingSelection(_ recording: RecordingInfo) {
    hideRecapsPanel()

    summaryPanel?.close()
    summaryPanel = nil

    showSummaryPanel(recordingID: recording.id)
  }
}
