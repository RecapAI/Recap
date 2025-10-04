import Carbon
import Cocoa
import OSLog

@MainActor
protocol GlobalShortcutDelegate: AnyObject {
  func globalShortcutActivated()
}

@MainActor
final class GlobalShortcutManager {
  private var hotKeyRef: EventHotKeyRef?
  private var eventHandler: EventHandlerRef?
  private weak var delegate: GlobalShortcutDelegate?

  // Default shortcut: Cmd+R
  private var currentShortcut: (keyCode: UInt32, modifiers: UInt32) = (
    keyCode: 15,
    modifiers: UInt32(cmdKey)
  )  // 'R' key with Cmd
  private let logger = Logger(
    subsystem: AppConstants.Logging.subsystem,
    category: String(describing: GlobalShortcutManager.self)
  )

  init() {
    setupEventHandling()
  }

  deinit {
    // Note: We can't use Task here as it would capture self in deinit
    // The shortcut will be cleaned up when the app terminates
  }

  func setDelegate(_ delegate: GlobalShortcutDelegate) {
    self.delegate = delegate
  }

  func registerShortcut(keyCode: UInt32, modifiers: UInt32) {
    unregisterShortcut()
    currentShortcut = (keyCode: keyCode, modifiers: modifiers)
    registerShortcut()
  }

  func registerDefaultShortcut() {
    registerShortcut(keyCode: 15, modifiers: UInt32(cmdKey))  // Cmd+R
  }

  private func registerShortcut() {
    let eventType = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))

    let status = InstallEventHandler(
      GetApplicationEventTarget(),
      { (_, theEvent, userData) -> OSStatus in
        guard let userData = userData, let theEvent = theEvent else {
          return OSStatus(eventNotHandledErr)
        }
        let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(userData)
          .takeUnretainedValue()
        return manager.handleHotKeyEvent(theEvent)
      },
      1,
      [eventType],
      Unmanaged.passUnretained(self).toOpaque(),
      &eventHandler
    )

    guard status == noErr else {
      logger.error("Failed to install event handler: \(status, privacy: .public)")
      return
    }

    let hotKeyID = EventHotKeyID(signature: OSType(0x4D4B_4D4B), id: 1)
    let status2 = RegisterEventHotKey(
      currentShortcut.keyCode,
      currentShortcut.modifiers,
      hotKeyID,
      GetApplicationEventTarget(),
      0,
      &hotKeyRef
    )

    guard status2 == noErr else {
      logger.error("Failed to register hot key: \(status2, privacy: .public)")
      return
    }

    logger.info("Global shortcut registered: Cmd+R")
  }

  private func unregisterShortcut() {
    if let hotKeyRef = hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
      self.hotKeyRef = nil
    }

    if let eventHandler = eventHandler {
      RemoveEventHandler(eventHandler)
      self.eventHandler = nil
    }
  }

  private func setupEventHandling() {
    // This is handled in registerShortcut
  }

  private func handleHotKeyEvent(_ event: EventRef) -> OSStatus {
    DispatchQueue.main.async { [weak self] in
      self?.delegate?.globalShortcutActivated()
    }
    return noErr
  }

  func getCurrentShortcut() -> (keyCode: UInt32, modifiers: UInt32) {
    return currentShortcut
  }

  func getShortcutString() -> String {
    let keyString = getKeyString(for: currentShortcut.keyCode)
    let modifierString = getModifierString(for: currentShortcut.modifiers)
    return "\(modifierString)\(keyString)"
  }

  private static let keyCodeMap: [UInt32: String] = [
    0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
    8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y",
    17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=",
    25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O", 32: "U",
    33: "[", 34: "I", 35: "P", 36: "Return", 37: "L", 38: "J", 39: "'", 40: "K",
    41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab",
    49: "Space", 50: "`", 51: "Delete", 53: "Escape", 123: "Left", 124: "Right",
    125: "Down", 126: "Up"
  ]

  private func getKeyString(for keyCode: UInt32) -> String {
    return Self.keyCodeMap[keyCode] ?? "Key\(keyCode)"
  }

  private func getModifierString(for modifiers: UInt32) -> String {
    var result = ""
    if (modifiers & UInt32(cmdKey)) != 0 {
      result += "⌘"
    }
    if (modifiers & UInt32(optionKey)) != 0 {
      result += "⌥"
    }
    if (modifiers & UInt32(controlKey)) != 0 {
      result += "⌃"
    }
    if (modifiers & UInt32(shiftKey)) != 0 {
      result += "⇧"
    }
    return result
  }
}
