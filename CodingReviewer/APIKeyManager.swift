//
//  APIKeyManager.swift
//  CodingReviewer
//
//  Created by AI Assistant on 7/17/25.
//

import Foundation
import AppLogger
import Security
import SwiftUI
import Combine
import os

// MARK: - API Key Manager

@MainActor
final class APIKeyManager: ObservableObject {

    // MARK: - Singleton

    static let shared = APIKeyManager()

    // MARK: - Published Properties

    @Published var hasValidKey: Bool = false
    @Published var isConfigured: Bool = false
    @Published var showingKeySetup: Bool = false
    @Published var hasValidGeminiKey: Bool = false
    @Published var selectedAIProvider: AIProvider = .openai

    enum AIProvider: String, CaseIterable {
        case openai = "OpenAI"
        case gemini = "Google Gemini"

        var displayName: String {
            return self.rawValue
        }
    }

    // MARK: - Constants

    private let keychainService = "com.DanielStevens.CodingReviewer"
    private let openAIKeyAccount = "openai-api-key"
    private let geminiKeyAccount = "gemini-api-key"
    private let logger = AppLogger.shared
    private let osLogger = Logger(subsystem: "com.DanielStevens.CodingReviewer", category: "APIKeyManager")

    // MARK: - Initialization

    init() {
        checkAPIKeyStatus()
    }

    // MARK: - Public Methods

    func getOpenAIKey() -> String? {
        // First check environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            logger.log("Using OpenAI API key from environment", level: .info, category: .security)
            return envKey
        }

        // Then check Keychain
        return getKeychainValue(account: openAIKeyAccount)
    }

    func setOpenAIKey(_ key: String) throws {
        guard !key.isEmpty else {
            throw APIKeyError.emptyKey
        }

        guard isValidOpenAIKey(key) else {
            throw APIKeyError.invalidFormat
        }

        try setKeychainValue(key, account: openAIKeyAccount)
        hasValidKey = true
        isConfigured = true

        logger.log("OpenAI API key saved successfully", level: .info, category: .security)
    }

    func removeOpenAIKey() throws {
        try deleteKeychainValue(account: openAIKeyAccount)
        hasValidKey = false
        isConfigured = false

        logger.log("OpenAI API key removed", level: .info, category: .security)
    }

    func validateOpenAIKey(_ key: String) async -> Bool {
        guard isValidOpenAIKey(key) else { return false }

        // Test the key with a simple API call
        do {
            let isValid = try await testOpenAIKey(key)
            if isValid {
                logger.log("OpenAI API key validation successful", level: .info, category: .security)
            } else {
                logger.log("OpenAI API key validation failed", level: .warning, category: .security)
            }
            return isValid
        } catch {
            logger.log("Error validating OpenAI API key: \(error)", level: .error, category: .security)
            return false
        }
    }

    func checkAPIKeyStatus() {
        let hasKey = getOpenAIKey() != nil
        hasValidKey = hasKey
        isConfigured = hasKey

        let hasGeminiKey = getGeminiKey() != nil
        hasValidGeminiKey = hasGeminiKey

        if !hasKey {
            logger.log("No OpenAI API key found", level: .warning, category: .security)
        }

        if !hasGeminiKey {
            AppLogger.shared.debug("No Gemini API key found")
        }
    }

    // MARK: - Gemini API Key Methods

    func getGeminiKey() -> String? {
        // First check environment variable
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            AppLogger.shared.debug("Using Gemini API key from environment")
            return envKey
        }

        // Then check Keychain
        return getKeychainValue(account: geminiKeyAccount)
    }

    func setGeminiKey(_ key: String) throws {
        guard !key.isEmpty else {
            throw APIKeyError.emptyKey
        }

        guard isValidGeminiKey(key) else {
            throw APIKeyError.invalidFormat
        }

        try setKeychainValue(key, account: geminiKeyAccount)
        hasValidGeminiKey = true

        AppLogger.shared.debug("Gemini API key saved successfully")
    }

    func removeGeminiKey() throws {
        try deleteKeychainValue(account: geminiKeyAccount)
        hasValidGeminiKey = false

        AppLogger.shared.debug("Gemini API key removed")
    }

    func validateGeminiKey(_ key: String) async -> Bool {
        guard isValidGeminiKey(key) else { return false }

        // Test the key with a simple API call
        do {
            let isValid = try await testGeminiKey(key)
            if isValid {
                AppLogger.shared.debug("Gemini API key validation successful")
            } else {
                AppLogger.shared.debug("Gemini API key validation failed")
            }
            return isValid
        } catch {
            AppLogger.shared.debug("Error validating Gemini API key: \(error)")
            return false
        }
    }

    func showKeySetup() {
        AppLogger.shared.debug("� [DEBUG] APIKeyManager.showKeySetup() called")
        AppLogger.shared.debug("🔑 [DEBUG] Before change - showingKeySetup: \(showingKeySetup)")
        osLogger.info("🔑 APIKeyManager showKeySetup called, before: \(self.showingKeySetup)")
        showingKeySetup = true
        AppLogger.shared.debug("🔑 [DEBUG] After change - showingKeySetup: \(showingKeySetup)")
        osLogger.info("� APIKeyManager showKeySetup completed, after: \(self.showingKeySetup)")
    }
}

// MARK: - Private Methods

private extension APIKeyManager {

    func isValidOpenAIKey(_ key: String) -> Bool {
        // OpenAI keys start with "sk-" and are typically 51 characters
        return key.hasPrefix("sk-") && key.count >= 20
    }

    func isValidGeminiKey(_ key: String) -> Bool {
        // Gemini keys typically start with "AI" and are about 39 characters
        return key.hasPrefix("AI") && key.count >= 20
    }

    func testOpenAIKey(_ key: String) async throws -> Bool {
        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            throw APIKeyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIKeyError.invalidResponse
        }

        return httpResponse.statusCode == 200
    }

    func testGeminiKey(_ key: String) async throws -> Bool {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(key)") else {
            throw APIKeyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIKeyError.invalidResponse
        }

        return httpResponse.statusCode == 200
    }

    // MARK: - Keychain Operations

    func setKeychainValue(_ value: String, account: String) throws {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw APIKeyError.keychainError(status)
        }
    }

    func getKeychainValue(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    func deleteKeychainValue(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIKeyError.keychainError(status)
        }
    }
}

// MARK: - Error Types

enum APIKeyError: LocalizedError {
    case emptyKey
    case invalidFormat
    case invalidURL
    case invalidResponse
    case keychainError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .emptyKey:
            return "API key cannot be empty"
        case .invalidFormat:
            return "Invalid API key format. OpenAI keys should start with 'sk-'"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        }
    }
}
