import Combine
import Mockable
import XCTest

@testable import Recap

@MainActor
extension GeneralSettingsViewModelSpec {
  func testToggleAutoDetectMeetingsSuccess() async throws {
    await initSut()

    given(mockUserPreferencesRepository)
      .updateAutoDetectMeetings(.value(true))
      .willReturn()

    await sut.toggleAutoDetectMeetings(true)

    XCTAssertTrue(sut.autoDetectMeetings)
    XCTAssertNil(sut.errorMessage)

    verify(mockUserPreferencesRepository)
      .updateAutoDetectMeetings(.value(true))
      .called(1)
  }

  func testToggleAutoDetectMeetingsError() async throws {
    await initSut()

    given(mockUserPreferencesRepository)
      .updateAutoDetectMeetings(.any)
      .willThrow(NSError(domain: "TestError", code: 500))

    await sut.toggleAutoDetectMeetings(true)

    XCTAssertFalse(sut.autoDetectMeetings)
    XCTAssertNotNil(sut.errorMessage)
  }

  func testToggleAutoStopRecordingSuccess() async throws {
    await initSut()

    given(mockUserPreferencesRepository)
      .updateAutoStopRecording(.value(true))
      .willReturn()

    await sut.toggleAutoStopRecording(true)

    XCTAssertTrue(sut.isAutoStopRecording)
    XCTAssertNil(sut.errorMessage)

    verify(mockUserPreferencesRepository)
      .updateAutoStopRecording(.value(true))
      .called(1)
  }

  func testWarningManagerIntegration() async throws {
    let testWarnings = [
      WarningItem(id: "1", title: "Test Warning", message: "Test warning message")
    ]

    let warningPublisher = PassthroughSubject<[WarningItem], Never>()
    given(mockWarningManager)
      .activeWarningsPublisher
      .willReturn(warningPublisher.eraseToAnyPublisher())

    given(mockLLMService)
      .getUserPreferences()
      .willReturn(
        UserPreferencesInfo(
          selectedProvider: .ollama,
          autoDetectMeetings: false,
          autoStopRecording: false
        ))

    given(mockLLMService)
      .getAvailableModels()
      .willReturn([])

    given(mockLLMService)
      .getSelectedModel()
      .willReturn(nil)

    sut = GeneralSettingsViewModel(
      llmService: mockLLMService,
      userPreferencesRepository: mockUserPreferencesRepository,
      keychainAPIValidator: mockKeychainAPIValidator,
      keychainService: mockKeychainService,
      warningManager: mockWarningManager,
      fileManagerHelper: mockFileManagerHelper
    )

    try await Task.sleep(nanoseconds: 100_000_000)

    XCTAssertEqual(sut.activeWarnings.count, 0)

    warningPublisher.send(testWarnings)

    try await Task.sleep(nanoseconds: 100_000_000)

    XCTAssertEqual(sut.activeWarnings.count, 1)
    XCTAssertEqual(sut.activeWarnings.first?.title, "Test Warning")
  }
}
