import SwiftUI

struct CustomSegmentedControl<T: Hashable>: View {
  let options: [T]
  @Binding var selection: T
  let displayName: (T) -> String
  let onSelectionChange: ((T) -> Void)?

  init(
    options: [T],
    selection: Binding<T>,
    displayName: @escaping (T) -> String,
    onSelectionChange: ((T) -> Void)? = nil
  ) {
    self.options = options
    self._selection = selection
    self.displayName = displayName
    self.onSelectionChange = onSelectionChange
  }

  var body: some View {
    HStack(spacing: 0) {
      ForEach(Array(options.enumerated()), id: \.element) { _, option in
        Button {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            selection = option
          }
          onSelectionChange?(option)
        } label: {
          Text(displayName(option))
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(
              selection == option
                ? UIConstants.Colors.textPrimary
                : UIConstants.Colors.textSecondary
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .background(
              selection == option
                ? LinearGradient(
                  gradient: Gradient(stops: [
                    .init(
                      color: Color(hex: "4A4A4A").opacity(0.4), location: 0),
                    .init(
                      color: Color(hex: "2A2A2A").opacity(0.6), location: 1)
                  ]),
                  startPoint: .top,
                  endPoint: .bottom
                )
                : LinearGradient(
                  gradient: Gradient(colors: [Color.clear]),
                  startPoint: .top,
                  endPoint: .bottom
                )
            )
            .overlay(
              selection == option
                ? RoundedRectangle(cornerRadius: 6)
                  .stroke(
                    LinearGradient(
                      gradient: Gradient(stops: [
                        .init(
                          color: Color(hex: "979797").opacity(0.3),
                          location: 0),
                        .init(
                          color: Color(hex: "979797").opacity(0.2),
                          location: 1)
                      ]),
                      startPoint: .top,
                      endPoint: .bottom
                    ),
                    lineWidth: 0.8
                  )
                : nil
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selection)
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
    .padding(4)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(hex: "1A1A1A").opacity(0.6))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(
              LinearGradient(
                gradient: Gradient(stops: [
                  .init(color: Color(hex: "979797").opacity(0.2), location: 0),
                  .init(color: Color(hex: "979797").opacity(0.1), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
              ),
              lineWidth: 0.8
            )
        )
    )
  }
}

#Preview {
  VStack(spacing: 30) {
    CustomSegmentedControl(
      options: ["Local", "Cloud"],
      selection: .constant("Local"),
      displayName: { $0 }
    )
    .frame(width: 285)

    CustomSegmentedControl(
      options: ["Option A", "Option B"],
      selection: .constant("Option B"),
      displayName: { $0 }
    )
    .frame(width: 260)

    Text("This text should not move")
      .foregroundColor(.white)
  }
  .frame(width: 400, height: 300)
  .padding(40)
  .background(Color.black)
}
