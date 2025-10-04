import Foundation

/// Represents a single segment of transcribed text with timing information
struct TranscriptionSegment: Equatable, Codable {
  let text: String
  let startTime: TimeInterval
  let endTime: TimeInterval
  let source: AudioSource

  /// The audio source this segment came from
  enum AudioSource: String, CaseIterable, Codable {
    case systemAudio = "system_audio"
    case microphone = "microphone"
  }

  /// Duration of this segment
  var duration: TimeInterval {
    endTime - startTime
  }

  /// Check if this segment overlaps with another segment
  func overlaps(with other: TranscriptionSegment) -> Bool {
    return startTime < other.endTime && endTime > other.startTime
  }

  /// Check if this segment occurs before another segment
  func isBefore(_ other: TranscriptionSegment) -> Bool {
    return endTime <= other.startTime
  }

  /// Check if this segment occurs after another segment
  func isAfter(_ other: TranscriptionSegment) -> Bool {
    return startTime >= other.endTime
  }
}

/// Collection of transcription segments with utility methods for merging and sorting
struct TimestampedTranscription: Equatable, Codable {
  let segments: [TranscriptionSegment]
  let totalDuration: TimeInterval

  init(segments: [TranscriptionSegment]) {
    self.segments = segments.sorted { $0.startTime < $1.startTime }
    self.totalDuration = segments.map { $0.endTime }.max() ?? 0
  }

  /// Get all segments from a specific audio source
  func segments(from source: TranscriptionSegment.AudioSource) -> [TranscriptionSegment] {
    return segments.filter { $0.source == source }
  }

  /// Get segments within a specific time range
  func segments(in timeRange: ClosedRange<TimeInterval>) -> [TranscriptionSegment] {
    return segments.filter { segment in
      segment.startTime <= timeRange.upperBound && segment.endTime >= timeRange.lowerBound
    }
  }

  /// Merge with another timestamped transcription, interleaving by time
  func merged(with other: TimestampedTranscription) -> TimestampedTranscription {
    let allSegments = segments + other.segments
    return TimestampedTranscription(segments: allSegments)
  }

  /// Get a simple text representation (current behavior)
  var combinedText: String {
    return segments.map { $0.text }.joined(separator: " ")
  }

  /// Get a formatted text representation with timestamps
  var formattedText: String {
    return segments.map { segment in
      let startMinutes = Int(segment.startTime) / 60
      let startSeconds = Int(segment.startTime) % 60
      let endMinutes = Int(segment.endTime) / 60
      let endSeconds = Int(segment.endTime) % 60

      return "[\(String(format: "%02d:%02d", startMinutes, startSeconds))-"
        + "\(String(format: "%02d:%02d", endMinutes, endSeconds))] "
        + "[\(segment.source.rawValue)] \(segment.text)"
    }.joined(separator: "\n")
  }

  /// Get segments grouped by source
  var segmentsBySource: [TranscriptionSegment.AudioSource: [TranscriptionSegment]] {
    return Dictionary(grouping: segments) { $0.source }
  }
}
