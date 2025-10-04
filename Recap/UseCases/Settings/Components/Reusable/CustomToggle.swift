import SwiftUI

struct CustomToggle: View {
  @Binding var isOn: Bool
  let label: String

  var body: some View {
    HStack {
      Text(label)
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(UIConstants.Colors.textPrimary)

      Spacer()

      Toggle("", isOn: $isOn)
        .toggleStyle(CustomToggleStyle())
        .labelsHidden()
    }
  }
}

struct CustomToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button {
      withAnimation(.easeInOut(duration: 0.2)) {
        configuration.isOn.toggle()
      }
    } label: {
      RoundedRectangle(cornerRadius: 16)
        .fill(
          configuration.isOn
            ? LinearGradient(
              gradient: Gradient(stops: [
                .init(color: Color(hex: "4A4A4A").opacity(0.4), location: 0),
                .init(color: Color(hex: "2A2A2A").opacity(0.6), location: 1)
              ]),
              startPoint: .top,
              endPoint: .bottom
            )
            : LinearGradient(
              gradient: Gradient(stops: [
                .init(color: Color(hex: "3A3A3A"), location: 0),
                .init(color: Color(hex: "2A2A2A"), location: 1)
              ]),
              startPoint: .leading,
              endPoint: .trailing
            )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(
              LinearGradient(
                gradient: Gradient(stops: [
                  .init(color: Color(hex: "979797").opacity(0.3), location: 0),
                  .init(color: Color(hex: "979797").opacity(0.2), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
              ),
              lineWidth: 0.5
            )
        )
        .frame(width: 48, height: 28)
        .overlay(
          Circle()
            .fill(Color.white)
            .frame(width: 24, height: 24)
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            .offset(x: configuration.isOn ? 10 : -10)
            .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
        )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  VStack(spacing: 20) {
    CustomToggle(isOn: .constant(true), label: "Enable Notifications")
    CustomToggle(isOn: .constant(false), label: "Auto-start on login")
    CustomToggle(isOn: .constant(true), label: "Show in menu bar")
  }
  .padding(40)
  .background(Color.black)
}
