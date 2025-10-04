import SwiftUI

struct CustomTextField: View {
  let label: String
  let placeholder: String
  @Binding var text: String
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

      TextField(placeholder, text: $text)
        .focused($isFocused)
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
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    CustomTextField(
      label: "API Endpoint",
      placeholder: "https://api.openai.com/v1",
      text: .constant("https://api.openai.com/v1")
    )

    CustomTextField(
      label: "Empty Field",
      placeholder: "Enter value",
      text: .constant("")
    )
  }
  .padding(40)
  .background(Color.black)
}
