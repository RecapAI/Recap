import AppKit

@MainActor
protocol StatusBarManagerType {
    var statusButton: NSStatusBarButton? { get }
    var delegate: StatusBarDelegate? { get set }
    func setRecordingState(_ recording: Bool)
}
