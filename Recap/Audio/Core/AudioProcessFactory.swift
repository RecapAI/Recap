import AppKit
import AudioToolbox
import Foundation

extension AudioProcess {
  init(app: NSRunningApplication, objectID: AudioObjectID) {
    let name =
      app.localizedName ?? app.bundleURL?.deletingPathExtension().lastPathComponent ?? app
      .bundleIdentifier?.components(separatedBy: ".").last ?? "Unknown \(app.processIdentifier)"

    self.init(
      id: app.processIdentifier,
      kind: .app,
      name: name,
      audioActive: objectID.readProcessIsRunning(),
      bundleID: app.bundleIdentifier,
      bundleURL: app.bundleURL,
      objectID: objectID
    )
  }

  init(objectID: AudioObjectID, runningApplications apps: [NSRunningApplication]) throws {
    let pid: pid_t = try objectID.read(kAudioProcessPropertyPID, defaultValue: -1)

    if let app = apps.first(where: { $0.processIdentifier == pid }) {
      self.init(app: app, objectID: objectID)
    } else {
      try self.init(objectID: objectID, pid: pid)
    }
  }

  init(objectID: AudioObjectID, pid: pid_t) throws {
    let bundleID = objectID.readProcessBundleID()
    let bundleURL: URL?
    let name: String

    (name, bundleURL) =
      if let info = ProcessInfoHelper.processInfo(for: pid) {
        (info.name, URL(fileURLWithPath: info.path).parentBundleURL())
      } else if let id = bundleID?.lastReverseDNSComponent {
        (id, nil)
      } else {
        ("Unknown (\(pid))", nil)
      }

    self.init(
      id: pid,
      kind: bundleURL?.isApp == true ? .app : .process,
      name: name,
      audioActive: objectID.readProcessIsRunning(),
      bundleID: bundleID.flatMap { $0.isEmpty ? nil : $0 },
      bundleURL: bundleURL,
      objectID: objectID
    )
  }
}
