//
//  APIKeyManager.swift
//  CodingReviewer
//
//  Created by AI Assistant on 7/17/25.
//

import Foundation
import Security
import SwiftUI
import Combine
import os

// MARK: - API Key Manager

@MainActor
final class APIKeyManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var hasValidKey: Bool = false
    @Published var isConfigured: Bool = false
    @Published var showingKeySetup: Bool = false
    
    // MARK: - Constants
    
    private let keychainService = "com.DanielStevens.CodingReviewer"
    private let openAIKeyAccount = "openai-api-key"
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
        
        if !hasKey {
            logger.log("No OpenAI API key found", level: .warning, category: .security)
        }
    }
    
    func showKeySetup() {
        print("� [DEBUG] APIKeyManager.showKeySetup() called")
        print("🔑 [DEBUG] Before change - showingKeySetup: \(showingKeySetup)")
        osLogger.info("🔑 APIKeyManager showKeySetup called, before: \(self.showingKeySetup)")
        showingKeySetup = true
        print("🔑 [DEBUG] After change - showingKeySetup: \(showingKeySetup)")
        osLogger.info("� APIKeyManager showKeySetup completed, after: \(self.showingKeySetup)")
    }
}

// MARK: - Private Methods

private extension APIKeyManager {
    
    func isValidOpenAIKey(_ key: String) -> Bool {
        // OpenAI keys start with "sk-" and are typically 51 characters
        return key.hasPrefix("sk-") && key.count >= 20
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

// MARK: - API Key Setup View

struct APIKeySetupView: View {
    
    @ObservedObject var keyManager: APIKeyManager
    @State private var apiKey: String = ""
    @State private var isValidating: Bool = false
    @State private var validationMessage: String = ""
    @State private var showingHelp: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("OpenAI API Setup")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Configure your OpenAI API key to enable AI-powered code analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // API Key Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.headline)
                    
                    SecureField("sk-...", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    
                    if !validationMessage.isEmpty {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundColor(validationMessage.contains("Success") ? .green : .red)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Validate & Save") {
                        Task {
                            await validateAndSave()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty || isValidating)
                    
                    Button("Help") {
                        showingHelp = true
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                // Privacy Notice
                VStack(spacing: 4) {
                    Text("🔒 Privacy & Security")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("Your API key is stored securely in the system Keychain and never shared.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("API Setup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if isValidating {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .sheet(isPresented: $showingHelp) {
            APIKeyHelpView()
        }
        .frame(width: 600, height: 700)
    }
    
    private func validateAndSave() async {
        isValidating = true
        validationMessage = ""
        
        do {
            let isValid = await keyManager.validateOpenAIKey(apiKey)
            
            if isValid {
                try keyManager.setOpenAIKey(apiKey)
                validationMessage = "✅ Success! API key saved."
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            } else {
                validationMessage = "❌ Invalid API key. Please check and try again."
            }
        } catch {
            validationMessage = "❌ Error: \(error.localizedDescription)"
        }
        
        isValidating = false
    }
}

// MARK: - Help View

struct APIKeyHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How to get your OpenAI API Key")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        helpStep(number: "1", 
                                title: "Visit OpenAI Platform", 
                                description: "Go to platform.openai.com and sign in to your account")
                        
                        helpStep(number: "2", 
                                title: "Navigate to API Keys", 
                                description: "Click on your profile menu and select 'View API keys'")
                        
                        helpStep(number: "3", 
                                title: "Create New Key", 
                                description: "Click 'Create new secret key' and give it a name")
                        
                        helpStep(number: "4", 
                                title: "Copy Your Key", 
                                description: "Copy the generated key (starts with 'sk-') and paste it above")
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 Tips")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("• Keep your API key secure and never share it")
                        Text("• Monitor your usage on the OpenAI dashboard")
                        Text("• You can revoke and create new keys anytime")
                        Text("• API calls are charged based on OpenAI's pricing")
                    }
                    .font(.subheadline)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🔒 Security")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("Your API key is stored in the macOS Keychain, which provides secure, encrypted storage. The key never leaves your device except to make authorized API calls to OpenAI.")
                            .font(.subheadline)
                    }
                }
                .padding()
            }
            .navigationTitle("API Key Help")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 700, height: 600)
    }
    
    private func helpStep(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
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
