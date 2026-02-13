import Combine
import Mockable
import XCTest

@testable import Recap

@MainActor
extension GeneralSettingsViewModelSpec {
  func testSelectProviderOllama() async throws {
    let testModels = [
      LLMModelInfo(id: "ollama1", name: "Ollama Model", provider: "ollama")
    ]

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
      .willReturn([])
      .getAvailableModels()
      .willReturn(testModels)

    given(mockLLMService)
      .getSelectedModel()
      .willReturn(nil)
      .getSelectedModel()
      .willReturn(testModels[0])

    given(mockLLMService)
      .selectProvider(.value(.ollama))
      .willReturn()

    sut = GeneralSettingsViewModel(
      llmService: mockLLMService,
      userPreferencesRepository: mockUserPreferencesRepository,
      keychainAPIValidator: mockKeychainAPIValidator,
      keychainService: mockKeychainService,
      warningManager: mockWarningManager,
      fileManagerHelper: mockFileManagerHelper
    )

    try? await Task.sleep(nanoseconds: 100_000_000)

    await sut.selectProvider(.ollama)

    XCTAssertEqual(sut.selectedProvider, .ollama)
    XCTAssertEqual(sut.availableModels.count, 1)
    XCTAssertNil(sut.errorMessage)
  }

  func testSelectProviderOpenRouterWithoutAPIKey() async throws {
    await initSut()

    given(mockKeychainAPIValidator)
      .validateOpenRouterAPI()
      .willReturn(.missingApiKey)

    given(mockKeychainService)
      .retrieve(key: .value(KeychainKey.openRouterApiKey.key))
      .willReturn(nil)

    await sut.selectProvider(.openRouter)

    XCTAssertTrue(sut.showAPIKeyAlert)
    XCTAssertNil(sut.existingAPIKey)
    XCTAssertNotEqual(sut.selectedProvider, .openRouter)
  }

  func testSelectProviderOpenRouterWithValidAPIKey() async throws {
    await initSut()

    given(mockKeychainAPIValidator)
      .validateOpenRouterAPI()
      .willReturn(.valid)

    let testModels = [
      LLMModelInfo(id: "openrouter1", name: "OpenRouter Model", provider: "openrouter")
    ]

    given(mockLLMService)
      .selectProvider(.value(.openRouter))
      .willReturn()

    given(mockLLMService)
      .getAvailableModels()
      .willReturn(testModels)

    given(mockLLMService)
      .getSelectedModel()
      .willReturn(nil)

    given(mockLLMService)
      .selectModel(id: .any)
      .willReturn()

    await sut.selectProvider(.openRouter)

    XCTAssertEqual(sut.selectedProvider, .openRouter)
    XCTAssertFalse(sut.showAPIKeyAlert)
  }
}
