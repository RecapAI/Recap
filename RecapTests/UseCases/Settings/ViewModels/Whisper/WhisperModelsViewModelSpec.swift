import Combine
import Mockable
import XCTest

@testable import Recap

@MainActor
final class WhisperModelsViewModelSpec: XCTestCase {
  private var sut: WhisperModelsViewModel!
  private var mockRepository = MockWhisperModelRepositoryType()
  private var cancellables = Set<AnyCancellable>()

  override func setUp() async throws {
    try await super.setUp()

    given(mockRepository)
      .getAllModels()
      .willReturn([])

    sut = WhisperModelsViewModel(repository: mockRepository)
    try await Task.sleep(nanoseconds: 100_000_000)
  }

  override func tearDown() async throws {
    sut = nil
    cancellables.removeAll()

    try await super.tearDown()
  }

  func testLoadModelsSuccess() async throws {
    sut.downloadedModels = Set(["tiny", "small"])
    sut.selectedModel = "small"

    XCTAssertEqual(sut.downloadedModels, Set(["tiny", "small"]))
    XCTAssertEqual(sut.selectedModel, "small")
    XCTAssertNil(sut.errorMessage)
    XCTAssertFalse(sut.showingError)
  }

  func testSelectModelSuccess() async throws {
    sut.downloadedModels.insert("small")

    given(mockRepository)
      .setSelectedModel(name: .value("small"))
      .willReturn()

    let expectation = XCTestExpectation(description: "Model selection completes")

    sut.$selectedModel
      .dropFirst()
      .sink { selectedModel in
        if selectedModel == "small" {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    sut.selectModel("small")

    await fulfillment(of: [expectation], timeout: 2.0)

    XCTAssertEqual(sut.selectedModel, "small")
    XCTAssertNil(sut.errorMessage)

    verify(mockRepository)
      .setSelectedModel(name: .value("small"))
      .called(1)
  }

  func testSelectModelNotDownloaded() async throws {
    XCTAssertFalse(sut.downloadedModels.contains("large"))

    sut.selectModel("large")

    try await Task.sleep(nanoseconds: 100_000_000)

    XCTAssertNil(sut.selectedModel)

    verify(mockRepository)
      .setSelectedModel(name: .any)
      .called(0)
  }

  func testSelectModelDeselection() async throws {
    sut.downloadedModels.insert("small")
    sut.selectedModel = "small"

    given(mockRepository)
      .getAllModels()
      .willReturn([createTestModel(name: "small", isDownloaded: true, isSelected: true)])

    given(mockRepository)
      .updateModel(.any)
      .willReturn()

    sut.selectModel("small")

    try await Task.sleep(nanoseconds: 100_000_000)

    XCTAssertNil(sut.selectedModel)
  }

  func testSelectModelError() async throws {
    sut.downloadedModels.insert("small")

    given(mockRepository)
      .setSelectedModel(name: .any)
      .willThrow(NSError(domain: "TestError", code: 500))

    sut.selectModel("small")

    try await Task.sleep(nanoseconds: 100_000_000)

    XCTAssertNotNil(sut.errorMessage)
    XCTAssertTrue(sut.showingError)
  }

  func testToggleTooltipShow() {
    let position = CGPoint(x: 100, y: 200)

    XCTAssertNil(sut.showingTooltipForModel)

    sut.toggleTooltip(for: "small", at: position)

    XCTAssertEqual(sut.showingTooltipForModel, "small")
    XCTAssertEqual(sut.tooltipPosition, position)
  }

  func testToggleTooltipHide() {
    sut.showingTooltipForModel = "small"

    sut.toggleTooltip(for: "small", at: .zero)

    XCTAssertNil(sut.showingTooltipForModel)
  }

  func testGetModelInfo() {
    let tinyInfo = sut.getModelInfo("tiny")
    XCTAssertNotNil(tinyInfo)
    XCTAssertEqual(tinyInfo?.displayName, "Tiny Model")

    let unknownInfo = sut.getModelInfo("unknown")
    XCTAssertNil(unknownInfo)
  }

  func testGetModelInfoWithVersionSuffix() {
    let largeV2Info = sut.getModelInfo("large-v2")
    XCTAssertNotNil(largeV2Info)
    XCTAssertEqual(largeV2Info?.displayName, "Large Model")

    let largeV3Info = sut.getModelInfo("large-v3")
    XCTAssertNotNil(largeV3Info)
    XCTAssertEqual(largeV3Info?.displayName, "Large Model")
  }

  func testModelDisplayName() {
    XCTAssertEqual(sut.modelDisplayName("large-v2"), "Large v2")
    XCTAssertEqual(sut.modelDisplayName("large-v3"), "Large v3")
    XCTAssertEqual(
      sut.modelDisplayName("distil-whisper_distil-large-v3_turbo"), "Distil Large v3 Turbo")
    XCTAssertEqual(sut.modelDisplayName("small"), "Small")
    XCTAssertEqual(sut.modelDisplayName("tiny"), "Tiny")
  }
}

extension WhisperModelsViewModelSpec {
  fileprivate func createTestModel(
    name: String,
    isDownloaded: Bool = false,
    isSelected: Bool = false,
    downloadedAt: Date? = nil,
    fileSizeInMB: Int64? = nil,
    variant: String? = nil
  ) -> WhisperModelData {
    WhisperModelData(
      name: name,
      isDownloaded: isDownloaded,
      isSelected: isSelected,
      downloadedAt: downloadedAt,
      fileSizeInMB: fileSizeInMB,
      variant: variant
    )
  }
}
