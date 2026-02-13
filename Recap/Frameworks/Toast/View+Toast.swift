import SwiftUI

@available(iOS 14, macOS 11, *)
extension View {
  public func toast(
    isPresenting: Binding<Bool>, duration: TimeInterval = 2, tapToDismiss: Bool = true,
    offsetY: CGFloat = 0, alert: @escaping () -> AlertToast, onTap: (() -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) -> some View {
    modifier(
      AlertToastModifier(
        isPresenting: isPresenting, duration: duration, tapToDismiss: tapToDismiss,
        offsetY: offsetY, alert: alert, onTap: onTap, completion: completion))
  }

  public func toast<Item>(
    item: Binding<Item?>, duration: Double = 2, tapToDismiss: Bool = true, offsetY: CGFloat = 0,
    alert: @escaping (Item?) -> AlertToast, onTap: (() -> Void)? = nil,
    completion: (() -> Void)? = nil
  ) -> some View where Item: Identifiable {
    modifier(
      AlertToastModifier(
        isPresenting: Binding(
          get: {
            item.wrappedValue != nil
          },
          set: { select in
            if !select {
              item.wrappedValue = nil
            }
          }
        ),
        duration: duration,
        tapToDismiss: tapToDismiss,
        offsetY: offsetY,
        alert: {
          alert(item.wrappedValue)
        },
        onTap: onTap,
        completion: completion
      )
    )
  }
}
