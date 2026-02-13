import SwiftUI

struct AppSelectionDropdown: View {
  @ObservedObject private var viewModel: AppSelectionViewModel
  let onAppSelected: (SelectableApp) -> Void
  let onClearSelection: () -> Void

  init(
    viewModel: AppSelectionViewModel,
    onAppSelected: @escaping (SelectableApp) -> Void,
    onClearSelection: @escaping () -> Void
  ) {
    self.viewModel = viewModel
    self.onAppSelected = onAppSelected
    self.onClearSelection = onClearSelection
  }

  var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      contentView
    }
    .frame(width: 280, height: 400)
    .clipped()
    .background(
      RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius * 0.6)
        .fill(UIConstants.Gradients.dropdownBackground)
    )
    .overlay(
      RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius * 0.6)
        .stroke(UIConstants.Gradients.standardBorder, lineWidth: UIConstants.Sizing.strokeWidth)
    )
  }

  private var contentView: some View {
    VStack(alignment: .leading, spacing: 0) {
      dropdownHeader

      systemWideRow

      if !viewModel.meetingApps.isEmpty || !viewModel.otherApps.isEmpty {
        sectionDivider
      }

      if !viewModel.meetingApps.isEmpty {
        sectionHeader("Meeting Apps")
        ForEach(viewModel.meetingApps) { app in
          appRow(app)
        }

        if !viewModel.otherApps.isEmpty {
          sectionDivider
        }
      }

      if !viewModel.otherApps.isEmpty {
        sectionHeader("Other Apps")
        ForEach(viewModel.otherApps) { app in
          appRow(app)
        }
      }

      if !viewModel.meetingApps.isEmpty || !viewModel.otherApps.isEmpty {
        sectionDivider
        clearSelectionRow
      }
    }
    .padding(.vertical, UIConstants.Spacing.cardInternalSpacing)
  }

  private var dropdownHeader: some View {
    HStack {
      Text("Select App")
        .font(UIConstants.Typography.cardTitle)
        .foregroundColor(UIConstants.Colors.textPrimary)

      Spacer()

      Button {
        viewModel.toggleAudioFilter()
      } label: {
        Image(systemName: "waveform")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(
            viewModel.isAudioFilterEnabled ? .white : UIConstants.Colors.textTertiary
          )
          .frame(width: 24, height: 24)
          .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .padding(8)
      .background(
        RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius * 0.4)
          .fill(
            viewModel.isAudioFilterEnabled
              ? UIConstants.Colors.textTertiary.opacity(0.2) : Color.clear
          )
          .contentShape(Rectangle())
      )
      .onHover { isHovered in
        if isHovered {
          NSCursor.pointingHand.push()
        } else {
          NSCursor.pop()
        }
      }
    }
    .padding(.horizontal, UIConstants.Spacing.cardPadding)
    .padding(.top, UIConstants.Spacing.cardInternalSpacing)
  }

  private func sectionHeader(_ title: String) -> some View {
    Text(title)
      .font(UIConstants.Typography.bodyText)
      .foregroundColor(UIConstants.Colors.textTertiary)
      .padding(.horizontal, UIConstants.Spacing.cardPadding)
      .padding(.vertical, UIConstants.Spacing.cardInternalSpacing)
  }

  private func appRow(_ app: SelectableApp) -> some View {
    Button {
      onAppSelected(app)
    } label: {
      HStack(spacing: 8) {
        Image(nsImage: app.icon)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 14, height: 14)

        Text(app.name)
          .font(UIConstants.Typography.bodyText)
          .foregroundColor(UIConstants.Colors.textPrimary)
          .lineLimit(1)

        Spacer(minLength: 0)

        if app.isAudioActive {
          Circle()
            .fill(UIConstants.Colors.audioGreen)
            .frame(width: 5, height: 5)
        }
      }
      .padding(.horizontal, UIConstants.Spacing.cardPadding)
      .padding(.vertical, UIConstants.Spacing.gridCellSpacing * 2)
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .background(
      RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius * 0.3)
        .fill(Color.clear)
        .onHover { isHovered in
          if isHovered {
            NSCursor.pointingHand.push()
          } else {
            NSCursor.pop()
          }
        }
    )
  }

  private var sectionDivider: some View {
    Rectangle()
      .fill(UIConstants.Colors.textTertiary.opacity(0.1))
      .frame(height: 1)
      .padding(.horizontal, UIConstants.Spacing.cardPadding)
      .padding(.vertical, UIConstants.Spacing.gridSpacing)
  }

  private var systemWideRow: some View {
    Button {
      onAppSelected(SelectableApp.allApps)
    } label: {
      HStack(spacing: 8) {
        Image(nsImage: SelectableApp.allApps.icon)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 14, height: 14)

        Text("All Apps")
          .font(UIConstants.Typography.bodyText)
          .foregroundColor(UIConstants.Colors.textPrimary)
          .lineLimit(1)

        Spacer(minLength: 0)

        Circle()
          .fill(UIConstants.Colors.audioGreen)
          .frame(width: 5, height: 5)
      }
      .padding(.horizontal, UIConstants.Spacing.cardPadding)
      .padding(.vertical, UIConstants.Spacing.gridCellSpacing * 2)
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .background(
      RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius * 0.3)
        .fill(Color.clear)
        .onHover { isHovered in
          if isHovered {
            NSCursor.pointingHand.push()
          } else {
            NSCursor.pop()
          }
        }
    )
  }

  private var clearSelectionRow: some View {
    Button {
      onClearSelection()
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "xmark.circle")
          .font(UIConstants.Typography.iconFont)
          .foregroundColor(UIConstants.Colors.textSecondary)

        Text("Clear Selection")
          .font(UIConstants.Typography.bodyText)
          .foregroundColor(UIConstants.Colors.textSecondary)

        Spacer(minLength: 0)
      }
      .padding(.horizontal, UIConstants.Spacing.cardPadding)
      .padding(.vertical, UIConstants.Spacing.gridCellSpacing * 2)
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .background(
      RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius * 0.3)
        .fill(Color.clear)
    )
  }
}

