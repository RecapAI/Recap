import Foundation
import ScreenCaptureKit

@MainActor
final class GoogleMeetDetector: MeetingDetectorType {
  @Published private(set) var isMeetingActive = false
  @Published private(set) var meetingTitle: String?

  let meetingAppName = "Google Meet"
  let supportedBundleIdentifiers: Set<String> = [
    "com.google.Chrome",
    "com.apple.Safari",
    "org.mozilla.firefox",
    "com.microsoft.edgemac"
  ]

  private let patternMatcher: MeetingPatternMatcher

  init() {
    self.patternMatcher = MeetingPatternMatcher(patterns: MeetingPatternMatcher.googleMeetPatterns)
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
