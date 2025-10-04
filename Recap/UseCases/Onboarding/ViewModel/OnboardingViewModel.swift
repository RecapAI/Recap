import AVFoundation
import Foundation

@MainActor
final class OnboardingViewModel: OnboardingViewModelType, ObservableObject {
  @Published var isMicrophoneEnabled: Bool = false
  @Published var isAutoDetectMeetingsEnabled: Bool = false
  @Published var isAutoSummarizeEnabled: Bool = true
  @Published var isLiveTranscriptionEnabled: Bool = true
  @Published var hasRequiredPermissions: Bool = false
  @Published var showErrorToast: Bool = false
  @Published var errorMessage: String = ""

  weak var delegate: OnboardingDelegate?

  private let permissionsHelper: PermissionsHelperType
  private let userPreferencesRepository: UserPreferencesRepositoryType

  var canContinue: Bool {
    true  // no enforced permissions yet
  }

  init(
    permissionsHelper: PermissionsHelperType,
    userPreferencesRepository: UserPreferencesRepositoryType
  ) {
    self.permissionsHelper = permissionsHelper
    self.userPreferencesRepository = userPreferencesRepository
    checkExistingPermissions()
  }

  func requestMicrophonePermission(_ enabled: Bool) async {
    if enabled {
      let granted = await permissionsHelper.requestMicrophonePermission()
      isMicrophoneEnabled = granted
    } else {
      isMicrophoneEnabled = false
    }
  }

  func toggleAutoDetectMeetings(_ enabled: Bool) async {
    if enabled {
      let screenGranted = await permissionsHelper.requestScreenRecordingPermission()
      let notificationGranted = await permissionsHelper.requestNotificationPermission()

      if screenGranted && notificationGranted {
        isAutoDetectMeetingsEnabled = true
        hasRequiredPermissions = true
      } else {
        isAutoDetectMeetingsEnabled = false
        hasRequiredPermissions = false
      }
    } else {
      isAutoDetectMeetingsEnabled = false
    }
  }

  func toggleAutoSummarize(_ enabled: Bool) {
    isAutoSummarizeEnabled = enabled
  }

  func toggleLiveTranscription(_ enabled: Bool) {
    isLiveTranscriptionEnabled = enabled
  }

  func completeOnboarding() {
    Task {
      do {
        try await userPreferencesRepository.updateOnboardingStatus(true)
        try await userPreferencesRepository.updateAutoDetectMeetings(isAutoDetectMeetingsEnabled)
        try await userPreferencesRepository.updateAutoSummarize(isAutoSummarizeEnabled)

        delegate?.onboardingDidComplete()
      } catch {
        errorMessage = "Failed to save preferences. Please try again."
        showErrorToast = true

        Task {
          try? await Task.sleep(nanoseconds: 3_000_000_000)
          showErrorToast = false
        }
      }
    }
  }

  private func checkExistingPermissions() {
    let microphoneStatus = permissionsHelper.checkMicrophonePermissionStatus()
    isMicrophoneEnabled = microphoneStatus == .authorized

    Task {
      let notificationStatus = await permissionsHelper.checkNotificationPermissionStatus()
      let screenStatus = permissionsHelper.checkScreenRecordingPermission()
      hasRequiredPermissions = notificationStatus && screenStatus

      isAutoDetectMeetingsEnabled = false
    }
  }
}
