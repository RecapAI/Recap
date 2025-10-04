import Foundation
import ScreenCaptureKit

#if MOCKING
  import Mockable
#endif

// MARK: - Window Protocol for Testing

protocol WindowTitleProviding {
  var title: String? { get }
}

extension SCWindow: WindowTitleProviding {}

@MainActor
#if MOCKING
  @Mockable
#endif
protocol MeetingDetectorType: ObservableObject {
  var isMeetingActive: Bool { get }
  var meetingTitle: String? { get }
  var meetingAppName: String { get }
  var supportedBundleIdentifiers: Set<String> { get }

  func checkForMeeting(in windows: [any WindowTitleProviding]) async -> MeetingDetectionResult
}

struct MeetingDetectionResult {
  let isActive: Bool
  let title: String?
  let confidence: MeetingConfidence

  enum MeetingConfidence {
    case high
    case medium
    case low
  }
}
