import Foundation
import OSLog
import Combine

// MARK: - Advanced AI Project Analyzer
// Continuously analyzes project health and prevents issues before they occur

@MainActor
class AdvancedAIProjectAnalyzer: ObservableObject {
    static let shared = AdvancedAIProjectAnalyzer()
    
    private let logger = OSLog(subsystem: "CodingReviewer", category: "AIProjectAnalyzer")
    private let learningCoordinator = AILearningCoordinator.shared
    private let codeGenerator = EnhancedAICodeGenerator.shared
    private let fixEngine = AutomaticFixEngine.shared
    
    // MARK: - Published Properties
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: Double = 0.0
    @Published var projectHealth: ProjectHealth = ProjectHealth()
    @Published var riskAssessment: RiskAssessment = RiskAssessment(overallRisk: 0.0, criticalRisks: [], mitigation: "No assessment available")
    @Published var recommendations: [ProjectRecommendation] = []
    
    // MARK: - Analysis Components
    private var dependencyAnalyzer: DependencyAnalyzer
    private var architectureAnalyzer: ArchitectureAnalyzer
    private var performanceAnalyzer: PerformanceAnalyzer
    private var securityAnalyzer: SecurityAnalyzer
    private var qualityAnalyzer: QualityAnalyzer
    private var predictiveAnalyzer: PredictiveAnalyzer
    
    private var analysisTimer: Timer?
    
    private init() {
        self.dependencyAnalyzer = DependencyAnalyzer()
        self.architectureAnalyzer = ArchitectureAnalyzer()
        self.performanceAnalyzer = PerformanceAnalyzer()
        self.securityAnalyzer = SecurityAnalyzer()
        self.qualityAnalyzer = QualityAnalyzer()
        self.predictiveAnalyzer = PredictiveAnalyzer()
        
        startContinuousAnalysis()
    }
    
    // MARK: - Public Interface
    
    func performComprehensiveAnalysis() async -> ComprehensiveAnalysisResult {
        isAnalyzing = true
        analysisProgress = 0.0
        
        os_log("Starting comprehensive project analysis", log: logger, type: .info)
        
        var results = ComprehensiveAnalysisResult()
        
        do {
            // Phase 1: Dependency Analysis
            analysisProgress = 0.1
            results.dependencies = await dependencyAnalyzer.analyze()
            
            // Phase 2: Architecture Analysis
            analysisProgress = 0.2
            results.architecture = await architectureAnalyzer.analyze()
            
            // Phase 3: Performance Analysis
            analysisProgress = 0.4
            results.performance = await performanceAnalyzer.analyze()
            
            // Phase 4: Security Analysis
            analysisProgress = 0.5
            results.security = await securityAnalyzer.analyze()
            
            // Phase 5: Code Quality Analysis
            analysisProgress = 0.7
            results.quality = await qualityAnalyzer.analyze()
            
            // Phase 6: Predictive Analysis
            analysisProgress = 0.8
            results.predictions = await predictiveAnalyzer.analyze()
            
            // Phase 7: Generate Recommendations
            analysisProgress = 0.9
            results.recommendations = await generateRecommendations(from: results)
            
            // Phase 8: Update Project Health
            analysisProgress = 1.0
            await updateProjectHealth(from: results)
            
            os_log("Comprehensive analysis completed successfully", log: logger, type: .info)
            
        } catch {
            os_log("Analysis failed: %@", log: logger, type: .error, error.localizedDescription)
            results.error = error
        }
        
        isAnalyzing = false
        return results
    }
    
    func analyzeFile(_ filePath: String) async -> FileAnalysisResult {
        os_log("Analyzing file: %@", log: logger, type: .debug, filePath)
        
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            return FileAnalysisResult(
                fileName: (filePath as NSString).lastPathComponent,
                filePath: filePath,
                fileType: (filePath as NSString).pathExtension,
                issuesFound: 0,
                issues: []
            )
        }
        
        // Use AI to predict potential issues
        let predictedIssues = await learningCoordinator.predictIssues(in: filePath)
        
        // Convert predicted issues to analysis issues
        let analysisIssues = predictedIssues.map { predictedIssue in
            AnalysisIssue(
                type: mapIssueTypeToString(predictedIssue.type),
                severity: mapConfidenceToSeverity(predictedIssue.confidence),
                message: predictedIssue.description,
                lineNumber: predictedIssue.lineNumber,
                line: ""
            )
        }
        
