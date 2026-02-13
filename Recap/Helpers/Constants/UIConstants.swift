//
//  UIConstants.swift
//  Recap
//
//  Created by Rawand Ahmad on 25/07/2025.
//

import SwiftUI

struct UIConstants {

  struct Colors {
    static let backgroundGradientStart = Color(hex: "050507")
    static let backgroundGradientMiddle = Color(hex: "020202").opacity(0.45)
    static let backgroundGradientLightMiddle = Color(hex: "0A0A0A")
    static let backgroundGradientEnd = Color(hex: "020202")

    static let cardBackground1 = Color(hex: "474747").opacity(0.1)
    static let cardBackground2 = Color(hex: "0F0F0F").opacity(0.18)
    static let cardBackground3 = Color(hex: "050505").opacity(0.5)
    static let cardSecondaryBackground = Color(hex: "242323").opacity(0.4)

    static let borderStart = Color(hex: "979797").opacity(0.06)
    static let borderEnd = Color(hex: "C4C4C4").opacity(0.12)
    static let borderMid = Color(hex: "979797").opacity(0.08)

    static let audioActive = Color(hex: "9EFF36").opacity(0.6)
    static let audioInactive = Color(hex: "252525")
    static let audioGreen = Color(hex: "9EFF36")

    static let selectionStroke = Color(hex: "979797").opacity(0.5)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
  }

  struct Gradients {
    static let backgroundGradient = LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Colors.backgroundGradientStart, location: 0),
        .init(color: Colors.backgroundGradientMiddle, location: 0.4),
        .init(color: Colors.backgroundGradientEnd, location: 1)
      ]),
      startPoint: .bottomLeading,
      endPoint: .topTrailing
    )

    static let standardBorder = LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Colors.borderStart, location: 0),
        .init(color: Colors.borderEnd, location: 1)
      ]),
      startPoint: .top,
      endPoint: .bottom
    )

    static let reflectionBorder = LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Colors.audioGreen.opacity(0.15), location: 0),
        .init(color: Colors.borderMid, location: 0.3),
        .init(color: Colors.borderEnd, location: 1)
      ]),
      startPoint: .top,
      endPoint: .bottom
    )

    static let reflectionBorderRecording = LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Color.red.opacity(0.4), location: 0),
        .init(color: Colors.borderMid, location: 0.3),
        .init(color: Colors.borderEnd, location: 1)
      ]),
      startPoint: .top,
      endPoint: .bottom
    )

    static let iconGradient = LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Color(hex: "979797").opacity(0.01), location: 0),
        .init(color: Color.white.opacity(0.50), location: 0.5),
        .init(color: Color.white, location: 1)
      ]),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )

    static let dropdownBackground = LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Colors.backgroundGradientStart, location: 0),
        .init(color: Colors.backgroundGradientLightMiddle, location: 0.4),
        .init(color: Colors.backgroundGradientEnd, location: 1)
      ]),
      startPoint: .bottomLeading,
      endPoint: .topTrailing
    )

    static let summarySeparator = LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Color.clear, location: 0),
        .init(color: Colors.borderMid.opacity(0.3), location: 0.3),
        .init(color: Colors.borderMid.opacity(0.6), location: 0.5),
        .init(color: Colors.borderMid.opacity(0.3), location: 0.7),
        .init(color: Color.clear, location: 1)
      ]),
      startPoint: .leading,
      endPoint: .trailing
    )

    static let summaryButtonBackground = LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Color.clear, location: 0),
        .init(color: Colors.backgroundGradientStart.opacity(0.08), location: 0.4),
        .init(color: Colors.backgroundGradientStart.opacity(0.05), location: 0.7),
        .init(color: Colors.backgroundGradientStart.opacity(0.10), location: 1)
      ]),
      startPoint: .top,
      endPoint: .bottom
    )
  }

  struct Spacing {
    static let cardSpacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let contentPadding: CGFloat = 30
    static let cardPadding: CGFloat = 10
    static let cardInternalSpacing: CGFloat = 6
    static let gridSpacing: CGFloat = 2
    static let gridCellSpacing: CGFloat = 4
  }

  struct Sizing {
    static let cornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 1.5
    static let borderWidth: CGFloat = 2
    static let strokeWidth: CGFloat = 1
    static let heatmapCellSize: CGFloat = 6
    static let selectionCircleSize: CGFloat = 16
    static let iconSize: CGFloat = 8
  }

  struct Typography {
    static let appTitle = Font.system(size: 24, weight: .bold)
    static let cardTitle = Font.system(size: 12, weight: .bold)
    static let infoCardTitle = Font.system(size: 16, weight: .bold)
    static let transcriptionTitle = Font.system(size: 12, weight: .bold)
    static let bodyText = Font.system(size: 10, weight: .regular)
    static let iconFont = Font.system(size: 8, weight: .bold)
    static let infoIconFont = Font.system(size: 24, weight: .bold)
  }

  struct Layout {
    static func cardWidth(containerWidth: CGFloat) -> CGFloat {
      max((containerWidth - 82) / 2, 50)
    }

    static func infoCardWidth(containerWidth: CGFloat) -> CGFloat {
      max((containerWidth - 75) / 2, 50)
    }

    static func fullCardWidth(containerWidth: CGFloat) -> CGFloat {
      max(containerWidth - 60, 100)
    }
  }
}
