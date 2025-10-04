import Foundation
import WhisperKit

/// Utility class for extracting timestamps from WhisperKit transcription results
/// This provides enhanced functionality for working with timestamped transcriptions
struct WhisperKitTimestampExtractor {

  /// Extract timestamped segments from WhisperKit transcription results
  /// - Parameters:
  ///   - segments: WhisperKit segments from transcribe result
  ///   - source: Audio source (microphone or system audio)
  /// - Returns: Array of timestamped transcription segments
  static func extractSegments(
    from segments: [Any],
    source: TranscriptionSegment.AudioSource
  ) -> [TranscriptionSegment] {
    return segments.compactMap { segment in
      // Use Mirror to access properties dynamically
      let mirror = Mirror(reflecting: segment)
      guard let text = mirror.children.first(where: { $0.label == "text" })?.value as? String,
        let start = mirror.children.first(where: { $0.label == "start" })?.value as? Float,
        let end = mirror.children.first(where: { $0.label == "end" })?.value as? Float
      else {
        return nil
      }

      let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      guard !trimmedText.isEmpty else { return nil }

      return TranscriptionSegment(
        text: trimmedText,
        startTime: TimeInterval(start),
        endTime: TimeInterval(end),
        source: source
      )
    }
  }

  /// Extract word-level segments from WhisperKit transcription results
  /// - Parameters:
  ///   - segments: WhisperKit segments from transcribe result
  ///   - source: Audio source (microphone or system audio)
  /// - Returns: Array of word-level timestamped segments
  static func extractWordSegments(
    from segments: [Any],
    source: TranscriptionSegment.AudioSource
  ) -> [TranscriptionSegment] {
    var wordSegments: [TranscriptionSegment] = []

    for segment in segments {
      let segmentMirror = Mirror(reflecting: segment)

      // Extract word-level timestamps if available
      if let words = segmentMirror.children.first(where: { $0.label == "words" })?.value
        as? [Any] {
        for word in words {
          let wordMirror = Mirror(reflecting: word)
          guard
            let wordText = wordMirror.children.first(where: { $0.label == "word" })?
              .value as? String,
            let wordStart = wordMirror.children.first(where: { $0.label == "start" })?
              .value as? Float,
            let wordEnd = wordMirror.children.first(where: { $0.label == "end" })?.value
              as? Float
          else { continue }

          let text = wordText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
          guard !text.isEmpty else { continue }

          wordSegments.append(
            TranscriptionSegment(
              text: text,
              startTime: TimeInterval(wordStart),
              endTime: TimeInterval(wordEnd),
              source: source
            ))
        }
      } else {
        // Fallback to segment-level timing
        guard
          let text = segmentMirror.children.first(where: { $0.label == "text" })?.value
            as? String,
          let start = segmentMirror.children.first(where: { $0.label == "start" })?.value
            as? Float,
          let end = segmentMirror.children.first(where: { $0.label == "end" })?.value
            as? Float
        else { continue }

        let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { continue }

        wordSegments.append(
          TranscriptionSegment(
            text: trimmedText,
            startTime: TimeInterval(start),
            endTime: TimeInterval(end),
            source: source
          ))
      }
    }

    return wordSegments
  }

  /// Create a more granular transcription by splitting segments into smaller chunks
  /// - Parameters:
  ///   - segments: WhisperKit segments
  ///   - source: Audio source
  ///   - maxSegmentDuration: Maximum duration for each segment in seconds
  /// - Returns: Array of refined timestamped segments
  static func createRefinedSegments(
    from segments: [Any],
    source: TranscriptionSegment.AudioSource,
    maxSegmentDuration: TimeInterval = 5.0
  ) -> [TranscriptionSegment] {
    var refinedSegments: [TranscriptionSegment] = []

    for segment in segments {
      let mirror = Mirror(reflecting: segment)
      guard let text = mirror.children.first(where: { $0.label == "text" })?.value as? String,
        let start = mirror.children.first(where: { $0.label == "start" })?.value as? Float,
        let end = mirror.children.first(where: { $0.label == "end" })?.value as? Float
      else { continue }

      let duration = end - start

      if duration <= Float(maxSegmentDuration) {
        // Segment is already small enough
        refinedSegments.append(
          TranscriptionSegment(
            text: text,
            startTime: TimeInterval(start),
            endTime: TimeInterval(end),
            source: source
          ))
      } else {
        // Split the segment into smaller chunks
        let words = text.components(separatedBy: CharacterSet.whitespaces)
        let wordsPerChunk = max(
          1, Int(Double(words.count) * maxSegmentDuration / Double(duration)))

        for wordIndex in stride(from: 0, to: words.count, by: wordsPerChunk) {
          let endIndex = min(wordIndex + wordsPerChunk, words.count)
          let chunkWords = Array(words[wordIndex..<endIndex])
          let chunkText = chunkWords.joined(separator: " ")

          guard
            !chunkText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
              .isEmpty
          else { continue }

          // Calculate proportional timing for this chunk
          let chunkStartRatio = Double(wordIndex) / Double(words.count)
          let chunkEndRatio = Double(endIndex) / Double(words.count)

          let chunkStartTime = Double(start) + (Double(duration) * chunkStartRatio)
          let chunkEndTime = Double(start) + (Double(duration) * chunkEndRatio)

          refinedSegments.append(
            TranscriptionSegment(
              text: chunkText,
              startTime: chunkStartTime,
              endTime: chunkEndTime,
              source: source
            ))
        }
      }
    }

    return refinedSegments
  }

  /// Estimate duration for a text segment based on speaking rate
  /// - Parameter text: Text to estimate duration for
  /// - Returns: Estimated duration in seconds
  static func estimateDuration(for text: String) -> TimeInterval {
    let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    let wordCount = trimmedText.components(separatedBy: CharacterSet.whitespaces).count

    // Estimate based on average speaking rate (150 words per minute)
    let wordsPerSecond = 150.0 / 60.0
    let estimatedDuration = Double(wordCount) / wordsPerSecond

    // Ensure minimum duration and add some padding for natural speech
    return max(1.0, estimatedDuration * 1.2)
  }

  /// Check if WhisperKit segments contain word-level timestamp information
  /// - Parameter segments: WhisperKit segments
  /// - Returns: True if word timestamps are available, false otherwise
  static func hasWordTimestamps(_ segments: [Any]) -> Bool {
    return segments.contains { segment in
      let mirror = Mirror(reflecting: segment)
      guard let words = mirror.children.first(where: { $0.label == "words" })?.value as? [Any]
      else { return false }
      return !words.isEmpty
    }
  }

  /// Get the total duration of all segments
  /// - Parameter segments: Array of transcription segments
  /// - Returns: Total duration in seconds
  static func totalDuration(_ segments: [Any]) -> TimeInterval {
    return segments.compactMap { segment in
      let mirror = Mirror(reflecting: segment)
      guard let end = mirror.children.first(where: { $0.label == "end" })?.value as? Float
      else { return nil }
      return TimeInterval(end)
    }.max() ?? 0
  }
}
