import Combine
import SwiftUI

private let keyCodeMap: [Int32: String] = [
  0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
  8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y",
  17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=",
  25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O", 32: "U",
  33: "[", 34: "I", 35: "P", 36: "Return", 37: "L", 38: "J", 39: "'", 40: "K",
  41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab",
  49: "Space", 50: "`", 51: "Delete", 53: "Escape", 123: "Left", 124: "Right",
  125: "Down", 126: "Up"
]

private let keyEquivalentMap: [Character: Int32] = [
  "a": 0, "b": 11, "c": 8, "d": 2, "e": 14, "f": 3, "g": 5, "h": 4,
  "i": 34, "j": 38, "k": 40, "l": 37, "m": 46, "n": 45, "o": 31, "p": 35,
  "q": 12, "r": 15, "s": 1, "t": 17, "u": 32, "v": 9, "w": 13, "x": 7,
  "y": 16, "z": 6
]

struct GlobalShortcutSettingsView<ViewModel: GeneralSettingsViewModelType>: View {
  @ObservedObject private var viewModel: ViewModel
  @State private var isRecordingShortcut = false
  @State private var currentKeyCode: Int32 = 15
  @State private var currentModifiers: Int32 = 1_048_840

  init(viewModel: ViewModel) {
    self.viewModel = viewModel
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Global Shortcut")
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(UIConstants.Colors.textPrimary)

      VStack(alignment: .leading, spacing: 8) {
        Text("Press the key combination you want to use for starting/stopping recording:")
          .font(.system(size: 12))
          .foregroundColor(UIConstants.Colors.textSecondary)

        HStack {
          Button {
            isRecordingShortcut = true
          } label: {
            HStack {
              Text(shortcutDisplayString)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(UIConstants.Colors.textPrimary)

              Spacer()

              Image(systemName: "keyboard")
                .font(.system(size: 12))
                .foregroundColor(UIConstants.Colors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
              RoundedRectangle(cornerRadius: 6)
                .fill(
                  isRecordingShortcut
                    ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1)
                )
            )
            .overlay(
              RoundedRectangle(cornerRadius: 6)
                .stroke(
                  isRecordingShortcut ? Color.blue : Color.gray.opacity(0.3),
                  lineWidth: 1
                )
            )
          }
          .buttonStyle(PlainButtonStyle())
          .frame(width: 200)

          if isRecordingShortcut {
            Button("Cancel") {
              isRecordingShortcut = false
            }
            .font(.system(size: 12))
            .foregroundColor(UIConstants.Colors.textSecondary)
          }
        }

        if isRecordingShortcut {
          Text("Press any key combination...")
            .font(.system(size: 11))
            .foregroundColor(.blue)
        }
      }
    }
    .onAppear {
      currentKeyCode = viewModel.globalShortcutKeyCode
      currentModifiers = viewModel.globalShortcutModifiers
    }
    .onChange(of: viewModel.globalShortcutKeyCode) { _, newValue in
      currentKeyCode = newValue
    }
    .onChange(of: viewModel.globalShortcutModifiers) { _, newValue in
      currentModifiers = newValue
    }
    .onKeyPress { keyPress in
      if isRecordingShortcut {
        // Convert KeyEquivalent to key code (simplified mapping)
        let keyCode = getKeyCodeFromKeyEquivalent(keyPress.key)
        let modifiers = Int32(keyPress.modifiers.rawValue)

        Task {
          await viewModel.updateGlobalShortcut(keyCode: keyCode, modifiers: modifiers)
        }

        isRecordingShortcut = false
        return .handled
      }
      return .ignored
    }
  }

  private var shortcutDisplayString: String {
    let keyString = getKeyString(for: currentKeyCode)
    let modifierString = getModifierString(for: currentModifiers)
    return "\(modifierString)\(keyString)"
  }

  private func getKeyString(for keyCode: Int32) -> String {
    return keyCodeMap[keyCode] ?? "Key\(keyCode)"
  }

  private func getKeyCodeFromKeyEquivalent(_ key: KeyEquivalent) -> Int32 {
    switch key {
    case .space: return 49
    case .tab: return 48
    case .return: return 36
    case .escape: return 53
    case .delete: return 51
    default:
      if let char = key.character.lowercased().first,
        let keyCode = keyEquivalentMap[char] {
        return keyCode
      }
      return 15  // Default to 'R'
    }
  }

  private func getModifierString(for modifiers: Int32) -> String {
    var result = ""
    if (modifiers & Int32(NSEvent.ModifierFlags.command.rawValue)) != 0 {
      result += "⌘"
    }
    if (modifiers & Int32(NSEvent.ModifierFlags.option.rawValue)) != 0 {
      result += "⌥"
    }
    if (modifiers & Int32(NSEvent.ModifierFlags.control.rawValue)) != 0 {
      result += "⌃"
    }
    if (modifiers & Int32(NSEvent.ModifierFlags.shift.rawValue)) != 0 {
      result += "⇧"
    }
    return result
  }
}

// Note: Preview removed due to complex mock requirements
