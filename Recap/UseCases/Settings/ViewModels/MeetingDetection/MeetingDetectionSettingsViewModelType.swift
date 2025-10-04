import Foundation

@MainActor
protocol MeetingDetectionSettingsViewModelType: ObservableObject {
  var hasScreenRecordingPermission: Bool { get }
  var autoDetectMeetings: Bool { get }

  func handleAutoDetectToggle(_ enabled: Bool) async
  func checkPermissionStatus() async
  func openScreenRecordingPreferences()
}
