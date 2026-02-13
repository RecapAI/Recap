import AppKit
import Foundation

@MainActor
protocol SystemLifecycleDelegate: AnyObject {
  func systemWillSleep()
  func systemDidWake()
}

@MainActor
final class SystemLifecycleManager {
  weak var delegate: SystemLifecycleDelegate?

  private var sleepObserver: NSObjectProtocol?
  private var wakeObserver: NSObjectProtocol?

  init() {
    setupNotifications()
  }

  private func setupNotifications() {
    let workspace = NSWorkspace.shared
    let notificationCenter = workspace.notificationCenter

    sleepObserver = notificationCenter.addObserver(
      forName: NSWorkspace.willSleepNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.delegate?.systemWillSleep()
      }
    }

    wakeObserver = notificationCenter.addObserver(
      forName: NSWorkspace.didWakeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.delegate?.systemDidWake()
      }
    }
  }

  deinit {
    if let observer = sleepObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
    }
    if let observer = wakeObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
    }
  }
}
