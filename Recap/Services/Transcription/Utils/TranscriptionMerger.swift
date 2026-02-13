import Foundation

/// Utility class for merging and working with timestamped transcriptions
struct TranscriptionMerger {

  /// Merge timestamped transcriptions from microphone and system audio
  /// - Parameters:
  ///   - systemAudioSegments: Segments from system audio
  ///   - microphoneSegments: Segments from microphone audio
  /// - Returns: Merged timestamped transcription with segments sorted by time
  static func mergeTranscriptions(
    systemAudioSegments: [TranscriptionSegment],
    microphoneSegments: [TranscriptionSegment]
  ) -> TimestampedTranscription {
    let allSegments = systemAudioSegments + microphoneSegments
    return TimestampedTranscription(segments: allSegments)
  }

  /// Get a chronological view of the transcription with speaker identification
  /// - Parameter transcription: The timestamped transcription
  /// - Returns: Array of segments with speaker labels, sorted by time
  static func getChronologicalView(_ transcription: TimestampedTranscription)
    -> [ChronologicalSegment] {
    return transcription.segments.map { segment in
      ChronologicalSegment(
        text: segment.text,
        startTime: segment.startTime,
        endTime: segment.endTime,
        speaker: segment.source == .microphone ? "User" : "System Audio",
        source: segment.source
      )
    }.sorted { $0.startTime < $1.startTime }
  }

  /// Get segments within a specific time range
  /// - Parameters:
  ///   - transcription: The timestamped transcription
  ///   - startTime: Start time in seconds
  ///   - endTime: End time in seconds
  /// - Returns: Segments within the specified time range
  static func getSegmentsInTimeRange(
    _ transcription: TimestampedTranscription,
    startTime: TimeInterval,
    endTime: TimeInterval
  ) -> [TranscriptionSegment] {
    return transcription.segments.filter { segment in
      segment.startTime <= endTime && segment.endTime >= startTime
    }
  }

  /// Get a formatted transcript with timestamps and speaker labels
  /// - Parameter transcription: The timestamped transcription
  /// - Returns: Formatted transcript string
  static func getFormattedTranscript(_ transcription: TimestampedTranscription) -> String {
    let chronologicalSegments = getChronologicalView(transcription)

    return chronologicalSegments.map { segment in
      let duration = segment.endTime - segment.startTime
      let source = segment.source == .microphone ? "Microphone" : "System Audio"
      let cleanedText = TranscriptionTextCleaner.cleanWhisperKitText(segment.text)

      return
        "\(String(format: "%.2f", segment.startTime)) + "
        + "\(String(format: "%.2f", duration)), [\(source)]: \(cleanedText)"
    }.joined(separator: "\n")
  }

  /// Get segments by source (microphone or system audio)
  /// - Parameters:
  ///   - transcription: The timestamped transcription
  ///   - source: The audio source to filter by
  /// - Returns: Segments from the specified source
  static func getSegmentsBySource(
    _ transcription: TimestampedTranscription,
    source: TranscriptionSegment.AudioSource
  ) -> [TranscriptionSegment] {
    return transcription.segments.filter { $0.source == source }
  }

  /// Find overlapping segments between different sources
  /// - Parameter transcription: The timestamped transcription
  /// - Returns: Array of overlapping segment pairs
  static func findOverlappingSegments(_ transcription: TimestampedTranscription)
    -> [OverlappingSegments] {
    let systemSegments = getSegmentsBySource(transcription, source: .systemAudio)
    let microphoneSegments = getSegmentsBySource(transcription, source: .microphone)

    var overlappingPairs: [OverlappingSegments] = []

    for systemSegment in systemSegments {
      for microphoneSegment in microphoneSegments
      where systemSegment.overlaps(with: microphoneSegment) {
        overlappingPairs.append(
          OverlappingSegments(
            systemAudio: systemSegment,
            microphone: microphoneSegment
          ))
      }
    }

    return overlappingPairs
  }
}

/// Represents a segment in chronological order with speaker information
struct ChronologicalSegment {
  let text: String
  let startTime: TimeInterval
  let endTime: TimeInterval
  let speaker: String
  let source: TranscriptionSegment.AudioSource
}

/// Represents overlapping segments from different sources
struct OverlappingSegments {
  let systemAudio: TranscriptionSegment
  let microphone: TranscriptionSegment

  /// Calculate the overlap duration
  var overlapDuration: TimeInterval {
    let overlapStart = max(systemAudio.startTime, microphone.startTime)
    let overlapEnd = min(systemAudio.endTime, microphone.endTime)
    return max(0, overlapEnd - overlapStart)
  }

  /// Get the overlap percentage for the system audio segment
  var systemAudioOverlapPercentage: Double {
    guard systemAudio.duration > 0 else { return 0 }
    return overlapDuration / systemAudio.duration
  }

  /// Get the overlap percentage for the microphone segment
  var microphoneOverlapPercentage: Double {
    guard microphone.duration > 0 else { return 0 }
    return overlapDuration / microphone.duration
  }
}
