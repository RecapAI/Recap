import Foundation

@MainActor
protocol SummarizationServiceType: AnyObject {
  var isAvailable: Bool { get }
  var currentModelName: String? { get }

  func checkAvailability() async -> Bool
  func summarize(_ request: SummarizationRequest) async throws -> SummarizationResult
  func cancelCurrentSummarization()
}
