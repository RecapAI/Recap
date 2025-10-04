//
//  InformationCard.swift
//  Recap
//
//  Created by Rawand Ahmad on 25/07/2025.
//

import SwiftUI

struct InformationCard: View {
  let icon: String
  let title: String
  let description: String
  let containerWidth: CGFloat

  var body: some View {
    CardBackground(
      width: UIConstants.Layout.infoCardWidth(containerWidth: containerWidth),
      height: 100,
      backgroundColor: UIConstants.Colors.cardBackground2,
      borderGradient: UIConstants.Gradients.standardBorder
    )
    .overlay(
      VStack(alignment: .leading, spacing: 8) {
        Image(systemName: icon)
          .font(UIConstants.Typography.infoIconFont)
          .foregroundStyle(UIConstants.Gradients.iconGradient)

        Text(title)
          .font(UIConstants.Typography.infoCardTitle)
          .foregroundColor(UIConstants.Colors.textPrimary)
          .frame(maxWidth: .infinity, alignment: .leading)

        Text(description)
          .font(UIConstants.Typography.bodyText)
          .foregroundColor(UIConstants.Colors.textTertiary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 16)
    )
    .contentShape(Rectangle())
  }
}
