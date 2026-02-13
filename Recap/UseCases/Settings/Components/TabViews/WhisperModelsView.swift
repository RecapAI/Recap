import SwiftUI

struct WhisperModelsView: View {
  @ObservedObject var viewModel: WhisperModelsViewModel

  var body: some View {
    GeometryReader { geometry in
      let mainCardBackground = LinearGradient(
        gradient: Gradient(stops: [
          .init(color: Color(hex: "232222").opacity(0.2), location: 0),
          .init(color: Color(hex: "0F0F0F").opacity(0.3), location: 1)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )

      let mainCardBorder = LinearGradient(
        gradient: Gradient(stops: [
          .init(color: Color(hex: "979797").opacity(0.1), location: 0),
          .init(color: Color(hex: "C4C4C4").opacity(0.2), location: 1)
        ]),
        startPoint: .top,
        endPoint: .bottom
      )

      RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius)
        .fill(mainCardBackground)
        .frame(width: geometry.size.width - 40)
        .overlay(
          RoundedRectangle(cornerRadius: UIConstants.Sizing.cornerRadius)
            .stroke(mainCardBorder, lineWidth: UIConstants.Sizing.borderWidth)
        )
        .overlay(
          VStack(alignment: .leading, spacing: UIConstants.Spacing.sectionSpacing) {
            HStack {
              Text("Models")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(UIConstants.Colors.textPrimary)
              Spacer()
            }
            .padding(.top, 14)
            .padding(.horizontal, 14)

            ScrollView {
              VStack(alignment: .leading, spacing: 16) {
                modelSection(
                  title: "Recommended Models",
                  models: viewModel.recommendedModels
                )

                modelSection(
                  title: "Other Models",
                  models: viewModel.otherModels
                )
              }
              .padding(.horizontal, 20)
            }
            .padding(.bottom, 8)
          }
        )
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        .overlay(
          Group {
            if let tooltipModel = viewModel.showingTooltipForModel,
              let modelInfo = viewModel.getModelInfo(tooltipModel) {
              VStack(alignment: .leading, spacing: 2) {
                Text(modelInfo.displayName)
                  .font(.system(size: 10, weight: .semibold))
                  .foregroundColor(.white)
                Text("Size: \(modelInfo.parameters) parameters")
                  .font(.system(size: 9))
                  .foregroundColor(.white)
                Text("VRAM: \(modelInfo.vram)")
                  .font(.system(size: 9))
                  .foregroundColor(.white)
                Text("Speed: \(modelInfo.relativeSpeed)")
                  .font(.system(size: 9))
                  .foregroundColor(.white)
              }
              .padding(8)
              .background(
                RoundedRectangle(cornerRadius: 6)
                  .fill(Color.black.opacity(0.95))
                  .shadow(radius: 4)
              )
              .position(
                x: viewModel.tooltipPosition.x + 60,
                y: viewModel.tooltipPosition.y - 40)
            }
          }
        )
    }
  }

  private func modelSection(title: String, models: [String]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.system(size: 10, weight: .semibold))
        .foregroundColor(UIConstants.Colors.textSecondary)

      VStack(spacing: 4) {
        ForEach(models, id: \.self) { model in
          ModelRowView(
            modelName: model,
            displayName: viewModel.modelDisplayName(model),
            isSelected: viewModel.selectedModel == model,
            isDownloaded: viewModel.downloadedModels.contains(model),
            isDownloading: viewModel.downloadingModels.contains(model),
            downloadProgress: viewModel.downloadProgress[model] ?? 0.0,
            showingTooltip: viewModel.showingTooltipForModel == model,
            onSelect: {
              withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectModel(model)
              }
            },
            onDownload: {
              viewModel.downloadModel(model)
            },
            onTooltipToggle: { position in
              withAnimation {
                viewModel.toggleTooltip(for: model, at: position)
              }
            }
          )
        }
      }
    }
  }
}

struct ModelRowView: View {
  let modelName: String
  let displayName: String
  let isSelected: Bool
  let isDownloaded: Bool
  let isDownloading: Bool
  let downloadProgress: Double
  let showingTooltip: Bool
  let onSelect: () -> Void
  let onDownload: () -> Void
  let onTooltipToggle: (CGPoint) -> Void

  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color(hex: "2A2A2A").opacity(0.2))
      .frame(height: 30)
      .frame(maxHeight: 40)
      .overlay(
        HStack(spacing: 12) {
          RoundedRectangle(cornerRadius: 4)
            .fill(Color(hex: "2A2A2A"))
            .frame(width: 16, height: 16)
            .overlay(
              Image(systemName: "cpu")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(UIConstants.Colors.textPrimary)
            )

          HStack(spacing: 6) {
            Text(displayName)
              .font(.system(size: 10, weight: .semibold))
              .foregroundColor(UIConstants.Colors.textPrimary)

            GeometryReader { geometry in
              Button {
                let frame = geometry.frame(in: .global)
                let buttonCenter = CGPoint(
                  x: frame.midX + 25,
                  y: frame.midY - 75
                )
                onTooltipToggle(buttonCenter)
              } label: {
                Image(systemName: "questionmark.circle")
                  .font(.system(size: 12, weight: .medium))
                  .foregroundColor(UIConstants.Colors.textSecondary)
              }
              .buttonStyle(PlainButtonStyle())
            }
            .frame(width: 12, height: 12)
          }

          Spacer()

          if !isDownloaded {
            DownloadPillButton(
              text: isDownloading ? "Downloading" : "Download",
              isDownloading: isDownloading,
              downloadProgress: downloadProgress,
              action: onDownload
            )
          }

          if isDownloaded {
            Circle()
              .stroke(
                UIConstants.Colors.selectionStroke,
                lineWidth: UIConstants.Sizing.strokeWidth
              )
              .frame(
                width: UIConstants.Sizing.selectionCircleSize,
                height: UIConstants.Sizing.selectionCircleSize
              )
              .overlay {
                if isSelected {
                  Image(systemName: "checkmark")
                    .font(UIConstants.Typography.iconFont)
                    .foregroundColor(UIConstants.Colors.textPrimary)
                }
              }
          }
        }
        .padding(.horizontal, 12)
      )
      .contentShape(Rectangle())
      .onTapGesture {
        if isDownloaded {
          onSelect()
        }
      }
  }

}
