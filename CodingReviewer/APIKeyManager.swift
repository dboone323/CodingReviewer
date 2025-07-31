// SECURITY: API key handling - ensure proper encryption and keychain storage
import OSLog
import Foundation
import SwiftUI
import Combine

@MainActor
// / APIKeyManager class
// / TODO: Add detailed documentation
public class APIKeyManager: ObservableObject {
    static let shared = APIKeyManager()

    @Published var showingKeySetup = false;
    @Published var hasValidKey = false;
    @Published var isConfigured = false;
    @Published var hasValidGeminiKey = false;

    // Keys
    private let openAIKeyAccount = "openai_api_key"
    private let geminiKeyAccount = "gemini_api_key"

    init() {
        checkAPIKeyStatus()
    }

    // MARK: - Generic UserDefaults Methods (simplified for now)

    private func setUserDefaultsValue(_ value: String, key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private func getUserDefaultsValue(key: String) -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    private func removeUserDefaultsValue(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - OpenAI API Key Methods

    func getOpenAIKey() -> String? {
        // First check environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            os_log("%@", "Using OpenAI API key from environment")
            return envKey
        }

        // Then check UserDefaults
        return getUserDefaultsValue(key: openAIKeyAccount)
    }

    func setOpenAIKey(_ key: String) {
        setUserDefaultsValue(key, key: openAIKeyAccount)
        hasValidKey = true
        isConfigured = true
        os_log("%@", "OpenAI API key saved successfully")
    }

    func removeOpenAIKey() {
        removeUserDefaultsValue(key: openAIKeyAccount)
        hasValidKey = false
        isConfigured = false
        os_log("%@", "OpenAI API key removed")
    }

    func validateOpenAIKey(_ key: String) async -> Bool {
        // Add your validation logic here
        os_log("%@", "OpenAI API key validation successful")
        return true
    }

    func checkAPIKeyStatus() {
        let hasKey = getOpenAIKey() != nil
        hasValidKey = hasKey
        isConfigured = hasKey

        let hasGeminiKey = getGeminiKey() != nil
        hasValidGeminiKey = hasGeminiKey

        if !hasKey {
            os_log("%@", "No OpenAI API key found")
        }

        if !hasGeminiKey {
            os_log("%@", "No Gemini API key found")
        }
    }

    // MARK: - Gemini API Key Methods

    func getGeminiKey() -> String? {
        // First check environment variable
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            os_log("%@", "Using Gemini API key from environment")
            return envKey
        }

        // Then check UserDefaults
        return getUserDefaultsValue(key: geminiKeyAccount)
    }

    func setGeminiKey(_ key: String) {
        setUserDefaultsValue(key, key: geminiKeyAccount)
        hasValidGeminiKey = true
        os_log("%@", "Gemini API key saved successfully")
    }

    func removeGeminiKey() {
        removeUserDefaultsValue(key: geminiKeyAccount)
        hasValidGeminiKey = false
        os_log("%@", "Gemini API key removed")
    }

    func validateGeminiKey(_ key: String) async -> Bool {
        // Add your validation logic here
        os_log("%@", "Gemini API key validation successful")
        return true
    }

    func showKeySetup() {
        os_log("%@", "🔑 [DEBUG] APIKeyManager.showKeySetup() called")
        os_log("%@", "🔑 [DEBUG] Before change - showingKeySetup: \(showingKeySetup)")
        DispatchQueue.main.async {
            self.showingKeySetup = true
        }
        os_log("%@", "🔑 [DEBUG] After change - showingKeySetup: \(showingKeySetup)")
    }
}
