import OSLog
import SwiftUI

private let pillButtonPreviewLogger = Logger(
  subsystem: AppConstants.Logging.subsystem, category: "PillButtonPreview")

struct PillButton: View {
  let text: String
  let icon: String?
  let action: () -> Void
  let borderGradient: LinearGradient?

  init(
    text: String, icon: String? = nil, borderGradient: LinearGradient? = nil,
    action: @escaping () -> Void
  ) {
    self.text = text
    self.icon = icon
    self.borderGradient = borderGradient
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if let icon = icon {
          Image(systemName: icon)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
        }

        Text(text)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.white)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(Color(hex: "242323"))
          .overlay(
            RoundedRectangle(cornerRadius: 20)
              .stroke(
                borderGradient
                  ?? LinearGradient(
                    gradient: Gradient(stops: [
                      .init(color: Color(hex: "979797").opacity(0.6), location: 0),
                      .init(color: Color(hex: "979797").opacity(0.4), location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                  ),
                lineWidth: 1
              )
          )
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  VStack(spacing: 20) {
    PillButton(text: "Start Recording", icon: "mic.fill") {
      pillButtonPreviewLogger.info("Recording started")
    }

    PillButton(text: "Button", icon: nil) {
      pillButtonPreviewLogger.info("Button tapped")
    }
  }
  .padding()
  .background(Color.black)
}