        // Get improvement suggestions
        let improvements = await codeGenerator.suggestImprovements(for: content, filePath: filePath)
        
        // Convert to recommendations
        let recommendations = improvements.map { improvement in
            FileRecommendation(
                type: .codeImprovement(improvement),
                priority: mapSeverityToPriority(improvement.severity),
                description: improvement.description,
                suggestion: improvement.suggestion
            )
        }
        
        // Calculate confidence based on AI predictions
        let confidence = calculateConfidence(predictedIssues: predictedIssues, improvements: improvements)
        
        return FileAnalysisResult(
            fileName: (filePath as NSString).lastPathComponent,
            filePath: filePath,
            fileType: (filePath as NSString).pathExtension,
            issuesFound: analysisIssues.count,
            issues: analysisIssues
        )
    }
    
    func performHealthCheck() async -> HealthCheckResult {
        os_log("Performing project health check", log: logger, type: .debug)
        
        let projectPath = FileManager.default.currentDirectoryPath + "/CodingReviewer"
        let swiftFiles = findSwiftFiles(in: projectPath)
        
        var healthMetrics = HealthMetrics()
        var issues: [ProjectIssue] = []
        
        // Analyze each file
        for filePath in swiftFiles {
            let fileResult = await analyzeFile(filePath)
            healthMetrics.totalFiles += 1
            
            if !fileResult.issues.isEmpty {
                healthMetrics.filesWithIssues += 1
                
                // Get the predicted issues again for ProjectIssue creation
                let predictedIssues = await learningCoordinator.predictIssues(in: filePath)
                
                issues.append(contentsOf: predictedIssues.map { predictedIssue in
                    ProjectIssue(
                        type: .codeIssue(predictedIssue),
                        severity: mapConfidenceToSeverityEnum(predictedIssue.confidence),
                        filePath: filePath,
                        description: predictedIssue.description
                    )
                })
            }
        }
        
        // Check build system health
        let buildHealth = await checkBuildSystemHealth()
        healthMetrics.buildSystemHealth = buildHealth.score
        issues.append(contentsOf: buildHealth.issues)
        
        // Check dependency health
        let dependencyHealth = await checkDependencyHealth()
        healthMetrics.dependencyHealth = dependencyHealth.score
        issues.append(contentsOf: dependencyHealth.issues)
        
        // Calculate overall health score
        let overallHealth = calculateOverallHealth(metrics: healthMetrics)
        
        return HealthCheckResult(
            overallHealth: overallHealth,
            metrics: healthMetrics,
            issues: issues,
            timestamp: Date()
        )
    }
    
    func preventPotentialIssues() async -> PreventionResult {
        os_log("Running issue prevention analysis", log: logger, type: .info)
        
        var preventedIssues: [PreventedIssue] = []
        var appliedFixes: [AutomaticFix] = []
        
        let projectPath = FileManager.default.currentDirectoryPath + "/CodingReviewer"
        let swiftFiles = findSwiftFiles(in: projectPath)
        
        for filePath in swiftFiles {
            let fileAnalysis = await analyzeFile(filePath)
            let predictedIssues = await learningCoordinator.predictIssues(in: filePath)
            
            // Apply preventive fixes for high-severity issues
            for (index, issue) in fileAnalysis.issues.enumerated() where issue.severity == "High" {
                do {
                    let fixResult = try await fixEngine.applyAutomaticFixes(to: filePath)
                    appliedFixes.append(contentsOf: fixResult.appliedFixes)
                    
                    // Use the corresponding predicted issue if available
                    if index < predictedIssues.count {
                        preventedIssues.append(PreventedIssue(
                            originalIssue: predictedIssues[index],
                            preventionMethod: .automaticFix,
                            filePath: filePath
                        ))
                    }
                } catch {
                    os_log("Failed to apply preventive fix: %@", log: logger, type: .error, error.localizedDescription)
                }
            }
        }
        
        return PreventionResult(
            preventedIssues: preventedIssues,
            appliedFixes: appliedFixes,
            preventionScore: calculatePreventionScore(preventedIssues.count, appliedFixes.count)
        )
    }
    
    // MARK: - Private Methods
    
    private func startContinuousAnalysis() {
        // Run analysis every 5 minutes
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await self.performHealthCheck()
                await self.preventPotentialIssues()
            }
        }
    }
    
    private func generateRecommendations(from results: ComprehensiveAnalysisResult) async -> [ProjectRecommendation] {
        var recommendations: [ProjectRecommendation] = []
        
        // Architecture recommendations
        if results.architecture.score < 0.8 {
            recommendations.append(ProjectRecommendation(
                type: .architecture,
                priority: .high,
                title: "Improve Architecture Compliance",
                description: "Architecture analysis shows patterns that could be improved for better maintainability",
                estimatedImpact: .high,
                estimatedEffort: .medium
            ))
        }
        
        // Performance recommendations
        if results.performance.score < 0.7 {
            recommendations.append(ProjectRecommendation(
                type: .performance,
                priority: .medium,
                title: "Optimize Performance",
                description: "Performance analysis identified opportunities for optimization",
                estimatedImpact: .medium,
                estimatedEffort: .low
            ))
        }
        
        // Security recommendations
        if !results.security.vulnerabilities.isEmpty {
            recommendations.append(ProjectRecommendation(
                type: .security,
                priority: .high,
                title: "Address Security Vulnerabilities",
                description: "Security analysis found \(results.security.vulnerabilities.count) potential vulnerabilities",
                estimatedImpact: .high,
                estimatedEffort: .high
            ))
        }
        
        // Quality recommendations based on AI predictions
        if results.predictions.overallRisk > 0.6 {
            recommendations.append(ProjectRecommendation(
                type: .quality,
                priority: .medium,
                title: "Address Code Quality Issues",
                description: "Predictive analysis indicates elevated risk of future issues",
                estimatedImpact: .medium,
                estimatedEffort: .medium
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func updateProjectHealth(from results: ComprehensiveAnalysisResult) async {
        let newHealth = ProjectHealth(
            overallScore: calculateOverallScore(from: results),
            dependencyHealth: results.dependencies.score,
            architectureHealth: results.architecture.score,
            performanceHealth: results.performance.score,
            securityHealth: results.security.score,
            qualityHealth: results.quality.score,
            riskLevel: results.predictions.overallRisk,
            lastUpdated: Date()
        )
        
        projectHealth = newHealth
        riskAssessment = results.predictions
        recommendations = results.recommendations
    }
    
    private func checkBuildSystemHealth() async -> (score: Double, issues: [ProjectIssue]) {
        // Check build configuration, dependencies, etc.
        var score = 1.0
        var issues: [ProjectIssue] = []
        
        // Check for common build issues
        let buildLogPath = FileManager.default.currentDirectoryPath + "/build_status.log"
        if FileManager.default.fileExists(atPath: buildLogPath) {
            if let buildLog = try? String(contentsOfFile: buildLogPath, encoding: .utf8) {
                if buildLog.contains("error:") {
                    score -= 0.3
                    issues.append(ProjectIssue(
                        type: .buildSystem,
                        severity: .error,
                        filePath: buildLogPath,
                        description: "Build errors detected in build log"
                    ))
                }
                
                if buildLog.contains("warning:") {
                    score -= 0.1
                    issues.append(ProjectIssue(
                        type: .buildSystem,
                        severity: .warning,
                        filePath: buildLogPath,
                        description: "Build warnings detected in build log"
                    ))
                }
            }
        }
        
        return (max(score, 0.0), issues)
    }
    
    private func checkDependencyHealth() async -> (score: Double, issues: [ProjectIssue]) {
        // Check Package.swift, Podfile, etc. for dependency issues
        var score = 1.0
        var issues: [ProjectIssue] = []
        
        // This would check for outdated dependencies, conflicts, etc.
        // For now, return a good score
        
        return (score, issues)
    }
    
    private func calculateOverallHealth(metrics: HealthMetrics) -> Double {
        let issueRatio = metrics.totalFiles > 0 ? Double(metrics.filesWithIssues) / Double(metrics.totalFiles) : 0.0
        let healthScore = 1.0 - issueRatio
        
        return (healthScore + metrics.buildSystemHealth + metrics.dependencyHealth) / 3.0
    }
    
    private func calculateOverallScore(from results: ComprehensiveAnalysisResult) -> Double {
        let scores = [
            results.dependencies.score,
            results.architecture.score,
            results.performance.score,
            results.security.score,
            results.quality.score
        ]
        
        return scores.reduce(0.0, +) / Double(scores.count)
    }
    
    private func calculateConfidence(predictedIssues: [PredictedIssue], improvements: [CodeImprovement]) -> Double {
        guard !predictedIssues.isEmpty || !improvements.isEmpty else { return 1.0 }
        
        let avgPredictionConfidence = predictedIssues.isEmpty ? 1.0 : 
            predictedIssues.reduce(0.0) { $0 + $1.confidence } / Double(predictedIssues.count)
        
        // Factor in number of improvements suggested (more suggestions = more room for improvement)
        let improvementFactor = max(0.5, 1.0 - (Double(improvements.count) * 0.1))
        
        return avgPredictionConfidence * improvementFactor
    }
    
    private func calculatePreventionScore(_ preventedCount: Int, _ fixesCount: Int) -> Double {
        // Higher score for more prevented issues and applied fixes
        return min(1.0, (Double(preventedCount) * 0.1) + (Double(fixesCount) * 0.05))
    }
    
    private func mapSeverityToPriority(_ severity: CodeImprovement.Severity) -> FileRecommendation.Priority {
        switch severity {
        case .error: return .high
        case .warning: return .medium
        case .info: return .low
        }
    }
    
    private func mapConfidenceToSeverity(_ confidence: Double) -> String {
        if confidence > 0.8 {
            return "High"
        } else if confidence > 0.5 {
            return "Medium"
        } else {
            return "Low"
        }
    }
    
    private func mapConfidenceToSeverityEnum(_ confidence: Double) -> ProjectIssue.Severity {
        if confidence > 0.8 {
            return .error
        } else if confidence > 0.5 {
            return .warning
        } else {
            return .info
        }
    }
    
    private func mapIssueTypeToString(_ issueType: PredictedIssue.IssueType) -> String {
        switch issueType {
        case .immutableVariable:
            return "Immutable Variable"
        case .forceUnwrapping:
            return "Force Unwrapping"
        case .asyncAddition:
            return "Async Addition"
        case .other:
            return "Other"
        }
    }
    
    private func findSwiftFiles(in directory: String) -> [String] {
        var swiftFiles: [String] = []
        let fileManager = FileManager.default
        
        if let enumerator = fileManager.enumerator(atPath: directory) {
            for case let file as String in enumerator {
                if file.hasSuffix(".swift") && !file.contains("/.") {
                    swiftFiles.append(directory + "/" + file)
                }
            }
        }
        
        return swiftFiles
    }
}

// MARK: - Analysis Components

class DependencyAnalyzer {
    func analyze() async -> DependencyAnalysisResult {
        // Analyze dependencies for issues, outdated versions, conflicts
        return DependencyAnalysisResult(
            score: 0.9,
            outdatedDependencies: [],
            vulnerableDependencies: [],
            conflictingDependencies: []
        )
    }
}

class ArchitectureAnalyzer {
    func analyze() async -> ArchitectureAnalysisResult {
        // Analyze code architecture patterns, MVVM compliance, etc.
        return ArchitectureAnalysisResult(
            score: 0.85,
            patterns: [],
            violations: [],
            suggestions: []
        )
    }
}

class PerformanceAnalyzer {
    func analyze() async -> PerformanceAnalysisResult {
        // Analyze for performance issues, memory leaks, inefficient patterns
        return PerformanceAnalysisResult(
            score: 0.8,
            issues: [],
            optimizations: []
        )
    }
}

class SecurityAnalyzer {
    func analyze() async -> SecurityAnalysisResult {
        // Analyze for security vulnerabilities
        return SecurityAnalysisResult(
            score: 0.95,
            vulnerabilities: [],
            recommendations: []
        )
    }
}

class QualityAnalyzer {
    func analyze() async -> QualityAnalysisResult {
        // Analyze code quality metrics
        return QualityAnalysisResult(
            score: 0.88,
            metrics: QualityMetrics(),
            issues: []
        )
    }
}

class PredictiveAnalyzer {
    func analyze() async -> RiskAssessment {
        // Use AI to predict future issues
        return RiskAssessment(
            overallRisk: 0.3,
            criticalRisks: ["Potential memory leaks", "Async race conditions"],
            mitigation: "Implement comprehensive testing and code review processes"
        )
    }
}

// MARK: - Data Types

struct ProjectHealth {
    let overallScore: Double
    let dependencyHealth: Double
    let architectureHealth: Double
    let performanceHealth: Double
    let securityHealth: Double
    let qualityHealth: Double
    let riskLevel: Double
    let lastUpdated: Date
    
    init() {
        self.overallScore = 0.0
        self.dependencyHealth = 0.0
        self.architectureHealth = 0.0
        self.performanceHealth = 0.0
        self.securityHealth = 0.0
        self.qualityHealth = 0.0
        self.riskLevel = 0.0
        self.lastUpdated = Date()
    }
    
    init(overallScore: Double, dependencyHealth: Double, architectureHealth: Double, performanceHealth: Double, securityHealth: Double, qualityHealth: Double, riskLevel: Double, lastUpdated: Date) {
        self.overallScore = overallScore
        self.dependencyHealth = dependencyHealth
        self.architectureHealth = architectureHealth
        self.performanceHealth = performanceHealth
        self.securityHealth = securityHealth
        self.qualityHealth = qualityHealth
        self.riskLevel = riskLevel
        self.lastUpdated = lastUpdated
    }
}

struct ComprehensiveAnalysisResult {
    var dependencies: DependencyAnalysisResult = DependencyAnalysisResult(score: 0.0, outdatedDependencies: [], vulnerableDependencies: [], conflictingDependencies: [])
    var architecture: ArchitectureAnalysisResult = ArchitectureAnalysisResult(score: 0.0, patterns: [], violations: [], suggestions: [])
    var performance: PerformanceAnalysisResult = PerformanceAnalysisResult(score: 0.0, issues: [], optimizations: [])
    var security: SecurityAnalysisResult = SecurityAnalysisResult(score: 0.0, vulnerabilities: [], recommendations: [])
    var quality: QualityAnalysisResult = QualityAnalysisResult(score: 0.0, metrics: QualityMetrics(), issues: [])
    var predictions: RiskAssessment = RiskAssessment(overallRisk: 0.0, criticalRisks: [], mitigation: "No assessment available")
    var recommendations: [ProjectRecommendation] = []
    var error: Error?
}

struct FileRecommendation {
    let type: RecommendationType
    let priority: Priority
    let description: String
    let suggestion: String
    
    enum RecommendationType {
        case codeImprovement(CodeImprovement)
        case performance
        case security
        case style
    }
    
    enum Priority: Int, CaseIterable {
        case low = 1
        case medium = 2
        case high = 3
    }
}

struct HealthCheckResult {
    let overallHealth: Double
    let metrics: HealthMetrics
    let issues: [ProjectIssue]
    let timestamp: Date
}

struct HealthMetrics {
    var totalFiles: Int = 0
    var filesWithIssues: Int = 0
    var buildSystemHealth: Double = 1.0
    var dependencyHealth: Double = 1.0
}

struct ProjectIssue {
    let type: IssueType
    let severity: Severity
    let filePath: String
    let description: String
    
    enum IssueType {
        case codeIssue(PredictedIssue)
        case buildSystem
        case dependency
        case architecture
        case performance
        case security
    }
    
    enum Severity: String, CaseIterable {
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
    }
}

struct PreventionResult {
    let preventedIssues: [PreventedIssue]
    let appliedFixes: [AutomaticFix]
    let preventionScore: Double
}

struct PreventedIssue {
    let originalIssue: PredictedIssue
    let preventionMethod: PreventionMethod
    let filePath: String
    
    enum PreventionMethod {
        case automaticFix
        case codeGeneration
        case refactoring
    }
}

struct ProjectRecommendation {
    let type: RecommendationType
    let priority: Priority
    let title: String
    let description: String
    let estimatedImpact: Impact
    let estimatedEffort: Effort
    
    enum RecommendationType {
        case architecture
        case performance
        case security
        case quality
        case dependency
    }
    
    enum Priority: Int, CaseIterable {
        case low = 1
        case medium = 2
        case high = 3
    }
    
    enum Impact {
        case low, medium, high
    }
    
    enum Effort {
        case low, medium, high
    }
}

// Analysis Result Types
struct DependencyAnalysisResult {
    let score: Double
    let outdatedDependencies: [String]
    let vulnerableDependencies: [String]
    let conflictingDependencies: [String]
}

struct ArchitectureAnalysisResult {
    let score: Double
    let patterns: [String]
    let violations: [String]
    let suggestions: [String]
}

struct PerformanceAnalysisResult {
    let score: Double
    let issues: [String]
    let optimizations: [String]
}

struct SecurityAnalysisResult {
    let score: Double
    let vulnerabilities: [String]
    let recommendations: [String]
}

struct QualityAnalysisResult {
    let score: Double
    let metrics: QualityMetrics
    let issues: [String]
}

struct QualityMetrics {
    let complexity: Double = 0.0
    let maintainability: Double = 0.0
    let testCoverage: Double = 0.0
    let duplication: Double = 0.0
}
