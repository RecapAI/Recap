import Combine
import SwiftUI

@available(iOS 14, macOS 11, *)
public struct AlertToast: View {
  /// The display mode
  /// - `alert`
  /// - `hud`
  /// - `banner`
  public var displayMode: DisplayMode = .alert

  /// What the alert would show
  /// `complete`, `error`, `systemImage`, `image`, `loading`, `regular`
  public var type: AlertType

  /// The title of the alert (`Optional(String)`)
  public var title: String?

  /// The subtitle of the alert (`Optional(String)`)
  public var subTitle: String?

  /// Customize your alert appearance
  public var style: AlertStyle?

  /// Full init
  public init(
    displayMode: DisplayMode = .alert,
    type: AlertType,
    title: String? = nil,
    subTitle: String? = nil,
    style: AlertStyle? = nil
  ) {

    self.displayMode = displayMode
    self.type = type
    self.title = title
    self.subTitle = subTitle
    self.style = style
  }

  /// Short init with most used parameters
  public init(
    displayMode: DisplayMode,
    type: AlertType,
    title: String? = nil
  ) {

    self.displayMode = displayMode
    self.type = type
    self.title = title
  }

  /// Banner from the bottom of the view
  public var banner: some View {
    VStack {
      Spacer()

      // Banner view starts here
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          switch type {
          case .complete(let color):
            Image(systemName: "checkmark")
              .foregroundColor(color)
          case .error(let color):
            Image(systemName: "xmark")
              .foregroundColor(color)
          case .systemImage(let name, let color):
            Image(systemName: name)
              .foregroundColor(color)
          case .image(let name, let color):
            Image(name)
              .renderingMode(.template)
              .foregroundColor(color)
          case .loading:
            ActivityIndicator(color: style?.activityIndicatorColor ?? .white)
          case .regular:
            EmptyView()
          }

          Text(LocalizedStringKey(title ?? ""))
            .font(style?.titleFont ?? Font.headline.bold())
        }

        if let subTitle = subTitle {
          Text(LocalizedStringKey(subTitle))
            .font(style?.subTitleFont ?? Font.subheadline)
        }
      }
      .multilineTextAlignment(.leading)
      .textColor(style?.titleColor ?? nil)
      .padding()
      .frame(maxWidth: 400, alignment: .leading)
      .alertBackground(style?.backgroundColor ?? nil)
      .cornerRadius(10)
      .padding([.horizontal, .bottom])
    }
  }

  /// HUD View
  public var hud: some View {
    Group {
      HStack(spacing: 16) {
        switch type {
        case .complete(let color):
          Image(systemName: "checkmark")
            .hudModifier()
            .foregroundColor(color)
        case .error(let color):
          Image(systemName: "xmark")
            .hudModifier()
            .foregroundColor(color)
        case .systemImage(let name, let color):
          Image(systemName: name)
            .hudModifier()
            .foregroundColor(color)
        case .image(let name, let color):
          Image(name)
            .hudModifier()
            .foregroundColor(color)
        case .loading:
          ActivityIndicator(color: style?.activityIndicatorColor ?? .white)
        case .regular:
          EmptyView()
        }

        if title != nil || subTitle != nil {
          VStack(alignment: type == .regular ? .center : .leading, spacing: 2) {
            if let title = title {
              Text(LocalizedStringKey(title))
                .font(style?.titleFont ?? Font.body.bold())
                .multilineTextAlignment(.center)
                .textColor(style?.titleColor ?? nil)
            }
            if let subTitle = subTitle {
              Text(LocalizedStringKey(subTitle))
                .font(style?.subTitleFont ?? Font.footnote)
                .opacity(0.7)
                .multilineTextAlignment(.center)
                .textColor(style?.subtitleColor ?? nil)
            }
          }
        }
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 8)
      .frame(minHeight: 50)
      .alertBackground(style?.backgroundColor ?? nil)
      .clipShape(Capsule())
      .overlay(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1))
      .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 6)
      .compositingGroup()
    }
    .padding(.top)
  }

  /// Alert View
  public var alert: some View {
    VStack {
      switch type {
      case .complete(let color):
        Spacer()
        AnimatedCheckmark(color: color)
        Spacer()
      case .error(let color):
        Spacer()
        AnimatedXmark(color: color)
        Spacer()
      case .systemImage(let name, let color):
        Spacer()
        Image(systemName: name)
          .renderingMode(.template)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .scaledToFit()
          .foregroundColor(color)
          .padding(.bottom)
        Spacer()
      case .image(let name, let color):
        Spacer()
        Image(name)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .scaledToFit()
          .foregroundColor(color)
          .padding(.bottom)
        Spacer()
      case .loading:
        ActivityIndicator(color: style?.activityIndicatorColor ?? .white)
      case .regular:
        EmptyView()
      }

      VStack(spacing: type == .regular ? 8 : 2) {
        if let title = title {
          Text(LocalizedStringKey(title))
            .font(style?.titleFont ?? Font.body.bold())
            .multilineTextAlignment(.center)
            .textColor(style?.titleColor ?? nil)
        }
        if let subTitle = subTitle {
          Text(LocalizedStringKey(subTitle))
            .font(style?.subTitleFont ?? Font.footnote)
            .opacity(0.7)
            .multilineTextAlignment(.center)
            .textColor(style?.subtitleColor ?? nil)
        }
      }
    }
    .padding()
    .withFrame(type != .regular && type != .loading)
    .alertBackground(style?.backgroundColor ?? nil)
    .cornerRadius(10)
  }

  /// Body init determine by `displayMode`
  public var body: some View {
    switch displayMode {
    case .alert:
      alert
    case .hud:
      hud
    case .banner:
      banner
    }
  }
}
