import Combine
import Mockable
import XCTest

@testable import Recap

@MainActor
extension GeneralSettingsViewModelSpec {
  func testLoadModelsSuccess() async throws {
    let testModels = [
      LLMModelInfo(id: "model1", name: "Model 1", provider: "ollama"),
      LLMModelInfo(id: "model2", name: "Model 2", provider: "ollama")
    ]

    await initSut(
      availableModels: testModels,
      selectedModel: testModels[0]
    )

    XCTAssertEqual(sut.availableModels.count, 2)
    XCTAssertEqual(sut.selectedModel?.id, "model1")
    XCTAssertTrue(sut.hasModels)
    XCTAssertFalse(sut.isLoading)
    XCTAssertNil(sut.errorMessage)
  }

  func testLoadModelsError() async throws {
    given(mockWarningManager)
      .activeWarningsPublisher
      .willReturn(Just([]).eraseToAnyPublisher())

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
      .willThrow(
        NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test error"])
      )

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

    XCTAssertNotNil(sut.errorMessage)
    XCTAssertTrue(sut.errorMessage?.contains("Test error") ?? false)
    XCTAssertFalse(sut.isLoading)
    XCTAssertEqual(sut.availableModels.count, 0)
  }

  func testSelectModelSuccess() async throws {
    await initSut()

    let testModel = LLMModelInfo(id: "model1", name: "Model 1", provider: "ollama")

    given(mockLLMService)
      .selectModel(id: .value("model1"))
      .willReturn()

    await sut.selectModel(testModel)

    XCTAssertEqual(sut.selectedModel?.id, "model1")
    XCTAssertNil(sut.errorMessage)

    verify(mockLLMService)
      .selectModel(id: .value("model1"))
      .called(1)
  }

  func testSelectModelError() async throws {
    await initSut()

    let testModel = LLMModelInfo(id: "model1", name: "Model 1", provider: "ollama")

    given(mockLLMService)
      .selectModel(id: .any)
      .willThrow(NSError(domain: "TestError", code: 500))

    await sut.selectModel(testModel)

    XCTAssertNil(sut.selectedModel)
    XCTAssertNotNil(sut.errorMessage)
  }
}
