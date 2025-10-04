//
//  AppSelectionButton.swift
//  Recap
//
//  Created by Rawand Ahmad on 25/07/2025.
//

import SwiftUI

struct AppSelectionButton: View {
  @ObservedObject private var viewModel: AppSelectionViewModel
  @StateObject private var dropdownManager = DropdownWindowManager()
  @State private var buttonView: NSView?

  init(viewModel: AppSelectionViewModel) {
    self.viewModel = viewModel
  }

  var body: some View {
    Button {
      if viewModel.state.isShowingDropdown {
        dropdownManager.hideDropdown()
        viewModel.toggleDropdown()
      } else {
        viewModel.toggleDropdown()
        showDropdownWindow()
      }
    } label: {
      buttonContent
    }
    .buttonStyle(PlainButtonStyle())
    .background(
      ViewGeometryReader { view in
        buttonView = view
      }
    )
    .onReceive(viewModel.$state) { state in
      if !state.isShowingDropdown {
        dropdownManager.hideDropdown()
      }
    }
  }

  private func showDropdownWindow() {
    guard let buttonView = buttonView else { return }

    dropdownManager.showDropdown(
      relativeTo: buttonView,
      viewModel: viewModel,
      onAppSelected: { app in
        withAnimation(.easeInOut(duration: 0.2)) {
          viewModel.selectApp(app)
        }
      },
      onClearSelection: {
        withAnimation(.easeInOut(duration: 0.2)) {
          viewModel.clearSelection()
        }
      },
      onDismiss: {
        withAnimation(.easeInOut(duration: 0.2)) {
          viewModel.toggleDropdown()
        }
      }
    )
  }

  private var buttonContent: some View {
    HStack(spacing: UIConstants.Spacing.gridCellSpacing * 2) {
      Image(systemName: viewModel.state.isShowingDropdown ? "chevron.up" : "chevron.down")
        .font(UIConstants.Typography.iconFont)
        .foregroundColor(UIConstants.Colors.textPrimary)

      if let selectedApp = viewModel.state.selectedApp {
        selectedAppIcon(selectedApp)
        selectedAppText(selectedApp)
      } else {
        defaultIcon
        defaultText
      }
    }
    .padding(.horizontal, UIConstants.Spacing.cardPadding)
    .padding(.vertical, UIConstants.Spacing.cardPadding)
    .background(
      RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius)
        .stroke(
          LinearGradient(
            gradient: Gradient(stops: [
              .init(color: Color(hex: "979797").opacity(0.3), location: 0),
              .init(color: Color(hex: "979797").opacity(0.2), location: 1)
            ]),
            startPoint: .top,
            endPoint: .bottom
          ),
          lineWidth: UIConstants.Sizing.strokeWidth
        )
    )
  }

  private func selectedAppIcon(_ app: SelectableApp) -> some View {
    RoundedRectangle(cornerRadius: UIConstants.Sizing.smallCornerRadius * 2)
      .fill(Color.white)
      .frame(width: 15, height: 15)
      .overlay(
        Image(nsImage: app.icon)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 12, height: 12)
      )
  }

  private func selectedAppText(_ app: SelectableApp) -> some View {
    Text(app.name)
      .font(UIConstants.Typography.cardTitle)
      .foregroundColor(UIConstants.Colors.textPrimary)
      .lineLimit(1)
  }

  private var defaultIcon: some View {
    RoundedRectangle(cornerRadius: UIConstants.Sizing.smallCornerRadius * 2)
      .fill(UIConstants.Colors.textTertiary.opacity(0.3))
      .frame(width: 15, height: 15)
      .overlay(
        Image(systemName: "app")
          .font(UIConstants.Typography.iconFont)
          .foregroundColor(UIConstants.Colors.textTertiary)
      )
  }

  private var defaultText: some View {
    Text("Select App")
      .font(UIConstants.Typography.cardTitle)
      .foregroundColor(UIConstants.Colors.textSecondary)
  }
}

#Preview {
  let controller = AudioProcessController()
  let viewModel = AppSelectionViewModel(audioProcessController: controller)

  return AppSelectionButton(viewModel: viewModel)
    .padding()
    .background(Color.black)
}
