import CoreData
import Foundation

@MainActor
final class UserPreferencesRepository: UserPreferencesRepositoryType {
  private let coreDataManager: CoreDataManagerType
  private let defaultPreferencesId = "default-preferences"

  init(coreDataManager: CoreDataManagerType) {
    self.coreDataManager = coreDataManager
  }

  func getOrCreatePreferences() async throws -> UserPreferencesInfo {
    let context = coreDataManager.viewContext
    let request: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@", defaultPreferencesId)
    request.fetchLimit = 1

    do {
      let preferences = try context.fetch(request).first

      if let existingPreferences = preferences {
        syncToUserDefaults(existingPreferences)
        return UserPreferencesInfo(from: existingPreferences)
      } else {
        return try createDefaultPreferences(in: context)
      }
    } catch {
      throw LLMError.dataAccessError(error.localizedDescription)
    }
  }

  private func syncToUserDefaults(_ preferences: UserPreferences) {
    if let customPath = preferences.customTmpDirectoryPath {
      UserDefaults.standard.set(customPath, forKey: "customTmpDirectoryPath")
      if let bookmark = preferences.customTmpDirectoryBookmark {
        UserDefaults.standard.set(bookmark, forKey: "customTmpDirectoryBookmark")
      }
    }
  }

  private func createDefaultPreferences(in context: NSManagedObjectContext) throws
    -> UserPreferencesInfo {
    let newPreferences = UserPreferences(context: context)
    newPreferences.id = defaultPreferencesId
    newPreferences.createdAt = Date()
    newPreferences.modifiedAt = Date()
    newPreferences.autoSummarizeEnabled = true
    newPreferences.autoSummarizeDuringRecording = true
    newPreferences.autoSummarizeAfterRecording = true
    newPreferences.autoTranscribeEnabled = true
    newPreferences.selectedProvider = LLMProvider.default.rawValue
    newPreferences.autoDetectMeetings = false
    newPreferences.autoStopRecording = false

    try context.save()
    return UserPreferencesInfo(from: newPreferences)
  }

  func fetchOrCreatePreferences(
    in context: NSManagedObjectContext
  ) throws -> UserPreferences {
    let request: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
    request.predicate = NSPredicate(format: "id == %@", defaultPreferencesId)
    request.fetchLimit = 1

    if let existing = try context.fetch(request).first {
      return existing
    }

    let newPreferences = UserPreferences(context: context)
    newPreferences.id = defaultPreferencesId
    newPreferences.createdAt = Date()
    newPreferences.modifiedAt = Date()
    newPreferences.autoSummarizeEnabled = true
    newPreferences.selectedProvider = LLMProvider.default.rawValue
    newPreferences.autoDetectMeetings = false
    newPreferences.autoStopRecording = false
    newPreferences.onboarded = false

    return newPreferences
  }

  private func performUpdate(
    _ updateBlock: (UserPreferences) throws -> Void
  ) async throws {
    let context = coreDataManager.viewContext
    do {
      let preferences = try fetchOrCreatePreferences(in: context)
      try updateBlock(preferences)
      preferences.modifiedAt = Date()
      try context.save()
    } catch {
      throw LLMError.dataAccessError(error.localizedDescription)
    }
  }

  func updateSelectedLLMModel(id: String?) async throws {
    try await performUpdate { preferences in
      preferences.selectedLLMModelID = id
    }
  }

  func updateSelectedProvider(_ provider: LLMProvider) async throws {
    try await performUpdate { preferences in
      preferences.selectedProvider = provider.rawValue
    }
  }

  func updateAutoDetectMeetings(_ enabled: Bool) async throws {
    try await performUpdate { preferences in
      preferences.autoDetectMeetings = enabled
    }
  }

  func updateAutoStopRecording(_ enabled: Bool) async throws {
    try await performUpdate { preferences in
      preferences.autoStopRecording = enabled
    }
  }

  func updateSummaryPromptTemplate(_ template: String?) async throws {
    try await performUpdate { preferences in
      preferences.summaryPromptTemplate = template
    }
  }

  func updateAutoSummarize(_ enabled: Bool) async throws {
    try await performUpdate { preferences in
      preferences.autoSummarizeEnabled = enabled
    }
  }

  func updateAutoTranscribe(_ enabled: Bool) async throws {
    try await performUpdate { preferences in
      preferences.autoTranscribeEnabled = enabled
    }
  }

  func updateOnboardingStatus(_ completed: Bool) async throws {
    try await performUpdate { preferences in
      preferences.onboarded = completed
    }
  }

  func updateMicrophoneEnabled(_ enabled: Bool) async throws {
    try await performUpdate { preferences in
      preferences.microphoneEnabled = enabled
    }
  }

  func updateGlobalShortcut(keyCode: Int32, modifiers: Int32) async throws {
    try await performUpdate { preferences in
      preferences.globalShortcutKeyCode = keyCode
      preferences.globalShortcutModifiers = modifiers
    }
  }

  func updateCustomTmpDirectory(path: String?, bookmark: Data?) async throws {
    try await performUpdate { preferences in
      preferences.customTmpDirectoryPath = path
      preferences.customTmpDirectoryBookmark = bookmark
    }

    // Also save to UserDefaults for synchronous access
    if let path = path {
      UserDefaults.standard.set(path, forKey: "customTmpDirectoryPath")
      if let bookmark = bookmark {
        UserDefaults.standard.set(bookmark, forKey: "customTmpDirectoryBookmark")
      }
    } else {
      UserDefaults.standard.removeObject(forKey: "customTmpDirectoryPath")
      UserDefaults.standard.removeObject(forKey: "customTmpDirectoryBookmark")
    }
  }
}
