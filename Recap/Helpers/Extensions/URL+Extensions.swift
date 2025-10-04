import Foundation
import UniformTypeIdentifiers

extension URL {
  func parentBundleURL(maxDepth: Int = 8) -> URL? {
    var depth = 0
    var url = deletingLastPathComponent()
    while depth < maxDepth, !url.isBundle {
      url = url.deletingLastPathComponent()
      depth += 1
    }
    return url.isBundle ? url : nil
  }

  var isBundle: Bool {
    (try? resourceValues(forKeys: [.contentTypeKey]))?.contentType?.conforms(to: .bundle)
      == true
  }

  var isApp: Bool {
    (try? resourceValues(forKeys: [.contentTypeKey]))?.contentType?.conforms(to: .application)
      == true
  }
}
