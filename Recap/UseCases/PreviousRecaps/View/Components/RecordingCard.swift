import SwiftUI

struct RecordingCard: View {
  let recording: RecordingInfo
  let containerWidth: CGFloat
  let onViewTap: () -> Void

  var body: some View {
    CardBackground(
      width: containerWidth - (UIConstants.Spacing.contentPadding * 2),
      height: 80,
      backgroundColor: Color(hex: "242323").opacity(0.25),
      borderGradient: LinearGradient(
        gradient: Gradient(stops: [
          .init(color: Color(hex: "979797").opacity(0.10), location: 0),
          .init(color: Color(hex: "979797").opacity(0.02), location: 1)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .overlay(
      VStack(spacing: 12) {
        HStack {
          VStack(
            alignment: .leading,
            spacing: UIConstants.Spacing.cardInternalSpacing
          ) {
            Text(formattedStartTime)
              .font(UIConstants.Typography.transcriptionTitle)
              .foregroundColor(UIConstants.Colors.textPrimary)
              .lineLimit(1)

            HStack(spacing: 8) {
              stateView

              if let duration = recording.duration {
                Text("•")
                  .font(UIConstants.Typography.bodyText)
                  .foregroundColor(UIConstants.Colors.textTertiary)

                Text(formattedDuration(duration))
                  .font(UIConstants.Typography.bodyText)
                  .foregroundColor(UIConstants.Colors.textSecondary)
                  .lineLimit(1)
              }
            }
          }
          Spacer()

          PillButton(
            text: "View",
            icon: "square.arrowtriangle.4.outward",
            borderGradient: LinearGradient(
              gradient: Gradient(stops: [
                .init(color: Color(hex: "979797").opacity(0.2), location: 0),
                .init(color: Color(hex: "979797").opacity(0.15), location: 1)
              ]),
              startPoint: .top,
              endPoint: .bottom
            )
          ) {
            onViewTap()
          }
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 16)
    )
  }

  private var formattedStartTime: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    return formatter.localizedString(for: recording.startDate, relativeTo: Date())
  }

  private var stateView: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(stateColor)
        .frame(width: 6, height: 6)

      Text(recording.state.displayName)
        .font(UIConstants.Typography.bodyText)
        .foregroundColor(stateColor)
        .lineLimit(1)
    }
  }

  private var stateColor: Color {
    switch recording.state {
    case .completed:
      return UIConstants.Colors.audioGreen
    case .transcriptionFailed, .summarizationFailed:
      return .red
    case .transcribing, .summarizing:
      return .orange
    default:
      return UIConstants.Colors.textTertiary
    }
  }

  private func formattedDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    let seconds = Int(duration) % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%d:%02d", minutes, seconds)
    }
  }
}
