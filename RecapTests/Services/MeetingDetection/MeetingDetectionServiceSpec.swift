import Combine
import Mockable
import XCTest

@testable import Recap

@MainActor
final class MeetingDetectionServiceSpec: XCTestCase {
  private var sut: MeetingDetectionService!
  private var mockAudioProcessController: MockAudioProcessControllerType!
  private var cancellables: Set<AnyCancellable>!

  override func setUp() async throws {
    try await super.setUp()

    mockAudioProcessController = MockAudioProcessControllerType()
    cancellables = Set<AnyCancellable>()

    let emptyProcesses: [AudioProcess] = []
    let emptyGroups: [AudioProcessGroup] = []

    given(mockAudioProcessController)
      .processes
      .willReturn(emptyProcesses)

    given(mockAudioProcessController)
      .processGroups
      .willReturn(emptyGroups)

    given(mockAudioProcessController)
      .meetingApps
      .willReturn(emptyProcesses)

    let mockPermissionsHelper = MockPermissionsHelperType()
    sut = MeetingDetectionService(
      audioProcessController: mockAudioProcessController,
      permissionsHelper: mockPermissionsHelper)
  }

  override func tearDown() async throws {
    sut = nil
    mockAudioProcessController = nil
    cancellables = nil

    try await super.tearDown()
  }

  // MARK: - Initialization Tests

  func testInitialState() {
    XCTAssertFalse(sut.isMeetingActive)
    XCTAssertNil(sut.activeMeetingInfo)
    XCTAssertNil(sut.detectedMeetingApp)
    XCTAssertFalse(sut.hasPermission)
    XCTAssertFalse(sut.isMonitoring)
  }

  // MARK: - Monitoring Tests

  func testStartMonitoring() {
    XCTAssertFalse(sut.isMonitoring)

    sut.startMonitoring()

    XCTAssertTrue(sut.isMonitoring)
  }

  func testStopMonitoring() {
    sut.startMonitoring()
    XCTAssertTrue(sut.isMonitoring)

    sut.stopMonitoring()

    XCTAssertFalse(sut.isMonitoring)
    XCTAssertFalse(sut.isMeetingActive)
    XCTAssertNil(sut.activeMeetingInfo)
    XCTAssertNil(sut.detectedMeetingApp)
  }

  func testStartMonitoringTwiceDoesNotDuplicate() {
    sut.startMonitoring()
    let firstIsMonitoring = sut.isMonitoring

    sut.startMonitoring()

    XCTAssertEqual(firstIsMonitoring, sut.isMonitoring)
    XCTAssertTrue(sut.isMonitoring)
  }

  func testMeetingStatePublisherEmitsInactive() async throws {
    let expectation = XCTestExpectation(description: "Meeting state publisher emits inactive")

    sut.meetingStatePublisher
      .sink { state in
        if case .inactive = state {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    await fulfillment(of: [expectation], timeout: 1.0)
  }

  func testMeetingStatePublisherRemovesDuplicates() async throws {
    var receivedStates: [MeetingState] = []

    sut.meetingStatePublisher
      .sink { state in
        receivedStates.append(state)
      }
      .store(in: &cancellables)

    try await Task.sleep(nanoseconds: 100_000_000)

    XCTAssertEqual(receivedStates.count, 1)
    XCTAssertEqual(receivedStates.first, .inactive)
  }

  func testStopMonitoringClearsAllState() {
    sut.startMonitoring()

    sut.stopMonitoring()

    XCTAssertFalse(sut.isMeetingActive)
    XCTAssertNil(sut.activeMeetingInfo)
    XCTAssertNil(sut.detectedMeetingApp)
    XCTAssertFalse(sut.isMonitoring)
  }

  func testMeetingDetectionServiceRespectsControllerProcesses() {
    let teamsProcess = TestData.createAudioProcess(
      name: "Microsoft Teams",
      bundleID: "com.microsoft.teams2"
    )

    let processes: [RecapTests.AudioProcess] = [teamsProcess]

    given(mockAudioProcessController)
      .processes
      .willReturn(processes)

    verify(mockAudioProcessController)
      .processes
      .called(0)
  }
}

// MARK: - Test Helpers

private enum TestData {
  static func createAudioProcess(
    name: String,
    bundleID: String? = nil
  ) -> RecapTests.AudioProcess {
    RecapTests.AudioProcess(
      id: pid_t(Int32.random(in: 1000...9999)),
      kind: .app,
      name: name,
      audioActive: true,
      bundleID: bundleID,
      bundleURL: nil,
      objectID: 0
    )
  }
}
