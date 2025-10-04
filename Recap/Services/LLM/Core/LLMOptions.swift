import Foundation

struct LLMOptions {
  let temperature: Double
  let maxTokens: Int?
  let topP: Double?
  let topK: Int?
  let repeatPenalty: Double?
  let keepAliveMinutes: Int?
  let seed: Int?
  let stopSequences: [String]?

  init(
    temperature: Double = 0.7,
    maxTokens: Int? = 8192,
    topP: Double? = nil,
    topK: Int? = nil,
    repeatPenalty: Double? = nil,
    keepAliveMinutes: Int? = nil,
    seed: Int? = nil,
    stopSequences: [String]? = nil
  ) {
    self.temperature = temperature
    self.maxTokens = maxTokens
    self.topP = topP
    self.topK = topK
    self.repeatPenalty = repeatPenalty
    self.keepAliveMinutes = keepAliveMinutes
    self.seed = seed
    self.stopSequences = stopSequences
  }

  static var defaultSummarization: LLMOptions {
    LLMOptions(
      temperature: 0.3,
      maxTokens: 8192,
      keepAliveMinutes: 5
    )
  }
}
