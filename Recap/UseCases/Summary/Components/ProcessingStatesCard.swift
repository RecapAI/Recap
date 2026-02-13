import SwiftUI

struct ProcessingStatesCard: View {
  let containerWidth: CGFloat
  let currentStage: ProcessingStage

  enum ProcessingStage: Int, CaseIterable {
    case recorded = 0
    case transcribing = 1
    case summarizing = 2

    var label: String {
      switch self {
      case .recorded:
        return "Recorded"
      case .transcribing:
        return "Transcribing"
      case .summarizing:
        return "Summarizing"
      }
    }

    var description: (headline: String, detail: String) {
      switch self {
      case .recorded:
        return ("Recording captured", "Your audio has been successfully recorded and saved.")
      case .transcribing:
        return ("Converting speech to text", "Using Whisper to transcribe your recording.")
      case .summarizing:
        return (
          "Creating your summary",
          "Analyzing the transcript and generating a concise markdown summary."
        )
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("Recap In Progress")
        .font(UIConstants.Typography.infoCardTitle)
        .foregroundColor(UIConstants.Colors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)

      progressSection

      descriptionSection
    }
    .padding(24)
    .frame(width: UIConstants.Layout.fullCardWidth(containerWidth: containerWidth))
    .background(
      RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius)
        .fill(UIConstants.Colors.cardBackground1.opacity(0.6))
        .overlay(
          RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius)
            .stroke(
              LinearGradient(
                gradient: Gradient(stops: [
                  .init(color: Color(hex: "979797").opacity(0.03), location: 0),
                  .init(color: Color(hex: "979797").opacity(0.08), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
              ),
              lineWidth: UIConstants.Sizing.borderWidth
            )
        )
    )
  }

  private var progressSection: some View {
    HStack(spacing: 16) {
      ForEach(ProcessingStage.allCases, id: \.self) { stage in
        ProcessingStageItem(
          stage: stage,
          progressState: progressState(for: stage)
        )
        .frame(maxWidth: .infinity)
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(hex: "1A1A1A").opacity(0.4))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(
              LinearGradient(
                gradient: Gradient(stops: [
                  .init(color: Color(hex: "979797").opacity(0.15), location: 0),
                  .init(color: Color(hex: "979797").opacity(0.08), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
              ),
              lineWidth: 0.8
            )
        )
    )
  }

  private var descriptionSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("What is happening now?")
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(UIConstants.Colors.textTertiary)

      Text(currentStage.description.headline)
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(UIConstants.Colors.textPrimary)

      Text(currentStage.description.detail)
        .font(.system(size: 11, weight: .regular))
        .foregroundColor(UIConstants.Colors.textSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func progressState(for stage: ProcessingStage) -> ProcessingProgressBar.ProgressState {
    if stage.rawValue < currentStage.rawValue {
      return .completed
    } else if stage == currentStage {
      return .current
    } else {
      return .pending
    }
  }
}
