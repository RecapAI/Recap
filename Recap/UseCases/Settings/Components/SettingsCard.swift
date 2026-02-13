import SwiftUI

struct SettingsCard<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    let cardBackground = LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Color(hex: "232222").opacity(0.2), location: 0),
        .init(color: Color(hex: "0F0F0F").opacity(0.3), location: 1)
      ]),
      startPoint: .top,
      endPoint: .bottom
    )

    let cardBorder = LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Color(hex: "979797").opacity(0.05), location: 0),
        .init(color: Color(hex: "C4C4C4").opacity(0.1), location: 1)
      ]),
      startPoint: .top,
      endPoint: .bottom
    )

    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(UIConstants.Colors.textPrimary)

      content
    }
    .padding(20)
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
  VStack(spacing: 16) {
    SettingsCard(title: "Model Selection") {
      VStack(spacing: 16) {
        HStack {
          Text("Provider")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(UIConstants.Colors.textPrimary)
          Spacer()
          Text("Local")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(UIConstants.Colors.textSecondary)
        }
      }
    }

    SettingsCard(title: "Recording Settings") {
      VStack(spacing: 16) {
        CustomToggle(isOn: .constant(true), label: "Auto Detect Meetings")
        CustomToggle(isOn: .constant(false), label: "Auto Stop Recording")
      }
    }
  }
  .padding(20)
  .background(Color.black)
}
