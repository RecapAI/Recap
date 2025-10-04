//
//  ReflectionCard.swift
//  Recap
//
//  Created by Rawand Ahmad on 25/07/2025.
//

import SwiftUI

struct CustomReflectionCard: View {
  let containerWidth: CGFloat
  @ObservedObject private var appSelectionViewModel: AppSelectionViewModel
  let isRecording: Bool
  let recordingDuration: TimeInterval
  let canStartRecording: Bool
  let onToggleRecording: () -> Void

  init(
    containerWidth: CGFloat,
    appSelectionViewModel: AppSelectionViewModel,
    isRecording: Bool,
    recordingDuration: TimeInterval,
    canStartRecording: Bool,
    onToggleRecording: @escaping () -> Void
  ) {
    self.containerWidth = containerWidth
    self.appSelectionViewModel = appSelectionViewModel
    self.isRecording = isRecording
    self.recordingDuration = recordingDuration
    self.canStartRecording = canStartRecording
    self.onToggleRecording = onToggleRecording
  }

  var body: some View {
    CardBackground(
      width: UIConstants.Layout.fullCardWidth(containerWidth: containerWidth),
      height: 60,
      backgroundColor: UIConstants.Colors.cardBackground2,
      borderGradient: isRecording
        ? UIConstants.Gradients.reflectionBorderRecording
        : UIConstants.Gradients.reflectionBorder
    )
    .overlay(
      HStack {
        AppSelectionButton(viewModel: appSelectionViewModel)
          .padding(.leading, UIConstants.Spacing.cardSpacing)

        Spacer()

        RecordingButton(
          isRecording: isRecording,
          recordingDuration: recordingDuration,
          isEnabled: canStartRecording,
          onToggleRecording: onToggleRecording
        )
        .padding(.trailing, UIConstants.Spacing.cardSpacing)
      }
    )
    .animation(.easeInOut(duration: 0.3), value: isRecording)
    .onAppear {
      appSelectionViewModel.refreshAvailableApps()
    }
  }
}
