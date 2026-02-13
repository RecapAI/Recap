import Foundation

struct ProviderStatus {
  let name: String
  let isAvailable: Bool
  let statusMessage: String

  static func ollama(isAvailable: Bool) -> ProviderStatus {
    ProviderStatus(
      name: "Ollama",
      isAvailable: isAvailable,
      statusMessage: isAvailable
        ? "Connected to Ollama at localhost:11434"
        : "Ollama not detected. Please install and run Ollama from https://ollama.ai"
    )
  }
}
