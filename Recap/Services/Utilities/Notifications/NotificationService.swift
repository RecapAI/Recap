import Foundation
import OSLog
import UserNotifications

@MainActor
final class NotificationService: NotificationServiceType {
  private let logger = Logger(
    subsystem: AppConstants.Logging.subsystem, category: "NotificationService")
  private let notificationCenter = UNUserNotificationCenter.current()

  func sendMeetingStartedNotification(appName: String, title: String) async {
    let content = UNMutableNotificationContent()
    content.title = "\(appName): Meeting Detected"
    content.body = "Want to start recording it?"
    content.sound = .default
    content.categoryIdentifier = "MEETING_ACTIONS"
    content.userInfo = ["action": "open_app"]

    await sendNotification(identifier: "meeting-started", content: content)
  }

  func sendMeetingEndedNotification() async {
    let content = UNMutableNotificationContent()
    content.title = "Meeting Ended"
    content.body = "The meeting has ended"
    content.sound = .default

    await sendNotification(identifier: "meeting-ended", content: content)
  }
}

extension NotificationService {
  fileprivate func sendNotification(identifier: String, content: UNMutableNotificationContent) async {
    let request = UNNotificationRequest(
      identifier: identifier,
      content: content,
      trigger: nil
    )

    do {
      try await notificationCenter.add(request)
    } catch {
      logger.error("Failed to send notification \(identifier): \(error)")
    }
  }
}
