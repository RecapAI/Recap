import SwiftUI

struct PreviousRecapsDropdown<ViewModel: PreviousRecapsViewModelType>: View {
    @ObservedObject private var viewModel: ViewModel
    let onRecordingSelected: (RecordingInfo) -> Void
    let onClose: () -> Void
    
    init(
        viewModel: ViewModel,
        onRecordingSelected: @escaping (RecordingInfo) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onRecordingSelected = onRecordingSelected
        self.onClose = onClose
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            contentView
        }
        .frame(width: 380, height: 500)
        .clipped()
        .background(
            RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius * 0.6)
                .fill(UIConstants.Gradients.backgroundGradient)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius * 0.6)
                        .fill(.ultraThinMaterial)
                )
        )
        .task {
            await viewModel.loadRecordings()
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            dropdownHeader
            
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            } else if viewModel.groupedRecordings.isEmpty {
                emptyStateView
            } else {
                recordingsContent
                    .animation(.easeInOut(duration: 0.3), value: viewModel.groupedRecordings.todayRecordings.count)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.groupedRecordings.thisWeekRecordings.count)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.groupedRecordings.allRecordings.count)
            }
        }
        .padding(.top, UIConstants.Spacing.contentPadding)
        .padding(.bottom, UIConstants.Spacing.cardPadding)
    }
    
    private var dropdownHeader: some View {
        HStack {
            Text("Previous Recaps")
                .foregroundColor(UIConstants.Colors.textPrimary)
                .font(UIConstants.Typography.appTitle)
            
            Spacer()
            
            PillButton(text: "Close", icon: "xmark") {
                onClose()
            }
        }
        .padding(.horizontal, UIConstants.Spacing.contentPadding)
        .padding(.bottom, UIConstants.Spacing.sectionSpacing)
    }
    
    private var recordingsContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !viewModel.groupedRecordings.todayRecordings.isEmpty {
                sectionHeader("Today")
                ForEach(viewModel.groupedRecordings.todayRecordings) { recording in
                    RecordingCard(
                        recording: recording,
                        containerWidth: 380,
                        onViewTap: {
                            onRecordingSelected(recording)
                        }
                    )
                    .padding(.horizontal, UIConstants.Spacing.contentPadding)
                    .padding(.bottom, UIConstants.Spacing.cardSpacing)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
                
                if !viewModel.groupedRecordings.thisWeekRecordings.isEmpty || !viewModel.groupedRecordings.allRecordings.isEmpty {
                    sectionDivider
                }
            }
            
            if !viewModel.groupedRecordings.thisWeekRecordings.isEmpty {
                sectionHeader("This Week")
                ForEach(viewModel.groupedRecordings.thisWeekRecordings) { recording in
                    RecordingCard(
                        recording: recording,
                        containerWidth: 380,
                        onViewTap: {
                            onRecordingSelected(recording)
                        }
                    )
                    .padding(.horizontal, UIConstants.Spacing.contentPadding)
                    .padding(.bottom, UIConstants.Spacing.cardSpacing)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
                
                if !viewModel.groupedRecordings.allRecordings.isEmpty {
                    sectionDivider
                }
            }
            
            if !viewModel.groupedRecordings.allRecordings.isEmpty {
                sectionHeader("All Recaps")
                ForEach(viewModel.groupedRecordings.allRecordings) { recording in
                    RecordingCard(
                        recording: recording,
                        containerWidth: 380,
                        onViewTap: {
                            onRecordingSelected(recording)
                        }
                    )
                    .padding(.horizontal, UIConstants.Spacing.contentPadding)
                    .padding(.bottom, UIConstants.Spacing.cardSpacing)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(UIConstants.Colors.textTertiary)
            .padding(.horizontal, UIConstants.Spacing.contentPadding)
            .padding(.bottom, UIConstants.Spacing.gridCellSpacing)
            .padding(.all, 6)
    }
    
    private var sectionDivider: some View {
        Rectangle()
            .fill(UIConstants.Colors.textTertiary.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, UIConstants.Spacing.cardPadding)
            .padding(.vertical, UIConstants.Spacing.gridSpacing)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(0.8)
            
            Text("Loading recordings...")
                .font(UIConstants.Typography.bodyText)
                .foregroundColor(UIConstants.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text("Error Loading Recordings")
                .font(UIConstants.Typography.bodyText)
                .foregroundColor(UIConstants.Colors.textPrimary)
            
            Text(message)
                .font(.caption)
                .foregroundColor(UIConstants.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, UIConstants.Spacing.cardPadding)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.title)
                .foregroundColor(UIConstants.Colors.textTertiary)
            
            Text("No Recordings Yet")
                .font(UIConstants.Typography.bodyText)
                .foregroundColor(UIConstants.Colors.textPrimary)
            
            Text("Start recording to see your previous recaps here")
                .font(.caption)
                .foregroundColor(UIConstants.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, UIConstants.Spacing.cardPadding)
    }
}

#Preview {
    PreviousRecapsDropdown(viewModel: MockPreviousRecapsViewModel(), onRecordingSelected: { _ in }, onClose: {})
}

private class MockPreviousRecapsViewModel: ObservableObject, PreviousRecapsViewModelType {
    @Published var groupedRecordings = GroupedRecordings(
        todayRecordings: [
            RecordingInfo(
                id: "today",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date()),
                state: .completed,
                errorMessage: nil,
                recordingURL: URL(fileURLWithPath: "/tmp/today.m4a"),
                microphoneURL: nil,
                hasMicrophoneAudio: false,
                applicationName: "Teams",
                transcriptionText: "Meeting about project updates",
                summaryText: "Discussed progress and next steps",
                timestampedTranscription: nil,
                createdAt: Date(),
                modifiedAt: Date()
            )
        ],
        thisWeekRecordings: [
            RecordingInfo(
                id: "week",
                startDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: -3, to: Calendar.current.date(byAdding: .minute, value: 45, to: Date()) ?? Date()),
                state: .completed,
                errorMessage: nil,
                recordingURL: URL(fileURLWithPath: "/tmp/week.m4a"),
                microphoneURL: nil,
                hasMicrophoneAudio: false,
                applicationName: "Teams",
                transcriptionText: "Team standup discussion",
                summaryText: "Daily standup with team updates",
                timestampedTranscription: nil,
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                modifiedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            )
        ],
        allRecordings: []
    )
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadRecordings() async {}
    func startAutoRefresh() {}
    func stopAutoRefresh() {}
}
