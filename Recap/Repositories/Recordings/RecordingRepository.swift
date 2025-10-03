import Foundation
import CoreData

final class RecordingRepository: RecordingRepositoryType {
    private let coreDataManager: CoreDataManagerType
    
    init(coreDataManager: CoreDataManagerType) {
        self.coreDataManager = coreDataManager
    }
    
    func createRecording(id: String, startDate: Date, recordingURL: URL, microphoneURL: URL?, hasMicrophoneAudio: Bool, applicationName: String?) async throws -> RecordingInfo {
        try await withCheckedThrowingContinuation { continuation in
            coreDataManager.performBackgroundTask { context in
                do {
                    let recording = UserRecording(context: context)
                    recording.id = id
                    recording.startDate = startDate
                    recording.recordingURL = recordingURL.path
                    recording.microphoneURL = microphoneURL?.path
                    recording.hasMicrophoneAudio = hasMicrophoneAudio
                    recording.applicationName = applicationName
                    recording.state = RecordingProcessingState.recording.rawValue
                    recording.createdAt = Date()
                    recording.modifiedAt = Date()
                    
                    try context.save()
                    
                    let info = RecordingInfo(from: recording)
                    continuation.resume(returning: info)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchRecording(id: String) async throws -> RecordingInfo? {
        try await withCheckedThrowingContinuation { continuation in
            coreDataManager.performBackgroundTask { context in
                let request = UserRecording.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", id)
                request.fetchLimit = 1
                
                do {
                    let recordings = try context.fetch(request)
                    let info = recordings.first.map { RecordingInfo(from: $0) }
                    continuation.resume(returning: info)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchAllRecordings() async throws -> [RecordingInfo] {
        try await withCheckedThrowingContinuation { continuation in
            coreDataManager.performBackgroundTask { context in
                let request = UserRecording.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                
                do {
                    let recordings = try context.fetch(request)
                    let infos = recordings.map { RecordingInfo(from: $0) }
                    continuation.resume(returning: infos)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchRecordings(withState state: RecordingProcessingState) async throws -> [RecordingInfo] {
        try await withCheckedThrowingContinuation { continuation in
            coreDataManager.performBackgroundTask { context in
                let request = UserRecording.fetchRequest()
                request.predicate = NSPredicate(format: "state == %d", state.rawValue)
                request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                
                do {
                    let recordings = try context.fetch(request)
                    let infos = recordings.map { RecordingInfo(from: $0) }
                    continuation.resume(returning: infos)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateRecordingState(id: String, state: RecordingProcessingState, errorMessage: String?) async throws {
        try await withCheckedThrowingContinuation { continuation in
            coreDataManager.performBackgroundTask { context in
                do {
                    let recording = try self.fetchRecordingEntity(id: id, context: context)
                    recording.state = state.rawValue
                    recording.errorMessage = errorMessage
                    recording.modifiedAt = Date()
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateRecordingEndDate(id: String, endDate: Date) async throws {
        try await withCheckedThrowingContinuation { continuation in
            coreDataManager.performBackgroundTask { context in
                do {
                    let recording = try self.fetchRecordingEntity(id: id, context: context)
                    recording.endDate = endDate
                    recording.modifiedAt = Date()
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateRecordingTranscription(id: String, transcriptionText: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            coreDataManager.performBackgroundTask { context in
                do {
                    let recording = try self.fetchRecordingEntity(id: id, context: context)
                    recording.transcriptionText = transcriptionText
                    recording.modifiedAt = Date()
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateRecordingTimestampedTranscription(id: String, timestampedTranscription: TimestampedTranscription) async throws {
        try await withCheckedThrowingContinuation { continuation in
            coreDataManager.performBackgroundTask { context in
                do {
                    let recording = try self.fetchRecordingEntity(id: id, context: context)
                    
                    // Encode the timestamped transcription to binary data
                    let data = try JSONEncoder().encode(timestampedTranscription)
                    recording.timestampedTranscriptionData = data
                    recording.modifiedAt = Date()
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateRecordingSummary(id: String, summaryText: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            coreDataManager.performBackgroundTask { context in
                do {
                    let recording = try self.fetchRecordingEntity(id: id, context: context)
                    recording.summaryText = summaryText
                    recording.modifiedAt = Date()
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func updateRecordingURLs(id: String, recordingURL: URL?, microphoneURL: URL?) async throws {
        try await withCheckedThrowingContinuation { continuation in
            coreDataManager.performBackgroundTask { context in
                do {
                    let recording = try self.fetchRecordingEntity(id: id, context: context)
                    if let recordingURL = recordingURL {
                        recording.recordingURL = recordingURL.path
                    }
                    if let microphoneURL = microphoneURL {
                        recording.microphoneURL = microphoneURL.path
                    }
                    recording.modifiedAt = Date()
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func deleteRecording(id: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            coreDataManager.performBackgroundTask { context in
                do {
                    let recording = try self.fetchRecordingEntity(id: id, context: context)
                    context.delete(recording)
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func deleteAllRecordings() async throws {
        try await withCheckedThrowingContinuation { continuation in
            coreDataManager.performBackgroundTask { context in
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserRecording")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                
                do {
                    try context.execute(deleteRequest)
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func fetchRecordingEntity(id: String, context: NSManagedObjectContext) throws -> UserRecording {
        let request = UserRecording.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        guard let recording = try context.fetch(request).first else {
            throw RecordingRepositoryError.recordingNotFound(id: id)
        }
        
        return recording
    }
}

enum RecordingRepositoryError: LocalizedError {
    case recordingNotFound(id: String)
    
    var errorDescription: String? {
        switch self {
        case .recordingNotFound(let id):
            return "Recording with ID '\(id)' not found"
        }
    }
}