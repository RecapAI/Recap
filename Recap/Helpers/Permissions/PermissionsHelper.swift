import AVFoundation
import Foundation
import ScreenCaptureKit
import UserNotifications

@MainActor
final class PermissionsHelper: PermissionsHelperType {
  func requestMicrophonePermission() async -> Bool {
    await withCheckedContinuation { continuation in
      AVCaptureDevice.requestAccess(for: .audio) { granted in
        continuation.resume(returning: granted)
      }
    }
  }

  func requestScreenRecordingPermission() async -> Bool {
    do {
      _ = try await SCShareableContent.current
      return true
    } catch {
      return false
    }
  }

  func requestNotificationPermission() async -> Bool {
    do {
      let center = UNUserNotificationCenter.current()
      let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
      return granted
    } catch {
      return false
    }
  }

  func checkMicrophonePermissionStatus() -> AVAuthorizationStatus {
    AVCaptureDevice.authorizationStatus(for: .audio)
  }

  func checkNotificationPermissionStatus() async -> Bool {
    await withCheckedContinuation { continuation in
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        continuation.resume(returning: settings.authorizationStatus == .authorized)
      }
    }
  }

  func checkScreenRecordingPermission() -> Bool {
    if #available(macOS 11.0, *) {
      return CGPreflightScreenCaptureAccess()
    } else {
      return true
    }
  }

  func checkScreenCapturePermission() async -> Bool {
    do {
      _ = try await SCShareableContent.current
      return true
    } catch {
      return false
    }
  }
}
