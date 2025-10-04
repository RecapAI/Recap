import AppKit
import SwiftUI

struct ViewGeometryReader: NSViewRepresentable {
  let onViewCreated: (NSView) -> Void

  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    view.wantsLayer = true
    DispatchQueue.main.async {
      onViewCreated(view)
    }
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
  }
}
