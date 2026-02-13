import Foundation

struct AudioProcessGroup: Identifiable, Hashable, Sendable {
  var id: String
  var title: String
  var processes: [AudioProcess]
}

extension AudioProcessGroup {
  static func groups(with processes: [AudioProcess]) -> [AudioProcessGroup] {
    var byKind = [AudioProcess.Kind: AudioProcessGroup]()

    for process in processes {
      byKind[process.kind, default: .init(for: process.kind)].processes.append(process)
    }

    return byKind.values.sorted(by: {
      $0.title.localizedStandardCompare($1.title) == .orderedAscending
    })
  }

  init(for kind: AudioProcess.Kind) {
    self.init(id: kind.rawValue, title: kind.groupTitle, processes: [])
  }
}
