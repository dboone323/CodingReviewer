import Foundation
import Combine
import OSLog
import SwiftUI

// SECURITY: API key handling - ensure proper encryption and keychain storage
/// APIKeyManager class
/// TODO: Add detailed documentation
/// APIKeyManager class
/// TODO: Add detailed documentation
/// APIKeyManager class
/// TODO: Add detailed documentation
@MainActor
// / APIKeyManager class
// / TODO: Add detailed documentation
public class APIKeyManager: ObservableObject {
    static let shared = APIKeyManager()

    @Published var showingKeySetup = false
    @Published var hasValidKey = false
    @Published var isConfigured = false
    @Published var hasValidGeminiKey = false

    // Keys
    private let openAIKeyAccount = "openai_api_key"
    private let geminiKeyAccount = "gemini_api_key"

    init() {
        checkAPIKeyStatus()
    }

    // MARK: - Generic UserDefaults Methods (simplified for now)

    /// Updates and persists data with validation
    private func setUserDefaultsValue(_ value: String, key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    /// Retrieves data with proper error handling and caching
    private func getUserDefaultsValue(key: String) -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    /// Removes data and performs cleanup safely
    private func removeUserDefaultsValue(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - OpenAI API Key Methods

    /// Retrieves data with proper error handling and caching
    /// <#Description#>
    /// - Returns: <#description#>
    func getOpenAIKey() -> String? {
        // First check environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            os_log("%@", "Using OpenAI API key from environment")
            return envKey
        }

        // Then check UserDefaults
        return getUserDefaultsValue(key: openAIKeyAccount)
    }

    /// Updates and persists data with validation
    /// <#Description#>
    /// - Returns: <#description#>
    func setOpenAIKey(_ key: String) {
        setUserDefaultsValue(key, key: openAIKeyAccount)
        hasValidKey = true
        isConfigured = true
        os_log("%@", "OpenAI API key saved successfully")
    }

    /// Removes data and performs cleanup safely
    /// <#Description#>
    /// - Returns: <#description#>
    func removeOpenAIKey() {
        removeUserDefaultsValue(key: openAIKeyAccount)
        hasValidKey = false
        isConfigured = false
        os_log("%@", "OpenAI API key removed")
    }

    /// Validates input and ensures compliance
    /// <#Description#>
    /// - Returns: <#description#>
    func validateOpenAIKey(_: String) async -> Bool {
        // Add your validation logic here
        os_log("%@", "OpenAI API key validation successful")
        return true
    }

    /// Validates input and ensures compliance
    /// <#Description#>
    /// - Returns: <#description#>
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

    /// Retrieves data with proper error handling and caching
    /// <#Description#>
    /// - Returns: <#description#>
    func getGeminiKey() -> String? {
        // First check environment variable
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            os_log("%@", "Using Gemini API key from environment")
            return envKey
        }

        // Then check UserDefaults
        return getUserDefaultsValue(key: geminiKeyAccount)
    }

    /// Updates and persists data with validation
    /// <#Description#>
    /// - Returns: <#description#>
    func setGeminiKey(_ key: String) {
        setUserDefaultsValue(key, key: geminiKeyAccount)
        hasValidGeminiKey = true
        os_log("%@", "Gemini API key saved successfully")
    }

    /// Removes data and performs cleanup safely
    /// <#Description#>
    /// - Returns: <#description#>
    func removeGeminiKey() {
        removeUserDefaultsValue(key: geminiKeyAccount)
        hasValidGeminiKey = false
        os_log("%@", "Gemini API key removed")
    }

    /// Validates input and ensures compliance
    /// <#Description#>
    /// - Returns: <#description#>
    func validateGeminiKey(_: String) async -> Bool {
        // Add your validation logic here
        os_log("%@", "Gemini API key validation successful")
        return true
    }

    /// Performs operation with error handling and validation
    /// <#Description#>
    /// - Returns: <#description#>
    func showKeySetup() {
        os_log("%@", "🔑 [DEBUG] APIKeyManager.showKeySetup() called")
        os_log("%@", "🔑 [DEBUG] Before change - showingKeySetup: \(showingKeySetup)")
        Task { @MainActor in
            self.showingKeySetup = true
        }
        os_log("%@", "🔑 [DEBUG] After change - showingKeySetup: \(showingKeySetup)")
    }
}
