import Combine
import SwiftUI

struct GeneralSettingsView<ViewModel: GeneralSettingsViewModelType>: View {
  @ObservedObject var viewModel: ViewModel
  var recapViewModel: RecapViewModel?

  init(viewModel: ViewModel, recapViewModel: RecapViewModel? = nil) {
    self.viewModel = viewModel
    self.recapViewModel = recapViewModel
  }

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          // Audio Sources Section (moved from LeftPaneView)
          if let recapViewModel = recapViewModel {
            SettingsCard(title: "Audio Sources") {
              HStack(spacing: UIConstants.Spacing.cardSpacing) {
                HeatmapCard(
                  title: "System Audio",
                  containerWidth: geometry.size.width,
                  isSelected: true,
                  audioLevel: recapViewModel.systemAudioHeatmapLevel,
                  isInteractionEnabled: !recapViewModel.isRecording,
                  onToggle: {}
                )
                HeatmapCard(
                  title: "Microphone",
                  containerWidth: geometry.size.width,
                  isSelected: recapViewModel.isMicrophoneEnabled,
                  audioLevel: recapViewModel.microphoneHeatmapLevel,
                  isInteractionEnabled: !recapViewModel.isRecording,
                  onToggle: {
                    recapViewModel.toggleMicrophone()
                  }
                )
              }
            }
          }

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

              modelSelectionContent()

              HStack {
                Spacer()

                PillButton(
                  text: viewModel.isTestingProvider ? "Testing..." : "Test LLM Provider",
                  icon: viewModel.isTestingProvider ? nil : "checkmark.circle"
                ) {
                  Task {
                    await viewModel.testLLMProvider()
                  }
                }
                .disabled(viewModel.isTestingProvider)
              }

              if let testResult = viewModel.testResult {
                Text(testResult)
                  .font(.system(size: 11, weight: .regular))
                  .foregroundColor(UIConstants.Colors.textSecondary)
                  .padding(12)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .background(
                    RoundedRectangle(cornerRadius: 8)
                      .fill(Color(hex: "1A1A1A"))
                      .overlay(
                        RoundedRectangle(cornerRadius: 8)
                          .stroke(Color(hex: "2A2A2A"), lineWidth: 1)
                      )
                  )
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

          SettingsCard(title: "Processing Options") {
            VStack(spacing: 16) {
              settingsRow(label: "Enable Transcription") {
                Toggle(
                  "",
                  isOn: Binding(
                    get: { viewModel.isAutoTranscribeEnabled },
                    set: { newValue in
                      Task {
                        await viewModel.toggleAutoTranscribe(newValue)
                      }
                    }
                  )
                )
                .toggleStyle(SwitchToggleStyle(tint: UIConstants.Colors.audioGreen))
              }

              Text("When disabled, transcription will be skipped")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(UIConstants.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

              settingsRow(label: "Enable Summarization") {
                Toggle(
                  "",
                  isOn: Binding(
                    get: { viewModel.isAutoSummarizeEnabled },
                    set: { newValue in
                      Task {
                        await viewModel.toggleAutoSummarize(newValue)
                      }
                    }
                  )
                )
                .toggleStyle(SwitchToggleStyle(tint: UIConstants.Colors.audioGreen))
              }

              Text(
                "When disabled, recordings will only be transcribed without summarization"
              )
              .font(.system(size: 11, weight: .regular))
              .foregroundColor(UIConstants.Colors.textSecondary)
              .frame(maxWidth: .infinity, alignment: .leading)
            }
          }

          SettingsCard(title: "Global Shortcut") {
            GlobalShortcutSettingsView(viewModel: viewModel)
          }

          SettingsCard(title: "File Storage") {
            FolderSettingsView(
              viewModel: AnyFolderSettingsViewModel(viewModel.folderSettingsViewModel)
            )
          }

        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
      }
    }
    .toast(
      isPresenting: Binding(
        get: { viewModel.showToast },
        set: { _ in }
      )
    ) {
      AlertToast(
        displayMode: .hud,
        type: .error(.red),
        title: viewModel.toastMessage
      )
    }
    .blur(radius: viewModel.showAPIKeyAlert || viewModel.showOpenAIAlert ? 2 : 0)
    .animation(
      .easeInOut(duration: 0.3), value: viewModel.showAPIKeyAlert || viewModel.showOpenAIAlert
    )
    .overlay(apiKeyAlertOverlay())
  }
}

#if DEBUG
  #Preview {
    GeneralSettingsView(viewModel: PreviewGeneralSettingsViewModel())
      .frame(width: 550, height: 500)
      .background(Color.black)
  }
#endif
