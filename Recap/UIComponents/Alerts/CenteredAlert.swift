import SwiftUI

struct CenteredAlert<Content: View>: View {
  @Binding var isPresented: Bool
  let title: String
  let onDismiss: () -> Void
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      headerSection

      Divider()
        .background(Color.white.opacity(0.1))

      VStack(alignment: .leading, spacing: 20) {
        content
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 20)
    }
    .frame(width: 400)
    .background(
      RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius)
        .fill(.thinMaterial)
        .overlay(
          RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius)
            .fill(UIConstants.Gradients.backgroundGradient.opacity(0.8))
        )
        .overlay(
          RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius)
            .stroke(
              UIConstants.Gradients.standardBorder,
              lineWidth: UIConstants.Sizing.strokeWidth)
        )
    )
  }

  private var headerSection: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 0) {
        Text(title)
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(UIConstants.Colors.textPrimary)
          .multilineTextAlignment(.leading)
      }

      Spacer()

      PillButton(
        text: "Close",
        icon: "xmark"
      ) {
        isPresented = false
        onDismiss()
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 20)
  }
}

#Preview {
  ZStack {
    Rectangle()
      .fill(Color.gray.opacity(0.3))
      .overlay(
        Text("Background Content")
          .foregroundColor(.white)
      )

    Color.black.opacity(0.3)
      .ignoresSafeArea()

    CenteredAlert(
      isPresented: .constant(true),
      title: "Example Alert",
      onDismiss: {},
      content: {
        VStack(alignment: .leading, spacing: 20) {
          Text("This is centered alert content")
            .foregroundColor(.white)

          Button("Example Button") {}
            .foregroundColor(.blue)
        }
      }
    )
  }
  .frame(width: 600, height: 400)
  .background(Color.black)
}
