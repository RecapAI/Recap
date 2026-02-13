import XCTest

extension XCTestCase {
  func fulfillment(
    of expectations: [XCTestExpectation],
    timeout: TimeInterval,
    enforceOrder: Bool = false
  ) async {
    await withCheckedContinuation { continuation in
      wait(for: expectations, timeout: timeout, enforceOrder: enforceOrder)
      continuation.resume()
    }
  }
}
