import SwiftUI

struct PermissionCard: View {
  let title: String
  let description: String
  @Binding var isEnabled: Bool
  var isExpandable: Bool = false
  var expandedContent: (() -> AnyView)?
  var isDisabled: Bool = false
  let onToggle: (Bool) async -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(UIConstants.Colors.textPrimary)

          Text(description)
            .font(.system(size: 11, weight: .regular))
            .foregroundColor(UIConstants.Colors.textSecondary)
            .lineLimit(2)
        }

        Spacer()

        Toggle(
          "",
          isOn: Binding(
            get: { isEnabled },
            set: { newValue in
              if !isDisabled {
                Task {
                  await onToggle(newValue)
                }
              }
            }
          )
        )
        .toggleStyle(CustomToggleStyle())
        .labelsHidden()
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
      }
      .padding(16)

      if isExpandable, let expandedContent = expandedContent {
        Divider()
          .background(Color.white.opacity(0.1))
          .padding(.horizontal, 16)

        expandedContent()
          .padding(16)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(
          LinearGradient(
            gradient: Gradient(stops: [
              .init(color: Color(hex: "2A2A2A").opacity(0.3), location: 0),
              .init(color: Color(hex: "1A1A1A").opacity(0.4), location: 1)
            ]),
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(
              LinearGradient(
                gradient: Gradient(stops: [
                  .init(color: Color(hex: "979797").opacity(0.15), location: 0),
                  .init(color: Color(hex: "C4C4C4").opacity(0.2), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
              ),
              lineWidth: 0.5
            )
        )
    )
  }
}

struct PermissionRequirement: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
      Text(text)

      Spacer()
    }
    .font(.system(size: 10, weight: .regular))
    .foregroundColor(UIConstants.Colors.textSecondary)
  }
}

#Preview {
  VStack(spacing: 16) {
    PermissionCard(
      title: "Microphone Access",
      description: "Required for recording audio",
      isEnabled: .constant(true),
      onToggle: { _ in }
    )

    PermissionCard(
      title: "Auto Detect Meetings",
      description: "Automatically start recording when a meeting begins",
      isEnabled: .constant(false),
      isExpandable: true,
      expandedContent: {
        AnyView(
          VStack(alignment: .leading, spacing: 8) {
            Text("Required Permissions:")
              .font(.system(size: 11, weight: .medium))
              .foregroundColor(UIConstants.Colors.textPrimary)

            PermissionRequirement(
              icon: "rectangle.on.rectangle",
              text: "Screen Recording Access"
            )
            PermissionRequirement(
              icon: "bell",
              text: "Notification Access"
            )
          }
        )
      },
      onToggle: { _ in }
    )
  }
  .padding(75)
  .background(Color.black)
}
