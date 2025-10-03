import SwiftUI

struct MeetingDetectionView<ViewModel: MeetingDetectionSettingsViewModelType>: View {
    @ObservedObject private var viewModel: ViewModel
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.autoDetectMeetings && !viewModel.hasScreenRecordingPermission {
                        ActionableWarningCard(
                            warning: WarningItem(
                                id: "screen-recording",
                                title: "Permission Required",
                                message: "Screen Recording permission needed to detect meeting windows",
                                icon: "exclamationmark.shield",
                                severity: .warning
                            ),
                            containerWidth: geometry.size.width,
                            buttonText: "Open System Settings",
                            buttonAction: {
                                viewModel.openScreenRecordingPreferences()
                            },
                            footerText: "This permission allows Recap to read window titles only. No screen content is captured or recorded."
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    SettingsCard(title: "Meeting Detection") {
                        VStack(spacing: 16) {
                            settingsRow(
                                label: "Auto-detect meetings",
                                description: "Get notified in console when Teams, Zoom, or Meet meetings begin"
                            ) {
                                Toggle("", isOn: Binding(
                                    get: { viewModel.autoDetectMeetings },
                                    set: { newValue in
                                        Task {
                                            await viewModel.handleAutoDetectToggle(newValue)
                                        }
                                    }
                                ))
                                .toggleStyle(CustomToggleStyle())
                                .labelsHidden()
                            }
                            
                            if viewModel.autoDetectMeetings {
                                VStack(spacing: 12) {
                                    if !viewModel.hasScreenRecordingPermission {
                                        HStack {
                                            Text("Please enable Screen Recording permission above to continue.")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.autoDetectMeetings)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.hasScreenRecordingPermission)
            }
        }
        .onAppear {
            Task {
                await viewModel.checkPermissionStatus()
            }
        }
        .onChange(of: viewModel.autoDetectMeetings) { oldValue, enabled in
            if enabled {
                Task {
                    await viewModel.checkPermissionStatus()
                }
            }
        }
    }
    
    private func settingsRow<Content: View>(
        label: String,
        description: String? = nil,
        @ViewBuilder control: () -> Content
    ) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(UIConstants.Colors.textPrimary)
                
                if let description = description {
                    Text(description)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            control()
        }
    }
    
}
