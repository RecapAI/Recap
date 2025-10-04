import Combine
import Foundation

#if MOCKING
  import Mockable
#endif

#if MOCKING
  @Mockable
#endif
protocol AudioProcessControllerType: ObservableObject {
  var processes: [AudioProcess] { get }
  var processGroups: [AudioProcessGroup] { get }
  var meetingApps: [AudioProcess] { get }

  func activate()
}
