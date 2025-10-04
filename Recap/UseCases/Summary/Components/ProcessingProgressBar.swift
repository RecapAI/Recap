import SwiftUI

struct ProcessingProgressBar: View {
  let state: ProgressState

  enum ProgressState {
    case pending
    case current
    case completed
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        backgroundBar

        if state == .completed {
          completedBar(width: geometry.size.width)
        } else if state == .current {
          currentBar(width: geometry.size.width)
        } else {
          pendingSlashes(width: geometry.size.width)
        }
      }
    }
    .frame(height: 6)
  }

  private var backgroundBar: some View {
    RoundedRectangle(cornerRadius: 3)
      .fill(Color(hex: "1A1A1A").opacity(0.4))
      .overlay(
        RoundedRectangle(cornerRadius: 3)
          .stroke(
            LinearGradient(
              gradient: Gradient(stops: [
                .init(color: Color(hex: "979797").opacity(0.1), location: 0),
                .init(color: Color(hex: "979797").opacity(0.05), location: 1)
              ]),
              startPoint: .top,
              endPoint: .bottom
            ),
            lineWidth: 0.5
          )
      )
  }

  private func completedBar(width: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: 3)
      .fill(
        LinearGradient(
          gradient: Gradient(stops: [
            .init(color: UIConstants.Colors.audioGreen.opacity(0.4), location: 0),
            .init(color: UIConstants.Colors.audioGreen.opacity(0.3), location: 1)
          ]),
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .frame(width: width)
  }

  private func currentBar(width: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: 3)
      .fill(
        LinearGradient(
          gradient: Gradient(stops: [
            .init(color: UIConstants.Colors.audioGreen.opacity(0.7), location: 0),
            .init(color: UIConstants.Colors.audioGreen.opacity(0.5), location: 1)
          ]),
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .frame(width: width * 0.6)
  }

  private func pendingSlashes(width: CGFloat) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 3)
        .fill(Color.clear)
        .frame(width: width, height: 6)
        .overlay(
          HStack(spacing: 4) {
            ForEach(0..<Int(width / 8), id: \.self) { _ in
              Rectangle()
                .fill(Color(hex: "979797").opacity(0.1))
                .frame(width: 3, height: 6)
                .rotationEffect(.degrees(-45))
            }
          }
          .clipShape(RoundedRectangle(cornerRadius: 3))
        )
    }
  }
}

struct ProcessingStageItem: View {
  let stage: ProcessingStatesCard.ProcessingStage
  let progressState: ProcessingProgressBar.ProgressState

  @State private var iconPulse = 0.3

  var body: some View {
    VStack(spacing: 12) {
      stageIcon
        .opacity(progressState == .current ? iconPulse : 1.0)

      Text(stage.label)
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(
          progressState == .pending
            ? UIConstants.Colors.textTertiary
            : UIConstants.Colors.textPrimary
        )
        .frame(maxWidth: .infinity)

      ProcessingProgressBar(state: progressState)
        .frame(maxWidth: .infinity)
    }
    .onAppear {
      if progressState == .current {
        withAnimation(
          Animation.easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
          iconPulse = 1.0
        }
      }
    }
  }

  private var stageIcon: some View {
    ZStack {
      Circle()
        .fill(iconBackground)
        .frame(width: 32, height: 32)
        .overlay(
          Circle()
            .stroke(iconBorder, lineWidth: 1)
        )

      Image(systemName: iconName)
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(iconColor)
    }
  }

  private var iconName: String {
    switch stage {
    case .recorded:
      return "checkmark"
    case .transcribing:
      return "waveform"
    case .summarizing:
      return "doc.text"
    }
  }

  private var iconBackground: some ShapeStyle {
    switch progressState {
    case .completed:
      return LinearGradient(
        gradient: Gradient(stops: [
          .init(color: UIConstants.Colors.audioGreen.opacity(0.3), location: 0),
          .init(color: UIConstants.Colors.audioGreen.opacity(0.2), location: 1)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    case .current:
      return LinearGradient(
        gradient: Gradient(stops: [
          .init(color: Color(hex: "4A4A4A").opacity(0.4), location: 0),
          .init(color: Color(hex: "2A2A2A").opacity(0.6), location: 1)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    case .pending:
      return LinearGradient(
        gradient: Gradient(colors: [Color(hex: "1A1A1A").opacity(0.3)]),
        startPoint: .top,
        endPoint: .bottom
      )
    }
  }

  private var iconBorder: some ShapeStyle {
    switch progressState {
    case .completed:
      return UIConstants.Colors.audioGreen.opacity(0.5)
    case .current:
      return Color(hex: "979797").opacity(0.4)
    case .pending:
      return Color(hex: "979797").opacity(0.2)
    }
  }

  private var iconColor: Color {
    switch progressState {
    case .completed:
      return UIConstants.Colors.audioGreen
    case .current:
      return UIConstants.Colors.textPrimary
    case .pending:
      return UIConstants.Colors.textTertiary
    }
  }
}
