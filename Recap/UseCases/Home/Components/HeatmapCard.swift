//
//  HeatmapCard.swift
//  Recap
//
//  Created by Rawand Ahmad on 25/07/2025.
//

import SwiftUI

struct HeatmapCard: View {
  let title: String
  let containerWidth: CGFloat
  let isSelected: Bool
  let audioLevel: Float
  let isInteractionEnabled: Bool
  let onToggle: () -> Void

  var body: some View {
    CardBackground(
      width: UIConstants.Layout.cardWidth(containerWidth: containerWidth),
      height: 90,
      backgroundColor: UIConstants.Colors.cardBackground1,
      borderGradient: UIConstants.Gradients.standardBorder
    )
    .overlay(
      VStack(spacing: 2) {
        HeatmapGrid(audioLevel: audioLevel)
          .padding(.top, 14)

        Spacer()

        Rectangle()
          .fill(UIConstants.Colors.cardSecondaryBackground)
          .frame(height: 35)
          .overlay(
            HStack {
              Text(title)
                .foregroundColor(UIConstants.Colors.textPrimary)
                .font(UIConstants.Typography.cardTitle)

              Spacer()

              Circle()
                .stroke(
                  UIConstants.Colors.selectionStroke,
                  lineWidth: UIConstants.Sizing.strokeWidth
                )
                .frame(
                  width: UIConstants.Sizing.selectionCircleSize,
                  height: UIConstants.Sizing.selectionCircleSize
                )
                .overlay {
                  if isSelected {
                    Image(systemName: "checkmark")
                      .font(UIConstants.Typography.iconFont)
                      .foregroundColor(UIConstants.Colors.textPrimary)
                  }
                }
            }
            .padding(.horizontal, UIConstants.Spacing.cardPadding)
          )
      }
      .clipShape(RoundedRectangle(cornerRadius: 18))
    )
    .contentShape(RoundedRectangle(cornerRadius: 18))
    .onTapGesture {
      if isInteractionEnabled {
        onToggle()
      }
    }
    .opacity(isInteractionEnabled ? (isSelected ? 1.0 : 0.8) : 0.6)
    .animation(.easeInOut(duration: 0.2), value: isSelected)
    .animation(.easeInOut(duration: 0.2), value: isInteractionEnabled)
    .clipped()

  }
}

struct HeatmapGrid: View {
  let cols = 18
  let rows = 4
  let audioLevel: Float

  func cellOpacity(row: Int, col: Int) -> Double {
    let clampedLevel = min(max(audioLevel, 0), 1)
    guard clampedLevel > 0 else { return 0 }

    let rowFromBottom = rows - 1 - row
    let centerCol = Double(cols) / 2.0
    let distanceFromCenter = abs(Double(col) - centerCol + 0.5) / centerCol

    let baseWidthFactors = [1.0, 0.85, 0.65, 0.4]
    let baseWidthFactor = baseWidthFactors[min(rowFromBottom, baseWidthFactors.count - 1)]

    let rowThreshold = Double(rowFromBottom) / Double(rows)
    let levelProgress = Double(clampedLevel)

    guard levelProgress > rowThreshold else { return 0 }

    let rowIntensity = min((levelProgress - rowThreshold) * Double(rows), 1.0)

    let centerIntensity = 1.0 - pow(distanceFromCenter, 2.0)
    let widthThreshold = baseWidthFactor * rowIntensity

    guard distanceFromCenter < widthThreshold else { return 0 }

    let edgeFade = 1.0 - pow(distanceFromCenter / widthThreshold, 3.0)
    let intensity = rowIntensity * centerIntensity * edgeFade

    return intensity * 0.9
  }

  var body: some View {
    VStack(spacing: UIConstants.Spacing.gridCellSpacing) {
      ForEach(0..<rows, id: \.self) { row in
        HStack(spacing: UIConstants.Spacing.gridSpacing) {
          ForEach(0..<cols, id: \.self) { col in
            Rectangle()
              .fill(
                UIConstants.Colors.audioActive.opacity(
                  cellOpacity(row: row, col: col))
              )
              .background(UIConstants.Colors.audioInactive)
              .frame(
                width: UIConstants.Sizing.heatmapCellSize,
                height: UIConstants.Sizing.heatmapCellSize
              )
              .cornerRadius(UIConstants.Sizing.smallCornerRadius)
              .animation(.easeInOut(duration: 0.15), value: audioLevel)
          }
        }
      }
    }
  }
}
