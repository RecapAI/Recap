import AVFoundation
import Combine
import Mockable
import XCTest

@testable import Recap

@MainActor
final class OnboardingViewModelSpec: XCTestCase {
  private var sut: OnboardingViewModel!
  private var mockUserPreferencesRepository: MockUserPreferencesRepositoryType!
  private var mockPermissionsHelper: MockPermissionsHelperType!
  private var mockDelegate: MockOnboardingDelegate!
  private var cancellables = Set<AnyCancellable>()

  override func setUp() async throws {
    try await super.setUp()

    mockUserPreferencesRepository = MockUserPreferencesRepositoryType()
    mockPermissionsHelper = MockPermissionsHelperType()

    given(mockUserPreferencesRepository)
      .getOrCreatePreferences()
      .willReturn(UserPreferencesInfo())

    given(mockPermissionsHelper)
      .checkMicrophonePermissionStatus()
      .willReturn(.notDetermined)
    given(mockPermissionsHelper)
      .checkNotificationPermissionStatus()
      .willReturn(false)
    given(mockPermissionsHelper)
      .checkScreenRecordingPermission()
      .willReturn(false)

    mockDelegate = MockOnboardingDelegate()

    sut = OnboardingViewModel(
      permissionsHelper: mockPermissionsHelper,
      userPreferencesRepository: mockUserPreferencesRepository
    )
    sut.delegate = mockDelegate

    try await Task.sleep(nanoseconds: 100_000_000)
  }

  override func tearDown() async throws {
    sut = nil
    mockUserPreferencesRepository = nil
    mockPermissionsHelper = nil
    mockDelegate = nil
    cancellables.removeAll()

    try await super.tearDown()
  }

  func testInitialState() async throws {
    XCTAssertFalse(sut.isMicrophoneEnabled)
    XCTAssertFalse(sut.isAutoDetectMeetingsEnabled)
    XCTAssertTrue(sut.isAutoSummarizeEnabled)
    XCTAssertTrue(sut.isLiveTranscriptionEnabled)
    XCTAssertFalse(sut.hasRequiredPermissions)
    XCTAssertTrue(sut.canContinue)
    XCTAssertFalse(sut.showErrorToast)
    XCTAssertEqual(sut.errorMessage, "")
  }

  func testToggleAutoSummarize() {
    XCTAssertTrue(sut.isAutoSummarizeEnabled)

    sut.toggleAutoSummarize(false)
    XCTAssertFalse(sut.isAutoSummarizeEnabled)

    sut.toggleAutoSummarize(true)
    XCTAssertTrue(sut.isAutoSummarizeEnabled)
  }

  func testToggleLiveTranscription() {
    XCTAssertTrue(sut.isLiveTranscriptionEnabled)

    sut.toggleLiveTranscription(false)
    XCTAssertFalse(sut.isLiveTranscriptionEnabled)

    sut.toggleLiveTranscription(true)
    XCTAssertTrue(sut.isLiveTranscriptionEnabled)
  }

  func testCompleteOnboardingSuccess() async throws {
    sut.isAutoDetectMeetingsEnabled = true
    sut.isAutoSummarizeEnabled = false

    given(mockUserPreferencesRepository)
      .updateOnboardingStatus(.value(true))
      .willReturn()
    given(mockUserPreferencesRepository)
      .updateAutoDetectMeetings(.value(true))
      .willReturn()
    given(mockUserPreferencesRepository)
      .updateAutoSummarize(.value(false))
      .willReturn()

    sut.completeOnboarding()

    try await Task.sleep(nanoseconds: 200_000_000)

    XCTAssertTrue(mockDelegate.onboardingDidCompleteCalled)
    XCTAssertFalse(sut.showErrorToast)
    XCTAssertEqual(sut.errorMessage, "")

    verify(mockUserPreferencesRepository)
      .updateOnboardingStatus(.value(true))
      .called(1)
    verify(mockUserPreferencesRepository)
      .updateAutoDetectMeetings(.value(true))
      .called(1)
    verify(mockUserPreferencesRepository)
      .updateAutoSummarize(.value(false))
      .called(1)
  }

  func testCompleteOnboardingFailure() async throws {
    given(mockUserPreferencesRepository)
      .updateOnboardingStatus(.any)
      .willThrow(TestError.mockError)

    sut.completeOnboarding()

    try await Task.sleep(nanoseconds: 200_000_000)

    XCTAssertFalse(mockDelegate.onboardingDidCompleteCalled)
    XCTAssertTrue(sut.showErrorToast)
    XCTAssertEqual(sut.errorMessage, "Failed to save preferences. Please try again.")

    try await Task.sleep(nanoseconds: 3_200_000_000)

    XCTAssertFalse(sut.showErrorToast)
  }

  func testAutoDetectMeetingsToggleWithPermissions() async throws {
    given(mockPermissionsHelper)
      .requestScreenRecordingPermission()
      .willReturn(true)
    given(mockPermissionsHelper)
      .requestNotificationPermission()
      .willReturn(true)

    await sut.toggleAutoDetectMeetings(true)

    XCTAssertTrue(sut.isAutoDetectMeetingsEnabled)
    XCTAssertTrue(sut.hasRequiredPermissions)
  }

  func testAutoDetectMeetingsToggleWithoutPermissions() async throws {
    given(mockPermissionsHelper)
      .requestScreenRecordingPermission()
      .willReturn(false)
    given(mockPermissionsHelper)
      .requestNotificationPermission()
      .willReturn(true)

    await sut.toggleAutoDetectMeetings(true)

    XCTAssertFalse(sut.isAutoDetectMeetingsEnabled)
    XCTAssertFalse(sut.hasRequiredPermissions)
  }

  func testAutoDetectMeetingsToggleOff() async throws {
    sut.isAutoDetectMeetingsEnabled = true
    sut.hasRequiredPermissions = true

    await sut.toggleAutoDetectMeetings(false)

    XCTAssertFalse(sut.isAutoDetectMeetingsEnabled)
  }

  func testMicrophonePermissionToggle() async throws {
    given(mockPermissionsHelper)
      .requestMicrophonePermission()
      .willReturn(true)

    await sut.requestMicrophonePermission(true)

    XCTAssertTrue(sut.isMicrophoneEnabled)

    await sut.requestMicrophonePermission(false)

    XCTAssertFalse(sut.isMicrophoneEnabled)
  }
}

// MARK: - Mock Classes

@MainActor
private class MockOnboardingDelegate: OnboardingDelegate {
  var onboardingDidCompleteCalled = false

  func onboardingDidComplete() {
    onboardingDidCompleteCalled = true
  }
}

private enum TestError: Error {
  case mockError
}
