import Foundation
import OSLog

@MainActor
final class DragDropViewModel: DragDropViewModelType {
  @Published var transcriptEnabled: Bool
  @Published var summarizeEnabled: Bool
  @Published var isProcessing = false
  @Published var errorMessage: String?
  @Published var successMessage: String?

  private let transcriptionService: TranscriptionServiceType
  private let llmService: LLMServiceType
  private let userPreferencesRepository: UserPreferencesRepositoryType
  private let recordingFileManagerHelper: RecordingFileManagerHelperType
  private let logger = Logger(
    subsystem: AppConstants.Logging.subsystem,
    category: String(describing: DragDropViewModel.self))

  init(
    transcriptionService: TranscriptionServiceType,
    llmService: LLMServiceType,
    userPreferencesRepository: UserPreferencesRepositoryType,
    recordingFileManagerHelper: RecordingFileManagerHelperType
  ) {
    self.transcriptionService = transcriptionService
    self.llmService = llmService
    self.userPreferencesRepository = userPreferencesRepository
    self.recordingFileManagerHelper = recordingFileManagerHelper

    // Initialize with defaults, will be loaded async
    self.transcriptEnabled = true
    self.summarizeEnabled = true

    // Load user preferences asynchronously
    Task {
      if let prefs = try? await userPreferencesRepository.getOrCreatePreferences() {
        await MainActor.run {
          self.transcriptEnabled = prefs.autoTranscribeEnabled
          self.summarizeEnabled = prefs.autoSummarizeEnabled
        }
      }
    }
  }

  func handleDroppedFile(url: URL) async {
    errorMessage = nil
    successMessage = nil
    isProcessing = true

    do {
      try validateFileFormat(url: url)
      let recordingDirectory = try await prepareRecordingDirectory(url: url)
      let transcriptionText = try await transcribeIfEnabled(recordingDirectory: recordingDirectory)
      try await summarizeIfEnabled(text: transcriptionText, recordingDirectory: recordingDirectory)

      successMessage = "File processed successfully! Saved to: \(recordingDirectory.path)"
      logger.info("✅ Drag & drop processing complete")

    } catch let error as DragDropError {
      errorMessage = error.localizedDescription
      logger.error("❌ Drag & drop error: \(error.localizedDescription)")
    } catch {
      errorMessage = "Failed to process file: \(error.localizedDescription)"
      logger.error("❌ Unexpected error in drag & drop: \(error.localizedDescription)")
    }

    isProcessing = false
  }

  private func validateFileFormat(url: URL) throws {
    let fileExtension = url.pathExtension.lowercased()
    let supportedFormats = ["wav", "mp3", "m4a", "flac"]
    guard supportedFormats.contains(fileExtension) else {
      throw DragDropError.unsupportedFormat(fileExtension)
    }
  }

  private func prepareRecordingDirectory(url: URL) throws -> URL {
    let timestamp = ISO8601DateFormatter().string(from: Date())
      .replacingOccurrences(of: ":", with: "-")
      .replacingOccurrences(of: ".", with: "-")
    let recordingID = "drag_drop_\(timestamp)"

    let recordingDirectory = try recordingFileManagerHelper.createRecordingDirectory(for: recordingID)
    let destinationURL = recordingDirectory.appendingPathComponent("system_recording.wav")
    try FileManager.default.copyItem(at: url, to: destinationURL)

    logger.info("Copied audio file to: \(destinationURL.path)")
    return recordingDirectory
  }

  private func transcribeIfEnabled(recordingDirectory: URL) async throws -> String? {
    guard transcriptEnabled else { return nil }

    logger.info("Starting transcription for drag & drop file")
    let audioURL = recordingDirectory.appendingPathComponent("system_recording.wav")
    let result = try await transcriptionService.transcribe(audioURL: audioURL, microphoneURL: nil)

    let transcriptURL = try saveFormattedTranscript(
      result: result,
      recordingDirectory: recordingDirectory,
      audioURL: audioURL,
      startDate: Date()
    )
    logger.info("Saved transcript to: \(transcriptURL.path)")
    return result.combinedText
  }

  private func summarizeIfEnabled(text: String?, recordingDirectory: URL) async throws {
    guard summarizeEnabled, let text = text else { return }

    logger.info("Starting summarization for drag & drop file")
    let summary = try await llmService.generateSummarization(
      text: text,
      options: .defaultSummarization
    )

    let summaryURL = recordingDirectory.appendingPathComponent("summary.md")
    try summary.write(to: summaryURL, atomically: true, encoding: String.Encoding.utf8)
    logger.info("Saved summary to: \(summaryURL.path)")
  }

  private func saveFormattedTranscript(
    result: TranscriptionResult,
    recordingDirectory: URL,
    audioURL: URL,
    startDate: Date
  ) throws -> URL {
    var markdown = ""

    // Title
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
    let dateString = dateFormatter.string(from: startDate)
    markdown += "# Transcription - \(dateString)\n\n"

    // Metadata
    let generatedFormatter = ISO8601DateFormatter()
    generatedFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    markdown += "**Generated:** \(generatedFormatter.string(from: Date()))\n"

    // Duration from transcription result
    markdown += "**Duration:** \(String(format: "%.2f", result.transcriptionDuration))s\n"

    // Model used
    markdown += "**Model:** \(result.modelUsed)\n"

    // Sources (for drag & drop, it's always system audio only)
    markdown += "**Sources:** System Audio\n"

    // Transcript section
    markdown += "## Transcript\n\n"

    // Format transcript using timestamped data if available, otherwise use combined text
    if let timestampedTranscription = result.timestampedTranscription {
      let formattedTranscript = TranscriptionMerger.getFormattedTranscript(timestampedTranscription)
      markdown += formattedTranscript
    } else {
      // Fallback to combined text if no timestamped data
      markdown += result.combinedText
    }

    markdown += "\n"

    // Save to file
    let filename = "transcription_\(dateString).md"
    let fileURL = recordingDirectory.appendingPathComponent(filename)
    try markdown.write(to: fileURL, atomically: true, encoding: .utf8)

    return fileURL
  }
}

enum DragDropError: LocalizedError {
  case unsupportedFormat(String)

  var errorDescription: String? {
    switch self {
    case .unsupportedFormat(let format):
      return "Unsupported audio format: .\(format). Supported formats: wav, mp3, m4a, flac"
    }
  }
}
