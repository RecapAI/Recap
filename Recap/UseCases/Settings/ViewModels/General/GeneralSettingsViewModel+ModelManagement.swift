import Foundation

@MainActor
extension GeneralSettingsViewModel {
  func loadModels() async {
    isLoading = true
    errorMessage = nil

    do {
      availableModels = try await llmService.getAvailableModels()
      selectedModel = try await llmService.getSelectedModel()

      if selectedModel == nil, let firstModel = availableModels.first {
        await selectModel(firstModel)
      }
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func selectModel(_ model: LLMModelInfo) async {
    errorMessage = nil
    selectedModel = model

    do {
      try await llmService.selectModel(id: model.id)
    } catch {
      errorMessage = error.localizedDescription
      selectedModel = nil
    }
  }

  func selectManualModel(_ modelName: String) async {
    guard !modelName.isEmpty else {
      return
    }

    errorMessage = nil
    manualModelNameValue = modelName

    let manualModel = LLMModelInfo(name: modelName, provider: selectedProvider.rawValue)
    selectedModel = manualModel

    do {
      try await llmService.selectModel(id: manualModel.id)
    } catch {
      errorMessage = error.localizedDescription
      selectedModel = nil
    }
  }

  func updateModelsForNewProvider() async {
    do {
      let newModels = try await llmService.getAvailableModels()
      availableModels = newModels

      let currentSelection = try await llmService.getSelectedModel()
      let isCurrentModelAvailable = newModels.contains { $0.id == currentSelection?.id }

      if !isCurrentModelAvailable, let firstModel = newModels.first {
        await selectModel(firstModel)
      } else {
        selectedModel = currentSelection
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
