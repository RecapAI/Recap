import Foundation

@MainActor
protocol PreviousRecapsViewModelType: ObservableObject {
  var groupedRecordings: GroupedRecordings { get }
  var isLoading: Bool { get }
  var errorMessage: String? { get }

  func loadRecordings() async
  func startAutoRefresh()
  func stopAutoRefresh()
}
