import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .quickStart
    @State private var codeInput: String = ""
    @State private var analysisResults: [AnalysisResult] = []
    @State private var isAnalyzing = false
    @State private var showWelcome = true

    enum Tab: String, CaseIterable {
        case quickStart = "Quick Start"
        case files = "Files"
        case insights = "AI Insights"
        case patterns = "Patterns"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .quickStart: "bolt.circle.fill"
            case .files: "folder.fill"
            case .insights: "brain.head.profile"
            case .patterns: "chart.line.uptrend.xyaxis"
            case .settings: "gearshape.fill"
            }
        }

        var color: Color {
            switch self {
            case .quickStart: .blue
            case .files: .green
            case .insights: .purple
            case .patterns: .orange
            case .settings: .gray
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

                // Status Indicator
                VStack(alignment: .leading, spacing: 8) {
                    Divider()

                    HStack {
                        Circle()
                            .fill(isAnalyzing ? Color.orange : Color.green)
                            .frame(width: 8, height: 8)

                        Text(isAnalyzing ? "Analyzing..." : "Ready")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
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
                    case .files:
                        EnhancedFileUploadView()
                    case .insights:
                        EnhancedAIInsightsView()
                    case .patterns:
                        PatternAnalysisView()
                    case .settings:
                        SettingsView()
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

    private func handleQuickAction() {
        switch selectedTab {
        case .quickStart:
            if !codeInput.isEmpty {
                runAnalysis()
            }
        case .files:
            // Trigger file upload
            break
        case .insights:
            // Refresh insights
            break
        case .patterns:
            // Run pattern analysis
            break
        case .settings:
            // Reset to defaults
            break
        }
    }

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
                ),
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
                                print(result)
                                """
                            }

                            SampleCodeButton(title: "Swift Example") {
                                codeInput = """
    /// <#Description#>
    /// - Returns: <#description#>
                                func processUserData(users: [String]) {
                                    for user in users {
                                        let query = "SELECT * FROM users WHERE name = '" + user + "'"
                                        // Execute query
                                        print(query)
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

            // Analyze Button
            Button(action: {
                if !codeInput.isEmpty {
                    runAnalysis()
                }
            }) {
                HStack {
                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing...")
                    } else {
                        Image(systemName: "magnifyingglass")
                        Text("Analyze Code")
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(codeInput.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(20)
            }
            .disabled(codeInput.isEmpty || isAnalyzing)
            .buttonStyle(PlainButtonStyle())

            // Results Section
            if !analysisResults.isEmpty {
                AnalysisResultsView(results: analysisResults)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }

    private func runAnalysis() {
        isAnalyzing = true

        // Simulate analysis with realistic delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Generate sample results based on code content
            var results: [AnalysisResult] = []

            if codeInput.contains("SELECT"), codeInput.contains("+") {
                results.append(AnalysisResult(
                    id: UUID(),
                    type: "Security",
                    severity: "High",
                    message: "SQL Injection vulnerability detected",
                    lineNumber: findLineNumber(for: "SELECT"),
                    suggestion: "Use parameterized queries to prevent SQL injection"
                ))
            }

            if codeInput.contains("for"), codeInput.contains("total") {
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

            analysisResults = results
            isAnalyzing = false
        }
    }

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

// ANALYSIS RESULTS VIEW
struct AnalysisResultsView: View {
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

struct AnalysisResultCard: View {
    let result: AnalysisResult

    private var severityColor: Color {
        switch result.severity.lowercased() {
        case "high": .red
        case "medium": .orange
        case "low": .yellow
        default: .blue
        }
    }

    private var severityIcon: String {
        switch result.severity.lowercased() {
        case "high": "exclamationmark.triangle.fill"
        case "medium": "exclamationmark.circle.fill"
        case "low": "info.circle.fill"
        default: "checkmark.circle.fill"
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
                    Slider(value: $analysisDepth, in: 1 ... 5, step: 1) {
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

// DATA MODELS
struct AnalysisResult: Identifiable {
    let id: UUID
    let type: String
    let severity: String
    let message: String
    let lineNumber: Int
    let suggestion: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
