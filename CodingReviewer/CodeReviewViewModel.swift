// SECURITY: API key handling - ensure proper encryption and keychain storage
import OSLog
import SwiftUI
import Foundation
import Combine
import os

// MARK: - Analysis Debouncer

// / Protocol for code review functionality to enable better testability
protocol CodeReviewService {
    func analyzeCode(_ code: String) async -> CodeAnalysisReport
}

// / Performance-optimized analysis with debouncing
actor AnalysisDebouncer {
    private var lastAnalysisTime: Date = .distantPast;
    private let debounceInterval: TimeInterval = 0.5

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

// / Represents a comprehensive code analysis report
struct CodeAnalysisReport {
    let results: [AnalysisResult]
    let metrics: CodeMetrics
    let overallRating: Rating

    enum Rating {
        case excellent
        case good
        case needsImprovement
        case poor

        var description: String {
            switch self {
            case .excellent: return "🌟 Excellent"
            case .good: return "👍 Good"
            case .needsImprovement: return "⚠️ Needs Improvement"
            case .poor: return "❌ Poor"
            }
        }
    }
}

// / Code metrics for analysis
struct CodeMetrics {
    let characterCount: Int
    let lineCount: Int
    let estimatedComplexity: Int
    let analysisTime: TimeInterval
}

// / Enhanced ViewModel with AI integration and better architecture
@MainActor
final class CodeReviewViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var codeInput: String = "";
    @Published var analysisResults: [AnalysisResult] = [];
    @Published var aiAnalysisResult: AIAnalysisResponse?
    @Published var aiSuggestions: [AISuggestion] = [];
    @Published var availableFixes: [CodeFix] = [];
    @Published var isAnalyzing: Bool = false;
    @Published var isAIAnalyzing: Bool = false;
    @Published var errorMessage: String?
    @Published var showingResults: Bool = false;
    @Published var selectedLanguage: CodeLanguage = .swift;
    @Published var aiEnabled: Bool = false;
    @Published var analysisReport: CodeAnalysisReport?

    // For legacy support
    @Published var analysisResult: String = "";

    // MARK: - Private Properties

    private let codeReviewService: CodeReviewService
    private var aiService: EnhancedAICodeReviewService?
    private let keyManager: APIKeyManager
    private var cancellables = Set<AnyCancellable>();
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
    func analyzeCode() async {
        guard !codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "No code provided for analysis"
            return
        }

        guard codeInput.count < 100000 else {
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
                        fixes: [],
                        documentation: enhancedResult,
                        complexity: ComplexityScore(
                            score: Double(qualityScore) / 100.0,
                            description: "Enhanced analysis quality score",
                            cyclomaticComplexity: calculateCyclomaticComplexity(codeInput)
                        ),
                        maintainability: MaintainabilityScore(
                            score: Double(qualityScore) / 100.0,
                            description: "Code maintainability assessment"
                        ),
                        executionTime: Date().timeIntervalSince(startTime)
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
    @MainActor
    // / analyze function
    // / TODO: Add detailed documentation
    public func analyze(_ code: String) {
        codeInput = code
        Task {
            await analyzeCode()
        }
    }

    // / Applies an AI-generated fix to the code
    func applyFix(_ fix: CodeFix) {
        // For now, replace the original code with the fixed code
        // In a more sophisticated implementation, you'd locate the exact position
        if codeInput.contains(fix.originalCode) {
            codeInput = codeInput.replacingOccurrences(of: fix.originalCode, with: fix.fixedCode)
            logger.log("Applied AI fix: \(fix.title)", level: .info, category: .ai)

            // Re-analyze after applying fix
            Task {
                await analyzeCode()
            }
        } else {
            errorMessage = "Cannot apply fix: original code not found"
        }
    }

    // / Explains a specific issue using AI
    func explainIssue(_ issue: AnalysisResult) async {
        guard let aiService = aiService else { return }

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
        if let line = issue.line {
            let lines = codeInput.components(separatedBy: .newlines)
            let startLine = max(0, line - 3)
            let endLine = min(lines.count - 1, line + 3)
            return lines[startLine...endLine].joined(separator: "\n")
        }
        return codeInput
    }

    // / Generates documentation for the current code
    func generateDocumentation() async {
        guard let aiService = aiService, !codeInput.isEmpty else { return }

        do {
            _ = try await aiService.generateDocumentation(for: codeInput, language: selectedLanguage.rawValue)
            // Could populate a documentation view or copy to clipboard
            logger.log("AI documentation generated", level: .info, category: .ai)
        } catch {
            logger.log("Failed to generate AI documentation: \(error)", level: .error, category: .ai)
        }
    }

    // / Shows the API key setup screen
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
    public func clearResults() {
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
        if hasKey && aiService == nil {
            setupAIService()
        } else if !hasKey {
            aiService = nil
            aiEnabled = false
        }
    }

    private func generateReportString(from report: CodeAnalysisReport) -> String {
        var reportString = "📊 Code Analysis Report\n";
        reportString += String(repeating: "=", count: 50) + "\n\n"

        // Basic metrics
        reportString += "📈 Code Metrics:\n"
        reportString += "• Character count: \(report.metrics.characterCount)\n"
        reportString += "• Line count: \(report.metrics.lineCount)\n"
        reportString += "• Estimated complexity: \(report.metrics.estimatedComplexity)\n"
        reportString += "• Analysis time: \(String(format: "%.2f", report.metrics.analysisTime))s\n\n"

        // Group results by type
        let qualityResults = report.results.filter { $0.type == .quality }
        let securityResults = report.results.filter { $0.type == .security }
        let suggestionResults = report.results.filter { $0.type == .suggestion }
        let performanceResults = report.results.filter { $0.type == .performance }

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
        reportString += "📊 Overall Rating: \(report.overallRating.description)\n"

        // AI Analysis if available
        if let aiResult = aiAnalysisResult {
            reportString += "\n🤖 AI Analysis:\n"
            if let complexity = aiResult.complexity {
                reportString += "• Complexity Score: \(complexity.cyclomaticComplexity)\n"
            }
            if let maintainability = aiResult.maintainability {
                reportString += "• Maintainability: \(String(format: "%.2f", maintainability.score))\n"
            }
            reportString += "• AI Suggestions: \(aiResult.suggestions.count)\n"
            if let documentation = aiResult.documentation, !documentation.isEmpty {
                reportString += "\n💬 AI Assessment:\n\(documentation)\n"
            }
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

    private func generateFixesFromSuggestions(_ suggestions: [AISuggestion]) -> [CodeFix] {
        return [] // Simplified for now
    }

    private func extractRelevantCode(for suggestion: AISuggestion) -> String {
        return ""
    }

    private func generateFixedCode(for suggestion: AISuggestion) -> String {
        return ""
    }

    private func calculateCyclomaticComplexity(_ code: String) -> Double {
        let keywords = ["if", "else", "for", "while", "switch", "case", "guard", "catch"]
        return keywords.reduce(1.0) { complexity, keyword in
            let count = code.components(separatedBy: keyword).count - 1
            return complexity + Double(count)
        }
    }

    private func extractSecurityRelatedCode(_ title: String) -> String {
        return ""
    }

    private func extractQualityRelatedCode(_ title: String) -> String {
        return ""
    }

    private func extractGenericCodeSnippet() -> String {
        return ""
    }

    private func extractLongFunction() -> String {
        return ""
    }

    private func breakLongLines(_ code: String) -> String {
        return code
    }

// MARK: - Default Implementation

// / Default implementation of CodeReviewService
final class DefaultCodeReviewService: CodeReviewService {

    private let analyzers: [CodeAnalyzer] = [
        QualityAnalyzer(),
        SecurityAnalyzer(),
        PerformanceAnalyzer()
    ]

    func analyzeCode(_ code: String) async -> CodeAnalysisReport {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Run analysis on background queue
        return await withTaskGroup(of: [AnalysisResult].self) { group in
            var allResults: [AnalysisResult] = [];

            // Add analysis tasks to group
            for analyzer in analyzers {
                group.addTask {
                    await analyzer.analyze(code)
                }
            }

            // Collect results
            for await results in group {
                allResults.append(contentsOf: results)
            }

            let endTime = CFAbsoluteTimeGetCurrent()
            let analysisTime = endTime - startTime

            // Calculate metrics
            let metrics = CodeMetrics(
                characterCount: code.count,
                lineCount: code.components(separatedBy: .newlines).count,
                estimatedComplexity: calculateComplexity(code),
                analysisTime: analysisTime
            )

            // Determine overall rating
            let rating = determineRating(from: allResults)

            return CodeAnalysisReport(
                results: allResults,
                metrics: metrics,
                overallRating: rating
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
        let criticalCount = results.filter { $0.severity == .critical }.count
        let highCount = results.filter { $0.severity == .high }.count
        let mediumCount = results.filter { $0.severity == .medium }.count
        let totalIssues = criticalCount + highCount + mediumCount

        switch totalIssues {
        case 0: return .excellent
        case 1...2: return .good
        case 3...5: return .needsImprovement
        default: return .poor
        }
    }

    // MARK: - Helper Methods

    private func convertToEnhancedAnalysisItems(_ results: [AnalysisResult]) -> [EnhancedAnalysisItem] {
        results.map { result in
            EnhancedAnalysisItem(
                message: result.message,
                severity: result.severity.rawValue,
                lineNumber: result.line,
                type: result.type.rawValue
            )
        }
    }
}
}
