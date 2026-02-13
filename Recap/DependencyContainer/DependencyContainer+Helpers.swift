import Foundation

extension DependencyContainer {

  func makePermissionsHelper() -> PermissionsHelperType {
    PermissionsHelper()
  }

  func makeRecordingFileManagerHelper() -> RecordingFileManagerHelperType {
    RecordingFileManagerHelper(userPreferencesRepository: userPreferencesRepository)
  }
}
