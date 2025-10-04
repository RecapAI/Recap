import Foundation

/// Utility class for cleaning and formatting transcription text
final class TranscriptionTextCleaner {

  /// Clean WhisperKit text by removing structured tags and formatting it nicely
  static func cleanWhisperKitText(_ text: String) -> String {
    var cleanedText = text

    // Remove WhisperKit structured tags
    cleanedText = cleanedText.replacingOccurrences(of: "<|startoftranscript|>", with: "")
    cleanedText = cleanedText.replacingOccurrences(of: "<|endoftext|>", with: "")
    cleanedText = cleanedText.replacingOccurrences(of: "<|en|>", with: "")
    cleanedText = cleanedText.replacingOccurrences(of: "<|transcribe|>", with: "")

    // Remove timestamp patterns like <|0.00|> and <|2.00|>
    cleanedText = cleanedText.replacingOccurrences(
      of: "<|\\d+\\.\\d+\\|>", with: "", options: .regularExpression)

    // Remove pipe characters at the beginning and end of text
    cleanedText = cleanedText.replacingOccurrences(
      of: "^\\s*\\|\\s*", with: "", options: .regularExpression)
    cleanedText = cleanedText.replacingOccurrences(
      of: "\\s*\\|\\s*$", with: "", options: .regularExpression)

    // Clean up extra whitespace and normalize line breaks
    cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
    cleanedText = cleanedText.replacingOccurrences(
      of: "\\s+", with: " ", options: .regularExpression)

    return cleanedText
  }

  /// Clean and prettify transcription text with enhanced formatting
  static func prettifyTranscriptionText(_ text: String) -> String {
    // First clean the WhisperKit tags
    var cleanedText = cleanWhisperKitText(text)

    // Handle special sections like [User Audio Note: ...]
    cleanedText = formatUserAudioNotes(cleanedText)

    // Clean up [ Silence ] markers
    cleanedText = cleanedText.replacingOccurrences(
      of: "\\[ Silence \\]", with: "", options: .regularExpression)

    // Normalize whitespace and ensure proper paragraph formatting
    cleanedText = cleanedText.replacingOccurrences(
      of: "\\n\\s*\\n", with: "\n\n", options: .regularExpression)
    cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)

    return cleanedText
  }

  /// Format user audio note sections nicely
  private static func formatUserAudioNotes(_ text: String) -> String {
    var formattedText = text

    // Replace user audio note markers with cleaner formatting
    formattedText = formattedText.replacingOccurrences(
      of:
        "\\[User Audio Note: The following was spoken by the user during this recording\\."
        + " Please incorporate this context when creating the meeting summary:\\]",
      with: "\n**User Input:**",
      options: .regularExpression
    )

    formattedText = formattedText.replacingOccurrences(
      of:
        "\\[End of User Audio Note\\. Please align the above user input with "
        + "the meeting content for a comprehensive summary\\.\\]",
      with: "\n**System Audio:**",
      options: .regularExpression
    )

    return formattedText
  }
}
