import Foundation
import AudioToolbox
import AVFoundation

protocol AudioTapType: ObservableObject {
    var activated: Bool { get }
    var audioLevel: Float { get }
    var errorMessage: String? { get }
    var tapStreamDescription: AudioStreamBasicDescription? { get }

    @MainActor func activate()
    func invalidate()
    func run(on queue: DispatchQueue, ioBlock: @escaping AudioDeviceIOBlock,
             invalidationHandler: @escaping (Self) -> Void) throws
}

protocol AudioTapRecorderType: ObservableObject {
    var fileURL: URL { get }
    var isRecording: Bool { get }

    @MainActor func start() throws
    func stop()
}
