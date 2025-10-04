//
//  CardBackground.swift
//  Recap
//
//  Created by Rawand Ahmad on 25/07/2025.
//

import SwiftUI

struct CardBackground: View {
  let width: CGFloat
  let height: CGFloat
  let backgroundColor: Color
  let borderGradient: LinearGradient

  private var safeWidth: CGFloat {
    max(width, 50)
  }

  private var safeHeight: CGFloat {
    max(height, 50)
  }

  var body: some View {
    RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius)
      .fill(backgroundColor)
      .frame(width: safeWidth, height: safeHeight)
      .overlay(
        RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius)
          .stroke(borderGradient, lineWidth: UIConstants.Sizing.borderWidth)
      )
  }
}
