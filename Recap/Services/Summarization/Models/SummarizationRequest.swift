import Foundation

enum SummarizationStyle: String, CaseIterable {
  case concise
  case detailed
  case bulletPoints
  case executive
}

struct TranscriptMetadata {
  let duration: TimeInterval
  let participants: [String]?
  let recordingDate: Date
  let applicationName: String?
}

struct SummarizationOptions {
  let style: SummarizationStyle
  let includeActionItems: Bool
  let includeKeyPoints: Bool
  let maxLength: Int?
  let customPrompt: String?

  static var `default`: SummarizationOptions {
    SummarizationOptions(
      style: .concise,
      includeActionItems: true,
      includeKeyPoints: true,
      maxLength: nil,
      customPrompt: nil
    )
  }
}

struct SummarizationRequest {
  let transcriptText: String
  let metadata: TranscriptMetadata?
  let options: SummarizationOptions
}
