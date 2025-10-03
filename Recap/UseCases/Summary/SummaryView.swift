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
                    } else if viewModel.hasSummary {
                        summaryView
                    } else {
                        errorView(viewModel.currentRecording?.errorMessage ?? "Recording is in an unexpected state")
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
                    if let recording = viewModel.currentRecording,
                       let summaryText = recording.summaryText,
                       let transcriptionText = recording.transcriptionText {
                        
                        VStack(alignment: .leading, spacing: UIConstants.Spacing.cardInternalSpacing) {
                            if !transcriptionText.isEmpty {
                                TranscriptDropdownButton(transcriptText: transcriptionText)
                            }
                            
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
}
