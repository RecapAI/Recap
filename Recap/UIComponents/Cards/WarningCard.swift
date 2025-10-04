import SwiftUI

struct WarningCard: View {
  let warning: WarningItem
  let containerWidth: CGFloat

  init(warning: WarningItem, containerWidth: CGFloat) {
    self.warning = warning
    self.containerWidth = containerWidth
  }

  var body: some View {
    let severityColor = Color(hex: warning.severity.color)

    let cardBackground = LinearGradient(
      gradient: Gradient(stops: [
        .init(color: severityColor.opacity(0.1), location: 0),
        .init(color: severityColor.opacity(0.05), location: 1)
      ]),
      startPoint: .top,
      endPoint: .bottom
    )

    let cardBorder = LinearGradient(
      gradient: Gradient(stops: [
        .init(color: severityColor.opacity(0.3), location: 0),
        .init(color: severityColor.opacity(0.2), location: 1)
      ]),
      startPoint: .top,
      endPoint: .bottom
    )

    HStack(spacing: 12) {
      Image(systemName: warning.icon)
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(severityColor)

      VStack(alignment: .leading, spacing: 4) {
        Text(warning.title)
          .font(UIConstants.Typography.cardTitle)
          .foregroundColor(UIConstants.Colors.textPrimary)

        Text(warning.message)
          .font(.system(size: 10, weight: .regular))
          .foregroundColor(UIConstants.Colors.textSecondary)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
      }

      Spacer()
    }
    .padding(.horizontal, UIConstants.Spacing.cardPadding + 4)
    .padding(.vertical, UIConstants.Spacing.cardPadding)
    .frame(width: UIConstants.Layout.fullCardWidth(containerWidth: containerWidth))
    .background(
      RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius)
        .fill(cardBackground)
        .overlay(
          RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius)
            .stroke(cardBorder, lineWidth: UIConstants.Sizing.borderWidth)
        )
    )
  }
}

#Preview {
  GeometryReader { geometry in
    VStack(spacing: 16) {
      WarningCard(
        warning: WarningItem(
          id: "ollama",
          title: "Ollama Not Running",
          message: "Please start Ollama to use local AI models for summarization.",
          icon: "server.rack",
          severity: .warning
        ),
        containerWidth: geometry.size.width
      )

      WarningCard(
        warning: WarningItem(
          id: "network",
          title: "Connection Issue",
          message: "Unable to connect to the service. Check your network connection and try again.",
          icon: "network.slash",
          severity: .error
        ),
        containerWidth: geometry.size.width
      )
    }
    .padding(20)
  }
  .frame(width: 500, height: 300)
  .background(UIConstants.Gradients.backgroundGradient)
}
