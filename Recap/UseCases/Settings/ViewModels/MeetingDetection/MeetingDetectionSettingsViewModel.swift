import Foundation
import SwiftUI

@MainActor
final class MeetingDetectionSettingsViewModel: MeetingDetectionSettingsViewModelType {
  @Published var hasScreenRecordingPermission = false
  @Published var autoDetectMeetings = false

  private let detectionService: any MeetingDetectionServiceType
  private let userPreferencesRepository: UserPreferencesRepositoryType
  private let permissionsHelper: any PermissionsHelperType

  init(
    detectionService: any MeetingDetectionServiceType,
    userPreferencesRepository: UserPreferencesRepositoryType,
    permissionsHelper: any PermissionsHelperType
  ) {
    self.detectionService = detectionService
    self.userPreferencesRepository = userPreferencesRepository
    self.permissionsHelper = permissionsHelper

    Task {
      await loadCurrentSettings()
    }
  }

  private func loadCurrentSettings() async {
    guard let preferences = try? await userPreferencesRepository.getOrCreatePreferences() else {
      return
    }

    withAnimation(.easeInOut(duration: 0.2)) {
      autoDetectMeetings = preferences.autoDetectMeetings
    }
  }

  func handleAutoDetectToggle(_ enabled: Bool) async {
    try? await userPreferencesRepository.updateAutoDetectMeetings(enabled)

    withAnimation(.easeInOut(duration: 0.2)) {
      autoDetectMeetings = enabled
    }

    if enabled {
      let hasPermission = await permissionsHelper.checkScreenCapturePermission()
      hasScreenRecordingPermission = hasPermission

      if hasPermission {
        detectionService.startMonitoring()
      } else {
        openScreenRecordingPreferences()
      }
    } else {
      detectionService.stopMonitoring()
    }

  }

  func checkPermissionStatus() async {
    hasScreenRecordingPermission = await permissionsHelper.checkScreenCapturePermission()

    if autoDetectMeetings && hasScreenRecordingPermission {
      detectionService.startMonitoring()
    }
  }

  func openScreenRecordingPreferences() {
    if let url = URL(
      string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
      NSWorkspace.shared.open(url)
    }
  }
}
