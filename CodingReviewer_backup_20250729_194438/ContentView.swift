// SECURITY: API key handling - ensure proper encryption and keychain storage
import SwiftUI
import Foundation
import os

struct ContentView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    @StateObject private var keyManager: APIKeyManager
    @StateObject private var viewModel: CodeReviewViewModel
    @State private var selectedTab: Tab = .analysis;

    init() {
        let keyManager = APIKeyManager()
        self._keyManager = StateObject(wrappedValue: keyManager)
        self._viewModel = StateObject(wrappedValue: CodeReviewViewModel(keyManager: keyManager))
    }

    enum Tab: String, CaseIterable {
        case analysis = "Analysis"
        case files = "Files"
        case ai = "AI Insights"
        case patterns = "Patterns"
        case settings = "Settings"

        var systemImage: String {
            switch self {
            case .analysis: return "magnifyingglass.circle"
            case .files: return "folder.badge.plus"
            case .ai: return "brain.head.profile"
            case .patterns: return "brain"
            case .settings: return "gear"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Text("CodeReviewer")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Spacer()

                        if viewModel.aiEnabled {
                            Label("AI Enabled", systemImage: "brain.head.profile")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }

                    Text("Intelligent Code Analysis & Review")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.controlBackgroundColor))

                // Tab Selection
                Picker("View", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.systemImage)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top)

                // Content
                TabView(selection: $selectedTab) {
                    AnalysisView(viewModel: viewModel)
                        .tag(Tab.analysis)

                    FileUploadView()
                        .tag(Tab.files)

                    AIInsightsView()
                        .tag(Tab.ai)

                    PatternAnalysisView(viewModel: viewModel)
                        .tag(Tab.patterns)

                    SettingsView(keyManager: keyManager, viewModel: viewModel)
                        .tag(Tab.settings)
                }
            }
        }
        .navigationTitle("")
        .sheet(isPresented: $keyManager.showingKeySetup) {
            APIKeySetupView()
        }
        .frame(minWidth: 900, minHeight: 700)
    }
}

// MARK: - Analysis View

struct AnalysisView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    @ObservedObject var viewModel: CodeReviewViewModel
    @State private var showingLanguagePicker = false;

    var body: some View {
        VStack(spacing: 16) {
            // Language Selection
            HStack {
                Text("Language:")
                    .font(.headline)

                Button(viewModel.selectedLanguage.displayName) {
                    showingLanguagePicker = true
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Clear") {
                    viewModel.clearResults()
                    viewModel.codeInput = ""
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            // Code Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Code to Analyze")
                    .font(.headline)

                ScrollView {
                    TextEditor(text: $viewModel.codeInput)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                }
                .border(Color.gray.opacity(0.3))
            }
            .padding(.horizontal)

            // Action Buttons
            HStack(spacing: 12) {
                Button("Analyze Code") {
                    Task {
                        await viewModel.analyzeCode()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isAnalyzing)

                if viewModel.aiEnabled {
                    Button("AI Documentation") {
                        Task {
                            await viewModel.generateDocumentation()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.codeInput.isEmpty)
                }
            }

            // Loading Indicator
            if viewModel.isAnalyzing || viewModel.isAIAnalyzing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)

                    Text(viewModel.isAIAnalyzing ? "AI analyzing..." : "Analyzing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            // Results
            if viewModel.showingResults {
                ContentAnalysisResultsView(viewModel: viewModel)
            }

            Spacer()
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerView(selectedLanguage: $viewModel.selectedLanguage)
        }
    }
}

// MARK: - AI Suggestion Row

struct AISuggestionRow: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    let suggestion: AISuggestion
    @State private var isExpanded = false;

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Severity indicator
                Circle()
                    .fill(severityColor)
                    .frame(width: 8, height: 8)

                Text(suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                // Confidence badge
                Text("\(Int(suggestion.confidence * 100))%")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Label(suggestion.type.rawValue, systemImage: typeIcon)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Label(suggestion.severity.rawValue, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(severityColor)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }

    private var severityColor: Color {
        switch suggestion.severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }

    private var typeIcon: String {
        switch suggestion.type {
        case .codeQuality: return "checkmark.seal"
        case .security: return "lock.shield"
        case .performance: return "speedometer"
        case .bestPractice: return "star"
        case .refactoring: return "arrow.triangle.2.circlepath"
        case .documentation: return "doc.text"
        }
    }
}

// MARK: - Analysis Results View (ContentView specific)

struct ContentAnalysisResultsView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    @ObservedObject var viewModel: CodeReviewViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Traditional Analysis Results
                if !viewModel.analysisResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Analysis Results")
                            .font(.headline)

                        ForEach(viewModel.analysisResults, id: \.message) { result in
                            AnalysisResultRow(result: result, viewModel: viewModel)
                        }
                    }
                }

                // Available Fixes
                if !viewModel.availableFixes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI-Suggested Fixes")
                            .font(.headline)

                        ForEach(viewModel.availableFixes, id: \.id) { fix in
                            AIFixRow(fix: fix, viewModel: viewModel)
                        }
                    }
                }

                // Legacy Text Results
                if !viewModel.analysisResult.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detailed Report")
                            .font(.headline)

                        Text(viewModel.analysisResult)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color(.textBackgroundColor))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Individual Result Views

