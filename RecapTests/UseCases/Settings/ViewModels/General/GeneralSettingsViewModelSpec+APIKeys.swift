import Combine
import Mockable
import XCTest

@testable import Recap

@MainActor
extension GeneralSettingsViewModelSpec {
  func testSaveAPIKeySuccess() async throws {
    await initSut()

    given(mockKeychainService)
      .store(key: .value(KeychainKey.openRouterApiKey.key), value: .value("test-api-key"))
      .willReturn()

    given(mockLLMService)
      .reinitializeProviders()
      .willReturn()

    given(mockKeychainAPIValidator)
      .validateOpenRouterAPI()
      .willReturn(.valid)

    given(mockLLMService)
      .selectProvider(.value(.openRouter))
      .willReturn()

    given(mockLLMService)
      .getAvailableModels()
      .willReturn([])

    given(mockLLMService)
      .getSelectedModel()
      .willReturn(nil)

    try await sut.saveAPIKey("test-api-key")

    XCTAssertFalse(sut.showAPIKeyAlert)
    XCTAssertEqual(sut.existingAPIKey, "test-api-key")
    XCTAssertEqual(sut.selectedProvider, .openRouter)
  }

  func testDismissAPIKeyAlert() async throws {
    await initSut()

    given(mockKeychainAPIValidator)
      .validateOpenRouterAPI()
      .willReturn(.missingApiKey)

    given(mockKeychainService)
      .retrieve(key: .value(KeychainKey.openRouterApiKey.key))
      .willReturn("existing-key")

    await sut.selectProvider(.openRouter)

    XCTAssertTrue(sut.showAPIKeyAlert)
    XCTAssertEqual(sut.existingAPIKey, "existing-key")

    sut.dismissAPIKeyAlert()

    XCTAssertFalse(sut.showAPIKeyAlert)
    XCTAssertNil(sut.existingAPIKey)
  }
}
