import SwiftUI

extension SummaryView {
  func recordingStateInfo(_ recording: RecordingInfo) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      stateHeader(recording)

      if needsActionButtons(for: recording) {
        actionSection(recording)
      }
    }
    .padding(12)
    .background(Color(hex: "242323").opacity(0.3))
    .cornerRadius(8)
  }

  func stateHeader(_ recording: RecordingInfo) -> some View {
    HStack {
      Text("Recording State:")
        .font(UIConstants.Typography.bodyText)
        .foregroundColor(UIConstants.Colors.textSecondary)

      Text(recording.state.displayName)
        .font(UIConstants.Typography.bodyText.weight(.semibold))
        .foregroundColor(stateColor(for: recording.state))
    }
  }

  func needsActionButtons(for recording: RecordingInfo) -> Bool {
    recording.state == .recording || recording.state == .recorded || recording.state.isFailed
  }

  func actionSection(_ recording: RecordingInfo) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      stateWarningMessage(recording)
      actionButtons
    }
  }

  @ViewBuilder
  func stateWarningMessage(_ recording: RecordingInfo) -> some View {
    if recording.state == .recording {
      Text("This recording is stuck in 'Recording' state.")
        .font(.caption)
        .foregroundColor(.orange)
    } else if recording.state.isFailed {
      Text("This recording has failed processing.")
        .font(.caption)
        .foregroundColor(.red)
    }
  }

  var actionButtons: some View {
    HStack(spacing: 8) {
      fixAndProcessButton
      markCompletedButton
    }
  }

  var fixAndProcessButton: some View {
    Button {
      Task {
        await viewModel.fixStuckRecording()
      }
    } label: {
      HStack(spacing: 6) {
        Image(systemName: "wrench.and.screwdriver")
        Text("Fix & Process")
      }
      .font(.caption.weight(.medium))
      .foregroundColor(.white)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(Color.orange)
      .cornerRadius(6)
    }
    .buttonStyle(.plain)
  }

  var markCompletedButton: some View {
    Button {
      Task {
        await viewModel.markAsCompleted()
      }
    } label: {
      HStack(spacing: 6) {
        Image(systemName: "checkmark.circle")
        Text("Mark Completed")
      }
      .font(.caption.weight(.medium))
      .foregroundColor(.white)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(Color.green.opacity(0.8))
      .cornerRadius(6)
    }
    .buttonStyle(.plain)
  }

  func stateColor(for state: RecordingProcessingState) -> Color {
    switch state {
    case .completed:
      return UIConstants.Colors.audioGreen
    case .transcriptionFailed, .summarizationFailed:
      return .red
    case .transcribing, .summarizing:
      return .orange
    case .recording:
      return .yellow
    default:
      return UIConstants.Colors.textTertiary
    }
  }
}
