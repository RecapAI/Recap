import Mockable
import ScreenCaptureKit
import XCTest

@testable import Recap

@MainActor
final class GoogleMeetDetectorSpec: XCTestCase {
  private var sut: GoogleMeetDetector!

  override func setUp() async throws {
    try await super.setUp()
    sut = GoogleMeetDetector()
  }

  override func tearDown() async throws {
    sut = nil
    try await super.tearDown()
  }

  func testMeetingAppName() {
    XCTAssertEqual(sut.meetingAppName, "Google Meet")
  }

  func testSupportedBundleIdentifiers() {
    let expected: Set<String> = [
      "com.google.Chrome",
      "com.apple.Safari",
      "org.mozilla.firefox",
      "com.microsoft.edgemac"
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

  func testCheckForMeetingWithGoogleMeetWindow() async {
    let meetingTitle = "Google Meet - Team Meeting"
    let mockWindow = MockWindow(title: meetingTitle)
    let result = await sut.checkForMeeting(in: [mockWindow])

    XCTAssertTrue(result.isActive)
    XCTAssertEqual(result.title, meetingTitle)
    XCTAssertEqual(result.confidence, .high)
  }

  func testCheckForMeetingWithGoogleMeetURL() async {
    let meetingTitle = "meet.google.com/abc-def-ghi - Chrome"
    let mockWindow = MockWindow(title: meetingTitle)
    let result = await sut.checkForMeeting(in: [mockWindow])

    XCTAssertTrue(result.isActive)
    XCTAssertEqual(result.title, meetingTitle)
    XCTAssertEqual(result.confidence, .high)
  }

  func testCheckForMeetingWithMeetDash() async {
    let meetingTitle = "Meet - Team Standup"
    let mockWindow = MockWindow(title: meetingTitle)
    let result = await sut.checkForMeeting(in: [mockWindow])

    XCTAssertTrue(result.isActive)
    XCTAssertEqual(result.title, meetingTitle)
    XCTAssertEqual(result.confidence, .medium)
  }

  func testCheckForMeetingWithMeetKeyword() async {
    let meetingTitle = "Team meeting with John"
    let mockWindow = MockWindow(title: meetingTitle)
    let result = await sut.checkForMeeting(in: [mockWindow])

    XCTAssertTrue(result.isActive)
    XCTAssertEqual(result.title, meetingTitle)
    XCTAssertEqual(result.confidence, .medium)
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
    let meetingTitle1 = "Google Meet - Team Meeting"
    let meetingTitle2 = "Another Meet Window"
    let mockWindow1 = MockWindow(title: meetingTitle1)
    let mockWindow2 = MockWindow(title: meetingTitle2)

    let result = await sut.checkForMeeting(in: [mockWindow1, mockWindow2])

    XCTAssertTrue(result.isActive)
    XCTAssertEqual(result.title, meetingTitle1)
  }
}