struct AnalysisResultRow: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    let result: AnalysisResult
    @ObservedObject var viewModel: CodeReviewViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    severityIcon
                    Text(result.message)
                        .font(.subheadline)
                }

                Text(result.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if viewModel.aiEnabled {
                Button("Explain") {
                    Task {
                        await viewModel.explainIssue(result)
                    }
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
        }
        .padding()
        .background(result.severity.color.opacity(0.1))
        .cornerRadius(8)
    }

    private var severityIcon: some View {
        Image(systemName: result.severity.systemImage)
            .foregroundColor(result.severity.color)
    }
}

struct AIFixRow: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    let fix: CodeFix
    @ObservedObject var viewModel: CodeReviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(fix.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(Int(fix.confidence * 100))% confident")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Apply") {
                    viewModel.applyFix(fix)
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
            }

            Text(fix.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - AI-specific Views

struct AINotEnabledView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    @ObservedObject var keyManager: APIKeyManager
    @State private var showingSettings = false;

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("AI Features Not Available")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Configure your OpenAI API key to enable AI-powered code analysis, suggestions, and documentation generation.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            VStack(spacing: 12) {
                Button("Setup API Key") {
                    showingSettings = true
                }
                .buttonStyle(.borderedProminent)

                Button("Learn More") {
                    if let url = URL(string: "https://openai.com/api/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
            }

            // Feature Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Available AI Features:")
                    .font(.headline)
                    .padding(.top)

                FeaturePreviewRow(icon: "brain", title: "Intelligent Code Analysis", description: "Get smart insights about your code quality")
                FeaturePreviewRow(icon: "lightbulb", title: "Refactoring Suggestions", description: "Receive AI-powered improvement recommendations")
                FeaturePreviewRow(icon: "doc.text", title: "Auto Documentation", description: "Generate comprehensive code documentation")
                FeaturePreviewRow(icon: "text.bubble", title: "Code Explanations", description: "Understand complex code with AI explanations")
            }
            .padding(.top)
        }
        .padding()
        .sheet(isPresented: $showingSettings) {
            AISettingsView()
        }
    }
}

struct FeaturePreviewRow: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AIAnalysisResultView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    let aiResult: AIAnalysisResponse
    @ObservedObject var viewModel: CodeReviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Complexity Metrics
            VStack(alignment: .leading, spacing: 8) {
                Text("Code Complexity")
                    .font(.headline)

                HStack {
                    MetricCard(title: "Cyclomatic", value: "\(aiResult.complexity?.cyclomaticComplexity ?? 0)", color: Color.blue)
                    MetricCard(title: "Cognitive", value: "N/A", color: Color.orange)
                    MetricCard(title: "Maintainability", value: String(format: "%.2f", aiResult.maintainability?.score ?? 0.0), color: Color.green)
                }
            }

            // AI Suggestions
            if !aiResult.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Suggestions")
                        .font(.headline)

                    ForEach(aiResult.suggestions, id: \.id) { suggestion in
                        AISuggestionRow(suggestion: suggestion)
                    }
                }
            }

            // AI Explanation
            if let documentation = aiResult.documentation, !documentation.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Assessment")
                        .font(.headline)

                    Text(documentation)
                        .padding()
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct EmptyAIStateView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No AI Analysis Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Run a code analysis to see AI-powered insights and suggestions.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Extensions

// MARK: - Settings View

