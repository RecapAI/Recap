import Foundation

/// Service for exporting transcriptions to markdown format
final class TranscriptionMarkdownExporter {

  /// Export a recording's transcription to a markdown file
  /// - Parameters:
  ///   - recording: The recording information
  ///   - destinationDirectory: The directory where the markdown file should be saved
  /// - Returns: The URL of the created markdown file
  /// - Throws: Error if file creation fails
  static func exportToMarkdown(
    recording: RecordingInfo,
    destinationDirectory: URL
  ) throws -> URL {
    guard let timestampedTranscription = recording.timestampedTranscription else {
      throw TranscriptionMarkdownError.noTimestampedTranscription
    }

    let markdown = generateMarkdown(
      recording: recording,
      timestampedTranscription: timestampedTranscription
    )

    let fileURL = makeMarkdownURL(
      recording: recording,
      destinationDirectory: destinationDirectory
    )

    try markdown.write(to: fileURL, atomically: true, encoding: .utf8)

    return fileURL
  }

  /// Compute the markdown file URL for a recording.
  static func makeMarkdownURL(
    recording: RecordingInfo,
    destinationDirectory: URL
  ) -> URL {
    let filename = generateFilename(from: recording)
    return destinationDirectory.appendingPathComponent(filename)
  }

  /// Create a placeholder markdown file if one does not already exist.
  /// - Parameters:
  ///   - recording: The recording information used to name the file.
  ///   - destinationDirectory: The directory where the markdown file should live.
  /// - Returns: The URL of the placeholder (existing or newly created).
  static func preparePlaceholder(
    recording: RecordingInfo,
    destinationDirectory: URL
  ) throws -> URL {
    try FileManager.default.createDirectory(
      at: destinationDirectory,
      withIntermediateDirectories: true
    )

    let fileURL = makeMarkdownURL(
      recording: recording,
      destinationDirectory: destinationDirectory
    )

    guard !FileManager.default.fileExists(atPath: fileURL.path) else {
      return fileURL
    }

    let placeholder = placeholderMarkdown(for: recording)
    try placeholder.write(to: fileURL, atomically: true, encoding: .utf8)

    return fileURL
  }

  /// Generate the markdown content
  private static func generateMarkdown(
    recording: RecordingInfo,
    timestampedTranscription: TimestampedTranscription
  ) -> String {
    var markdown = ""

    // Title
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
    let dateString = dateFormatter.string(from: recording.startDate)
    markdown += "# Transcription - \(dateString)\n\n"

    // Metadata
    let generatedFormatter = ISO8601DateFormatter()
    generatedFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    markdown += "**Generated:** \(generatedFormatter.string(from: Date()))\n"

    if let duration = recording.duration {
      markdown += "**Duration:** \(String(format: "%.2f", duration))s\n"
    }

    // Model (we'll use a placeholder for now since it's not stored in RecordingInfo)
    markdown += "**Model:** whisperkit\n"

    // Sources
    var sources: [String] = []
    if timestampedTranscription.segments.contains(where: { $0.source == .systemAudio }) {
      sources.append("System Audio")
    }
    if timestampedTranscription.segments.contains(where: { $0.source == .microphone }) {
      sources.append("Microphone")
    }
    markdown += "**Sources:** \(sources.joined(separator: ", "))\n"

    // Transcript section
    markdown += "## Transcript\n\n"

    // Format transcript using the updated formatter
    let formattedTranscript = TranscriptionMerger.getFormattedTranscript(timestampedTranscription)
    markdown += formattedTranscript

    markdown += "\n"

    return markdown
  }

  /// Generate a filename for the markdown file
  private static func generateFilename(from recording: RecordingInfo) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
    let dateString = dateFormatter.string(from: recording.startDate)
    return "transcription_\(dateString).md"
  }

  /// Generate placeholder markdown content while transcription is in progress.
  private static func placeholderMarkdown(for recording: RecordingInfo) -> String {
    var markdown = ""

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
    let dateString = dateFormatter.string(from: recording.startDate)
    markdown += "# Transcription - \(dateString)\n\n"

    let generatedFormatter = ISO8601DateFormatter()
    generatedFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    markdown += "**Generated:** \(generatedFormatter.string(from: Date()))\n"

    if let duration = recording.duration {
      markdown += "**Duration:** \(String(format: "%.2f", duration))s\n"
    }

    if let applicationName = recording.applicationName {
      markdown += "**Source Application:** \(applicationName)\n"
    }

    markdown += "\n_Transcription in progress..._\n"

    return markdown
  }
}

/// Errors that can occur during markdown export
enum TranscriptionMarkdownError: LocalizedError {
  case noTimestampedTranscription
  case fileWriteFailed(String)

  var errorDescription: String? {
    switch self {
    case .noTimestampedTranscription:
      return "No timestamped transcription data available"
    case .fileWriteFailed(let reason):
      return "Failed to write markdown file: \(reason)"
    }
  }
}
