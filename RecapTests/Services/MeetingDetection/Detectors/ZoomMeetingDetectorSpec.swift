import Mockable
import ScreenCaptureKit
import XCTest

@testable import Recap

@MainActor
final class ZoomMeetingDetectorSpec: XCTestCase {
  private var sut: ZoomMeetingDetector!

  override func setUp() async throws {
    try await super.setUp()
    sut = ZoomMeetingDetector()
  }

  override func tearDown() async throws {
    sut = nil
    try await super.tearDown()
  }

  func testMeetingAppName() {
    XCTAssertEqual(sut.meetingAppName, "Zoom")
  }

  func testSupportedBundleIdentifiers() {
    let expected: Set<String> = ["us.zoom.xos"]
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

  func testCheckForMeetingWithZoomWindow() async {
    let meetingTitle = "Zoom Meeting - Team Standup"
    let mockWindow = MockWindow(title: meetingTitle)
    let result = await sut.checkForMeeting(in: [mockWindow])

    XCTAssertTrue(result.isActive)
    XCTAssertEqual(result.title, meetingTitle)
    XCTAssertNotEqual(result.confidence, .low)
  }

  func testCheckForMeetingWithZoomCall() async {
    let meetingTitle = "Zoom - Personal Meeting Room"
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
    let meetingTitle1 = "Zoom Meeting - Client Call"
    let meetingTitle2 = "Zoom - Another Meeting"
    let mockWindow1 = MockWindow(title: meetingTitle1)
    let mockWindow2 = MockWindow(title: meetingTitle2)

    let result = await sut.checkForMeeting(in: [mockWindow1, mockWindow2])

    XCTAssertTrue(result.isActive)
    XCTAssertEqual(result.title, meetingTitle1)
  }

  func testCheckForMeetingWithMixedCaseZoom() async {
    let meetingTitle = "zoom meeting with team"
    let mockWindow = MockWindow(title: meetingTitle)
    let result = await sut.checkForMeeting(in: [mockWindow])

    XCTAssertTrue(result.isActive)
    XCTAssertEqual(result.title, meetingTitle)
    XCTAssertNotEqual(result.confidence, .low)
  }

  func testCheckForMeetingWithZoomWebinar() async {
    let meetingTitle = "Zoom Webinar - Product Launch"
    let mockWindow = MockWindow(title: meetingTitle)
    let result = await sut.checkForMeeting(in: [mockWindow])

    XCTAssertTrue(result.isActive)
    XCTAssertEqual(result.title, meetingTitle)
    XCTAssertNotEqual(result.confidence, .low)
  }
}
