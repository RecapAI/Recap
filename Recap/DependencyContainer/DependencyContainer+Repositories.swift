import Foundation

extension DependencyContainer {

  func makeWhisperModelRepository() -> WhisperModelRepositoryType {
    WhisperModelRepository(coreDataManager: coreDataManager)
  }

  func makeRecordingRepository() -> RecordingRepositoryType {
    RecordingRepository(coreDataManager: coreDataManager)
  }

  func makeLLMModelRepository() -> LLMModelRepositoryType {
    LLMModelRepository(coreDataManager: coreDataManager)
  }

  func makeUserPreferencesRepository() -> UserPreferencesRepositoryType {
    UserPreferencesRepository(coreDataManager: coreDataManager)
  }
}
