import Foundation

struct MeetingPattern {
  let keyword: String
  let confidence: MeetingDetectionResult.MeetingConfidence
  let caseSensitive: Bool
  let excludePatterns: [String]

  init(
    keyword: String,
    confidence: MeetingDetectionResult.MeetingConfidence,
    caseSensitive: Bool = false,
    excludePatterns: [String] = []
  ) {
    self.keyword = keyword
    self.confidence = confidence
    self.caseSensitive = caseSensitive
    self.excludePatterns = excludePatterns
  }
}

final class MeetingPatternMatcher {
  private let patterns: [MeetingPattern]

  init(patterns: [MeetingPattern]) {
    self.patterns = patterns.sorted { $0.confidence.rawValue > $1.confidence.rawValue }
  }

  func findBestMatch(in title: String) -> MeetingDetectionResult.MeetingConfidence? {
    let processedTitle = title.lowercased()

    for pattern in patterns {
      let searchText = pattern.caseSensitive ? title : processedTitle
      let searchKeyword =
        pattern.caseSensitive ? pattern.keyword : pattern.keyword.lowercased()

      if searchText.contains(searchKeyword) {
        let shouldExclude = pattern.excludePatterns.contains { excludePattern in
          processedTitle.contains(excludePattern.lowercased())
        }

        if !shouldExclude {
          return pattern.confidence
        }
      }
    }

    return nil
  }
}

extension MeetingPatternMatcher {
  private static var commonMeetingPatterns: [MeetingPattern] {
    return [
      MeetingPattern(keyword: "refinement", confidence: .high),
      MeetingPattern(keyword: "daily", confidence: .high),
      MeetingPattern(keyword: "sync", confidence: .high),
      MeetingPattern(keyword: "retro", confidence: .high),
      MeetingPattern(keyword: "retrospective", confidence: .high),
      MeetingPattern(keyword: "meeting", confidence: .medium),
      MeetingPattern(keyword: "call", confidence: .medium)
    ]
  }

  static var teamsPatterns: [MeetingPattern] {
    return [
      MeetingPattern(keyword: "microsoft teams meeting", confidence: .high),
      MeetingPattern(keyword: "teams meeting", confidence: .high),
      MeetingPattern(keyword: "meeting in \"", confidence: .high),
      MeetingPattern(keyword: "call with", confidence: .high),
      MeetingPattern(
        keyword: "| Microsoft Teams",
        confidence: .high,
        caseSensitive: true,
        excludePatterns: ["chat", "activity", "microsoft teams"]
      ),
      MeetingPattern(keyword: "screen sharing", confidence: .medium)
    ] + commonMeetingPatterns
  }

  static var zoomPatterns: [MeetingPattern] {
    return [
      MeetingPattern(keyword: "zoom meeting", confidence: .high),
      MeetingPattern(keyword: "zoom webinar", confidence: .high),
      MeetingPattern(keyword: "screen share", confidence: .medium)
    ] + commonMeetingPatterns
  }

  static var googleMeetPatterns: [MeetingPattern] {
    return [
      MeetingPattern(keyword: "meet.google.com", confidence: .high),
      MeetingPattern(keyword: "google meet", confidence: .high),
      MeetingPattern(keyword: "meet -", confidence: .medium)
    ] + commonMeetingPatterns
  }
}
