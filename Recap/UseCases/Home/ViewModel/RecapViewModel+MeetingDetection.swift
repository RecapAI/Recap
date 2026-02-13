import Combine
import Foundation
import SwiftUI

// MARK: - Meeting Detection Setup
extension RecapViewModel {
  func setupMeetingDetection() {
    Task {
      guard await shouldEnableMeetingDetection() else { return }

      setupMeetingStateObserver()
      await startMonitoringIfPermissionGranted()
    }
  }
}

// MARK: - Private Setup Helpers
extension RecapViewModel {
  fileprivate func shouldEnableMeetingDetection() async -> Bool {
    do {
      let preferences = try await userPreferencesRepository.getOrCreatePreferences()
      return preferences.autoDetectMeetings
    } catch {
      logger.error("Failed to load meeting detection preferences: \(error)")
      return false
    }
  }

  fileprivate func setupMeetingStateObserver() {
    meetingDetectionService.meetingStatePublisher
      .sink { [weak self] meetingState in
        guard let self = self else { return }
        self.handleMeetingStateChange(meetingState)
      }
      .store(in: &cancellables)
  }

  fileprivate func startMonitoringIfPermissionGranted() async {
    if await permissionsHelper.checkScreenCapturePermission() {
      meetingDetectionService.startMonitoring()
    } else {
      logger.warning("Meeting detection permission denied")
    }
  }
}

// MARK: - Meeting State Handling
extension RecapViewModel {
  fileprivate func handleMeetingStateChange(_ meetingState: MeetingState) {
    switch meetingState {
    case .active(let info, let detectedApp):
      handleMeetingDetected(info: info, detectedApp: detectedApp)
    case .inactive:
      handleMeetingEnded()
    }
  }

  fileprivate func handleMeetingDetected(info: ActiveMeetingInfo, detectedApp: AudioProcess?) {
    autoSelectAppIfAvailable(detectedApp)

    let currentMeetingKey = "\(info.appName)-\(info.title)"
    if lastNotifiedMeetingKey != currentMeetingKey {
      lastNotifiedMeetingKey = currentMeetingKey
      sendMeetingStartedNotification(appName: info.appName, title: info.title)
    }
  }

  fileprivate func handleMeetingEnded() {
    lastNotifiedMeetingKey = nil
    sendMeetingEndedNotification()
  }
}

// MARK: - App Auto-Selection
extension RecapViewModel {
  fileprivate func autoSelectAppIfAvailable(_ detectedApp: AudioProcess?) {
    guard let detectedApp else {
      return
    }

    appSelectionCoordinator.autoSelectApp(detectedApp)
  }
}

// MARK: - Notification Helpers
extension RecapViewModel {
  fileprivate func sendMeetingStartedNotification(appName: String, title: String) {
    Task {
      await notificationService.sendMeetingStartedNotification(appName: appName, title: title)
    }
  }

  fileprivate func sendMeetingEndedNotification() {
    // Future enhancement: Analyze audio levels, and if silence is detected, send a notification here.
  }
}

// MARK: - Supporting Types
private enum MeetingDetectionConstants {
  static let autoSelectionAnimationDuration: Double = 0.3
}