struct SettingsView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    @ObservedObject var keyManager: APIKeyManager
    @ObservedObject var viewModel: CodeReviewViewModel
    @State private var selectedAIProvider = "OpenAI";
    @State private var showingProviderPicker = false;
    @State private var showingGeminiKeyInput = false;
    @State private var tempGeminiKey = "";

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)

            // AI Provider Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Provider")
                    .font(.headline)

                HStack {
                    Text("Provider:")

                    Button(selectedAIProvider) {
                        showingProviderPicker = true
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }
                .sheet(isPresented: $showingProviderPicker) {
                    AIProviderPickerView(selectedProvider: $selectedAIProvider)
                        .onDisappear {
                            // Save provider selection
                            UserDefaults.standard.set(selectedAIProvider, forKey: "selected_ai_provider")
                        }
                }

                Text("Select between OpenAI and Google Gemini for AI-powered code analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            // AI Configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("AI Configuration")
                    .font(.headline)

                HStack {
                    Text("Status:")
                    Text(viewModel.aiEnabled ? "✅ Enabled" : "❌ Disabled")
                        .foregroundColor(viewModel.aiEnabled ? .green : .red)

                    Spacer()

                    Button(keyManager.hasValidKey ? "Update API Key" : "Setup API Key") {
                        keyManager.showKeySetup()
                    }
                    .buttonStyle(.bordered)
                }

                if selectedAIProvider == "Google Gemini" {
                    HStack {
                        Text("Gemini Key:")
                        Text(keyManager.hasValidGeminiKey ? "✅ Configured" : "❌ Not set")
                            .foregroundColor(keyManager.hasValidGeminiKey ? .green : .red)

                        Spacer()

                        Button(keyManager.hasValidGeminiKey ? "Update Gemini Key" : "Add Gemini Key") {
                            showingGeminiKeyInput = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .sheet(isPresented: $showingGeminiKeyInput) {
                        GeminiKeyInputView(tempKey: $tempGeminiKey, keyManager: keyManager)
                    }
                }

                if keyManager.hasValidKey && selectedAIProvider == "OpenAI" {
                    Button("Remove OpenAI API Key") {
                        do {
                            try keyManager.removeOpenAIKey()
                        } catch {
                            // Handle error
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }

                if keyManager.hasValidGeminiKey && selectedAIProvider == "Google Gemini" {
                    Button("Remove Gemini API Key") {
                        do {
                            try keyManager.removeGeminiKey()
                        } catch {
                            // Handle error
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            Spacer()
        }
        .padding()
        .onAppear {
            // Load saved provider selection
            selectedAIProvider = UserDefaults.standard.string(forKey: "selected_ai_provider") ?? "OpenAI"
        }
    }
}

// MARK: - Gemini Key Input View

struct GeminiKeyInputView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    @Binding var tempKey: String
    @ObservedObject var keyManager: APIKeyManager
    @Environment(\.dismiss) private var dismiss
    @State private var isValidating = false;
    @State private var validationResult: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter your Google Gemini API Key")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("Get your API key from https://makersuite.google.com/app/apikey")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                SecureField("Gemini API Key (starts with 'AI')", text: $tempKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))

                if let result = validationResult {
                    Text(result)
                        .font(.caption)
                        .foregroundColor(result.contains("✅") ? .green : .red)
                }

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
                        saveKey()
                    }
                    .disabled(tempKey.isEmpty)
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Gemini API Key")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private func validateKey() async {
        isValidating = true
        validationResult = "Validating..."

        let isValid = await keyManager.validateGeminiKey(tempKey)

        DispatchQueue.main.async {
            self.isValidating = false
            self.validationResult = isValid ? "✅ Valid API key" : "❌ Invalid API key"
        }
    }

    private func saveKey() {
        do {
            try keyManager.setGeminiKey(tempKey)
            UserDefaults.standard.set(tempKey, forKey: "gemini_api_key")
            dismiss()
        } catch {
            validationResult = "❌ Error saving key: \(error.localizedDescription)"
        }
    }
}

// MARK: - AI Provider Picker

struct AIProviderPickerView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    @Binding var selectedProvider: String
    @Environment(\.dismiss) private var dismiss

    let providers = ["OpenAI", "Google Gemini"]

    var body: some View {
        NavigationView {
            List(providers, id: \.self) { provider in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(provider)
                            .font(.headline)

                        Text(provider == "OpenAI" ? "GPT models for code analysis" : "Google's Gemini AI for code analysis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if provider == selectedProvider {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedProvider = provider
                    dismiss()
                }
            }
            .navigationTitle("Select AI Provider")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

// MARK: - Language Picker

struct LanguagePickerView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    @Binding var selectedLanguage: CodeLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(CodeLanguage.allCases, id: \.self) { language in
                HStack {
                    Text(language.displayName)

                    Spacer()

                    if language == selectedLanguage {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedLanguage = language
                    dismiss()
                }
            }
            .navigationTitle("Select Language")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions

extension AnalysisResult.ResultType {
    var displayName: String {
        switch self {
        case .quality: return "Quality"
        case .security: return "Security"
        case .suggestion: return "Suggestion"
        case .performance: return "Performance"
        }
    }
}

#Preview {
    ContentView()
}
