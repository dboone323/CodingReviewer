import Foundation
// SECURITY: API key handling - ensure proper encryption and keychain storage
//
// APIKeySetupView.swift
// CodingReviewer
//
// API Key setup and configuration view
// Created on July 25, 2025
//

import SwiftUI
import Accessibility

struct APIKeySetupView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    @State private var tempKey = "";
    @State private var isValidating = false;
    @State private var validationResult: String?
    @State private var selectedProvider = "OpenAI";
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)

                    Text("API Key Setup")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Configure your AI service to enable advanced code analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Provider Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Provider")
                        .font(.headline)

                    Picker("Provider", selection: $selectedProvider) {
                        Text("OpenAI").tag("OpenAI")
                        Text("Google Gemini").tag("Google Gemini")
                    }
                    .pickerStyle(.segmented)
                }

                // API Key Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(selectedProvider) API Key")
                        .font(.headline)

                    SecureField("Enter your API key", text: $tempKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))

                    if selectedProvider == "OpenAI" {
                        Text("Get your API key from https:// platform.openai.com/api-keys")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Get your API key from https:// makersuite.google.com/app/apikey")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Validation Result
                if let result = validationResult {
                    Text(result)
                        .font(.caption)
                        .foregroundColor(result.contains("✅") ? .green : .red)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                }

                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button("Test Key") {
                        Task {
                            await validateKey()
                        }
                    }
                    .disabled(tempKey.isEmpty || isValidating)
                    .buttonStyle(.bordered)

                    Button("Save") {
                        Task {
                            await saveKey()
                        }
                    }
                    .disabled(tempKey.isEmpty)
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("API Key Setup")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    /// Validates input and ensures compliance
    private func validateKey() async {
        isValidating = true
        validationResult = "Validating..."

        // Simple validation - check if key has proper format
        let isValid: Bool
        if selectedProvider == "OpenAI" {
            isValid = tempKey.hasPrefix("sk-") && tempKey.count > 10
        } else {
            isValid = tempKey.count > 10 // Basic check for Gemini
        }

        // Simulate API call delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        await MainActor.run {
            self.isValidating = false
            self.validationResult = isValid ? "✅ Valid API key format" : "❌ Invalid API key format"
        }
    }

    /// Updates and persists data with validation
    private func saveKey() async {
        await MainActor.run {
            isValidating = true
            validationResult = "Saving..."
        }

        // Save to UserDefaults - will integrate with APIKeyManager later
        if selectedProvider == "OpenAI" {
            UserDefaults.standard.set(tempKey, forKey: "openai_api_key")
        } else {
            UserDefaults.standard.set(tempKey, forKey: "gemini_api_key")
        }

        await MainActor.run {
            self.isValidating = false
            self.validationResult = "✅ API key saved successfully"

            // Auto-dismiss after showing success message
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.dismiss()
            }
        }
    }
}

#Preview {
    APIKeySetupView()
}
