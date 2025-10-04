import AppKit

@MainActor
protocol SlidingPanelType: AnyObject {
  var panelDelegate: SlidingPanelDelegate? { get set }
  var contentView: NSView? { get }

  func setFrame(_ frameRect: NSRect, display flag: Bool)
}
