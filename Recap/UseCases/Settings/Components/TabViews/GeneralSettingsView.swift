import SwiftUI
import Combine

struct GeneralSettingsView<ViewModel: GeneralSettingsViewModelType>: View {
    @ObservedObject private var viewModel: ViewModel
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView() {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.activeWarnings, id: \.id) { warning in
                        WarningCard(warning: warning, containerWidth: geometry.size.width)
                    }
                    SettingsCard(title: "Model Selection") {
                        VStack(spacing: 16) {
                            settingsRow(label: "Provider") {
                                CustomSegmentedControl(
                                    options: LLMProvider.allCases,
                                    selection: Binding(
                                        get: { viewModel.selectedProvider },
                                        set: { newProvider in
                                            Task {
                                                await viewModel.selectProvider(newProvider)
                                            }
                                        }
                                    ),
                                    displayName: { $0.providerName }
                                )
                                .frame(width: 285)
                            }
                            
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                    Text("Loading models...")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(UIConstants.Colors.textSecondary)
                                }
                            } else if viewModel.hasModels {
                                settingsRow(label: "Summarizer Model") {
                                    if let currentSelection = viewModel.currentSelection {
                                        CustomDropdown(
                                            title: "Model",
                                            options: viewModel.availableModels,
                                            selection: Binding(
                                                get: { currentSelection },
                                                set: { newModel in
                                                    Task {
                                                        await viewModel.selectModel(newModel)
                                                    }
                                                }
                                            ),
                                            displayName: { $0.name },
                                            showSearch: true
                                        )
                                        .frame(width: 285)
                                    } else {
                                        HStack {
                                            ProgressView()
                                                .scaleEffect(0.5)
                                            Text("Setting up...")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(UIConstants.Colors.textSecondary)
                                        }
                                    }
                                }
                            } else {
                                settingsRow(label: "Selected Model") {
                                    Text("No models available")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(UIConstants.Colors.textSecondary)
                                }
                            }
                            
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    
                    SettingsCard(title: "Custom Prompt") {
                        VStack(alignment: .leading, spacing: 12) {
                            CustomTextEditor(
                                title: "Prompt Template",
                                text: viewModel.customPromptTemplate,
                                placeholder: "Enter your custom prompt template here...",
                                height: 120
                            )
                            
                            HStack {
                                Text("Customize how AI summarizes your meeting transcripts")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(UIConstants.Colors.textSecondary)
                                
                                Spacer()
                                
                                PillButton(text: "Reset to Default") {
                                    Task {
                                        await viewModel.resetToDefaultPrompt()
                                    }
                                }
                            }
                        }
                    }
                    
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .toast(isPresenting: Binding(
            get: { viewModel.showToast },
            set: { _ in }
        )) {
            AlertToast(
                displayMode: .hud,
                type: .error(.red),
                title: viewModel.toastMessage
            )
        }
        .blur(radius: viewModel.showAPIKeyAlert ? 2 : 0)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showAPIKeyAlert)
        .overlay(
            Group {
                if viewModel.showAPIKeyAlert {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .transition(.opacity)
                        
                        if viewModel.pendingAPIKeyProvider == .requesty {
                            RequestyAPIKeyAlert(
                                isPresented: Binding(
                                    get: { viewModel.showAPIKeyAlert },
                                    set: { _ in viewModel.dismissAPIKeyAlert() }
                                ),
                                existingKey: viewModel.existingAPIKey,
                                onSave: { apiKey in
                                    try await viewModel.saveAPIKey(apiKey)
                                }
                            )
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                        } else {
                            OpenRouterAPIKeyAlert(
                                isPresented: Binding(
                                    get: { viewModel.showAPIKeyAlert },
                                    set: { _ in viewModel.dismissAPIKeyAlert() }
                                ),
                                existingKey: viewModel.existingAPIKey,
                                onSave: { apiKey in
                                    try await viewModel.saveAPIKey(apiKey)
                                }
                            )
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                        }
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showAPIKeyAlert)
        )
    }
    
    
    private func settingsRow<Content: View>(
        label: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(UIConstants.Colors.textPrimary)
            
            Spacer()
            
            control()
        }
    }
}

#Preview {
    GeneralSettingsView(viewModel: PreviewGeneralSettingsViewModel())
        .frame(width: 550, height: 500)
        .background(Color.black)
}

private final class PreviewGeneralSettingsViewModel: GeneralSettingsViewModelType {
    func updateCustomPromptTemplate(_ template: String) async {}
    
    func resetToDefaultPrompt() async {}
    
    var customPromptTemplate: Binding<String> {
        .constant(UserPreferencesInfo.defaultPromptTemplate)
    }

    @Published var availableModels: [LLMModelInfo] = [
        LLMModelInfo(name: "llama3.2", provider: "ollama"),
        LLMModelInfo(name: "codellama", provider: "ollama")
    ]
    @Published var selectedModel: LLMModelInfo?
    @Published var selectedProvider: LLMProvider = .ollama
    @Published var autoDetectMeetings: Bool = true
    @Published var isAutoStopRecording: Bool = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var showAPIKeyAlert = false
    @Published var existingAPIKey: String?
    @Published var pendingAPIKeyProvider: LLMProvider?
    @Published var activeWarnings: [WarningItem] = [
        WarningItem(
            id: "ollama",
            title: "Ollama Not Running",
            message: "Please start Ollama to use local AI models for summarization.",
            icon: "server.rack",
            severity: .warning
        )
    ]
    
    var hasModels: Bool {
        !availableModels.isEmpty
    }
    
    var currentSelection: LLMModelInfo? {
        selectedModel
    }
    
    func loadModels() async {}
    func selectModel(_ model: LLMModelInfo) async {
        selectedModel = model
    }
    func selectProvider(_ provider: LLMProvider) async {
        selectedProvider = provider
    }
    func toggleAutoDetectMeetings(_ enabled: Bool) async {
        autoDetectMeetings = enabled
    }
    func toggleAutoStopRecording(_ enabled: Bool) async {
        isAutoStopRecording = enabled
    }
    func saveAPIKey(_ apiKey: String) async throws {}
    func dismissAPIKeyAlert() {
        showAPIKeyAlert = false
    }
}
