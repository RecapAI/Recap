import AppKit
import SwiftUI

extension MenuBarPanelManager: OnboardingDelegate {
  func onboardingDidComplete() {
    Task {
      await transitionFromOnboardingToMain()
    }
  }

  private func transitionFromOnboardingToMain() async {
    guard let currentPanel = panel else { return }

    await slideOutCurrentPanel(currentPanel)
    await createAndShowMainPanel()
  }

  private func slideOutCurrentPanel(_ currentPanel: SlidingPanel) async {
    await withCheckedContinuation { continuation in
      PanelAnimator.slideOut(panel: currentPanel) { [weak self] in
        self?.panel = nil
        self?.isVisible = false
        continuation.resume()
      }
    }
  }

  private func createAndShowMainPanel() async {
    panel = createMainPanel()
    guard let newPanel = panel else { return }

    positionPanel(newPanel)

    await withCheckedContinuation { continuation in
      PanelAnimator.slideIn(panel: newPanel) { [weak self] in
        self?.isVisible = true
        continuation.resume()
      }
    }
  }
}
