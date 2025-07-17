import SwiftUI
import os

struct ContentView: View {
    @StateObject private var keyManager: APIKeyManager
    @StateObject private var viewModel: CodeReviewViewModel
    @State private var selectedTab: Tab = .analysis
    
    init() {
        let keyManager = APIKeyManager()
        self._keyManager = StateObject(wrappedValue: keyManager)
        self._viewModel = StateObject(wrappedValue: CodeReviewViewModel(keyManager: keyManager))
    }
    
    enum Tab: String, CaseIterable {
        case analysis = "Analysis"
        case files = "Files"
        case ai = "AI Insights"
        case settings = "Settings"
        
        var systemImage: String {
            switch self {
            case .analysis: return "magnifyingglass.circle"
            case .files: return "folder.badge.plus"
            case .ai: return "brain.head.profile"
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
                    
                    AIInsightsView(viewModel: viewModel, keyManager: keyManager)
                        .tag(Tab.ai)
                    
                    SettingsView(keyManager: keyManager, viewModel: viewModel)
                        .tag(Tab.settings)
                }
            }
        }
        .navigationTitle("")
        .sheet(isPresented: $keyManager.showingKeySetup) {
            APIKeySetupView(keyManager: keyManager)
        }
        .frame(minWidth: 900, minHeight: 700)
    }
}

// MARK: - Analysis View

struct AnalysisView: View {
    @ObservedObject var viewModel: CodeReviewViewModel
    @State private var showingLanguagePicker = false
    
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

// MARK: - AI Insights View

struct AIInsightsView: View {
    @ObservedObject var viewModel: CodeReviewViewModel
    @ObservedObject var keyManager: APIKeyManager
    
    var body: some View {
        VStack(spacing: 16) {
            if !viewModel.aiEnabled {
                AINotEnabledView(viewModel: viewModel, keyManager: keyManager)
            } else if let aiResult = viewModel.aiAnalysisResult {
                AIAnalysisResultView(aiResult: aiResult, viewModel: viewModel)
            } else {
                EmptyAIStateView()
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Analysis Results View (ContentView specific)

struct ContentAnalysisResultsView: View {
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
    @ObservedObject var viewModel: CodeReviewViewModel
    @ObservedObject var keyManager: APIKeyManager
    
    private let logger = Logger(subsystem: "com.DanielStevens.CodingReviewer", category: "APIKeySetup")
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("AI Features Not Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Configure your OpenAI API key to enable AI-powered code analysis, suggestions, and fixes.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Setup API Key") {
                viewModel.showAPIKeySetup()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct AIAnalysisResultView: View {
    let aiResult: AIAnalysisResult
    @ObservedObject var viewModel: CodeReviewViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Complexity Metrics
            VStack(alignment: .leading, spacing: 8) {
                Text("Code Complexity")
                    .font(.headline)
                
                HStack {
                    MetricCard(title: "Cyclomatic", value: "\(aiResult.complexity.cyclomatic)")
                    MetricCard(title: "Cognitive", value: "\(aiResult.complexity.cognitive)")
                    MetricCard(title: "Maintainability", value: String(format: "%.2f", aiResult.maintainability.index))
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
            if !aiResult.explanation.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Assessment")
                        .font(.headline)
                    
                    Text(aiResult.explanation)
                        .padding()
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct AISuggestionRow: View {
    let suggestion: AISuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(suggestion.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(suggestion.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let fix = suggestion.suggestedFix {
                Text("Suggested fix: \(fix)")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .italic()
            }
        }
        .padding()
        .background(suggestion.severity.color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct EmptyAIStateView: View {
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
    @ObservedObject var keyManager: APIKeyManager
    @ObservedObject var viewModel: CodeReviewViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)
            
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
                
                if keyManager.hasValidKey {
                    Button("Remove API Key") {
                        do {
                            try keyManager.removeOpenAIKey()
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
    }
}

// MARK: - Language Picker

struct LanguagePickerView: View {
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

extension AnalysisResult.Severity {
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
    
    var systemImage: String {
        switch self {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.circle"
        case .critical: return "exclamationmark.octagon"
        }
    }
}

#Preview {
    ContentView()
}
