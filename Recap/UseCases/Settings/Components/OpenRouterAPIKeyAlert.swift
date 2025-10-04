import SwiftUI

struct OpenRouterAPIKeyAlert: View {
    @Binding var isPresented: Bool
    @State private var apiKey: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    let existingKey: String?
    let onSave: (String) async throws -> Void

    private var isUpdateMode: Bool {
        existingKey != nil
    }

    private var title: String {
        isUpdateMode ? "Update OpenRouter API Key" : "Add OpenRouter API Key"
    }

    private var buttonTitle: String {
        isUpdateMode ? "Update Key" : "Save Key"
    }

    var body: some View {
        CenteredAlert(
            isPresented: $isPresented,
            title: title,
            onDismiss: {},
            content: {
                VStack(alignment: .leading, spacing: 20) {
                    inputSection

                    if let errorMessage = errorMessage {
                        errorSection(errorMessage)
                    }

                    HStack {
                        Spacer()

                        PillButton(
                            text: isLoading ? "Saving..." : buttonTitle,
                            icon: isLoading ? nil : "checkmark"
                        ) {
                            Task {
                                await saveAPIKey()
                            }
                        }
                    }
                }
            }
        )
        .onAppear {
            if let existingKey = existingKey {
                apiKey = existingKey
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            CustomPasswordField(
                label: "API Key",
                placeholder: "sk-or-v1-...",
                text: $apiKey
            )

            HStack {
                Text(
                    "Your API key is stored securely in the system keychain and never leaves your device."
                )
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(UIConstants.Colors.textSecondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                Spacer()
            }
        }
    }

    private func errorSection(_ message: String) -> some View {
        HStack {
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.red.opacity(0.3), lineWidth: 0.5)
                )
        )
    }

    private func saveAPIKey() async {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKey.isEmpty else {
            errorMessage = "Please enter an API key"
            return
        }

        guard trimmedKey.hasPrefix("sk-or-") else {
            errorMessage = "Invalid OpenRouter API key format. Key should start with 'sk-or-'"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await onSave(trimmedKey)
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    VStack {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Text("Background Content")
                    .foregroundColor(.white)
            )
    }
    .frame(height: 400)
    .overlay(
        OpenRouterAPIKeyAlert(
            isPresented: .constant(true),
            existingKey: nil,
            onSave: { _ in
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        )
        .frame(height: 300)
    )
    .background(Color.black)
}
