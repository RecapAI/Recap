import Combine
import Foundation
import OSLog
import ScreenCaptureKit

private struct DetectorResult {
  let detector: any MeetingDetectorType
  let result: MeetingDetectionResult
}

@MainActor
final class MeetingDetectionService: MeetingDetectionServiceType {
  @Published private(set) var isMeetingActive = false
  @Published private(set) var activeMeetingInfo: ActiveMeetingInfo?
  @Published private(set) var detectedMeetingApp: AudioProcess?
  @Published private(set) var hasPermission = false
  @Published private(set) var isMonitoring = false

  var meetingStatePublisher: AnyPublisher<MeetingState, Never> {
    Publishers.CombineLatest3($isMeetingActive, $activeMeetingInfo, $detectedMeetingApp)
      .map { isMeeting, meetingInfo, detectedApp in
        if isMeeting, let info = meetingInfo {
          return .active(info: info, detectedApp: detectedApp)
        } else {
          return .inactive
        }
      }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  private var monitoringTask: Task<Void, Never>?
  private var detectors: [any MeetingDetectorType] = []
  private let checkInterval: TimeInterval = 1.0
  private let logger = Logger(
    subsystem: AppConstants.Logging.subsystem, category: "MeetingDetectionService")
  private let audioProcessController: any AudioProcessControllerType
  private let permissionsHelper: any PermissionsHelperType

  init(
    audioProcessController: any AudioProcessControllerType,
    permissionsHelper: any PermissionsHelperType
  ) {
    self.audioProcessController = audioProcessController
    self.permissionsHelper = permissionsHelper
    setupDetectors()
  }

  private func setupDetectors() {
    detectors = [
      TeamsMeetingDetector(),
      ZoomMeetingDetector(),
      GoogleMeetDetector()
    ]
  }

  func startMonitoring() {
    guard !isMonitoring else { return }

    isMonitoring = true
    monitoringTask?.cancel()
    monitoringTask = Task {
      while !Task.isCancelled {
        if Task.isCancelled { break }
        await checkForMeetings()
        try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
      }
    }
  }

  func stopMonitoring() {
    monitoringTask?.cancel()
    isMonitoring = false
    monitoringTask = nil
    isMeetingActive = false
    activeMeetingInfo = nil
  }

  private func checkForMeetings() async {
    do {
      let content = try await SCShareableContent.current
      hasPermission = true

      var highestConfidenceResult: DetectorResult?

      for detector in detectors {
        let relevantWindows = content.windows.filter { window in
          guard let app = window.owningApplication else { return false }
          let bundleID = app.bundleIdentifier
          return detector.supportedBundleIdentifiers.contains(bundleID)
        }

        if !relevantWindows.isEmpty {
          let result = await detector.checkForMeeting(in: relevantWindows)

          if result.isActive {
            if highestConfidenceResult == nil {
              highestConfidenceResult = DetectorResult(
                detector: detector, result: result)
            } else if let currentResult = highestConfidenceResult {
              if result.confidence.rawValue > currentResult.result.confidence.rawValue {
                highestConfidenceResult = DetectorResult(
                  detector: detector, result: result)
              }
            }
          }
        }
      }

      if let detectorResult = highestConfidenceResult {
        let meetingInfo = ActiveMeetingInfo(
          appName: detectorResult.detector.meetingAppName,
          title: detectorResult.result.title ?? "Meeting in progress",
          confidence: detectorResult.result.confidence
        )
        let matchedApp = findMatchingAudioProcess(
          bundleIdentifiers: detectorResult.detector.supportedBundleIdentifiers
        )

        activeMeetingInfo = meetingInfo
        detectedMeetingApp = matchedApp
        isMeetingActive = true
      } else {
        activeMeetingInfo = nil
        detectedMeetingApp = nil
        isMeetingActive = false
      }

    } catch {
      logger.error("Failed to check for meetings: \(error.localizedDescription)")
      hasPermission = false
    }
  }

  private func findMatchingAudioProcess(bundleIdentifiers: Set<String>) -> AudioProcess? {
    audioProcessController.processes.first { process in
      guard let processBundleID = process.bundleID else { return false }
      return bundleIdentifiers.contains(processBundleID)
    }
  }
}

extension MeetingDetectionResult.MeetingConfidence: Comparable {
  var rawValue: Int {
    switch self {
    case .low: return 1
    case .medium: return 2
    case .high: return 3
    }
  }

  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
