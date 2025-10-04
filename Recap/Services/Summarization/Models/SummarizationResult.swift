import Foundation

enum ActionItemPriority: String, CaseIterable {
  case high
  case medium
  case low
}

struct ActionItem {
  let description: String
  let assignee: String?
  let priority: ActionItemPriority
}

struct SummarizationResult {
  let id: String
  let summary: String
  let keyPoints: [String]
  let actionItems: [ActionItem]
  let generatedAt: Date
  let modelUsed: String
  let processingTime: TimeInterval

  init(
    id: String = UUID().uuidString,
    summary: String,
    keyPoints: [String] = [],
    actionItems: [ActionItem] = [],
    generatedAt: Date = Date(),
    modelUsed: String,
    processingTime: TimeInterval = 0
  ) {
    self.id = id
    self.summary = summary
    self.keyPoints = keyPoints
    self.actionItems = actionItems
    self.generatedAt = generatedAt
    self.modelUsed = modelUsed
    self.processingTime = processingTime
  }
}
