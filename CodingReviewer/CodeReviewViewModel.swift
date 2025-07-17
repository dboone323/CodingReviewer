import SwiftUI
import Foundation
import Combine
import os

/// Protocol for code review functionality to enable better testability
protocol CodeReviewService {
    func analyzeCode(_ code: String) async -> CodeAnalysisReport
}

/// Performance-optimized analysis with debouncing
actor AnalysisDebouncer {
    private var lastAnalysisTime: Date = .distantPast
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

/// Represents a comprehensive code analysis report
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

/// Code metrics for analysis
struct CodeMetrics {
    let characterCount: Int
    let lineCount: Int
    let estimatedComplexity: Int
    let analysisTime: TimeInterval
}

/// Enhanced ViewModel with AI integration and better architecture
@MainActor
final class CodeReviewViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var codeInput: String = ""
    @Published var analysisResults: [AnalysisResult] = []
    @Published var aiAnalysisResult: AIAnalysisResult?
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
    private var aiService: OpenAICodeReviewService?
    private let keyManager: APIKeyManager
    private var cancellables = Set<AnyCancellable>()
    private let debouncer = AnalysisDebouncer()
    private let logger = AppLogger.shared
    private let osLogger = Logger(subsystem: "com.DanielStevens.CodingReviewer", category: "CodeReviewViewModel")
    
    // MARK: - Initialization
    
    @MainActor
    init(codeReviewService: CodeReviewService = DefaultCodeReviewService(), keyManager: APIKeyManager) {
        self.codeReviewService = codeReviewService
        self.keyManager = keyManager
        setupAIService()
        observeKeyManager()
    }
    
    // MARK: - Public Methods
    
    /// Performs comprehensive code analysis including AI if enabled
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
            
            do {
                // Run traditional analysis
                let report = await codeReviewService.analyzeCode(codeInput)
                analysisResults = report.results
                analysisReport = report
                analysisResult = generateReportString(from: report) // Legacy support
                
                // Run AI analysis if enabled
                if aiEnabled, let aiService = aiService {
                    isAIAnalyzing = true
                    let aiResult = try await aiService.analyzeWithAI(codeInput, language: selectedLanguage)
                    aiAnalysisResult = aiResult
                    aiSuggestions = aiResult.suggestions
                    
                    // Generate fixes for critical issues
                    let criticalIssues = analysisResults.filter { $0.severity == .critical || $0.severity == .high }
                    if !criticalIssues.isEmpty {
                        let fixes = try await aiService.generateFixes(for: criticalIssues)
                        availableFixes = fixes
                    }
                    
                    isAIAnalyzing = false
                }
                
                showingResults = true
                let duration = Date().timeIntervalSince(startTime)
                logger.logAnalysisComplete(resultsCount: report.results.count, duration: duration)
                
            } catch {
                errorMessage = error.localizedDescription
                logger.log("Analysis failed: \(error)", level: .error, category: .analysis)
            }
            
            isAnalyzing = false
        }
    }
    
    /// Legacy analyze method for backward compatibility
    @MainActor
    public func analyze(_ code: String) {
        codeInput = code
        Task {
            await analyzeCode()
        }
    }
    
    /// Applies an AI-generated fix to the code
    func applyFix(_ fix: CodeFix) {
        let originalRange = fix.range
        guard originalRange.location >= 0 && 
              originalRange.location + originalRange.length <= codeInput.count else {
            errorMessage = "Cannot apply fix: invalid range"
            return
        }
        
        let startIndex = codeInput.index(codeInput.startIndex, offsetBy: originalRange.location)
        let endIndex = codeInput.index(startIndex, offsetBy: originalRange.length)
        
        codeInput.replaceSubrange(startIndex..<endIndex, with: fix.fixedCode)
        
        logger.log("Applied AI fix: \(fix.title)", level: .info, category: .ai)
        
        // Re-analyze after applying fix
        Task {
            await analyzeCode()
        }
    }
    
    /// Explains a specific issue using AI
    func explainIssue(_ issue: AnalysisResult) async {
        guard let aiService = aiService else { return }
        
        do {
            let explanation = try await aiService.explainIssue(issue)
            // Could show this in a popup or detail view
            logger.log("AI explanation generated for issue: \(issue.message)", level: .info, category: .ai)
        } catch {
            logger.log("Failed to generate AI explanation: \(error)", level: .error, category: .ai)
        }
    }
    
    /// Generates documentation for the current code
    func generateDocumentation() async {
        guard let aiService = aiService, !codeInput.isEmpty else { return }
        
        do {
            let documentation = try await aiService.generateDocumentation(for: codeInput)
            // Could populate a documentation view or copy to clipboard
            logger.log("AI documentation generated", level: .info, category: .ai)
        } catch {
            logger.log("Failed to generate AI documentation: \(error)", level: .error, category: .ai)
        }
    }
    
    /// Shows the API key setup screen
    func showAPIKeySetup() {
        print("🧠 [DEBUG] CodeReviewViewModel.showAPIKeySetup() called")
        print("🧠 [DEBUG] About to call keyManager.showKeySetup()")
        osLogger.info("🧠 CodeReviewViewModel showAPIKeySetup called")
        keyManager.showKeySetup()
        print("🧠 [DEBUG] Completed call to keyManager.showKeySetup()")
        osLogger.info("🧠 CodeReviewViewModel showAPIKeySetup completed")
    }
    
    /// Clears all analysis results
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
        do {
            aiService = try OpenAICodeReviewService()
            aiEnabled = true
            logger.log("AI service initialized successfully", level: .info, category: .ai)
        } catch {
            logger.log("Failed to initialize AI service: \(error)", level: .warning, category: .ai)
            aiEnabled = false
        }
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
        var reportString = "📊 Code Analysis Report\n"
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
            reportString += "• Complexity Score: \(aiResult.complexity.cyclomatic)\n"
            reportString += "• Maintainability: \(String(format: "%.2f", aiResult.maintainability.index))\n"
            reportString += "• AI Suggestions: \(aiResult.suggestions.count)\n"
            if !aiResult.explanation.isEmpty {
                reportString += "\n💬 AI Assessment:\n\(aiResult.explanation)\n"
            }
        }
        
        return reportString
    }
}

// MARK: - Default Implementation

/// Default implementation of CodeReviewService
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
            var allResults: [AnalysisResult] = []
            
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
        var complexity = 1 // Base complexity
        
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
}
