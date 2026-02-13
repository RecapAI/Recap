import AVFoundation
import Foundation

#if MOCKING
  import Mockable
#endif

#if MOCKING
  @Mockable
#endif
@MainActor
protocol PermissionsHelperType: AnyObject {
  func requestMicrophonePermission() async -> Bool
  func requestScreenRecordingPermission() async -> Bool
  func requestNotificationPermission() async -> Bool
  func checkMicrophonePermissionStatus() -> AVAuthorizationStatus
  func checkNotificationPermissionStatus() async -> Bool
  func checkScreenRecordingPermission() -> Bool
  func checkScreenCapturePermission() async -> Bool
}
