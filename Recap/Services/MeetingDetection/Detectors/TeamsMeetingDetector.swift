import Foundation
import ScreenCaptureKit

@MainActor
final class TeamsMeetingDetector: MeetingDetectorType {
  @Published private(set) var isMeetingActive = false
  @Published private(set) var meetingTitle: String?

  let meetingAppName = "Microsoft Teams"
  let supportedBundleIdentifiers: Set<String> = [
    "com.microsoft.teams",
    "com.microsoft.teams2"
  ]

  private let patternMatcher: MeetingPatternMatcher

  init() {
    self.patternMatcher = MeetingPatternMatcher(patterns: MeetingPatternMatcher.teamsPatterns)
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
