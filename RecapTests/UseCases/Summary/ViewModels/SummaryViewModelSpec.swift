import XCTest
import Combine
import Mockable
@testable import Recap

@MainActor
final class SummaryViewModelSpec: XCTestCase {
    private var sut: SummaryViewModel!
    private var mockRecordingRepository = MockRecordingRepositoryType()
    private var mockProcessingCoordinator = MockProcessingCoordinatorType()
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        sut = SummaryViewModel(
            recordingRepository: mockRecordingRepository,
            processingCoordinator: mockProcessingCoordinator
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        cancellables.removeAll()
        
        try await super.tearDown()
    }
    
    func testLoadRecordingSuccess() async throws {
        let expectedRecording = createTestRecording(id: "test-id", state: .completed)
        
        given(mockRecordingRepository)
            .fetchRecording(id: .value("test-id"))
            .willReturn(expectedRecording)
        
        let expectation = XCTestExpectation(description: "Loading completes")
        
        sut.$isLoadingRecording
            .dropFirst()
            .sink { isLoading in
                if !isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        sut.loadRecording(withID: "test-id")
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertEqual(sut.currentRecording, expectedRecording)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testLoadRecordingFailure() async throws {
        let error = NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
        
        given(mockRecordingRepository)
            .fetchRecording(id: .any)
            .willThrow(error)
        
        let expectation = XCTestExpectation(description: "Loading completes")
        
        sut.$isLoadingRecording
            .dropFirst()
            .sink { isLoading in
                if !isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        sut.loadRecording(withID: "test-id")
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertNil(sut.currentRecording)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Failed to load recording") ?? false)
    }
    
    func testProcessingStageComputation() {
        sut.currentRecording = createTestRecording(state: .recorded)
        XCTAssertEqual(sut.processingStage, ProcessingStatesCard.ProcessingStage.recorded)
        
        sut.currentRecording = createTestRecording(state: .transcribing)
        XCTAssertEqual(sut.processingStage, ProcessingStatesCard.ProcessingStage.transcribing)
        
        sut.currentRecording = createTestRecording(state: .summarizing)
        XCTAssertEqual(sut.processingStage, ProcessingStatesCard.ProcessingStage.summarizing)
        
        sut.currentRecording = createTestRecording(state: .completed)
        XCTAssertNil(sut.processingStage)
    }
    
    func testHasSummaryComputation() {
        sut.currentRecording = createTestRecording(
            state: .completed,
            summaryText: "Test summary"
        )
        XCTAssertTrue(sut.hasSummary)
        
        sut.currentRecording = createTestRecording(
            state: .completed,
            summaryText: nil
        )
        XCTAssertFalse(sut.hasSummary)
    }
    
    func testRetryProcessingForTranscriptionFailed() async throws {
        let recording = createTestRecording(id: "test-id", state: .transcriptionFailed)
        sut.currentRecording = recording
        
        given(mockProcessingCoordinator)
            .retryProcessing(recordingID: .any)
            .willReturn()
        
        given(mockRecordingRepository)
            .fetchRecording(id: .any)
            .willReturn(recording)
        
        await sut.retryProcessing()
        
        verify(mockProcessingCoordinator)
            .retryProcessing(recordingID: .any)
            .called(1)
    }
    
    func testCopySummaryShowsToast() async throws {
        let recording = createTestRecording(
            state: .completed,
            summaryText: "Test summary content"
        )
        sut.currentRecording = recording
        
        XCTAssertFalse(sut.showingCopiedToast)
        
        sut.copySummary()
        
        XCTAssertTrue(sut.showingCopiedToast)
        
        try await Task.sleep(nanoseconds: 2_500_000_000)
        
        XCTAssertFalse(sut.showingCopiedToast)
    }
}

private extension SummaryViewModelSpec {
    func createTestRecording(
        id: String = UUID().uuidString,
        state: RecordingProcessingState = .completed,
        summaryText: String? = nil
    ) -> RecordingInfo {
        RecordingInfo(
            id: id,
            startDate: Date(),
            endDate: Date().addingTimeInterval(300),
            state: state,
            errorMessage: nil,
            recordingURL: URL(fileURLWithPath: "/test/recording.mp4"),
            microphoneURL: nil,
            hasMicrophoneAudio: false,
            applicationName: "Test App",
            transcriptionText: "Test transcription",
            summaryText: summaryText,
            timestampedTranscription: nil,
            createdAt: Date(),
            modifiedAt: Date()
        )
    }
}