// #Preview {
//    AppSelectionDropdown(
//        meetingApps: [
//            SelectableApp(
//                id: "zoom",
//                name: "Zoom",
//                bundleId: "us.zoom.xos",
//                icon: NSWorkspace.shared.icon(forFileType: "app"),
//                isAudioActive: true
//            ),
//            SelectableApp(
//                id: "teams",
//                name: "Microsoft Teams",
//                bundleId: "com.microsoft.teams2",
//                icon: NSWorkspace.shared.icon(forFileType: "app"),
//                isAudioActive: false
//            ),
//            SelectableApp(
//                id: "webex",
//                name: "Cisco Webex Meetings",
//                bundleId: "com.cisco.webexmeetingsapp",
//                icon: NSWorkspace.shared.icon(forFileType: "app"),
//                isAudioActive: true
//            )
//        ],
//        otherApps: [
//            SelectableApp(
//                id: "spotify",
//                name: "Spotify",
//                bundleId: "com.spotify.client",
//                icon: NSWorkspace.shared.icon(forFileType: "app"),
//                isAudioActive: true
//            ),
//            SelectableApp(
//                id: "safari",
//                name: "Safari",
//                bundleId: "com.apple.Safari",
//                icon: NSWorkspace.shared.icon(forFileType: "app"),
//                isAudioActive: false
//            ),
//            SelectableApp(
//                id: "chrome",
//                name: "Google Chrome",
//                bundleId: "com.google.Chrome",
//                icon: NSWorkspace.shared.icon(forFileType: "app"),
//                isAudioActive: true
//            ),
//            SelectableApp(
//                id: "firefox",
//                name: "Firefox",
//                bundleId: "org.mozilla.firefox",
//                icon: NSWorkspace.shared.icon(forFileType: "app"),
//                isAudioActive: false
//            ),
//            SelectableApp(
//                id: "notes",
//                name: "Notes",
//                bundleId: "com.apple.Notes",
//                icon: NSWorkspace.shared.icon(forFileType: "app"),
//                isAudioActive: false
//            ),
//            SelectableApp(
//                id: "finder",
//                name: "Finder",
//                bundleId: "com.apple.finder",
//                icon: NSWorkspace.shared.icon(forFileType: "app"),
//                isAudioActive: false
//            )
//        ],
//        onAppSelected: { _ in },
//        onClearSelection: { }
//    )
//    .frame(width: 300, height: 450)
// }
