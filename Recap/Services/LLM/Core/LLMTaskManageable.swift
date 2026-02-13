import Foundation

@MainActor
protocol LLMTaskManageable: AnyObject {
  var currentTask: Task<Void, Never>? { get set }
  func cancelCurrentTask()
}

extension LLMTaskManageable {
  func cancelCurrentTask() {
    currentTask?.cancel()
    currentTask = nil
  }

  func executeWithTaskManagement<T>(
    operation: @escaping () async throws -> T
  ) async throws -> T {
    cancelCurrentTask()

    return try await withTaskCancellationHandler {
      try await operation()
    } onCancel: {
      Task { [weak self] in
        await self?.cancelCurrentTask()
      }
    }
  }
}
