import SwiftUI
import UniformTypeIdentifiers

struct DragDropView<ViewModel: DragDropViewModelType>: View {
  @ObservedObject var viewModel: ViewModel
  let onClose: () -> Void

  @State private var isDragging = false

  var body: some View {
    GeometryReader { _ in
      ZStack {
        UIConstants.Gradients.backgroundGradient
          .ignoresSafeArea()

        VStack(spacing: UIConstants.Spacing.sectionSpacing) {
          // Header with close button
          HStack {
            Text("Drag & Drop")
              .foregroundColor(UIConstants.Colors.textPrimary)
              .font(UIConstants.Typography.appTitle)
              .padding(.leading, UIConstants.Spacing.contentPadding)
              .padding(.top, UIConstants.Spacing.sectionSpacing)

            Spacer()

            Text("Close")
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(.white)
              .padding(.horizontal, 12)
              .padding(.vertical, 10)
              .background(
                RoundedRectangle(cornerRadius: 20)
                  .fill(Color(hex: "242323"))
                  .overlay(
                    RoundedRectangle(cornerRadius: 20)
                      .stroke(
                        LinearGradient(
                          gradient: Gradient(stops: [
                            .init(
                              color: Color(hex: "979797").opacity(
                                0.6), location: 0),
                            .init(
                              color: Color(hex: "979797").opacity(
                                0.4), location: 1)
                          ]),
                          startPoint: .top,
                          endPoint: .bottom
                        ),
                        lineWidth: 0.8
                      )
                  )
                  .opacity(0.6)
              )
              .onTapGesture {
                onClose()
              }
              .padding(.trailing, UIConstants.Spacing.contentPadding)
              .padding(.top, UIConstants.Spacing.sectionSpacing)
          }

          // Checkboxes
          HStack(spacing: 16) {
            Toggle(isOn: $viewModel.transcriptEnabled) {
              Text("Transcript")
                .foregroundColor(UIConstants.Colors.textPrimary)
                .font(.system(size: 14, weight: .medium))
            }
            .toggleStyle(.checkbox)

            Toggle(isOn: $viewModel.summarizeEnabled) {
              Text("Summarize")
                .foregroundColor(UIConstants.Colors.textPrimary)
                .font(.system(size: 14, weight: .medium))
            }
            .toggleStyle(.checkbox)

            Spacer()
          }
          .padding(.horizontal, UIConstants.Spacing.contentPadding)
          .disabled(viewModel.isProcessing)

          // Drop zone
          ZStack {
            RoundedRectangle(cornerRadius: 12)
              .stroke(
                isDragging ? Color.blue : Color.gray.opacity(0.5),
                style: StrokeStyle(lineWidth: 2, dash: [10, 5])
              )
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(
                    isDragging
                      ? Color.blue.opacity(0.1)
                      : Color.black.opacity(0.2)
                  )
              )

            VStack(spacing: 16) {
              Image(systemName: isDragging ? "arrow.down.circle.fill" : "waveform.circle")
                .font(.system(size: 48))
                .foregroundColor(isDragging ? .blue : .gray)

              if viewModel.isProcessing {
                ProgressView()
                  .scaleEffect(1.2)
                  .padding(.bottom, 8)

                Text("Processing...")
                  .foregroundColor(UIConstants.Colors.textSecondary)
                  .font(.system(size: 14, weight: .medium))
              } else {
                Text(isDragging ? "Drop here" : "Drop audio file here")
                  .foregroundColor(UIConstants.Colors.textPrimary)
                  .font(.system(size: 16, weight: .semibold))

                Text("Supported formats: wav, mp3, m4a, flac")
                  .foregroundColor(UIConstants.Colors.textSecondary)
                  .font(.system(size: 12))
              }
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(.horizontal, UIConstants.Spacing.contentPadding)
          .padding(.bottom, UIConstants.Spacing.sectionSpacing)
          .onDrop(
            of: [.fileURL],
            isTargeted: $isDragging
          ) { providers in
            handleDrop(providers: providers)
          }

          // Messages
          if let error = viewModel.errorMessage {
            Text(error)
              .foregroundColor(.red)
              .font(.system(size: 12))
              .padding(.horizontal, UIConstants.Spacing.contentPadding)
              .padding(.bottom, 8)
              .multilineTextAlignment(.center)
          }

          if let success = viewModel.successMessage {
            Text(success)
              .foregroundColor(.green)
              .font(.system(size: 12))
              .padding(.horizontal, UIConstants.Spacing.contentPadding)
              .padding(.bottom, 8)
              .multilineTextAlignment(.center)
              .lineLimit(3)
          }
        }
      }
    }
  }

  private func handleDrop(providers: [NSItemProvider]) -> Bool {
    guard let provider = providers.first else { return false }

    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) {
      item, _ in
      guard let data = item as? Data,
        let url = URL(dataRepresentation: data, relativeTo: nil)
      else { return }

      Task { @MainActor in
        await viewModel.handleDroppedFile(url: url)
      }
    }

    return true
  }
}
