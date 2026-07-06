import Foundation
import Combine
import SwiftUI

@MainActor
protocol GeneralSettingsViewModelType: ObservableObject {
    var availableModels: [LLMModelInfo] { get }
    var selectedModel: LLMModelInfo? { get }
    var selectedProvider: LLMProvider { get }
    var autoDetectMeetings: Bool { get }
    var isAutoStopRecording: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var hasModels: Bool { get }
    var currentSelection: LLMModelInfo? { get }
    var showToast: Bool { get }
    var toastMessage: String { get }
    var activeWarnings: [WarningItem] { get }
    var customPromptTemplate: Binding<String> { get }
    var showAPIKeyAlert: Bool { get }
    var existingAPIKey: String? { get }
    var pendingAPIKeyProvider: LLMProvider? { get }
    
    func loadModels() async
    func selectModel(_ model: LLMModelInfo) async
    func selectProvider(_ provider: LLMProvider) async
    func toggleAutoDetectMeetings(_ enabled: Bool) async
    func toggleAutoStopRecording(_ enabled: Bool) async
    func updateCustomPromptTemplate(_ template: String) async
    func resetToDefaultPrompt() async
    func saveAPIKey(_ apiKey: String) async throws
    func dismissAPIKeyAlert()
}
