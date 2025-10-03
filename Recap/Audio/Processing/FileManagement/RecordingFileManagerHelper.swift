import Foundation

protocol RecordingFileManagerHelperType {
    func getBaseDirectory() -> URL
    func setBaseDirectory(_ url: URL, bookmark: Data?) throws
    func createRecordingDirectory(for recordingID: String) throws -> URL
}

final class RecordingFileManagerHelper: RecordingFileManagerHelperType {
    private let userPreferencesRepository: UserPreferencesRepositoryType

    init(userPreferencesRepository: UserPreferencesRepositoryType) {
        self.userPreferencesRepository = userPreferencesRepository
    }

    func getBaseDirectory() -> URL {
        // Try to get custom directory from preferences using security-scoped bookmark
        let defaults = UserDefaults.standard

        // First try to resolve from bookmark data
        if let bookmarkData = defaults.data(forKey: "customTmpDirectoryBookmark") {
            var isStale = false
            do {
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    // Fall through to default if we can't access
                    return defaultDirectory()
                }

                return url
            } catch {
                // Fall through to default if bookmark resolution fails
            }
        }

        // Fallback: try the path string (won't work for sandboxed access but kept for backwards compatibility)
        if let customPath = defaults.string(forKey: "customTmpDirectoryPath") {
            let url = URL(fileURLWithPath: customPath)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        return defaultDirectory()
    }

    private func defaultDirectory() -> URL {
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("Recap", isDirectory: true)
    }

    func setBaseDirectory(_ url: URL, bookmark: Data?) throws {
        // This will be handled by UserPreferencesRepository
        // Just validate the URL is accessible
        guard FileManager.default.isWritableFile(atPath: url.path) else {
            throw NSError(domain: "RecordingFileManagerHelper", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Directory is not writable"])
        }
    }

    func createRecordingDirectory(for recordingID: String) throws -> URL {
        let baseDir = getBaseDirectory()
        let recordingDir = baseDir.appendingPathComponent(recordingID, isDirectory: true)

        if !FileManager.default.fileExists(atPath: recordingDir.path) {
            try FileManager.default.createDirectory(
                at: recordingDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        return recordingDir
    }
}
