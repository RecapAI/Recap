import Combine
import Foundation

#if MOCKING
  import Mockable
#endif

@MainActor
#if MOCKING
  @Mockable
#endif
protocol WarningManagerType: ObservableObject {
  var activeWarnings: [WarningItem] { get }
  var activeWarningsPublisher: AnyPublisher<[WarningItem], Never> { get }

  func addWarning(_ warning: WarningItem)
  func removeWarning(withId id: String)
  func clearAllWarnings()
  func updateWarning(_ warning: WarningItem)
}

struct WarningItem: Identifiable, Equatable {
  let id: String
  let title: String
  let message: String
  let icon: String
  let severity: WarningSeverity

  init(
    id: String,
    title: String,
    message: String,
    icon: String = "exclamationmark.triangle.fill",
    severity: WarningSeverity = .warning
  ) {
    self.id = id
    self.title = title
    self.message = message
    self.icon = icon
    self.severity = severity
  }
}

enum WarningSeverity {
  case info
  case warning
  case error

  var color: String {
    switch self {
    case .info:
      return "0084FF"
    case .warning:
      return "FFA500"
    case .error:
      return "FF3B30"
    }
  }
}
