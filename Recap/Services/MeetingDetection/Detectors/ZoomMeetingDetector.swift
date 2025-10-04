import Foundation
import ScreenCaptureKit

@MainActor
final class ZoomMeetingDetector: MeetingDetectorType {
  @Published private(set) var isMeetingActive = false
  @Published private(set) var meetingTitle: String?

  let meetingAppName = "Zoom"
  let supportedBundleIdentifiers: Set<String> = ["us.zoom.xos"]

  private let patternMatcher: MeetingPatternMatcher

  init() {
    self.patternMatcher = MeetingPatternMatcher(patterns: MeetingPatternMatcher.zoomPatterns)
  }

  func checkForMeeting(in windows: [any WindowTitleProviding]) async -> MeetingDetectionResult {
    for window in windows {
      guard let title = window.title, !title.isEmpty else { continue }

      if let confidence = patternMatcher.findBestMatch(in: title) {
        return MeetingDetectionResult(
          isActive: true,
          title: title,
          confidence: confidence
        )
      }
    }

    return MeetingDetectionResult(
      isActive: false,
      title: nil,
      confidence: .low
    )
  }
}
