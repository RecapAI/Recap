//
//  RecapView.swift
//  Recap
//
//  Created by Rawand Ahmad on 25/07/2025.
//

import SwiftUI

struct RecapHomeView: View {
  @ObservedObject private var viewModel: RecapViewModel

  init(viewModel: RecapViewModel) {
    self.viewModel = viewModel
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        UIConstants.Gradients.backgroundGradient
          .ignoresSafeArea()

        ScrollView(.vertical, showsIndicators: false) {
          VStack(spacing: UIConstants.Spacing.sectionSpacing) {
            HStack {
              Text("Recap")
                .foregroundColor(UIConstants.Colors.textPrimary)
                .font(UIConstants.Typography.appTitle)
                .padding(.leading, UIConstants.Spacing.contentPadding)
                .padding(.top, UIConstants.Spacing.sectionSpacing)

              Spacer()

              Button {
                viewModel.closePanel()
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(UIConstants.Colors.textSecondary)
                  .font(.title2)
              }
              .buttonStyle(PlainButtonStyle())
              .padding(.trailing, UIConstants.Spacing.contentPadding)
              .padding(.top, UIConstants.Spacing.sectionSpacing)
            }

            ForEach(viewModel.activeWarnings, id: \.id) { warning in
              WarningCard(warning: warning, containerWidth: geometry.size.width)
                .padding(.horizontal, UIConstants.Spacing.contentPadding)
            }

            VStack(spacing: UIConstants.Spacing.cardSpacing) {
              TranscriptionCard(containerWidth: geometry.size.width) {
                viewModel.openView()
              }

              HStack(spacing: UIConstants.Spacing.cardSpacing) {
                InformationCard(
                  icon: "list.bullet.indent",
                  title: "Previous Recaps",
                  description: "View past recordings",
                  containerWidth: geometry.size.width
                )
                .onTapGesture {
                  viewModel.openPreviousRecaps()
                }

                InformationCard(
                  icon: "gear",
                  title: "Settings",
                  description: "App preferences",
                  containerWidth: geometry.size.width
                )
                .onTapGesture {
                  viewModel.openSettings()
                }
              }
            }

            Spacer(minLength: UIConstants.Spacing.sectionSpacing)
          }
        }
      }
    }
    .toast(isPresenting: $viewModel.showErrorToast) {
      AlertToast(
        displayMode: .banner(.slide),
        type: .error(.red),
        title: "Recording Error",
        subTitle: viewModel.errorMessage
      )
    }
  }
}

#Preview {
  let viewModel = RecapViewModel.createForPreview()

  return RecapHomeView(viewModel: viewModel)
    .frame(width: 500, height: 500)
}
