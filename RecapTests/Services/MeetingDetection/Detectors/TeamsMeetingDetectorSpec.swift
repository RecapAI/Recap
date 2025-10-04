import Mockable
import ScreenCaptureKit
import XCTest

@testable import Recap

@MainActor
final class TeamsMeetingDetectorSpec: XCTestCase {
  private var sut: TeamsMeetingDetector!

  override func setUp() async throws {
    try await super.setUp()
    sut = TeamsMeetingDetector()
  }

  override func tearDown() async throws {
    sut = nil
    try await super.tearDown()
  }

  func testMeetingAppName() {
    XCTAssertEqual(sut.meetingAppName, "Microsoft Teams")
  }

  func testSupportedBundleIdentifiers() {
    let expected: Set<String> = [
      "com.microsoft.teams",
      "com.microsoft.teams2"
    ]
    XCTAssertEqual(sut.supportedBundleIdentifiers, expected)
  }

  func testInitialState() {
    XCTAssertFalse(sut.isMeetingActive)
    XCTAssertNil(sut.meetingTitle)
  }

  func testCheckForMeetingWithEmptyWindows() async {
    let result = await sut.checkForMeeting(in: [])

    XCTAssertFalse(result.isActive)
    XCTAssertNil(result.title)
    XCTAssertEqual(result.confidence, .low)
  }

  func testCheckForMeetingWithNoMatchingWindows() async {
    let mockWindow = MockWindow(title: "Random Window Title")
    let result = await sut.checkForMeeting(in: [mockWindow])

    XCTAssertFalse(result.isActive)
    XCTAssertNil(result.title)
    XCTAssertEqual(result.confidence, .low)
  }

  func testCheckForMeetingWithTeamsWindow() async {
    let meetingTitle = "Microsoft Teams - Team Meeting"
    let mockWindow = MockWindow(title: meetingTitle)
    let result = await sut.checkForMeeting(in: [mockWindow])

    XCTAssertTrue(result.isActive)
    XCTAssertEqual(result.title, meetingTitle)
    XCTAssertNotEqual(result.confidence, .low)
  }

  func testCheckForMeetingWithTeamsCallWindow() async {
    let meetingTitle = "Teams Call - John Doe"
    let mockWindow = MockWindow(title: meetingTitle)
    let result = await sut.checkForMeeting(in: [mockWindow])

    XCTAssertTrue(result.isActive)
    XCTAssertEqual(result.title, meetingTitle)
    XCTAssertNotEqual(result.confidence, .low)
  }

  func testCheckForMeetingWithEmptyTitle() async {
    let mockWindow = MockWindow(title: "")
    let result = await sut.checkForMeeting(in: [mockWindow])

    XCTAssertFalse(result.isActive)
    XCTAssertNil(result.title)
    XCTAssertEqual(result.confidence, .low)
  }

  func testCheckForMeetingWithNilTitle() async {
    let mockWindow = MockWindow(title: nil)
    let result = await sut.checkForMeeting(in: [mockWindow])

    XCTAssertFalse(result.isActive)
    XCTAssertNil(result.title)
    XCTAssertEqual(result.confidence, .low)
  }

  func testCheckForMeetingReturnsFirstMatch() async {
    let meetingTitle1 = "Microsoft Teams - Team Meeting"
    let meetingTitle2 = "Teams Call - Another Meeting"
    let mockWindow1 = MockWindow(title: meetingTitle1)
    let mockWindow2 = MockWindow(title: meetingTitle2)

    let result = await sut.checkForMeeting(in: [mockWindow1, mockWindow2])

    XCTAssertTrue(result.isActive)
    XCTAssertEqual(result.title, meetingTitle1)
  }

  func testCheckForMeetingWithMixedCaseTeams() async {
    let meetingTitle = "teams call with client"
    let mockWindow = MockWindow(title: meetingTitle)
    let result = await sut.checkForMeeting(in: [mockWindow])

    XCTAssertTrue(result.isActive)
    XCTAssertEqual(result.title, meetingTitle)
    XCTAssertNotEqual(result.confidence, .low)
  }
}
