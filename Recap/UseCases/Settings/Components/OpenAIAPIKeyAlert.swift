import SwiftUI

struct OpenAIAPIKeyAlert: View {
    @Binding var isPresented: Bool
    @State private var apiKey: String = ""
    @State private var endpoint: String = "https://api.openai.com/v1"
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    let existingKey: String?
    let existingEndpoint: String?
    let onSave: (String, String) async throws -> Void

    private var isUpdateMode: Bool {
        existingKey != nil
    }

    private var title: String {
        isUpdateMode ? "Update OpenAI Configuration" : "Add OpenAI Configuration"
    }

    private var buttonTitle: String {
        isUpdateMode ? "Update" : "Save"
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
                                await saveConfiguration()
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
            if let existingEndpoint = existingEndpoint {
                endpoint = existingEndpoint
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            CustomTextField(
                label: "API Endpoint",
                placeholder: "https://api.openai.com/v1",
                text: $endpoint
            )

            Text(
                "For Azure OpenAI, use: https://YOUR-RESOURCE.openai.azure.com/openai/deployments/YOUR-DEPLOYMENT"
            )
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(UIConstants.Colors.textSecondary)
            .multilineTextAlignment(.leading)
            .lineLimit(3)

            CustomPasswordField(
                label: "API Key",
                placeholder: "sk-...",
                text: $apiKey
            )

            HStack {
                Text(
                    "Your credentials are stored securely in the system keychain and never leave your device."
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

    private func saveConfiguration() async {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKey.isEmpty else {
            errorMessage = "Please enter an API key"
            return
        }

        guard !trimmedEndpoint.isEmpty else {
            errorMessage = "Please enter an API endpoint"
            return
        }

        guard let url = URL(string: trimmedEndpoint), url.scheme != nil else {
            errorMessage = "Invalid endpoint URL format"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await onSave(trimmedKey, trimmedEndpoint)
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
        OpenAIAPIKeyAlert(
            isPresented: .constant(true),
            existingKey: nil,
            existingEndpoint: nil,
            onSave: { _, _ in
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        )
        .frame(height: 400)
    )
    .background(Color.black)
}
