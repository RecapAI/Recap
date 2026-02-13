import Foundation

@MainActor
extension GeneralSettingsViewModel {
  func testLLMProvider() async {
    errorMessage = nil
    testResult = nil
    isTestingProvider = true

    defer {
      isTestingProvider = false
    }

    let request = createTestRequest()

    do {
      let result = try await llmService.generateSummarization(
        text: await buildTestPrompt(from: request),
        options: LLMOptions(temperature: 0.7, maxTokens: 500, keepAliveMinutes: 5)
      )

      testResult = "✓ Test successful!\n\nSummary:\n\(result)"
    } catch {
      errorMessage = "Test failed: \(error.localizedDescription)"
    }
  }

  private func createTestRequest() -> SummarizationRequest {
    let boilerplateTranscript = """
    Speaker 1: Good morning everyone, thank you for joining today's meeting.
    Speaker 2: Thanks for having us. I wanted to discuss our Q4 roadmap.
    Speaker 1: Absolutely. Let's start with the main priorities.
    Speaker 2: We need to focus on three key areas: product launch, marketing campaign, \
    and customer feedback integration.
    Speaker 1: Agreed. For the product launch, we're targeting mid-November.
    Speaker 2: That timeline works well with our marketing plans.
    Speaker 1: Great. Any concerns or questions?
    Speaker 2: No, I think we're aligned. Let's schedule a follow-up next week.
    Speaker 1: Perfect, I'll send out calendar invites. Thanks everyone!
    """

    let metadata = TranscriptMetadata(
      duration: 180,
      participants: ["Speaker 1", "Speaker 2"],
      recordingDate: Date(),
      applicationName: "Test"
    )

    let options = SummarizationOptions(
      style: .concise,
      includeActionItems: true,
      includeKeyPoints: true,
      maxLength: nil,
      customPrompt: customPromptTemplateValue.isEmpty ? nil : customPromptTemplateValue
    )

    return SummarizationRequest(
      transcriptText: boilerplateTranscript,
      metadata: metadata,
      options: options
    )
  }

  private func buildTestPrompt(from request: SummarizationRequest) async -> String {
    var prompt = ""

    if let metadata = request.metadata {
      prompt += "Context:\n"
      if let appName = metadata.applicationName {
        prompt += "- Application: \(appName)\n"
      }
      prompt += "- Duration: 3 minutes\n"
      if let participants = metadata.participants, !participants.isEmpty {
        prompt += "- Participants: \(participants.joined(separator: ", "))\n"
      }
      prompt += "\n"
    }

    prompt += "Transcript:\n\(request.transcriptText)"

    return prompt
  }
}
