import Foundation
import Combine
import OSLog
import SwiftUI
import os

// SECURITY: API key handling - ensure proper encryption and keychain storage

// MARK: - Analysis Debouncer

/// Protocol for code review functionality to enable better testability
protocol CodeReviewService {
    func analyzeCode(_ code: String) async -> CodeAnalysisReport
}

/// Performance-optimized analysis with debouncing
actor AnalysisDebouncer {
    private var lastAnalysisTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 0.5

            /// Function description
            /// - Returns: Return value description
    func shouldAnalyze() -> Bool {
        let now = Date()
        let timeSinceLastAnalysis = now.timeIntervalSince(lastAnalysisTime)

        if timeSinceLastAnalysis >= debounceInterval {
            lastAnalysisTime = now
            return true
        }
        return false
    }
}

// / Enhanced ViewModel with AI integration and better architecture
@MainActor
final class CodeReviewViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var codeInput: String = ""
    @Published var analysisResults: [AnalysisResult] = []
    @Published var aiAnalysisResult: AIAnalysisResponse?
    @Published var aiSuggestions: [AISuggestion] = []
    @Published var availableFixes: [CodeFix] = []
    @Published var isAnalyzing: Bool = false
    @Published var isAIAnalyzing: Bool = false
    @Published var errorMessage: String?
    @Published var showingResults: Bool = false
    @Published var selectedLanguage: CodeLanguage = .swift
    @Published var aiEnabled: Bool = false
    @Published var analysisReport: CodeAnalysisReport?

    // For legacy support
    @Published var analysisResult: String = ""

    // MARK: - Private Properties

    private let codeReviewService: CodeReviewService
    private var aiService: EnhancedAICodeReviewService?
    private let keyManager: APIKeyManager
    private var cancellables = Set<AnyCancellable>()
    private let debouncer = AnalysisDebouncer()
    private let logger = AppLogger.shared
    private let osLogger = Logger(subsystem: "com.DanielStevens.CodingReviewer", category: "CodeReviewViewModel")

    // MARK: - Initialization

    @MainActor
    init(keyManager: APIKeyManager, codeReviewService: CodeReviewService? = nil) {
        self.codeReviewService = codeReviewService ?? DefaultCodeReviewService()
        self.keyManager = keyManager
        setupAIService()
        observeKeyManager()
    }

    // MARK: - Public Methods

    // / Performs comprehensive code analysis including AI if enabled
            /// Function description
            /// - Returns: Return value description
    func analyzeCode() async {
        guard !codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "No code provided for analysis"
            return
        }

        guard codeInput.count < 100_000 else {
            errorMessage = "Code too large (max 100,000 characters)"
            return
        }

        // Debounce analysis requests
        if await debouncer.shouldAnalyze() {
            isAnalyzing = true
            errorMessage = nil
            showingResults = false

            logger.logAnalysisStart(codeLength: codeInput.count)
            let startTime = Date()

            // Run traditional analysis
            let report = await codeReviewService.analyzeCode(codeInput)
            analysisResults = report.results
            analysisReport = report
            analysisResult = generateReportString(from: report) // Legacy support

            // Run enhanced AI analysis if enabled
            if aiEnabled, aiService != nil {
                isAIAnalyzing = true

                // Use enhanced AI service for real functionality
                let enhancedAI = EnhancedAIService(apiKeyManager: keyManager)
                await enhancedAI.analyzeCodeWithEnhancedAI(codeInput, language: selectedLanguage.rawValue)

                // Merge the enhanced results with existing analysis
                let enhancedResult = enhancedAI.analysisResult
                if !enhancedResult.isEmpty {
                    analysisResult += "\n\n" + enhancedResult
                }

                // Create comprehensive AI response
                let qualityScore = extractQualityScore(from: enhancedResult)
                aiAnalysisResult = AIAnalysisResponse(
                    suggestions: [],
                    complexityScore: Double(qualityScore) / 100.0,
                    maintainabilityScore: Double(qualityScore) / 100.0,
                    confidence: 0.8
                )

                isAIAnalyzing = false
            }

            showingResults = true
            let duration = Date().timeIntervalSince(startTime)
            logger.logAnalysisComplete(resultsCount: report.results.count, duration: duration)

            isAnalyzing = false
        }
    }

    // / Legacy analyze method for backward compatibility
    /// analyze function
    /// TODO: Add detailed documentation
    /// analyze function
    /// TODO: Add detailed documentation
    @MainActor
    // / analyze function
    // / TODO: Add detailed documentation
            /// Function description
            /// - Returns: Return value description
    func analyze(_ code: String) {
        codeInput = code
        Task {
            await analyzeCode()
        }
    }

    // / Applies an AI-generated fix to the code
            /// Function description
            /// - Returns: Return value description
    func applyFix(_ fix: CodeFix) {
        // For now, replace the original code with the fixed code
        // In a more sophisticated implementation, you'd locate the exact position
        if codeInput.contains(fix.originalCode) {
            codeInput = codeInput.replacingOccurrences(of: fix.originalCode, with: fix.fixedCode)
            logger.log("Applied AI fix: \(fix.description)", level: .info, category: .ai)

            // Re-analyze after applying fix
            Task {
                await analyzeCode()
            }
        } else {
            errorMessage = "Cannot apply fix: original code not found"
        }
    }

    // / Explains a specific issue using AI
            /// Function description
            /// - Returns: Return value description
    func explainIssue(_ issue: AnalysisResult) async {
        guard let aiService else { return }

        do {
            // Use explainCode method with the relevant code snippet
            let codeSnippet = extractCodeSnippet(for: issue)
            _ = try await aiService.explainCode(codeSnippet, language: selectedLanguage.rawValue)
            // Could show this in a popup or detail view
            logger.log("AI explanation generated for issue: \(issue.message)", level: .info, category: .ai)
        } catch {
            logger.log("Failed to generate AI explanation: \(error)", level: .error, category: .ai)
        }
    }

    private func extractCodeSnippet(for issue: AnalysisResult) -> String {
        // Extract a relevant code snippet for the issue
        let lines = codeInput.components(separatedBy: .newlines)
        let startLine = max(0, issue.lineNumber - 3)
        let endLine = min(lines.count - 1, issue.lineNumber + 3)
        return lines[startLine ... endLine].joined(separator: "\n")
    }

    // / Generates documentation for the current code
            /// Function description
            /// - Returns: Return value description
    func generateDocumentation() async {
        guard let aiService, !codeInput.isEmpty else { return }

        do {
            _ = try await aiService.generateDocumentation(for: codeInput, language: selectedLanguage.rawValue)
            // Could populate a documentation view or copy to clipboard
            logger.log("AI documentation generated", level: .info, category: .ai)
        } catch {
            logger.log("Failed to generate AI documentation: \(error)", level: .error, category: .ai)
        }
    }

    // / Shows the API key setup screen
            /// Function description
            /// - Returns: Return value description
    func showAPIKeySetup() {
        Task {
            AppLogger.shared.log("🧠 [DEBUG] CodeReviewViewModel.showAPIKeySetup() called", level: .debug)
            AppLogger.shared.log("🧠 [DEBUG] About to call keyManager.showKeySetup()", level: .debug)
        }
        osLogger.info("🧠 CodeReviewViewModel showAPIKeySetup called")
        keyManager.showKeySetup()
        Task {
            AppLogger.shared.log("🧠 [DEBUG] Completed call to keyManager.showKeySetup()", level: .debug)
        }
        osLogger.info("🧠 CodeReviewViewModel showAPIKeySetup completed")
    }

    // / Clears all analysis results
    // / clearResults function
    // / TODO: Add detailed documentation
    /// clearResults function
    /// TODO: Add detailed documentation
    /// clearResults function
    /// TODO: Add detailed documentation
            /// Function description
            /// - Returns: Return value description
    func clearResults() {
        analysisResult = ""
        analysisResults.removeAll()
        aiAnalysisResult = nil
        aiSuggestions.removeAll()
        availableFixes.removeAll()
        errorMessage = nil
        showingResults = false
    }

    // MARK: - Private Methods

    private func setupAIService() {
        guard keyManager.getOpenAIKey() != nil else {
            logger.log("No API key available for AI service", level: .warning, category: .ai)
            aiEnabled = false
            return
        }

        // Test if API key works - commented out for now to avoid dependency issues
        // _ = OpenAIService(apiKey: apiKey)
        aiService = EnhancedAICodeReviewService()
        aiEnabled = true
        logger.log("AI service initialized successfully", level: .info, category: .ai)
    }

    private func observeKeyManager() {
        keyManager.$hasValidKey
            .sink { [weak self] hasKey in
                self?.updateAIStatus(hasKey: hasKey)
            }
            .store(in: &cancellables)
    }

    private func updateAIStatus(hasKey: Bool) {
        if hasKey, aiService == nil {
            setupAIService()
        } else if !hasKey {
            aiService = nil
            aiEnabled = false
        }
    }

    private func generateReportString(from report: CodeAnalysisReport) -> String {
        var reportString = "📊 Code Analysis Report\n"
        reportString += String(repeating: "=", count: 50) + "\n\n"

        // Basic metrics
        reportString += "📈 Code Metrics:\n"
        reportString += "• Character count: \(report.metrics.characterCount)\n"
        reportString += "• Line count: \(report.metrics.lineCount)\n"
        reportString += "• Estimated complexity: \(report.metrics.complexityScore)\n"
        reportString += "• Function count: \(report.metrics.functionCount)\n\n"

        // Group results by type
        let qualityResults = report.results.filter { $0.type == "Quality" }
        let securityResults = report.results.filter { $0.type == "Security" }
        let suggestionResults = report.results.filter { $0.type == "Suggestion" }
        let performanceResults = report.results.filter { $0.type == "Performance" }

        // Quality Issues
        if qualityResults.isEmpty {
            reportString += "✅ Quality Issues: None detected\n\n"
        } else {
            reportString += "⚠️ Quality Issues (\(qualityResults.count)):\n"
            for (index, result) in qualityResults.enumerated() {
                reportString += "\(index + 1). \(result.message)\n"
            }
            reportString += "\n"
        }

        // Security Concerns
        if securityResults.isEmpty {
            reportString += "🔒 Security: No concerns detected\n\n"
        } else {
            reportString += "🔒 Security Concerns (\(securityResults.count)):\n"
            for (index, result) in securityResults.enumerated() {
                reportString += "\(index + 1). \(result.message)\n"
            }
            reportString += "\n"
        }

        // Performance Issues
        if performanceResults.isEmpty {
            reportString += "⚡ Performance: No issues detected\n\n"
        } else {
            reportString += "⚡ Performance Issues (\(performanceResults.count)):\n"
            for (index, result) in performanceResults.enumerated() {
                reportString += "\(index + 1). \(result.message)\n"
            }
            reportString += "\n"
        }

        // Suggestions
        if suggestionResults.isEmpty {
            reportString += "💡 Suggestions: None\n\n"
        } else {
            reportString += "💡 Suggestions (\(suggestionResults.count)):\n"
            for (index, result) in suggestionResults.enumerated() {
                reportString += "\(index + 1). \(result.message)\n"
            }
            reportString += "\n"
        }

        // Overall rating
        reportString += "📊 Overall Rating: \(report.rating.rawValue)\n"

        // AI Analysis if available
        if let aiResult = aiAnalysisResult {
            reportString += "\n🤖 AI Analysis:\n"
            reportString += "• Complexity Score: \(String(format: "%.2f", aiResult.complexityScore))\n"
            reportString += "• Maintainability: \(String(format: "%.2f", aiResult.maintainabilityScore))\n"
            reportString += "• AI Suggestions: \(aiResult.suggestions.count)\n"
            reportString += "• Confidence: \(String(format: "%.2f", aiResult.confidence))\n"
        }

        return reportString
    }

    private func extractQualityScore(from analysisResult: String) -> Int {
        // Extract quality score from analysis result
        if let range = analysisResult.range(of: "Quality Score: ") {
            let startIndex = range.upperBound
            let substring = analysisResult[startIndex...]

            if let endRange = substring.range(of: "/") {
                let scoreString = String(substring[..<endRange.lowerBound])
                return Int(scoreString) ?? 75
            }
        }
        return 75 // Default score
    }

    private func generateFixesFromSuggestions(_: [AISuggestion]) -> [CodeFix] {
        [] // Simplified for now
    }

    private func extractRelevantCode(for _: AISuggestion) -> String {
        ""
    }

    private func generateFixedCode(for _: AISuggestion) -> String {
        ""
    }

    private func calculateCyclomaticComplexity(_ code: String) -> Double {
        let keywords = ["if", "else", "for", "while", "switch", "case", "guard", "catch"]
        return keywords.reduce(1.0) { complexity, keyword in
            let count = code.components(separatedBy: keyword).count - 1
            return complexity + Double(count)
        }
    }

    private func extractSecurityRelatedCode(_: String) -> String {
        ""
    }

    private func extractQualityRelatedCode(_: String) -> String {
        ""
    }

    private func extractGenericCodeSnippet() -> String {
        ""
    }

    private func extractLongFunction() -> String {
        ""
    }

    private func breakLongLines(_ code: String) -> String {
        code
    }

    // MARK: - Default Implementation

    // / Default implementation of CodeReviewService
    final class DefaultCodeReviewService: CodeReviewService {
            /// Function description
            /// - Returns: Return value description
        func analyzeCode(_ code: String) async -> CodeAnalysisReport {
            let startTime = CFAbsoluteTimeGetCurrent()

            // Create analyzers on background queue to avoid main actor isolation
            return await withTaskGroup(of: [AnalysisResult].self) { group in
                var allResults: [AnalysisResult] = []

                // Add analysis tasks to group - create analyzers inside tasks to avoid data races
                group.addTask {
                    let analyzer = await MainActor.run { QualityAnalyzer() }
                    return await analyzer.analyze(code)
                }

                group.addTask {
                    let analyzer = await MainActor.run { SecurityAnalyzer() }
                    return await analyzer.analyze(code)
                }

                group.addTask {
                    let analyzer = await MainActor.run { PerformanceAnalyzer() }
                    return await analyzer.analyze(code)
                }

                // Collect results
                for await results in group {
                    allResults.append(contentsOf: results)
                }

                let endTime = CFAbsoluteTimeGetCurrent()
                _ = endTime - startTime // Track analysis time for potential future use

                // Calculate metrics
                let metrics = CodeMetrics(
                    characterCount: code.count,
                    lineCount: code.components(separatedBy: .newlines).count,
                    functionCount: 0, // Could be calculated
                    complexityScore: Double(calculateComplexity(code))
                )

                // Determine overall rating
                let rating = determineRating(from: allResults)

                return CodeAnalysisReport(
                    rating: rating,
                    summary: "Analysis completed with \(allResults.count) results",
                    timestamp: Date(),
                    results: allResults,
                    metrics: metrics
                )
            }
        }

        private func calculateComplexity(_ code: String) -> Int {
            let complexityKeywords = ["if", "else", "for", "while", "switch", "case", "catch", "&&", "||"]
            var complexity = 1 // Base complexity;

            for keyword in complexityKeywords {
                complexity += code.components(separatedBy: keyword).count - 1
            }

            return complexity
        }

        private func determineRating(from results: [AnalysisResult]) -> CodeAnalysisReport.Rating {
            let criticalCount = results.count(where: { $0.severity == "Critical" })
            let highCount = results.count(where: { $0.severity == "High" })
            let mediumCount = results.count(where: { $0.severity == "Medium" })
            let totalIssues = criticalCount + highCount + mediumCount

            switch totalIssues {
            case 0: return .excellent
            case 1 ... 2: return .good
            case 3 ... 5: return .fair
            default: return .poor
            }
        }

        // MARK: - Helper Methods

        private func convertToEnhancedAnalysisItems(_ results: [AnalysisResult]) -> [EnhancedAnalysisItem] {
            results.map { result in
                EnhancedAnalysisItem(
                    title: "\(result.type) Issue",
                    description: "\(result.message) (Line \(result.lineNumber))",
                    severity: result.severity,
                    category: result.type
                )
            }
        }
    }
}
