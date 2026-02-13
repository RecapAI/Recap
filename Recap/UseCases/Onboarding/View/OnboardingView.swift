import SwiftUI

struct OnboardingView<ViewModel: OnboardingViewModelType>: View {
  @ObservedObject private var viewModel: ViewModel

  init(viewModel: ViewModel) {
    self.viewModel = viewModel
  }

  var body: some View {
    VStack(spacing: 0) {
      headerSection

      ScrollView {
        VStack(spacing: 20) {
          permissionsSection
          featuresSection
        }
        .padding(.vertical, 20)
      }

      continueButton
    }
    .background(
      LinearGradient(
        gradient: Gradient(stops: [
          .init(color: Color(hex: "0F0F0F"), location: 0),
          .init(color: Color(hex: "1A1A1A"), location: 1)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .toast(isPresenting: $viewModel.showErrorToast) {
      AlertToast(
        displayMode: .banner(.slide),
        type: .error(.red),
        title: "Error",
        subTitle: viewModel.errorMessage
      )
    }
  }

  private var headerSection: some View {
    VStack(spacing: 6) {
      Text("Welcome to Recap")
        .font(.system(size: 18, weight: .bold))
        .foregroundColor(UIConstants.Colors.textPrimary)

      Text("Let's set up a few things to get you started")
        .font(.system(size: 12, weight: .regular))
        .foregroundColor(UIConstants.Colors.textSecondary)
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 24)
    .frame(maxWidth: .infinity)
    .background(
      LinearGradient(
        gradient: Gradient(stops: [
          .init(color: Color(hex: "2A2A2A").opacity(0.2), location: 0),
          .init(color: Color(hex: "1A1A1A").opacity(0.3), location: 1)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
  }

  private var permissionsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("PERMISSIONS")
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(UIConstants.Colors.textSecondary)
        .padding(.horizontal, 24)

      VStack(spacing: 12) {
        PermissionCard(
          title: "Microphone Access",
          description: "Required for recording and transcribing audio",
          isEnabled: Binding(
            get: { viewModel.isMicrophoneEnabled },
            set: { _ in }
          ),
          onToggle: { enabled in
            await viewModel.requestMicrophonePermission(enabled)
          }
        )

        PermissionCard(
          title: "Auto Detect Meetings",
          description: "Automatically start recording when a meeting begins",
          isEnabled: Binding(
            get: { viewModel.isAutoDetectMeetingsEnabled },
            set: { _ in }
          ),
          isExpandable: true,
          expandedContent: {
            AnyView(
              VStack(alignment: .leading, spacing: 12) {
                Text("This feature requires:")
                  .font(.system(size: 11, weight: .medium))
                  .foregroundColor(UIConstants.Colors.textPrimary)

                VStack(spacing: 8) {
                  HStack {
                    PermissionRequirement(
                      icon: "rectangle.on.rectangle",
                      text: "Screen Recording"
                    )
                    Text("Window titles only")
                      .italic()
                  }
                  HStack {
                    PermissionRequirement(
                      icon: "bell",
                      text: " Notifications"  // extra space needed :(
                    )
                    Text("Meeting alerts")
                      .italic()
                  }
                }
                .foregroundColor(UIConstants.Colors.textSecondary.opacity(0.5))
                .font(.system(size: 10, weight: .regular))

                if !viewModel.hasRequiredPermissions {
                  Text("App restart required after granting permissions")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color.orange.opacity(0.6))
                    .padding(.top, 4)
                }
              }
            )
          },
          onToggle: { enabled in
            await viewModel.toggleAutoDetectMeetings(enabled)
          }
        )
      }
      .padding(.horizontal, 24)
    }
  }

  private var featuresSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("FEATURES")
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(UIConstants.Colors.textSecondary)
        .padding(.horizontal, 24)

      VStack(spacing: 12) {
        PermissionCard(
          title: "Auto Summarize",
          description: "Generate summaries after each recording - Coming Soon!",
          isEnabled: Binding(
            get: { false },
            set: { _ in }
          ),
          isDisabled: true,
          onToggle: { _ in

          }
        )

        PermissionCard(
          title: "Live Transcription",
          description: "Show real-time transcription during recording",
          isEnabled: Binding(
            get: { viewModel.isLiveTranscriptionEnabled },
            set: { _ in }
          ),
          onToggle: { enabled in
            viewModel.toggleLiveTranscription(enabled)
          }
        )
      }
      .padding(.horizontal, 24)
    }
  }

  private var continueButton: some View {
    GeometryReader { geometry in
      HStack {
        Spacer()

        Button {
          viewModel.completeOnboarding()
        } label: {
          HStack(spacing: 6) {
            Image(systemName: "arrow.right.circle.fill")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.white)

            Text("Continue")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(.white)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
          .frame(width: geometry.size.width * 0.6)
          .background(
            RoundedRectangle(cornerRadius: 20)
              .fill(
                LinearGradient(
                  gradient: Gradient(stops: [
                    .init(color: Color(hex: "4A4A4A").opacity(0.4), location: 0),
                    .init(color: Color(hex: "3A3A3A").opacity(0.6), location: 1)
                  ]),
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
              .overlay(
                RoundedRectangle(cornerRadius: 20)
                  .stroke(
                    LinearGradient(
                      gradient: Gradient(stops: [
                        .init(color: Color(hex: "979797").opacity(0.6), location: 0),
                        .init(color: Color(hex: "979797").opacity(0.4), location: 1)
                      ]),
                      startPoint: .top,
                      endPoint: .bottom
                    ),
                    lineWidth: 1
                  )
              )
          )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.all, 6)

        Spacer()
      }
    }
    .frame(height: 60)
    .padding(.horizontal, 16)
    .background(
      LinearGradient(
        gradient: Gradient(stops: [
          .init(color: Color(hex: "1A1A1A").opacity(0.5), location: 0),
          .init(color: Color(hex: "0F0F0F").opacity(0.8), location: 1)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
  }
}

#Preview {
  OnboardingView(
    viewModel: OnboardingViewModel(
      permissionsHelper: PermissionsHelper(),
      userPreferencesRepository: PreviewUserPreferencesRepository()
    )
  )
  .frame(width: 600, height: 500)
}

private class PreviewUserPreferencesRepository: UserPreferencesRepositoryType {
  func getOrCreatePreferences() async throws -> UserPreferencesInfo {
    UserPreferencesInfo()
  }

  func updateSelectedLLMModel(id: String?) async throws {}
  func updateSelectedProvider(_ provider: LLMProvider) async throws {}
  func updateAutoSummarize(_ enabled: Bool) async throws {}
  func updateAutoSummarizeDuringRecording(_ enabled: Bool) async throws {}
  func updateAutoSummarizeAfterRecording(_ enabled: Bool) async throws {}
  func updateAutoTranscribe(_ enabled: Bool) async throws {}
  func updateSummaryPromptTemplate(_ template: String?) async throws {}
  func updateAutoDetectMeetings(_ enabled: Bool) async throws {}
  func updateAutoStopRecording(_ enabled: Bool) async throws {}
  func updateOnboardingStatus(_ completed: Bool) async throws {}
  func updateMicrophoneEnabled(_ enabled: Bool) async throws {}
  func updateGlobalShortcut(keyCode: Int32, modifiers: Int32) async throws {}
  func updateCustomTmpDirectory(path: String?, bookmark: Data?) async throws {}
}
