import OSLog
import SwiftUI

private let actionableWarningCardPreviewLogger = Logger(
  subsystem: AppConstants.Logging.subsystem,
  category: "ActionableWarningCardPreview"
)

struct ActionableWarningCard: View {
  let warning: WarningItem
  let containerWidth: CGFloat
  let buttonText: String?
  let buttonAction: (() -> Void)?
  let footerText: String?

  init(
    warning: WarningItem,
    containerWidth: CGFloat,
    buttonText: String? = nil,
    buttonAction: (() -> Void)? = nil,
    footerText: String? = nil
  ) {
    self.warning = warning
    self.containerWidth = containerWidth
    self.buttonText = buttonText
    self.buttonAction = buttonAction
    self.footerText = footerText
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

    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        Image(systemName: warning.icon)
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(severityColor)

        Text(warning.title)
          .font(UIConstants.Typography.cardTitle)
          .foregroundColor(UIConstants.Colors.textPrimary)

        Spacer()
      }

      VStack(alignment: .leading, spacing: 8) {
        Text(warning.message)
          .font(.system(size: 10, weight: .regular))
          .foregroundColor(UIConstants.Colors.textSecondary)
          .multilineTextAlignment(.leading)

        if let footerText = footerText {
          Text(footerText)
            .font(.system(size: 9))
            .foregroundColor(UIConstants.Colors.textSecondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      if let buttonText = buttonText, let buttonAction = buttonAction {
        HStack {
          PillButton(
            text: buttonText,
            icon: "gear"
          ) {
            buttonAction()
          }
          Spacer()
        }
      }
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
      ActionableWarningCard(
        warning: WarningItem(
          id: "screen-recording",
          title: "Permission Required",
          message: "Screen Recording permission needed to detect meeting windows",
          icon: "exclamationmark.shield",
          severity: .warning
        ),
        containerWidth: geometry.size.width,
        buttonText: "Open System Settings",
        buttonAction: {
          actionableWarningCardPreviewLogger.info("Button tapped")
        },
        footerText: """
          This permission allows Recap to read window titles only. \
          No screen content is captured or recorded.
          """
      )

      ActionableWarningCard(
        warning: WarningItem(
          id: "network",
          title: "Connection Issue",
          message:
            "Unable to connect to the service. Check your network connection and try again.",
          icon: "network.slash",
          severity: .error
        ),
        containerWidth: geometry.size.width
      )
    }
    .padding(20)
  }
  .frame(width: 500, height: 400)
  .background(UIConstants.Gradients.backgroundGradient)
}
