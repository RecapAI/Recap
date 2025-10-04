import SwiftUI

struct CustomPasswordField: View {
  let label: String
  let placeholder: String
  @Binding var text: String
  @State private var isSecure: Bool = true
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(label)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(UIConstants.Colors.textPrimary)
          .multilineTextAlignment(.leading)
        Spacer()
      }

      HStack(spacing: 12) {
        Group {
          if isSecure {
            SecureField(placeholder, text: $text)
              .focused($isFocused)
          } else {
            TextField(placeholder, text: $text)
              .focused($isFocused)
          }
        }
        .font(.system(size: 12, weight: .regular))
        .foregroundColor(UIConstants.Colors.textPrimary)
        .textFieldStyle(PlainTextFieldStyle())
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(
              LinearGradient(
                gradient: Gradient(stops: [
                  .init(color: Color(hex: "2A2A2A").opacity(0.3), location: 0),
                  .init(color: Color(hex: "1A1A1A").opacity(0.5), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(
                  isFocused
                    ? LinearGradient(
                      gradient: Gradient(stops: [
                        .init(
                          color: Color(hex: "979797").opacity(0.4),
                          location: 0),
                        .init(
                          color: Color(hex: "C4C4C4").opacity(0.3),
                          location: 1)
                      ]),
                      startPoint: .top,
                      endPoint: .bottom
                    )
                    : LinearGradient(
                      gradient: Gradient(stops: [
                        .init(
                          color: Color(hex: "979797").opacity(0.2),
                          location: 0),
                        .init(
                          color: Color(hex: "C4C4C4").opacity(0.15),
                          location: 1)
                      ]),
                      startPoint: .top,
                      endPoint: .bottom
                    ),
                  lineWidth: 1
                )
            )
        )

        PillButton(
          text: isSecure ? "Show" : "Hide",
          icon: isSecure ? "eye.slash" : "eye"
        ) {
          isSecure.toggle()
        }
        .padding(.trailing, 4)
      }
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    CustomPasswordField(
      label: "API Key",
      placeholder: "Enter your API key",
      text: .constant("sk-or-v1-abcdef123456789")
    )

    CustomPasswordField(
      label: "Empty Field",
      placeholder: "Enter password",
      text: .constant("")
    )
  }
  .padding(40)
  .background(Color.black)
}
