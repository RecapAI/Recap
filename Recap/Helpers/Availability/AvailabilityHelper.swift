import Combine
import Foundation

@MainActor
protocol AvailabilityHelperType: AnyObject {
  var isAvailable: Bool { get }
  var availabilityPublisher: AnyPublisher<Bool, Never> { get }

  func startMonitoring()
  func stopMonitoring()
  func checkAvailabilityNow() async -> Bool
}

@MainActor
final class AvailabilityHelper: AvailabilityHelperType {
  @Published private(set) var isAvailable: Bool = false
  var availabilityPublisher: AnyPublisher<Bool, Never> {
    $isAvailable.eraseToAnyPublisher()
  }

  private let checkInterval: TimeInterval
  private let availabilityCheck: () async -> Bool
  private var monitoringTimer: Timer?

  init(
    checkInterval: TimeInterval = 30.0,
    availabilityCheck: @escaping () async -> Bool
  ) {
    self.checkInterval = checkInterval
    self.availabilityCheck = availabilityCheck
  }

  deinit {
    monitoringTimer?.invalidate()
    monitoringTimer = nil
  }

  func startMonitoring() {
    Task {
      await checkAvailabilityNow()
    }

    monitoringTimer = Timer.scheduledTimer(
      withTimeInterval: checkInterval,
      repeats: true
    ) { [weak self] _ in
      Task { @MainActor in
        await self?.checkAvailabilityNow()
      }
    }
  }

  func stopMonitoring() {
    monitoringTimer?.invalidate()
    monitoringTimer = nil
  }

  func checkAvailabilityNow() async -> Bool {
    let available = await availabilityCheck()
    isAvailable = available
    return available
  }
}
