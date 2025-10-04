import AppKit
import SwiftUI

extension MenuBarPanelManager {
  func createSettingsPanel() -> SlidingPanel? {
    let contentView = SettingsView(
      whisperModelsViewModel: whisperModelsViewModel,
      generalSettingsViewModel: generalSettingsViewModel,
      meetingDetectionService: meetingDetectionService,
      userPreferencesRepository: userPreferencesRepository,
      recapViewModel: recapViewModel
    ) { [weak self] in
      self?.hideSettingsPanel()
    }
    let hostingController = NSHostingController(rootView: contentView)
    hostingController.view.wantsLayer = true
    hostingController.view.layer?.cornerRadius = 12

    let newPanel = SlidingPanel(contentViewController: hostingController)
    newPanel.panelDelegate = self
    return newPanel
  }

  func positionSettingsPanel(_ panel: NSPanel) {
    guard let statusButton = statusBarManager.statusButton,
      let statusWindow = statusButton.window,
      let screen = statusWindow.screen
    else { return }

    let screenFrame = screen.frame
    let settingsX = screenFrame.maxX - (initialSize.width * 2) - (panelOffset * 2) - panelSpacing
    let panelY = screenFrame.maxY - menuBarHeight - initialSize.height - panelSpacing

    panel.setFrame(
      NSRect(x: settingsX, y: panelY, width: initialSize.width, height: initialSize.height),
      display: false
    )
  }

  func showSettingsPanel() {
    if settingsPanel == nil {
      settingsPanel = createSettingsPanel()
    }

    guard let settingsPanel = settingsPanel else { return }

    positionSettingsPanel(settingsPanel)
    settingsPanel.contentView?.wantsLayer = true

    PanelAnimator.slideIn(panel: settingsPanel) { [weak self] in
      self?.isSettingsVisible = true
    }
  }

  func hideSettingsPanel() {
    guard let settingsPanel = settingsPanel else { return }

    PanelAnimator.slideOut(panel: settingsPanel) { [weak self] in
      self?.isSettingsVisible = false
    }
  }
}

extension MenuBarPanelManager: RecapViewModelDelegate {
  func didRequestSettingsOpen() {
    // Hide main panel and show only settings panel
    if isVisible {
      hidePanel()
    }
    toggleSidePanel(
      isVisible: isSettingsVisible,
      show: showSettingsPanel,
      hide: hideSettingsPanel
    )
  }

  func didRequestViewOpen() {
    toggleSidePanel(
      isVisible: isSummaryVisible,
      show: { showSummaryPanel() },
      hide: hideSummaryPanel
    )
  }

  func didRequestPreviousRecapsOpen() {
    toggleSidePanel(
      isVisible: isPreviousRecapsVisible,
      show: showPreviousRecapsWindow,
      hide: hidePreviousRecapsWindow
    )
  }

  func didRequestPanelClose() {
    hideMainPanel()
  }
}
