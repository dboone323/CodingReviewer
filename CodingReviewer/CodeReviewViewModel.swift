import SwiftUI
import Foundation
import Combine

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

/// Enhanced ViewModel with better architecture and error handling
final class CodeReviewViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var analysisResult: String = ""
    @Published var isAnalyzing: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let codeReviewService: CodeReviewService
    private var cancellables = Set<AnyCancellable>()
    private let debouncer = AnalysisDebouncer()
    
    // MARK: - Initialization
    init(codeReviewService: CodeReviewService = DefaultCodeReviewService()) {
        self.codeReviewService = codeReviewService
    }
    
    // MARK: - Public Methods
    
    /// Analyzes the provided Swift code string and updates the analysisResult.
    /// - Parameter code: The Swift source code string to analyze.
    @MainActor
    public func analyze(_ code: String) {
        guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            analysisResult = "❌ Error: No code provided for analysis."
            AppLogger.shared.log("Analysis failed: No code provided", level: .warning)
            return
        }
        
        // Validate input size
        guard code.count < 100000 else {
            analysisResult = "❌ Error: Code too large (max 100,000 characters)"
            AppLogger.shared.log("Analysis failed: Code too large (\(code.count) characters)", level: .warning)
            return
        }
        
        // Debounce analysis requests
        Task {
            if await debouncer.shouldAnalyze() {
                isAnalyzing = true
                errorMessage = nil
                
                AppLogger.shared.logAnalysisStart(codeLength: code.count)
                let startTime = Date()
                
                let report = await codeReviewService.analyzeCode(code)
                let duration = Date().timeIntervalSince(startTime)
                
                await MainActor.run {
                    self.analysisResult = self.generateReportString(from: report)
                    self.isAnalyzing = false
                    AppLogger.shared.logAnalysisComplete(resultsCount: report.results.count, duration: duration)
                    AccessibilityHelper.announceAnalysisComplete(self.analysisResult)
                }
            }
        }
    }
    
    /// Clears the current analysis results.
    public func clearResults() {
        analysisResult = ""
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
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
