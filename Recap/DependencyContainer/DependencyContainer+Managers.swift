import Foundation

extension DependencyContainer {
    
    func makeCoreDataManager() -> CoreDataManagerType {
        CoreDataManager(inMemory: inMemory)
    }
    
    func makeStatusBarManager() -> StatusBarManagerType {
        StatusBarManager()
    }
    
    func makeAudioProcessController() -> AudioProcessController {
        AudioProcessController()
    }
    
    func makeRecordingFileManager() -> RecordingFileManaging {
        RecordingFileManager()
    }
    
    func makeWarningManager() -> any WarningManagerType {
        WarningManager()
    }
}
