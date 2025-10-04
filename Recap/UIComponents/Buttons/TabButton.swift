import OSLog
import SwiftUI

private let tabButtonPreviewLogger = Logger(
  subsystem: AppConstants.Logging.subsystem, category: "TabButtonPreview")

struct TabButton: View {
  let text: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(text)
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(isSelected ? Color(hex: "2E2E2E") : Color.clear)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .overlay(
              RoundedRectangle(cornerRadius: 20)
                .stroke(
                  LinearGradient(
                    gradient: Gradient(stops: [
                      .init(color: Color(hex: "C8C8C8").opacity(0.2), location: 0),
                      .init(color: Color(hex: "0D0D0D"), location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                  ),
                  lineWidth: 1.5
                )
            )
        )
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  HStack(spacing: 8) {
    TabButton(text: "General", isSelected: true) {
      tabButtonPreviewLogger.info("General selected")
    }

    TabButton(text: "Whisper Models", isSelected: false) {
      tabButtonPreviewLogger.info("Whisper Models selected")
    }
  }
  .padding()
  .background(Color.black)
}
