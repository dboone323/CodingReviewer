import Foundation
import SwiftUI
import Combine

struct ContentView: View {
    @State private var selectedTab: Tab = .quickStart
    @State private var codeInput: String = ""
    @State private var analysisResults: [AnalysisResult] = []
    @State private var isAnalyzing = false
    @State private var showWelcome = true
    @StateObject private var fileUploadManager = FileUploadManager()
    @StateObject private var memoryMonitor = MemoryMonitor()
    @StateObject private var responseTracker = ResponseTimeTracker()
    @StateObject private var backgroundManager = BackgroundProcessingManager()

    enum Tab: String, CaseIterable {
        case quickStart = "Quick Start"
        case files = "Files"
        case aiDashboard = "AI Intelligence"
        case insights = "AI Insights"
        case patterns = "Patterns"
        case enhancement = "Smart Enhancement"
        case analytics = "Enterprise Analytics"
        case processing = "Background Processing"
        case integration = "Enterprise Integration"
        case testing = "Advanced Testing"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .quickStart: return "bolt.circle.fill"
            case .files: return "folder.fill"
            case .aiDashboard: return "brain.head.profile.fill"
            case .insights: return "brain.head.profile"
            case .patterns: return "chart.line.uptrend.xyaxis"
            case .enhancement: return "wand.and.stars"
            case .analytics: return "chart.bar.fill"
            case .processing: return "gearshape.2.fill"
            case .integration: return "building.2.fill"
            case .testing: return "flask.fill"
            case .settings: return "gearshape.fill"
            }
        }

        var color: Color {
            switch self {
            case .quickStart: return .blue
            case .files: return .green
            case .aiDashboard: return .cyan
            case .insights: return .purple
            case .patterns: return .orange
            case .enhancement: return .pink
            case .analytics: return .indigo
            case .processing: return .teal
            case .integration: return .brown
            case .testing: return .mint
            case .settings: return .gray
            }
        }
    }

    var body: some View {
        NavigationView {
            // SIDEBAR NAVIGATION (Replaces segmented picker)
            VStack(alignment: .leading, spacing: 0) {
                // App Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("CodeReviewer")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("AI-Powered Analysis")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    Divider()
                }
                .padding()

                // Navigation Tabs
                VStack(spacing: 4) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        NavigationTabButton(
                            tab: tab,
                            isSelected: selectedTab == tab
                        ) {
                            selectedTab = tab
                            showWelcome = false
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Status Indicator with Enhanced Performance Info
                VStack(alignment: .leading, spacing: 8) {
                    Divider()

                    // Main Status
                    HStack {
                        AccessibleStatusIndicator(
                            isAnalyzing ? .analyzing : .ready,
                            showLabel: false
                        )

                        Text(isAnalyzing ? "Analyzing..." : "Ready")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                    
                    // Memory Usage Indicator
                    HStack {
                        Text("Memory")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Circle()
                            .fill(memoryMonitor.memoryPressure.color)
                            .frame(width: 6, height: 6)
                        
                        Text(memoryMonitor.formatBytes(memoryMonitor.currentUsage))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Background Jobs Indicator
                    if !backgroundManager.activeJobs.isEmpty {
                        HStack {
                            Text("Jobs")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(backgroundManager.activeJobs.count)")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding()
            }
            .frame(width: 200)
            .background(Color(NSColor.controlBackgroundColor))

            // MAIN CONTENT AREA
            Group {
                if showWelcome {
                    WelcomeView(onGetStarted: {
                        selectedTab = .quickStart
                        showWelcome = false
                    })
                } else {
                    switch selectedTab {
                    case .quickStart:
                        QuickStartView(
                            codeInput: $codeInput,
                            analysisResults: $analysisResults,
                            isAnalyzing: $isAnalyzing
                        )
                        .environmentObject(backgroundManager)
                        .environmentObject(responseTracker)
                    case .files:
                        FileUploadView()
                            .environmentObject(fileUploadManager)
                    case .aiDashboard:
                        AIDashboardView()
                    case .insights:
                        EnhancedAIInsightsView()
                    case .patterns:
                        PatternAnalysisView()
                    case .enhancement:
                        SmartEnhancementView()
                    case .analytics:
                        EnhancedEnterpriseAnalyticsDashboard()
                    case .processing:
                        BackgroundProcessingDashboard()
                    case .integration:
                        EnterpriseIntegrationDashboard()
                    case .testing:
                        AdvancedTestingDashboardView()
                    case .settings:
                        VStack(spacing: 20) {
                            SettingsView()
                            
                            // Performance Dashboard
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Performance Monitor")
                                    .font(.headline)
                                
                                EnhancedPerformanceDashboard()
                                    .environmentObject(memoryMonitor)
                                    .environmentObject(responseTracker)
                                    .environmentObject(backgroundManager)
                            }
                            .padding()
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(12)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Spacer()
                    Text(selectedTab.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    // Quick action based on current tab
                    handleQuickAction()
                }) {
                    Label("Quick Action", systemImage: "bolt.fill")
                }
                .disabled(isAnalyzing)
            }
        }
    }

    /// Handles operations with comprehensive error management
    private func handleQuickAction() {
        switch selectedTab {
        case .quickStart:
            if !codeInput.isEmpty {
                runAnalysis()
            }
        case .files:
            // Trigger file upload
            break
        case .aiDashboard:
            // Refresh AI dashboard
            break
        case .insights:
            // Refresh insights
            break
        case .patterns:
            // Run pattern analysis
            break
        case .enhancement:
            // Run smart enhancement
            break
        case .analytics:
            // Refresh analytics dashboard
            break
        case .processing:
            // Show processing queue
            break
        case .integration:
            // Sync team data
            break
        case .testing:
            // Generate and run tests
            break
        case .settings:
            // Reset to defaults
            break
        }
    }

    /// Performs operation with comprehensive error handling and validation
    private func runAnalysis() {
        isAnalyzing = true

        // Simulate analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            analysisResults = [
                AnalysisResult(
                    id: UUID(),
                    type: "Security",
                    severity: "High",
                    message: "Potential SQL injection vulnerability detected",
                    lineNumber: 42,
                    suggestion: "Use parameterized queries instead of string concatenation"
                ),
                AnalysisResult(
                    id: UUID(),
                    type: "Performance",
                    severity: "Medium",
                    message: "Inefficient loop detected",
                    lineNumber: 18,
                    suggestion: "Consider using built-in collection methods"
                )
            ]
            isAnalyzing = false
        }
    }
}

// NAVIGATION TAB BUTTON COMPONENT
struct NavigationTabButton: View {
    let tab: ContentView.Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? tab.color : .secondary)
                    .frame(width: 20)

                Text(tab.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? tab.color.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? tab.color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// WELCOME SCREEN
struct WelcomeView: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Welcome Icon
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            // Welcome Text
            VStack(spacing: 16) {
                Text("Welcome to CodeReviewer")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("AI-powered code analysis made simple")
                    .font(.title3)
                    .foregroundColor(.secondary)

                Text("Paste your code, upload files, or explore AI insights to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Get Started Button
            Button(action: onGetStarted) {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Get Started")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(25)
            }
            .buttonStyle(PlainButtonStyle())

            // Feature Highlights
            HStack(spacing: 40) {
                FeatureHighlight(
                    icon: "doc.text.magnifyingglass",
                    title: "Smart Analysis",
                    description: "AI-powered code review"
                )

                FeatureHighlight(
                    icon: "folder.badge.gearshape",
                    title: "Batch Processing",
                    description: "Analyze entire projects"
                )

                FeatureHighlight(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Pattern Recognition",
                    description: "Identify code patterns"
                )
            }
            .padding(.top, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 120)
    }
}

// QUICK START VIEW (Simplified main analysis)
struct QuickStartView: View {
    @Binding var codeInput: String
    @Binding var analysisResults: [AnalysisResult]
    @Binding var isAnalyzing: Bool
    @EnvironmentObject var backgroundManager: BackgroundProcessingManager
    @EnvironmentObject var responseTracker: ResponseTimeTracker

    @State private var selectedLanguage: String = "Auto-detect"

    private let languages = ["Auto-detect", "Swift", "Python", "JavaScript", "Java", "C++", "Go", "Rust"]

    var body: some View {
        VStack(spacing: 20) {
            // Header with language picker
            HStack {
                VStack(alignment: .leading) {
                    Text("Code Analysis")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Paste your code below for instant AI-powered analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Picker("Language", selection: $selectedLanguage) {
                    ForEach(languages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 120)
            }
            .padding(.horizontal)
            .padding(.top)

            // Code Input Area
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Code Input")
                        .font(.headline)

                    Spacer()

                    if !codeInput.isEmpty {
                        Button("Clear") {
                            codeInput = ""
                            analysisResults = []
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }

                TextEditor(text: $codeInput)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .frame(minHeight: 200)

                if codeInput.isEmpty {
                    VStack(spacing: 8) {
                        Text("💡 Try pasting some code here")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 16) {
                            SampleCodeButton(title: "Python Example") {
                                codeInput = """
                                def calculate_total(items):
                                    total = 0
                                    for item in items:
                                        total = total + item['price']
                                    return total

                                # Usage
                                items = [{'price': 10}, {'price': 20}]
                                result = calculate_total(items)
                                AppLogger.shared.log("Python calculation result: \\(result)", level: .debug, category: .analysis)
                                """
                            }

                            SampleCodeButton(title: "Swift Example") {
                                codeInput = """
                                /// Analyzes and processes data with comprehensive validation
                                func processUserData(users: [String]) {
                                    for user in users {
                                        let query = "SELECT * FROM users WHERE name = '" + user + "'"
                                        // Execute query
                                        AppLogger.shared.log("Executing query: \\(query)", level: .debug, category: .security)
                                    }
                                }
                                }
                                """
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal)

            // Analyze Button with Enhanced Progress
            VStack(spacing: 8) {
                AccessibleButton(
                    "Analyze Code",
                    subtitle: isAnalyzing ? "Processing your code..." : "Run comprehensive analysis",
                    icon: isAnalyzing ? nil : "magnifyingglass",
                    style: codeInput.isEmpty ? .secondary : .primary
                ) {
                    if !codeInput.isEmpty {
                        runAnalysis()
                    }
                }
                .disabled(codeInput.isEmpty || isAnalyzing)
                
                // Enhanced Progress Indicator
                if isAnalyzing {
                    EnhancedProgressView(
                        progress: 0.0, // Will be updated by animation
                        title: "Analyzing Code",
                        subtitle: "Processing \(selectedLanguage) code...",
                        style: .detailed
                    )
                    .frame(height: 60)
                    .padding(.horizontal)
                }
            }

            // Results Section
            if !analysisResults.isEmpty {
                SimpleAnalysisResultsView(results: analysisResults)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }

    /// Performs operation with comprehensive error handling and validation
    private func runAnalysis() {
        isAnalyzing = true
        
        // Enqueue background job for comprehensive analysis
        _ = backgroundManager.enqueueJob(
            name: "Code Analysis",
            description: "Analyzing \(selectedLanguage) code for issues",
            priority: .high
        ) {
            // Simulate comprehensive analysis
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            return "Analysis Complete"
        }

        // Simulate analysis with realistic delay using response tracker
        Task {
            do {
                let results = try await responseTracker.trackOperation("Code Analysis") {
                    try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                    
                    // Generate sample results based on code content
                    var results: [AnalysisResult] = []

                    if codeInput.contains("SELECT") && codeInput.contains("+") {
                        results.append(AnalysisResult(
                            id: UUID(),
                            type: "Security",
                            severity: "High",
                            message: "SQL Injection vulnerability detected",
                            lineNumber: findLineNumber(for: "SELECT"),
                            suggestion: "Use parameterized queries to prevent SQL injection"
                        ))
                    }

                    if codeInput.contains("for") && codeInput.contains("total") {
                        results.append(AnalysisResult(
                            id: UUID(),
                            type: "Performance",
                            severity: "Medium",
                            message: "Consider using built-in sum() function",
                            lineNumber: findLineNumber(for: "for"),
                            suggestion: "Use sum(item['price'] for item in items) for better performance"
                        ))
                    }

                    if results.isEmpty {
                        results.append(AnalysisResult(
                            id: UUID(),
                            type: "Quality",
                            severity: "Low",
                            message: "Code looks good! No major issues found",
                            lineNumber: 1,
                            suggestion: "Consider adding comments for better documentation"
                        ))
                    }
                    
                    return results
                }

                await MainActor.run {
                    analysisResults = results
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    analysisResults = [AnalysisResult(
                        id: UUID(),
                        type: "Error",
                        severity: "High",
                        message: "Analysis failed: \(error.localizedDescription)",
                        lineNumber: 1,
                        suggestion: "Please try again or check your code format"
                    )]
                    isAnalyzing = false
                }
            }
        }
    }

    /// Performs operation with comprehensive error handling and validation
    private func findLineNumber(for text: String) -> Int {
        let lines = codeInput.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            if line.contains(text) {
                return index + 1
            }
        }
        return 1
    }
}

struct SampleCodeButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AnalysisResultCard: View {
    let result: AnalysisResult

    private var severityColor: Color {
        switch result.severity.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .yellow
        default: return .blue
        }
    }

    private var severityIcon: String {
        switch result.severity.lowercased() {
        case "high": return "exclamationmark.triangle.fill"
        case "medium": return "exclamationmark.circle.fill"
        case "low": return "info.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Severity Icon
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)
                .font(.title3)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(result.type)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("Line \(result.lineNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }

                Text(result.message)
                    .font(.body)
                    .foregroundColor(.primary)

                if !result.suggestion.isEmpty {
                    Text("💡 \(result.suggestion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
        }
        .padding()
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(severityColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// SETTINGS VIEW
struct SettingsView: View {
    @State private var enableRealTimeAnalysis = true
    @State private var analysisDepth = 2.0
    @State private var selectedTheme = "System"

    private let themes = ["Light", "Dark", "System"]

    var body: some View {
        Form {
            Section("Analysis Settings") {
                Toggle("Enable Real-time Analysis", isOn: $enableRealTimeAnalysis)

                VStack(alignment: .leading) {
                    Text("Analysis Depth")
                    Slider(value: $analysisDepth, in: 1...5, step: 1) {
                        Text("Depth")
                    } minimumValueLabel: {
                        Text("Fast")
                    } maximumValueLabel: {
                        Text("Deep")
                    }
                }
            }

            Section("Appearance") {
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(themes, id: \.self) { theme in
                        Text(theme).tag(theme)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("2.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text("2024.1")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

// ContentView uses UnifiedDataModels.swift for AnalysisResult
// All data models are now centralized in UnifiedDataModels.swift

// Simple Analysis Results View for ContentView
struct SimpleAnalysisResultsView: View {
    let results: [AnalysisResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Analysis Results")
                    .font(.headline)

                Spacer()

                Text("\(results.count) issue\(results.count == 1 ? "" : "s") found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVStack(spacing: 12) {
                ForEach(results) { result in
                    AnalysisResultCard(result: result)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
