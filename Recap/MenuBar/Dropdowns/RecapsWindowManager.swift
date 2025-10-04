import AppKit
import SwiftUI

@MainActor
final class RecapsWindowManager: ObservableObject {
  private var recapsWindow: NSPanel?
  private let windowWidth: CGFloat = 380
  private let windowHeight: CGFloat = 500

  func showRecapsWindow(
    relativeTo button: NSView,
    viewModel: PreviousRecapsViewModel,
    onRecordingSelected: @escaping (RecordingInfo) -> Void,
    onDismiss: @escaping () -> Void
  ) {
    hideRecapsWindow()

    let contentView = PreviousRecapsDropdown(
      viewModel: viewModel,
      onRecordingSelected: { recording in
        onRecordingSelected(recording)
        self.hideRecapsWindow()
      },
      onClose: { [weak self] in
        onDismiss()
        self?.hideRecapsWindow()
      }
    )

    let hostingController = NSHostingController(rootView: contentView)
    hostingController.view.wantsLayer = true

    let window = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    hostingController.view.frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)

    window.contentViewController = hostingController
    window.backgroundColor = .clear
    window.isOpaque = false
    window.hasShadow = true
    window.level = .floating
    window.isReleasedWhenClosed = false

    positionRecapsWindow(window: window, relativeTo: button)

    recapsWindow = window

    PanelAnimator.slideIn(panel: window)
    setupOutsideClickDetection(onDismiss: onDismiss)
  }

  func hideRecapsWindow() {
    guard let window = recapsWindow else { return }

    PanelAnimator.slideOut(panel: window) { [weak self] in
      self?.recapsWindow = nil
    }

    if let monitor = globalMonitor {
      NSEvent.removeMonitor(monitor)
      globalMonitor = nil
    }
  }

  private var globalMonitor: Any?

  private func setupOutsideClickDetection(onDismiss: @escaping () -> Void) {
    globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
      onDismiss()
      self.hideRecapsWindow()
    }
  }

  private func positionRecapsWindow(window: NSPanel, relativeTo button: NSView) {
    guard let buttonWindow = button.window,
      let screen = buttonWindow.screen
    else { return }

    let screenFrame = screen.frame

    let menuBarHeight: CGFloat = 24
    let panelOffset: CGFloat = 12
    let panelSpacing: CGFloat = 8
    let mainPanelWidth: CGFloat = 485

    let recapsX = screenFrame.maxX - mainPanelWidth - windowWidth - (panelOffset * 2) - panelSpacing
    let recapsY = screenFrame.maxY - menuBarHeight - windowHeight - panelSpacing

    window.setFrameOrigin(NSPoint(x: recapsX, y: recapsY))
  }
}
