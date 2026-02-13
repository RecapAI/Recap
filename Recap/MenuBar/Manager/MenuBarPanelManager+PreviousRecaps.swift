import AppKit
import SwiftUI

extension MenuBarPanelManager {
  func showPreviousRecapsWindow() {
    if previousRecapsWindowManager == nil {
      previousRecapsWindowManager = RecapsWindowManager()
    }

    guard let statusButton = statusBarManager.statusButton,
      let windowManager = previousRecapsWindowManager
    else { return }

    windowManager.showRecapsWindow(
      relativeTo: statusButton,
      viewModel: previousRecapsViewModel,
      onRecordingSelected: { [weak self] recording in
        self?.handleRecordingSelection(recording)
      },
      onDismiss: { [weak self] in
        self?.isPreviousRecapsVisible = false
      }
    )

    isPreviousRecapsVisible = true
  }

  func hidePreviousRecapsWindow() {
    previousRecapsWindowManager?.hideRecapsWindow()
    isPreviousRecapsVisible = false
  }

  private func handleRecordingSelection(_ recording: RecordingInfo) {
    hidePreviousRecapsWindow()

    summaryPanel?.close()
    summaryPanel = nil

    showSummaryPanel(recordingID: recording.id)
  }
}

extension MenuBarPanelManager {
  func hideOtherPanels() {
    if isSettingsVisible {
      hideSettingsPanel()
    }
    if isSummaryVisible {
      hideSummaryPanel()
    }
  }
}
