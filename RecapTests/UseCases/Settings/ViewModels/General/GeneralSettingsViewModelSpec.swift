import Combine
import Mockable
import XCTest

@testable import Recap

@MainActor
class GeneralSettingsViewModelSpec: XCTestCase {
  var sut: GeneralSettingsViewModel!
  var mockLLMService: MockLLMServiceType!
  var mockUserPreferencesRepository: MockUserPreferencesRepositoryType!
  var mockKeychainAPIValidator: MockKeychainAPIValidatorType!
  var mockKeychainService: MockKeychainServiceType!
  var mockWarningManager: MockWarningManagerType!
  var mockFileManagerHelper: RecordingFileManagerHelperType!
  var cancellables = Set<AnyCancellable>()

  override func setUp() async throws {
    try await super.setUp()

    mockLLMService = MockLLMServiceType()
    mockUserPreferencesRepository = MockUserPreferencesRepositoryType()
    mockKeychainAPIValidator = MockKeychainAPIValidatorType()
    mockKeychainService = MockKeychainServiceType()
    mockWarningManager = MockWarningManagerType()
    mockFileManagerHelper = TestRecordingFileManagerHelper()
  }

  func initSut(
    preferences: UserPreferencesInfo = UserPreferencesInfo(
      selectedProvider: .ollama,
      autoDetectMeetings: false,
      autoStopRecording: false
    ),
    availableModels: [LLMModelInfo] = [],
    selectedModel: LLMModelInfo? = nil,
    warnings: [WarningItem] = []
  ) async {
    given(mockWarningManager)
      .activeWarningsPublisher
      .willReturn(Just(warnings).eraseToAnyPublisher())

    given(mockLLMService)
      .getUserPreferences()
      .willReturn(preferences)

    given(mockLLMService)
      .getAvailableModels()
      .willReturn(availableModels)

    given(mockLLMService)
      .getSelectedModel()
      .willReturn(selectedModel)

    sut = GeneralSettingsViewModel(
      llmService: mockLLMService,
      userPreferencesRepository: mockUserPreferencesRepository,
      keychainAPIValidator: mockKeychainAPIValidator,
      keychainService: mockKeychainService,
      warningManager: mockWarningManager,
      fileManagerHelper: mockFileManagerHelper
    )

    try? await Task.sleep(nanoseconds: 100_000_000)
  }

  override func tearDown() async throws {
    sut = nil
    mockLLMService = nil
    mockUserPreferencesRepository = nil
    mockKeychainAPIValidator = nil
    mockKeychainService = nil
    mockWarningManager = nil
    mockFileManagerHelper = nil
    cancellables.removeAll()

    try await super.tearDown()
  }

  func testInitialState() async throws {
    await initSut()

    XCTAssertFalse(sut.isLoading)
    XCTAssertNil(sut.errorMessage)
    XCTAssertEqual(sut.selectedProvider, .ollama)
    XCTAssertFalse(sut.autoDetectMeetings)
    XCTAssertFalse(sut.isAutoStopRecording)
  }

}

private final class TestRecordingFileManagerHelper: RecordingFileManagerHelperType {
  private(set) var baseDirectory: URL

  init(baseDirectory: URL = URL(fileURLWithPath: "/tmp/recap-tests", isDirectory: true)) {
    self.baseDirectory = baseDirectory
  }

  func getBaseDirectory() -> URL {
    baseDirectory
  }

  func setBaseDirectory(_ url: URL, bookmark: Data?) throws {
    baseDirectory = url
  }

  func createRecordingDirectory(for recordingID: String) throws -> URL {
    baseDirectory.appendingPathComponent(recordingID, isDirectory: true)
  }
}
