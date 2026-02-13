import OSLog
import SwiftUI

private let summaryActionButtonPreviewLogger = Logger(
  subsystem: AppConstants.Logging.subsystem,
  category: "SummaryActionButtonPreview"
)

struct SummaryActionButton: View {
  let text: String
  let icon: String
  let action: () -> Void
  let isSecondary: Bool

  init(
    text: String,
    icon: String,
    isSecondary: Bool = false,
    action: @escaping () -> Void
  ) {
    self.text = text
    self.icon = icon
    self.isSecondary = isSecondary
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(systemName: icon)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(textColor)

        Text(text)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(textColor)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .frame(minWidth: 120)
      .background(backgroundGradient)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(borderGradient, lineWidth: 0.8)
      )
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .buttonStyle(PlainButtonStyle())
  }

  private var textColor: Color {
    isSecondary ? UIConstants.Colors.textSecondary : UIConstants.Colors.textPrimary
  }

  private var backgroundGradient: LinearGradient {
    if isSecondary {
      return LinearGradient(
        gradient: Gradient(colors: [Color.clear]),
        startPoint: .top,
        endPoint: .bottom
      )
    } else {
      return LinearGradient(
        gradient: Gradient(stops: [
          .init(color: Color(hex: "4A4A4A").opacity(0.3), location: 0),
          .init(color: Color(hex: "2A2A2A").opacity(0.5), location: 1)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    }
  }

  private var borderGradient: LinearGradient {
    if isSecondary {
      return LinearGradient(
        gradient: Gradient(stops: [
          .init(color: Color(hex: "979797").opacity(0.25), location: 0),
          .init(color: Color(hex: "979797").opacity(0.15), location: 1)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    } else {
      return LinearGradient(
        gradient: Gradient(stops: [
          .init(color: Color(hex: "979797").opacity(0.4), location: 0),
          .init(color: Color(hex: "979797").opacity(0.25), location: 1)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    }
  }
}

#Preview {
  VStack(spacing: 16) {
    HStack(spacing: 12) {
      SummaryActionButton(
        text: "Copy",
        icon: "doc.on.doc"
      ) {
        summaryActionButtonPreviewLogger.info("Copy tapped")
      }

      SummaryActionButton(
        text: "Retry",
        icon: "arrow.clockwise",
        isSecondary: true
      ) {
        summaryActionButtonPreviewLogger.info("Retry tapped")
      }
    }

    Text("Example in summary view context")
      .foregroundColor(.white.opacity(0.7))
      .font(.caption)
  }
  .padding(40)
  .background(Color.black)
}
