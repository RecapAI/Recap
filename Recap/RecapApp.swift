//
//  RecapApp.swift
//  Recap
//
//  Created by Rawand Ahmad on 22/07/2025.
//

import AppKit
import SwiftUI
import UserNotifications

@main
struct RecapApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    // We don't need any scenes since we're using NSStatusItem
    Settings {
      EmptyView()
    }
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  private var panelManager: MenuBarPanelManager?
  private var dependencyContainer: DependencyContainer?
  private var globalShortcutManager: GlobalShortcutManager?

  func applicationDidFinishLaunching(_ notification: Notification) {
    Task { @MainActor in
      dependencyContainer = DependencyContainer()
      panelManager = dependencyContainer?.createMenuBarPanelManager()

      // Setup global shortcut manager
      globalShortcutManager = GlobalShortcutManager()
      globalShortcutManager?.setDelegate(self)

      // Load global shortcut from user preferences
      await loadGlobalShortcutFromPreferences()

      UNUserNotificationCenter.current().delegate = self
    }
  }

  private func loadGlobalShortcutFromPreferences() async {
    guard let dependencyContainer = dependencyContainer else { return }

    do {
      let preferences = try await dependencyContainer.userPreferencesRepository
        .getOrCreatePreferences()
      await globalShortcutManager?.registerShortcut(
        keyCode: UInt32(preferences.globalShortcutKeyCode),
        modifiers: UInt32(preferences.globalShortcutModifiers)
      )
    } catch {
      // Fallback to default shortcut if loading preferences fails
      await globalShortcutManager?.registerDefaultShortcut()
    }
  }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    Task { @MainActor in
      if response.notification.request.content.userInfo["action"] as? String == "open_app" {
        panelManager?.showMainPanel()
      }
    }
    completionHandler()
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
    withCompletionHandler completionHandler:
      @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }
}

extension AppDelegate: GlobalShortcutDelegate {
  func globalShortcutActivated() {
    Task { @MainActor in
      // Toggle recording state when global shortcut is pressed
      if let panelManager = panelManager {
        if panelManager.recapViewModel.isRecording {
          await panelManager.recapViewModel.stopRecording()
        } else {
          await panelManager.startRecordingForAllApplications()
        }
      }
    }
  }
}
