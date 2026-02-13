import Foundation

@MainActor
protocol NotificationServiceType {
  func sendMeetingStartedNotification(appName: String, title: String) async
  func sendMeetingEndedNotification() async
}
