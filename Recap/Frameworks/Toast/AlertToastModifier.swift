import Combine
import SwiftUI

@available(iOS 14, macOS 11, *)
public struct AlertToastModifier: ViewModifier {

  /// Presentation `Binding<Bool>`
  @Binding var isPresenting: Bool

  /// Duration time to display the alert
  @State var duration: TimeInterval = 2

  /// Tap to dismiss alert
  @State var tapToDismiss: Bool = true

  var offsetY: CGFloat = 0

  /// Init `AlertToast` View
  var alert: () -> AlertToast

  /// Completion block returns `true` after dismiss
  var onTap: (() -> Void)?
  var completion: (() -> Void)?

  @State private var workItem: DispatchWorkItem?

  @State private var hostRect: CGRect = .zero
  @State private var alertRect: CGRect = .zero

  private var screen: CGRect {
    #if os(iOS)
      return UIScreen.main.bounds
    #else
      return NSScreen.main?.frame ?? .zero
    #endif
  }

  private var offset: CGFloat {
    return -hostRect.midY + alertRect.height
  }

  @ViewBuilder
  public func main() -> some View {
    if isPresenting {
      switch alert().displayMode {
      case .alert:
        alertModeView
      case .hud:
        hudModeView
      case .banner:
        bannerModeView
      }
    }
  }

  private var alertModeView: some View {
    alert()
      .onTapGesture { handleTapGesture() }
      .onDisappear(perform: { completion?() })
      .transition(AnyTransition.scale(scale: 0.8).combined(with: .opacity))
  }

  private var hudModeView: some View {
    alert()
      .overlay(
        GeometryReader { geo -> AnyView in
          let rect = geo.frame(in: .global)
          if rect.integral != alertRect.integral {
            DispatchQueue.main.async {
              self.alertRect = rect
            }
          }
          return AnyView(EmptyView())
        }
      )
      .onTapGesture { handleTapGesture() }
      .onDisappear(perform: { completion?() })
      .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
  }

  private var bannerModeView: some View {
    alert()
      .onTapGesture { handleTapGesture() }
      .onDisappear(perform: { completion?() })
      .transition(
        alert().displayMode == .banner(.slide)
          ? AnyTransition.slide.combined(with: .opacity)
          : AnyTransition.move(edge: .bottom))
  }

  private func handleTapGesture() {
    onTap?()
    if tapToDismiss {
      withAnimation(Animation.spring()) {
        self.workItem?.cancel()
        isPresenting = false
        self.workItem = nil
      }
    }
  }

  @ViewBuilder
  public func body(content: Content) -> some View {
    switch alert().displayMode {
    case .banner:
      bannerBodyView(content)
    case .hud:
      hudBodyView(content)
    case .alert:
      alertBodyView(content)
    }
  }

  private func bannerBodyView(_ content: Content) -> some View {
    content
      .overlay(
        ZStack {
          main()
            .offset(y: offsetY)
        }
        .animation(Animation.spring(), value: isPresenting)
      )
      .valueChanged(value: isPresenting) { presented in
        if presented {
          onAppearAction()
        }
      }
  }

  private func hudBodyView(_ content: Content) -> some View {
    content
      .overlay(
        GeometryReader { geo -> AnyView in
          let rect = geo.frame(in: .global)
          if rect.integral != hostRect.integral {
            DispatchQueue.main.async {
              self.hostRect = rect
            }
          }
          return AnyView(EmptyView())
        }
        .overlay(
          ZStack {
            main()
              .offset(y: offsetY)
          }
          .frame(maxWidth: screen.width, maxHeight: screen.height)
          .offset(y: offset)
          .animation(Animation.spring(), value: isPresenting))
      )
      .valueChanged(value: isPresenting) { presented in
        if presented {
          onAppearAction()
        }
      }
  }

  private func alertBodyView(_ content: Content) -> some View {
    content
      .overlay(
        ZStack {
          main()
            .offset(y: offsetY)
        }
        .frame(maxWidth: screen.width, maxHeight: screen.height, alignment: .center)
        .edgesIgnoringSafeArea(.all)
        .animation(Animation.spring(), value: isPresenting)
      )
      .valueChanged(value: isPresenting) { presented in
        if presented {
          onAppearAction()
        }
      }
  }

  private func onAppearAction() {
    guard workItem == nil else {
      return
    }

    if alert().type == .loading {
      duration = 0
      tapToDismiss = false
    }

    if duration > 0 {
      workItem?.cancel()

      let task = DispatchWorkItem {
        withAnimation(Animation.spring()) {
          isPresenting = false
          workItem = nil
        }
      }
      workItem = task
      DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
  }
}
