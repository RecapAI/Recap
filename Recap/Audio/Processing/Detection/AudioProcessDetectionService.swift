import AppKit
import AudioToolbox
import Foundation
import OSLog

protocol AudioProcessDetectionServiceType {
  func detectActiveProcesses(from apps: [NSRunningApplication]) throws -> [AudioProcess]
}

final class AudioProcessDetectionService: AudioProcessDetectionServiceType {
  private let logger = Logger(
    subsystem: AppConstants.Logging.subsystem,
    category: String(describing: AudioProcessDetectionService.self))

  func detectActiveProcesses(from apps: [NSRunningApplication]) throws -> [AudioProcess] {
    let objectIdentifiers = try AudioObjectID.readProcessList()

    let processes: [AudioProcess] = objectIdentifiers.compactMap { objectID in
      do {
        let process = try AudioProcess(objectID: objectID, runningApplications: apps)
        return process
      } catch {
        logger.warning(
          """
          Failed to initialize process with object ID #\(objectID, privacy: .public): \
          \(error, privacy: .public)
          """
        )
        return nil
      }
    }

    return processes.sorted { lhs, rhs in
      if lhs.isMeetingApp != rhs.isMeetingApp {
        return lhs.isMeetingApp
      }

      if lhs.audioActive != rhs.audioActive {
        return lhs.audioActive
      }

      return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
  }
}
