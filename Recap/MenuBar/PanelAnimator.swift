import AppKit
import QuartzCore

struct PanelAnimator {
  private static let slideInDuration: CFTimeInterval = 0.3
  private static let slideOutDuration: CFTimeInterval = 0.2
  private static let translateOffset: CGFloat = 50

  static func slideIn(panel: NSPanel, completion: (() -> Void)? = nil) {
    guard let layer = panel.contentView?.layer else {
      completion?()
      return
    }

    let panelWidth = panel.frame.width
    let translateDistance = panelWidth + translateOffset

    layer.transform = CATransform3DMakeTranslation(translateDistance, 0, 0)
    panel.alphaValue = 1.0
    panel.makeKeyAndOrderFront(nil)

    let slideAnimation = CABasicAnimation(keyPath: "transform.translation.x")
    slideAnimation.fromValue = translateDistance
    slideAnimation.toValue = 0
    slideAnimation.duration = slideInDuration
    slideAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.46, 0.45, 0.94)
    slideAnimation.fillMode = .forwards
    slideAnimation.isRemovedOnCompletion = false

    CATransaction.begin()
    CATransaction.setCompletionBlock {
      completion?()
    }

    layer.add(slideAnimation, forKey: "slideIn")
    layer.transform = CATransform3DIdentity

    CATransaction.commit()
  }

  static func slideOut(panel: NSPanel, completion: (() -> Void)? = nil) {
    guard let layer = panel.contentView?.layer else {
      panel.orderOut(nil)
      completion?()
      return
    }

    let panelWidth = panel.frame.width
    let translateDistance = panelWidth + translateOffset

    let slideOutAnimation = CABasicAnimation(keyPath: "transform.translation.x")
    slideOutAnimation.fromValue = 0
    slideOutAnimation.toValue = translateDistance
    slideOutAnimation.duration = slideOutDuration
    slideOutAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.55, 0.06, 0.68, 0.19)
    slideOutAnimation.fillMode = .forwards
    slideOutAnimation.isRemovedOnCompletion = false

    CATransaction.begin()
    CATransaction.setCompletionBlock {
      panel.orderOut(nil)
      completion?()
    }

    layer.add(slideOutAnimation, forKey: "slideOut")
    layer.transform = CATransform3DMakeTranslation(translateDistance, 0, 0)

    CATransaction.commit()
  }
}
