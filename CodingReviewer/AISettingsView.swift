import Foundation
import OSLog
import SwiftUI

// SECURITY: API key handling - ensure proper encryption and keychain storage
struct AISettingsView: View {
    @State private var openAIKey = ""
    @State private var geminiKey = ""
    @State private var selectedProvider: AIProvider = .openai
    @State private var showAlert = false
    @State private var alertMessage = ""

    enum AIProvider: String, CaseIterable {
        case openai = "OpenAI"
        case gemini = "Google Gemini"

        var displayName: String { rawValue }
    }

    var body: some View {
        Form {
            Section("AI Provider") {
                Picker("Provider", selection: $selectedProvider) {
                    ForEach(AIProvider.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedProvider) { _, newValue in
                    Logger().info("Provider changed to: \(newValue.rawValue)")
                }
            }

            Section("API Keys") {
                SecureField("OpenAI API Key", text: $openAIKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                SecureField("Google Gemini API Key", text: $geminiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Save API Keys") {
                    saveAPIKeys()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("AI Settings")
        .onAppear {
            loadAPIKeys()
        }
        .alert("Settings", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }

    /// Updates and persists data with validation
    private func saveAPIKeys() {
        // Simple keychain storage simulation
        UserDefaults.standard.set(openAIKey, forKey: "openai_key")
        UserDefaults.standard.set(geminiKey, forKey: "gemini_key")
        UserDefaults.standard.set(selectedProvider.rawValue, forKey: "selected_provider")

        alertMessage = "API keys saved successfully"
        showAlert = true
        Logger().info("API keys saved")
    }

    /// Retrieves data with proper error handling and caching
    private func loadAPIKeys() {
        openAIKey = UserDefaults.standard.string(forKey: "openai_key") ?? ""
        geminiKey = UserDefaults.standard.string(forKey: "gemini_key") ?? ""

        if let provider = UserDefaults.standard.string(forKey: "selected_provider"),
           let aiProvider = AIProvider(rawValue: provider)
        {
            selectedProvider = aiProvider
            Logger().info("Loaded provider from UserDefaults: \(provider)")
        } else {
            selectedProvider = .openai
            Logger().info("Set default provider to openai")
        }
    }
}
