import Foundation

struct ProcessInfoHelper {
  static func processInfo(for pid: pid_t) -> (name: String, path: String)? {
    let nameBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(MAXPATHLEN))
    let pathBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(MAXPATHLEN))

    defer {
      nameBuffer.deallocate()
      pathBuffer.deallocate()
    }

    let nameLength = proc_name(pid, nameBuffer, UInt32(MAXPATHLEN))
    let pathLength = proc_pidpath(pid, pathBuffer, UInt32(MAXPATHLEN))

    guard nameLength > 0, pathLength > 0 else {
      return nil
    }

    let name = String(cString: nameBuffer)
    let path = String(cString: pathBuffer)

    return (name, path)
  }
}
