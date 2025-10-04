import Combine
import Foundation

#if MOCKING
  import Mockable
#endif

@MainActor
#if MOCKING
  @Mockable
#endif
protocol MeetingDetectionServiceType: ObservableObject {
  var isMeetingActive: Bool { get }
  var activeMeetingInfo: ActiveMeetingInfo? { get }
  var detectedMeetingApp: AudioProcess? { get }
  var hasPermission: Bool { get }
  var isMonitoring: Bool { get }

  var meetingStatePublisher: AnyPublisher<MeetingState, Never> { get }

  func startMonitoring()
  func stopMonitoring()
}

struct ActiveMeetingInfo {
  let appName: String
  let title: String
  let confidence: MeetingDetectionResult.MeetingConfidence
}

enum MeetingState: Equatable {
  case inactive
  case active(info: ActiveMeetingInfo, detectedApp: AudioProcess?)

  static func == (lhs: MeetingState, rhs: MeetingState) -> Bool {
    switch (lhs, rhs) {
    case (.inactive, .inactive):
      return true
    case (.active(let lhsInfo, _), .active(let rhsInfo, _)):
      return lhsInfo.title == rhsInfo.title && lhsInfo.appName == rhsInfo.appName
    default:
      return false
    }
  }
}
