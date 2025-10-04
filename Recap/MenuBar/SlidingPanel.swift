import AppKit

@MainActor
protocol SlidingPanelDelegate: AnyObject {
  func panelDidReceiveClickOutside()
}

final class SlidingPanel: NSPanel, SlidingPanelType {
  weak var panelDelegate: SlidingPanelDelegate?
  private var eventMonitor: Any?
  var shouldCloseOnOutsideClick: Bool = true

  init(contentViewController: NSViewController, shouldCloseOnOutsideClick: Bool = true) {
    self.shouldCloseOnOutsideClick = shouldCloseOnOutsideClick
    super.init(
      contentRect: .zero,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    setupPanel(with: contentViewController)
    setupEventMonitoring()
  }

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }

  private func setupPanel(with contentViewController: NSViewController) {
    self.contentViewController = contentViewController
    self.level = .popUpMenu
    self.isOpaque = false
    self.backgroundColor = .clear
    self.hasShadow = true
    self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    self.animationBehavior = .none
    self.alphaValue = 0.0

    let containerView = createContainerView(with: contentViewController)
    self.contentView = containerView

    containerView.wantsLayer = true
    containerView.layer?.backgroundColor = NSColor.clear.cgColor
  }

  private func createContainerView(with contentViewController: NSViewController) -> NSView {
    let visualEffect = createVisualEffectView()
    let containerView = NSView()

    containerView.wantsLayer = true
    containerView.layer?.backgroundColor = NSColor.clear.cgColor

    containerView.addSubview(visualEffect)
    containerView.addSubview(contentViewController.view)

    setupVisualEffectConstraints(visualEffect, in: containerView)
    setupContentViewConstraints(contentViewController.view, in: containerView)

    return containerView
  }

  private func createVisualEffectView() -> NSVisualEffectView {
    let visualEffect = NSVisualEffectView()
    visualEffect.material = .popover
    visualEffect.blendingMode = .behindWindow
    visualEffect.state = .active
    visualEffect.wantsLayer = true
    visualEffect.layer?.cornerRadius = 12
    visualEffect.layer?.shouldRasterize = true
    visualEffect.layer?.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 2.0
    return visualEffect
  }

  private func setupEventMonitoring() {
    eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
      .leftMouseDown, .rightMouseDown
    ]) { [weak self] event in
      self?.handleGlobalClick(event)
    }
  }

  private func handleGlobalClick(_ event: NSEvent) {
    guard shouldCloseOnOutsideClick else { return }
    let globalLocation = NSEvent.mouseLocation
    if !self.frame.contains(globalLocation) {
      panelDelegate?.panelDidReceiveClickOutside()
    }
  }

  deinit {
    if let eventMonitor = eventMonitor {
      NSEvent.removeMonitor(eventMonitor)
    }
  }
}

extension SlidingPanel {
  private func setupVisualEffectConstraints(
    _ visualEffect: NSVisualEffectView, in container: NSView
  ) {
    visualEffect.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      visualEffect.topAnchor.constraint(equalTo: container.topAnchor),
      visualEffect.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      visualEffect.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      visualEffect.trailingAnchor.constraint(equalTo: container.trailingAnchor)
    ])
  }

  private func setupContentViewConstraints(_ contentView: NSView, in container: NSView) {
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.wantsLayer = true

    NSLayoutConstraint.activate([
      contentView.topAnchor.constraint(equalTo: container.topAnchor),
      contentView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      contentView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
    ])
  }
}
