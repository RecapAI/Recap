//
//  TranscriptionCard.swift
//  Recap
//
//  Created by Rawand Ahmad on 25/07/2025.
//

import SwiftUI

struct TranscriptionCard: View {
  let containerWidth: CGFloat
  let onViewTap: () -> Void

  var body: some View {
    CardBackground(
      width: UIConstants.Layout.fullCardWidth(containerWidth: containerWidth),
      height: 80,
      backgroundColor: UIConstants.Colors.cardBackground2,
      borderGradient: UIConstants.Gradients.standardBorder
    )
    .overlay(
      VStack(spacing: 12) {
        HStack {
          VStack(alignment: .leading, spacing: UIConstants.Spacing.cardInternalSpacing) {
            Text("Latest Meeting Summary")
              .font(UIConstants.Typography.transcriptionTitle)
              .foregroundColor(UIConstants.Colors.textPrimary)
            Text("View your latest meeting summary!")
              .font(UIConstants.Typography.bodyText)
              .foregroundColor(UIConstants.Colors.textTertiary)
          }
          Spacer()

          PillButton(text: "View", icon: "square.arrowtriangle.4.outward") {
            onViewTap()
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
    )
  }
}
