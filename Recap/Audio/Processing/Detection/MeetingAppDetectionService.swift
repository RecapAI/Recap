import Foundation

protocol MeetingAppDetecting {
  func detectMeetingApps() async -> [AudioProcess]
  func getAllAudioProcesses() async -> [AudioProcess]
}

final class MeetingAppDetectionService: MeetingAppDetecting {
  private var processController: (any AudioProcessControllerType)?

  init(processController: (any AudioProcessControllerType)?) {
    self.processController = processController
  }

  func setProcessController(_ controller: any AudioProcessControllerType) {
    self.processController = controller
  }

  func detectMeetingApps() async -> [AudioProcess] {
    guard let processController = processController else { return [] }
    return await MainActor.run { processController.meetingApps }
  }

  func getAllAudioProcesses() async -> [AudioProcess] {
    guard let processController = processController else { return [] }
    return await MainActor.run { processController.processes }
  }
}
