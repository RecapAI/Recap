import Combine
import SwiftUI

#if os(macOS)
  import AppKit
#endif

struct FolderSettingsView<ViewModel: FolderSettingsViewModelType>: View {
  @ObservedObject private var viewModel: ViewModel

  init(viewModel: ViewModel) {
    self.viewModel = viewModel
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      settingsRow(label: "Storage Location") {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text(viewModel.currentFolderPath)
              .font(.system(size: 11, weight: .medium))
              .foregroundColor(UIConstants.Colors.textPrimary)
              .lineLimit(1)
              .truncationMode(.middle)

            Spacer()

            PillButton(text: "Choose Folder") {
              openFolderPicker()
            }
          }

          Text("Recordings and transcriptions will be organized in event-based folders")
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(UIConstants.Colors.textSecondary)
        }
      }

      if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
          .font(.system(size: 11, weight: .medium))
          .foregroundColor(.red)
          .padding(.top, 4)
      }
    }
  }

  private func settingsRow<Content: View>(
    label: String,
    @ViewBuilder control: () -> Content
  ) -> some View {
    HStack {
      Text(label)
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(UIConstants.Colors.textPrimary)

      Spacer()

      control()
    }
  }

  private func openFolderPicker() {
    #if os(macOS)
      NSApp.activate(ignoringOtherApps: true)

      let panel = NSOpenPanel()
      panel.canChooseFiles = false
      panel.canChooseDirectories = true
      panel.allowsMultipleSelection = false
      panel.canCreateDirectories = true
      if !viewModel.currentFolderPath.isEmpty {
        panel.directoryURL = URL(
          fileURLWithPath: viewModel.currentFolderPath, isDirectory: true)
      }
      panel.prompt = "Choose"
      panel.message = "Select a folder where Recap will store recordings and segments."

      if let window = NSApp.keyWindow {
        panel.beginSheetModal(for: window) { response in
          guard response == .OK, let url = panel.url else { return }
          Task {
            await viewModel.updateFolderPath(url)
          }
        }
      } else {
        panel.begin { response in
          guard response == .OK, let url = panel.url else { return }
          Task {
            await viewModel.updateFolderPath(url)
          }
        }
      }
    #endif
  }
}

// MARK: - ViewModel Protocol

@MainActor
protocol FolderSettingsViewModelType: ObservableObject {
  var currentFolderPath: String { get }
  var errorMessage: String? { get }

  func updateFolderPath(_ url: URL) async
  func setErrorMessage(_ message: String?)
}

// MARK: - Type Erased Wrapper

@MainActor
final class AnyFolderSettingsViewModel: FolderSettingsViewModelType {
  let objectWillChange = ObservableObjectPublisher()
  private let _currentFolderPath: () -> String
  private let _errorMessage: () -> String?
  private let _updateFolderPath: (URL) async -> Void
  private let _setErrorMessage: (String?) -> Void
  private var cancellable: AnyCancellable?

  init<ViewModel: FolderSettingsViewModelType>(_ viewModel: ViewModel) {
    self._currentFolderPath = { viewModel.currentFolderPath }
    self._errorMessage = { viewModel.errorMessage }
    self._updateFolderPath = { await viewModel.updateFolderPath($0) }
    self._setErrorMessage = { viewModel.setErrorMessage($0) }
    cancellable = viewModel.objectWillChange.sink { [weak self] _ in
      self?.objectWillChange.send()
    }
  }

  var currentFolderPath: String { _currentFolderPath() }
  var errorMessage: String? { _errorMessage() }

  func updateFolderPath(_ url: URL) async {
    await _updateFolderPath(url)
  }

  func setErrorMessage(_ message: String?) {
    _setErrorMessage(message)
  }
}

// MARK: - Preview

#if DEBUG
  #Preview {
    FolderSettingsView(viewModel: PreviewFolderSettingsViewModel())
      .frame(width: 550, height: 200)
      .background(Color.black)
  }
#endif
