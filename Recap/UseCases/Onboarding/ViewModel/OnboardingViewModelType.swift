import Foundation

@MainActor
protocol OnboardingDelegate: AnyObject {
  func onboardingDidComplete()
}

@MainActor
protocol OnboardingViewModelType: ObservableObject {
  var isMicrophoneEnabled: Bool { get }
  var isAutoDetectMeetingsEnabled: Bool { get }
  var isAutoSummarizeEnabled: Bool { get }
  var isLiveTranscriptionEnabled: Bool { get }
  var hasRequiredPermissions: Bool { get }
  var showErrorToast: Bool { get set }
  var errorMessage: String { get }
  var canContinue: Bool { get }
  var delegate: OnboardingDelegate? { get set }

  func requestMicrophonePermission(_ enabled: Bool) async
  func toggleAutoDetectMeetings(_ enabled: Bool) async
  func toggleAutoSummarize(_ enabled: Bool)
  func toggleLiveTranscription(_ enabled: Bool)
  func completeOnboarding()
}
