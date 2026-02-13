import Combine
import Foundation

@MainActor
final class SummarizationService: SummarizationServiceType {
  var isAvailable: Bool {
    llmService.isProviderAvailable && currentModel != nil
  }

  var currentModelName: String? {
    currentModel?.name
  }

  private let llmService: LLMServiceType
  private var currentModel: LLMModelInfo?
  private var cancellables = Set<AnyCancellable>()

  init(llmService: LLMServiceType) {
    self.llmService = llmService
    setupModelMonitoring()
  }

  private func setupModelMonitoring() {
    Task {
      currentModel = try? await llmService.getSelectedModel()
    }
  }

  func checkAvailability() async -> Bool {
    currentModel = try? await llmService.getSelectedModel()
    return isAvailable
  }

  func summarize(_ request: SummarizationRequest) async throws -> SummarizationResult {
    guard isAvailable else {
      throw LLMError.providerNotAvailable
    }

    guard let model = currentModel else {
      throw LLMError.configurationError("No model selected for summarization")
    }

    let startTime = Date()

    let prompt = await buildPrompt(from: request)
    let options = buildLLMOptions(from: request.options)

    let summary = try await llmService.generateSummarization(
      text: prompt,
      options: options
    )

    let processingTime = Date().timeIntervalSince(startTime)

    return SummarizationResult(
      summary: summary,
      keyPoints: [],
      actionItems: [],
      modelUsed: model.name,
      processingTime: processingTime
    )
  }

  func cancelCurrentSummarization() {
    llmService.cancelCurrentTask()
  }

  private func buildPrompt(from request: SummarizationRequest) async -> String {
    var prompt = ""

    if let metadata = request.metadata {
      prompt += "Context:\n"
      if let appName = metadata.applicationName {
        prompt += "- Application: \(appName)\n"
      }
      prompt += "- Duration: \(formatDuration(metadata.duration))\n"
      if let participants = metadata.participants, !participants.isEmpty {
        prompt += "- Participants: \(participants.joined(separator: ", "))\n"
      }
      prompt += "\n"
    }

    prompt += "Transcript:\n\(request.transcriptText)"

    return prompt
  }

  private func buildLLMOptions(
    from options: SummarizationOptions
  ) -> LLMOptions {
    let maxTokens = options.maxLength.map { $0 * 2 }

    return LLMOptions(
      temperature: 0.7,
      maxTokens: maxTokens,
      keepAliveMinutes: 5
    )
  }

  private func formatDuration(_ duration: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .abbreviated
    return formatter.string(from: duration) ?? "Unknown"
  }
}
