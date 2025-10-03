import Foundation
import AppKit
import SwiftUI
import OSLog
import Combine

@MainActor
final class AudioProcessController: @MainActor AudioProcessControllerType {
    private let logger = Logger(subsystem: AppConstants.Logging.subsystem, category: String(describing: AudioProcessController.self))
    
    private let detectionService: AudioProcessDetectionServiceType
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var processes = [AudioProcess]() {
        didSet {
            guard processes != oldValue else { return }
            processGroups = AudioProcessGroup.groups(with: processes)
            meetingApps = processes.filter { $0.isMeetingApp && $0.audioActive }
        }
    }
    
    @Published private(set) var processGroups = [AudioProcessGroup]()
    @Published private(set) var meetingApps = [AudioProcess]()
    
    init(detectionService: AudioProcessDetectionServiceType = AudioProcessDetectionService()) {
        self.detectionService = detectionService
    }
    
    func activate() {
        logger.debug(#function)
        
        NSWorkspace.shared
            .publisher(for: \.runningApplications, options: [.initial, .new])
            .map { $0.filter({ $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) }
            .sink { [weak self] apps in
                self?.reloadProcesses(from: apps)
            }
            .store(in: &cancellables)
    }
}

private extension AudioProcessController {
    func reloadProcesses(from apps: [NSRunningApplication]) {
        do {
            processes = try detectionService.detectActiveProcesses(from: apps)
        } catch {
            logger.error("Error reading process list: \(error, privacy: .public)")
        }
    }
}
