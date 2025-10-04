import Combine
import Mockable
import XCTest

@testable import Recap

@MainActor
final class MeetingDetectionSettingsViewModelSpec: XCTestCase {
  private var sut: MeetingDetectionSettingsViewModel!
  private var mockDetectionService: MockMeetingDetectionServiceType!
  private var mockUserPreferencesRepository: MockUserPreferencesRepositoryType!
  private var mockPermissionsHelper: MockPermissionsHelperType!
  private var cancellables = Set<AnyCancellable>()

  override func setUp() async throws {
    try await super.setUp()

    mockDetectionService = MockMeetingDetectionServiceType()
    mockUserPreferencesRepository = MockUserPreferencesRepositoryType()
    mockPermissionsHelper = MockPermissionsHelperType()

    let defaultPreferences = UserPreferencesInfo(
      autoDetectMeetings: false
    )

    given(mockUserPreferencesRepository)
      .getOrCreatePreferences()
      .willReturn(defaultPreferences)
      .getOrCreatePreferences()
      .willReturn(UserPreferencesInfo(autoDetectMeetings: true))

    sut = MeetingDetectionSettingsViewModel(
      detectionService: mockDetectionService,
      userPreferencesRepository: mockUserPreferencesRepository,
      permissionsHelper: mockPermissionsHelper
    )

    try await Task.sleep(nanoseconds: 100_000_000)
  }

  override func tearDown() async throws {
    sut = nil
    mockDetectionService = nil
    mockUserPreferencesRepository = nil
    mockPermissionsHelper = nil
    cancellables.removeAll()

    try await super.tearDown()
  }

  func testInitialStateWithoutPermission() async throws {
    XCTAssertFalse(sut.hasScreenRecordingPermission)
    XCTAssertFalse(sut.autoDetectMeetings)
  }

  func testLoadCurrentSettingsSuccess() async throws {
    let preferences = UserPreferencesInfo(
      autoDetectMeetings: true
    )

    given(mockUserPreferencesRepository)
      .getOrCreatePreferences()
      .willReturn(preferences)

    sut = MeetingDetectionSettingsViewModel(
      detectionService: mockDetectionService,
      userPreferencesRepository: mockUserPreferencesRepository,
      permissionsHelper: mockPermissionsHelper
    )

    try await Task.sleep(nanoseconds: 200_000_000)

    XCTAssertTrue(sut.autoDetectMeetings)
  }

  func testHandleAutoDetectToggleOnWithPermission() async throws {
    given(mockUserPreferencesRepository)
      .updateAutoDetectMeetings(.value(true))
      .willReturn()

    given(mockPermissionsHelper)
      .checkScreenCapturePermission()
      .willReturn(true)

    given(mockDetectionService)
      .startMonitoring()
      .willReturn()

    await sut.handleAutoDetectToggle(true)

    XCTAssertTrue(sut.autoDetectMeetings)
    XCTAssertTrue(sut.hasScreenRecordingPermission)

    verify(mockDetectionService)
      .startMonitoring()
      .called(1)

    verify(mockUserPreferencesRepository)
      .updateAutoDetectMeetings(.value(true))
      .called(1)
  }

  func testHandleAutoDetectToggleOnWithoutPermission() async throws {
    given(mockUserPreferencesRepository)
      .updateAutoDetectMeetings(.value(true))
      .willReturn()

    given(mockPermissionsHelper)
      .checkScreenCapturePermission()
      .willReturn(false)

    await sut.handleAutoDetectToggle(true)

    XCTAssertTrue(sut.autoDetectMeetings)
    XCTAssertFalse(sut.hasScreenRecordingPermission)

    verify(mockDetectionService)
      .startMonitoring()
      .called(0)
  }

  func testHandleAutoDetectToggleOff() async throws {
    sut.autoDetectMeetings = true

    given(mockUserPreferencesRepository)
      .updateAutoDetectMeetings(.value(false))
      .willReturn()

    given(mockDetectionService)
      .stopMonitoring()
      .willReturn()

    await sut.handleAutoDetectToggle(false)

    XCTAssertFalse(sut.autoDetectMeetings)

    verify(mockDetectionService)
      .stopMonitoring()
      .called(1)

    verify(mockUserPreferencesRepository)
      .updateAutoDetectMeetings(.value(false))
      .called(1)
  }

  func testCheckPermissionStatusWithPermissionAndAutoDetect() async throws {
    sut.autoDetectMeetings = true

    given(mockPermissionsHelper)
      .checkScreenCapturePermission()
      .willReturn(true)

    given(mockDetectionService)
      .startMonitoring()
      .willReturn()

    await sut.checkPermissionStatus()

    XCTAssertTrue(sut.hasScreenRecordingPermission)

    verify(mockDetectionService)
      .startMonitoring()
      .called(1)
  }

  func testCheckPermissionStatusWithoutPermission() async throws {
    sut.autoDetectMeetings = true

    given(mockPermissionsHelper)
      .checkScreenCapturePermission()
      .willReturn(false)

    await sut.checkPermissionStatus()

    XCTAssertFalse(sut.hasScreenRecordingPermission)

    verify(mockDetectionService)
      .startMonitoring()
      .called(0)
  }

  func testCheckPermissionStatusWithPermissionButAutoDetectOff() async throws {
    sut.autoDetectMeetings = false

    given(mockPermissionsHelper)
      .checkScreenCapturePermission()
      .willReturn(true)

    await sut.checkPermissionStatus()

    XCTAssertTrue(sut.hasScreenRecordingPermission)

    verify(mockDetectionService)
      .startMonitoring()
      .called(0)
  }

  func testHandleAutoDetectToggleWithRepositoryError() async throws {
    given(mockUserPreferencesRepository)
      .updateAutoDetectMeetings(.any)
      .willThrow(NSError(domain: "TestError", code: 500))

    given(mockPermissionsHelper)
      .checkScreenCapturePermission()
      .willReturn(false)

    await sut.handleAutoDetectToggle(true)

    XCTAssertTrue(sut.autoDetectMeetings)
  }

  func testServiceStateTransitions() async throws {
    given(mockUserPreferencesRepository)
      .updateAutoDetectMeetings(.any)
      .willReturn()

    given(mockPermissionsHelper)
      .checkScreenCapturePermission()
      .willReturn(true)

    given(mockDetectionService)
      .startMonitoring()
      .willReturn()

    given(mockDetectionService)
      .stopMonitoring()
      .willReturn()

    await sut.handleAutoDetectToggle(true)
    XCTAssertTrue(sut.autoDetectMeetings)

    await sut.handleAutoDetectToggle(false)
    XCTAssertFalse(sut.autoDetectMeetings)

    verify(mockDetectionService)
      .startMonitoring()
      .called(1)

    verify(mockDetectionService)
      .stopMonitoring()
      .called(1)
  }
}
