import Foundation
import SwiftUI

struct RecordingRow: View {
  let recording: RecordingInfo
  let onSelected: (RecordingInfo) -> Void

  var body: some View {
    Button {
      onSelected(recording)
    } label: {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 8) {
            Text(formattedStartTime)
              .font(UIConstants.Typography.bodyText)
              .foregroundColor(UIConstants.Colors.textPrimary)
              .lineLimit(1)

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

          HStack(spacing: 8) {
            processingStateIndicator

            Text(recording.state.displayName)
              .font(.caption)
              .foregroundColor(stateColor)
              .lineLimit(1)

            Spacer()

            contentIndicators
          }
        }

        Spacer(minLength: 0)
      }
      .padding(.horizontal, UIConstants.Spacing.cardPadding)
      .padding(.vertical, UIConstants.Spacing.gridCellSpacing * 2)
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .background(
      RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius * 0.3)
        .fill(Color.clear)
        .onHover { isHovered in
          if isHovered {
            NSCursor.pointingHand.push()
          } else {
            NSCursor.pop()
          }
        }
    )
  }

  private var formattedStartTime: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    return formatter.localizedString(for: recording.startDate, relativeTo: Date())
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

  private var processingStateIndicator: some View {
    Circle()
      .fill(stateColor)
      .frame(width: 6, height: 6)
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

  private var contentIndicators: some View {
    HStack(spacing: 4) {
      if recording.transcriptionText != nil {
        Image(systemName: "doc.text")
          .font(.caption2)
          .foregroundColor(UIConstants.Colors.textSecondary)
      }

      if recording.summaryText != nil {
        Image(systemName: "doc.plaintext")
          .font(.caption2)
          .foregroundColor(UIConstants.Colors.textSecondary)
      }
    }
  }
}
