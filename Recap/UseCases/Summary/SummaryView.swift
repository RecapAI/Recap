import SwiftUI
import MarkdownUI

struct SummaryView<ViewModel: SummaryViewModelType>: View {
    let onClose: () -> Void
    @ObservedObject var viewModel: ViewModel
    let recordingID: String?

    init(
        onClose: @escaping () -> Void,
        viewModel: ViewModel,
        recordingID: String? = nil
    ) {
        self.onClose = onClose
        self.viewModel = viewModel
        self.recordingID = recordingID
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                UIConstants.Gradients.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: UIConstants.Spacing.sectionSpacing) {
                    headerView

                    if viewModel.isLoadingRecording {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(errorMessage)
                    } else if viewModel.currentRecording == nil {
                        noRecordingView
                    } else if viewModel.isProcessing {
                        processingView(geometry: geometry)
                    } else if viewModel.isRecordingReady {
                        summaryView
                    } else if let recording = viewModel.currentRecording {
                        stuckRecordingView(recording)
                    } else {
                        errorView("Recording is in an unexpected state")
                    }

                    Spacer()
                }
            }
        }
        .onAppear {
            if let recordingID = recordingID {
                viewModel.loadRecording(withID: recordingID)
            } else {
                viewModel.loadLatestRecording()
            }
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .toast(isPresenting: .init(
            get: { viewModel.showingCopiedToast },
            set: { _ in }
        )) {
            AlertToast(
                displayMode: .banner(.pop),
                type: .complete(UIConstants.Colors.audioGreen),
                title: "Copied to clipboard"
            )
        }
    }

    private var headerView: some View {
        HStack {
            Text("Summary")
                .foregroundColor(UIConstants.Colors.textPrimary)
                .font(UIConstants.Typography.appTitle)
                .padding(.leading, UIConstants.Spacing.contentPadding)
                .padding(.top, UIConstants.Spacing.sectionSpacing)

            Spacer()

            closeButton
                .padding(.trailing, UIConstants.Spacing.contentPadding)
                .padding(.top, UIConstants.Spacing.sectionSpacing)
        }
    }

    private var closeButton: some View {
        PillButton(text: "Close", icon: "xmark") {
            onClose()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)

            Text("Loading recording...")
                .font(UIConstants.Typography.bodyText)
                .foregroundColor(UIConstants.Colors.textSecondary)
        }
        .frame(maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red.opacity(0.8))

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(UIConstants.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, UIConstants.Spacing.contentPadding)
        }
        .frame(maxHeight: .infinity)
    }

    private func stuckRecordingView(_ recording: RecordingInfo) -> some View {
        VStack(spacing: 20) {
            recordingStateInfo(recording)
                .padding(.horizontal, UIConstants.Spacing.contentPadding)

            if let errorMessage = recording.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red.opacity(0.8))

                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(UIConstants.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, UIConstants.Spacing.contentPadding)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 20)
    }

    private var noRecordingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.slash")
                .font(.system(size: 48))
                .foregroundColor(UIConstants.Colors.textTertiary)

            Text("No recordings found")
                .font(.system(size: 14))
                .foregroundColor(UIConstants.Colors.textSecondary)
        }
        .frame(maxHeight: .infinity)
    }

    private func processingView(geometry: GeometryProxy) -> some View {
        VStack(spacing: UIConstants.Spacing.sectionSpacing) {
            if let stage = viewModel.processingStage {
                ProcessingStatesCard(
                    containerWidth: geometry.size.width,
                    currentStage: stage
                )
                .padding(.horizontal, UIConstants.Spacing.contentPadding)
            }

            Spacer()
        }
    }

    private var summaryView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.cardSpacing) {
                    if let recording = viewModel.currentRecording {

                        VStack(alignment: .leading, spacing: UIConstants.Spacing.cardInternalSpacing) {
                            recordingStateInfo(recording)

                            if let transcriptionText = recording.transcriptionText, !transcriptionText.isEmpty {
                                TranscriptDropdownButton(
                                    transcriptText: transcriptionText
                                )
                            }

                            if let summaryText = recording.summaryText, !summaryText.isEmpty {
                                Text("Summary")
                                    .font(UIConstants.Typography.infoCardTitle)
                                    .foregroundColor(UIConstants.Colors.textPrimary)

                                Markdown(summaryText)
                                    .markdownTheme(.docC)
                                    .markdownTextStyle {
                                        ForegroundColor(UIConstants.Colors.textSecondary)
                                        FontSize(12)
                                    }
                                    .markdownBlockStyle(\.heading1) { configuration in
                                        configuration.label
                                            .markdownTextStyle {
                                                FontWeight(.bold)
                                                FontSize(18)
                                                ForegroundColor(UIConstants.Colors.textPrimary)
                                            }
                                            .padding(.vertical, 8)
                                    }
                                    .markdownBlockStyle(\.heading2) { configuration in
                                        configuration.label
                                            .markdownTextStyle {
                                                FontWeight(.semibold)
                                                FontSize(16)
                                                ForegroundColor(UIConstants.Colors.textPrimary)
                                            }
                                            .padding(.vertical, 6)
                                    }
                                    .markdownBlockStyle(\.heading3) { configuration in
                                        configuration.label
                                            .markdownTextStyle {
                                                FontWeight(.medium)
                                                FontSize(14)
                                                ForegroundColor(UIConstants.Colors.textPrimary)
                                            }
                                            .padding(.vertical, 4)
                                    }
                                    .markdownBlockStyle(\.listItem) { configuration in
                                        configuration.label
                                            .markdownTextStyle {
                                                FontSize(12)
                                            }
                                    }
                                    .textSelection(.enabled)
                            }

                            if recording.summaryText == nil && recording.transcriptionText == nil {
                                Text("Recording completed without transcription or summary")
                                    .font(UIConstants.Typography.bodyText)
                                    .foregroundColor(UIConstants.Colors.textSecondary)
                                    .padding(.vertical, 20)
                            }
                        }
                        .padding(.horizontal, UIConstants.Spacing.contentPadding)
                        .padding(.vertical, UIConstants.Spacing.cardSpacing)
                        .padding(.bottom, 80)
                    }
                }
            }

            summaryActionButtons
        }
    }

    private var summaryActionButtons: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                SummaryActionButton(
                    text: "Copy Summary",
                    icon: "doc.on.doc"
                ) {
                    viewModel.copySummary()
                }

                SummaryActionButton(
                    text: "Copy Transcription",
                    icon: "doc.text"
                ) {
                    viewModel.copyTranscription()
                }

                SummaryActionButton(
                    text: retryButtonText,
                    icon: "arrow.clockwise"
                ) {
                    Task {
                        await viewModel.retryProcessing()
                    }
                }
            }
            .padding(.horizontal, UIConstants.Spacing.cardPadding)
            .padding(.top, UIConstants.Spacing.cardPadding)
            .padding(.bottom, UIConstants.Spacing.cardInternalSpacing)
        }
        .background(UIConstants.Gradients.summaryButtonBackground)
        .cornerRadius(UIConstants.Sizing.cornerRadius)
    }

    private var retryButtonText: String {
        guard let recording = viewModel.currentRecording else { return "Retry Summarization" }

        switch recording.state {
        case .transcriptionFailed:
            return "Retry"
        default:
            return "Retry Summarization"
        }
    }

    private func recordingStateInfo(_ recording: RecordingInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recording State:")
                    .font(UIConstants.Typography.bodyText)
                    .foregroundColor(UIConstants.Colors.textSecondary)

                Text(recording.state.displayName)
                    .font(UIConstants.Typography.bodyText.weight(.semibold))
                    .foregroundColor(stateColor(for: recording.state))
            }

            if recording.state == .recording || recording.state == .recorded || recording.state.isFailed {
                VStack(alignment: .leading, spacing: 8) {
                    if recording.state == .recording {
                        Text("This recording is stuck in 'Recording' state.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else if recording.state.isFailed {
                        Text("This recording has failed processing.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    HStack(spacing: 8) {
                        Button(action: {
                            Task {
                                await viewModel.fixStuckRecording()
                            }
                        }) {
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

                        Button(action: {
                            Task {
                                await viewModel.markAsCompleted()
                            }
                        }) {
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
                }
            }
        }
        .padding(12)
        .background(Color(hex: "242323").opacity(0.3))
        .cornerRadius(8)
    }

    private func stateColor(for state: RecordingProcessingState) -> Color {
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
