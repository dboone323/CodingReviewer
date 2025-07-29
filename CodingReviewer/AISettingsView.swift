import SwiftUI
import AppLogger

struct AISettingsView: View {
    @State private var openAIKey: String = ""
    @State private var geminiKey: String = ""
    @State private var selectedProvider: AIProvider = .openai
    @State private var showAlert = false
    @State private var alertMessage = ""

    private let keyManager = APIKeyManager()

    enum AIProvider: String, CaseIterable {
        case openai = "OpenAI"
        case gemini = "Google Gemini"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("AI Settings")
                .font(.title2)
                .fontWeight(.bold)

            // Provider Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Provider:")
                    .font(.headline)

                Picker("AI Provider", selection: $selectedProvider) {
                    ForEach(AIProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedProvider) { oldValue, newValue in
                    // Immediately save provider selection when changed
                    let providerString = newValue == .openai ? "openai" : "gemini"
                    UserDefaults.standard.set(providerString, forKey: "selectedAIProvider")
                    AppLogger.shared.debug("Provider changed to: \(providerString)")
                }
            }

            Divider()

            // API Key Input
            VStack(alignment: .leading, spacing: 8) {
                Text("\(selectedProvider.rawValue) API Key:")
                    .font(.headline)

                SecureField("Enter your \(selectedProvider.rawValue) API key", text: selectedProvider == .openai ? $openAIKey : $geminiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("Your API key is stored securely in the keychain")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Save Button
            Button("Save API Key") {
                saveAPIKey()
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedProvider == .openai ? openAIKey.isEmpty : geminiKey.isEmpty)

            Spacer()
        }
        .padding()
        .onAppear {
            loadAPIKeys()
        }
        .alert("Settings", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    private func loadAPIKeys() {
        // Load the selected provider first
        if let provider = UserDefaults.standard.string(forKey: "selectedAIProvider") {
            selectedProvider = provider == "gemini" ? .gemini : .openai
            AppLogger.shared.debug("Loaded provider from UserDefaults: \(provider)")
        } else {
            // Default to OpenAI if no provider is set
            selectedProvider = .openai
            UserDefaults.standard.set("openai", forKey: "selectedAIProvider")
            AppLogger.shared.debug("Set default provider to openai")
        }

        // Load API keys
        if let openAI = keyManager.getOpenAIKey() {
            openAIKey = openAI
        } else if let fallbackOpenAI = UserDefaults.standard.string(forKey: "openai_api_key") {
            openAIKey = fallbackOpenAI
        }

        if let gemini = keyManager.getGeminiKey() {
            geminiKey = gemini
        } else if let fallbackGemini = UserDefaults.standard.string(forKey: "gemini_api_key") {
            geminiKey = fallbackGemini
        }
    }

    private func saveAPIKey() {
        do {
            switch selectedProvider {
            case .openai:
                try keyManager.setOpenAIKey(openAIKey)
                UserDefaults.standard.set("openai", forKey: "selectedAIProvider")
                // Temporarily also save to UserDefaults for FileManagerService access
                UserDefaults.standard.set(openAIKey, forKey: "openai_api_key")
                alertMessage = "OpenAI API key saved successfully!"
            case .gemini:
                try keyManager.setGeminiKey(geminiKey)
                UserDefaults.standard.set("gemini", forKey: "selectedAIProvider")
                // Temporarily also save to UserDefaults for FileManagerService access
                UserDefaults.standard.set(geminiKey, forKey: "gemini_api_key")
                alertMessage = "Gemini API key saved successfully!"
            }
            showAlert = true
        } catch {
            alertMessage = "Failed to save API key: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    AISettingsView()
}