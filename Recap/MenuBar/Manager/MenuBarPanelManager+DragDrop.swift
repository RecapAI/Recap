import AppKit
import SwiftUI

extension MenuBarPanelManager {
  func createDragDropPanel() -> SlidingPanel? {
    let contentView = DragDropView(
      viewModel: dragDropViewModel
    ) { [weak self] in
      self?.hideDragDropPanel()
    }
    let hostingController = NSHostingController(rootView: contentView)
    hostingController.view.wantsLayer = true
    hostingController.view.layer?.cornerRadius = 12

    let newPanel = SlidingPanel(
      contentViewController: hostingController,
      shouldCloseOnOutsideClick: false
    )
    newPanel.panelDelegate = self
    return newPanel
  }

  func positionDragDropPanel(_ panel: NSPanel) {
    guard let statusButton = statusBarManager.statusButton,
      let statusWindow = statusButton.window,
      let screen = statusWindow.screen
    else { return }

    let screenFrame = screen.frame
    let dragDropX = screenFrame.maxX - (initialSize.width * 2) - (panelOffset * 2) - panelSpacing
    let panelY = screenFrame.maxY - menuBarHeight - initialSize.height - panelSpacing

    panel.setFrame(
      NSRect(x: dragDropX, y: panelY, width: initialSize.width, height: initialSize.height),
      display: false
    )
  }

  func showDragDropPanel() {
    if dragDropPanel == nil {
      dragDropPanel = createDragDropPanel()
    }

    guard let dragDropPanel = dragDropPanel else { return }

    positionDragDropPanel(dragDropPanel)
    dragDropPanel.contentView?.wantsLayer = true

    PanelAnimator.slideIn(panel: dragDropPanel) { [weak self] in
      self?.isDragDropVisible = true
    }
  }

  func hideDragDropPanel() {
    guard let dragDropPanel = dragDropPanel else { return }

    PanelAnimator.slideOut(panel: dragDropPanel) { [weak self] in
      self?.isDragDropVisible = false
    }
  }
}
