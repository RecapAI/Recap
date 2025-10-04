import MarkdownUI
import SwiftUI

extension SummaryView {
  func markdownContent(_ summaryText: String) -> some View {
    Markdown(summaryText)
      .markdownTheme(.docC)
      .markdownTextStyle {
        ForegroundColor(UIConstants.Colors.textSecondary)
        FontSize(12)
      }
      .markdownBlockStyle(\.heading1) { configuration in
        configuration.label
          .markdownTextStyle {
            FontWeight(.bold)
            FontSize(18)
            ForegroundColor(UIConstants.Colors.textPrimary)
          }
          .padding(.vertical, 8)
      }
      .markdownBlockStyle(\.heading2) { configuration in
        configuration.label
          .markdownTextStyle {
            FontWeight(.semibold)
            FontSize(16)
            ForegroundColor(UIConstants.Colors.textPrimary)
          }
          .padding(.vertical, 6)
      }
      .markdownBlockStyle(\.heading3) { configuration in
        configuration.label
          .markdownTextStyle {
            FontWeight(.medium)
            FontSize(14)
            ForegroundColor(UIConstants.Colors.textPrimary)
          }
          .padding(.vertical, 4)
      }
      .markdownBlockStyle(\.listItem) { configuration in
        configuration.label
          .markdownTextStyle {
            FontSize(12)
          }
      }
      .textSelection(.enabled)
  }
}
