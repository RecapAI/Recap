import Foundation
import SwiftUI

@MainActor
final class FolderSettingsViewModel: FolderSettingsViewModelType {
  @Published private(set) var currentFolderPath: String = ""
  @Published private(set) var errorMessage: String?

  private let userPreferencesRepository: UserPreferencesRepositoryType
  private let fileManagerHelper: RecordingFileManagerHelperType

  init(
    userPreferencesRepository: UserPreferencesRepositoryType,
    fileManagerHelper: RecordingFileManagerHelperType
  ) {
    self.userPreferencesRepository = userPreferencesRepository
    self.fileManagerHelper = fileManagerHelper

    loadCurrentFolderPath()
  }

  private func loadCurrentFolderPath() {
    Task {
      do {
        let preferences = try await userPreferencesRepository.getOrCreatePreferences()
        if let customPath = preferences.customTmpDirectoryPath {
          currentFolderPath = customPath
        } else {
          currentFolderPath = fileManagerHelper.getBaseDirectory().path
        }
      } catch {
        currentFolderPath = fileManagerHelper.getBaseDirectory().path
        errorMessage = "Failed to load folder settings: \(error.localizedDescription)"
      }
    }
  }

  func updateFolderPath(_ url: URL) async {
    errorMessage = nil

    do {
      #if os(macOS)
        var resolvedURL = url
        var bookmarkData: Data

        do {
          bookmarkData = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
          )

          var isStale = false
          resolvedURL = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
          )

          if isStale {
            bookmarkData = try resolvedURL.bookmarkData(
              options: [.withSecurityScope],
              includingResourceValuesForKeys: nil,
              relativeTo: nil
            )
          }
        } catch {
          errorMessage = "Failed to prepare folder access: \(error.localizedDescription)"
          return
        }

        let hasSecurityScope = resolvedURL.startAccessingSecurityScopedResource()
        defer {
          if hasSecurityScope {
            resolvedURL.stopAccessingSecurityScopedResource()
          }
        }

        try await validateAndPersistSelection(
          resolvedURL: resolvedURL, bookmark: bookmarkData)
      #else
        try await validateAndPersistSelection(resolvedURL: url, bookmark: nil)
      #endif
    } catch {
      errorMessage = "Failed to update folder path: \(error.localizedDescription)"
    }
  }

  private func validateAndPersistSelection(resolvedURL: URL, bookmark: Data?) async throws {
    // Check if the directory exists and is writable
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: resolvedURL.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      errorMessage = "Selected path does not exist or is not a directory"
      return
    }

    // Test write permissions
    let testFile = resolvedURL.appendingPathComponent(".recap_test")
    do {
      try Data("test".utf8).write(to: testFile)
      try FileManager.default.removeItem(at: testFile)
    } catch {
      errorMessage = "Selected directory is not writable: \(error.localizedDescription)"
      return
    }

    // Update the file manager helper
    try fileManagerHelper.setBaseDirectory(resolvedURL, bookmark: bookmark)

    // Save to preferences
    try await userPreferencesRepository.updateCustomTmpDirectory(
      path: resolvedURL.path,
      bookmark: bookmark
    )

    currentFolderPath = resolvedURL.path
  }

  func setErrorMessage(_ message: String?) {
    errorMessage = message
  }
}
