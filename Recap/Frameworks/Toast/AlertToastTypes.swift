import SwiftUI

@available(iOS 14, macOS 11, *)
extension AlertToast {
  public enum BannerAnimation {
    case slide, pop
  }

  public enum DisplayMode: Equatable {
    case alert
    case hud
    case banner(_ transition: BannerAnimation)
  }

  public enum AlertType: Equatable {
    case complete(_ color: Color)
    case error(_ color: Color)
    case systemImage(_ name: String, _ color: Color)
    case image(_ name: String, _ color: Color)
    case loading
    case regular
  }

  public enum AlertStyle: Equatable {
    case style(
      backgroundColor: Color? = nil,
      titleColor: Color? = nil,
      subTitleColor: Color? = nil,
      titleFont: Font? = nil,
      subTitleFont: Font? = nil,
      activityIndicatorColor: Color? = nil)

    var backgroundColor: Color? {
      switch self {
      case .style(backgroundColor: let color, _, _, _, _, _):
        return color
      }
    }

    var titleColor: Color? {
      switch self {
      case .style(_, let color, _, _, _, _):
        return color
      }
    }

    var subtitleColor: Color? {
      switch self {
      case .style(_, _, let color, _, _, _):
        return color
      }
    }

    var titleFont: Font? {
      switch self {
      case .style(_, _, _, titleFont: let font, _, _):
        return font
      }
    }

    var subTitleFont: Font? {
      switch self {
      case .style(_, _, _, _, subTitleFont: let font, _):
        return font
      }
    }

    var activityIndicatorColor: Color? {
      switch self {
      case .style(_, _, _, _, _, let color):
        return color
      }
    }
  }
}
