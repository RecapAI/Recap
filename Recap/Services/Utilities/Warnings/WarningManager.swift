import Combine
import Foundation

final class WarningManager: WarningManagerType {
  @Published private(set) var activeWarnings: [WarningItem] = []

  var activeWarningsPublisher: AnyPublisher<[WarningItem], Never> {
    $activeWarnings.eraseToAnyPublisher()
  }

  func addWarning(_ warning: WarningItem) {
    if !activeWarnings.contains(where: { $0.id == warning.id }) {
      activeWarnings.append(warning)
    }
  }

  func removeWarning(withId id: String) {
    activeWarnings.removeAll { $0.id == id }
  }

  func clearAllWarnings() {
    activeWarnings.removeAll()
  }

  func updateWarning(_ warning: WarningItem) {
    if let index = activeWarnings.firstIndex(where: { $0.id == warning.id }) {
      activeWarnings[index] = warning
    } else {
      addWarning(warning)
    }
  }
}
