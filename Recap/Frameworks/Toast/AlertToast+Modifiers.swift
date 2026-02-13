import Combine
import SwiftUI

@available(iOS 14, macOS 11, *)
struct WithFrameModifier: ViewModifier {
  var withFrame: Bool
  var maxWidth: CGFloat = 175
  var maxHeight: CGFloat = 175

  @ViewBuilder
  func body(content: Content) -> some View {
    if withFrame {
      content
        .frame(maxWidth: maxWidth, maxHeight: maxHeight, alignment: .center)
    } else {
      content
    }
  }
}

@available(iOS 14, macOS 11, *)
struct BackgroundModifier: ViewModifier {
  var color: Color?

  @ViewBuilder
  func body(content: Content) -> some View {
    if let color = color {
      content
        .background(color)
    } else {
      content
        .background(BlurView())
    }
  }
}

@available(iOS 14, macOS 11, *)
struct TextForegroundModifier: ViewModifier {
  var color: Color?

  @ViewBuilder
  func body(content: Content) -> some View {
    if let color = color {
      content
        .foregroundColor(color)
    } else {
      content
    }
  }
}

@available(iOS 14, macOS 11, *)
extension View {
  func withFrame(_ withFrame: Bool) -> some View {
    modifier(WithFrameModifier(withFrame: withFrame))
  }

  func alertBackground(_ color: Color? = nil) -> some View {
    modifier(BackgroundModifier(color: color))
  }

  func textColor(_ color: Color? = nil) -> some View {
    modifier(TextForegroundModifier(color: color))
  }

  @ViewBuilder func valueChanged<T: Equatable>(
    value: T, onChange: @escaping (T) -> Void
  ) -> some View {
    if #available(iOS 14.0, *) {
      self.onChange(of: value) { _, newValue in
        onChange(newValue)
      }
    } else {
      self.onReceive(Just(value)) { (value) in
        onChange(value)
      }
    }
  }
}

@available(iOS 14, macOS 11, *)
extension Image {
  func hudModifier() -> some View {
    self
      .renderingMode(.template)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(maxWidth: 20, maxHeight: 20, alignment: .center)
  }
}
