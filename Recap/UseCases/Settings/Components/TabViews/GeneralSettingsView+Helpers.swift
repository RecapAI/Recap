import SwiftUI

extension GeneralSettingsView {
  func settingsRow<Content: View>(
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

  @ViewBuilder
  func modelSelectionContent() -> some View {
    if viewModel.isLoading {
      loadingModelsView
    } else if viewModel.hasModels {
      modelDropdownView
    } else {
      manualModelInputView
    }
  }

  var loadingModelsView: some View {
    HStack {
      ProgressView()
        .scaleEffect(0.5)
      Text("Loading models...")
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(UIConstants.Colors.textSecondary)
    }
  }

  @ViewBuilder
  var modelDropdownView: some View {
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
  }

  var manualModelInputView: some View {
    settingsRow(label: "Model Name") {
      TextField("gpt-4o", text: viewModel.manualModelName)
        .font(.system(size: 12, weight: .regular))
        .foregroundColor(UIConstants.Colors.textPrimary)
        .textFieldStyle(PlainTextFieldStyle())
        .frame(width: 285)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(
              LinearGradient(
                gradient: Gradient(stops: [
                  .init(
                    color: Color(hex: "2A2A2A").opacity(
                      0.3), location: 0),
                  .init(
                    color: Color(hex: "1A1A1A").opacity(
                      0.5), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(
                  LinearGradient(
                    gradient: Gradient(stops: [
                      .init(
                        color: Color(hex: "979797")
                          .opacity(0.2),
                        location: 0),
                      .init(
                        color: Color(hex: "C4C4C4")
                          .opacity(0.15),
                        location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                  ),
                  lineWidth: 1
                )
            )
        )
    }
  }

  @ViewBuilder
  func apiKeyAlertOverlay() -> some View {
    Group {
      if viewModel.showAPIKeyAlert {
        ZStack {
          Color.black.opacity(0.3)
            .ignoresSafeArea()
            .transition(.opacity)

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

      if viewModel.showOpenAIAlert {
        ZStack {
          Color.black.opacity(0.3)
            .ignoresSafeArea()
            .transition(.opacity)

          OpenAIAPIKeyAlert(
            isPresented: Binding(
              get: { viewModel.showOpenAIAlert },
              set: { _ in viewModel.dismissOpenAIAlert() }
            ),
            existingKey: viewModel.existingOpenAIKey,
            existingEndpoint: viewModel.existingOpenAIEndpoint,
            onSave: { apiKey, endpoint in
              try await viewModel.saveOpenAIConfiguration(
                apiKey: apiKey, endpoint: endpoint)
            }
          )
          .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
      }
    }
    .animation(
      .spring(response: 0.4, dampingFraction: 0.8),
      value: viewModel.showAPIKeyAlert || viewModel.showOpenAIAlert)
  }
}
