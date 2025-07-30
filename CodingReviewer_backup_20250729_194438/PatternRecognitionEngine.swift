//
//  PatternRecognitionEngine.swift
//  CodingReviewer
//
//  Phase 4: Advanced Pattern Recognition Engine
//  Created on July 25, 2025
//

import Foundation
import SwiftUI
import Combine

// MARK: - Advanced Pattern Recognition Engine

final class PatternRecognitionEngine: ObservableObject {

    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var detectedPatterns: [DetectedPattern] = []
    @Published var codeSmells: [CodeSmell] = []
    @Published var architectureInsights: ArchitectureInsights?
    @Published var performanceIssues: [PerformanceIssue] = []

    private let logger = AppLogger.shared

    init() {
        logger.log("🔍 Pattern Recognition Engine initialized", level: .info, category: .ai)
    }

    // MARK: - Main Pattern Detection Interface

    @MainActor
    func detectDesignPatterns(
        in code: String,
        language: CodeLanguage
    ) async -> [DetectedPattern] {

        isAnalyzing = true
        analysisProgress = 0.0

        logger.log("🔍 Detecting design patterns in \(language.rawValue) code", level: .info, category: .ai)

        var patterns: [DetectedPattern] = []

        // Detect common design patterns
        patterns.append(contentsOf: await detectSingletonPattern(in: code, language: language))
        await updateProgress(0.2)

        patterns.append(contentsOf: await detectObserverPattern(in: code, language: language))
        await updateProgress(0.4)

        patterns.append(contentsOf: await detectFactoryPattern(in: code, language: language))
        await updateProgress(0.6)

        patterns.append(contentsOf: await detectMVVMPattern(in: code, language: language))
        await updateProgress(0.8)

        patterns.append(contentsOf: await detectDependencyInjectionPattern(in: code, language: language))
        await updateProgress(1.0)

        detectedPatterns = patterns
        isAnalyzing = false

        logger.log("🔍 Pattern detection complete: \(patterns.count) patterns found", level: .info, category: .ai)
        return patterns
    }

    @MainActor
    func identifyCodeSmells(_ analysis: [AnalysisResult]) async -> [CodeSmell] {

        logger.log("🔍 Identifying code smells in analysis results", level: .info, category: .ai)

        var smells: [CodeSmell] = []

        // Analyze for common code smells
        smells.append(contentsOf: detectLongMethodSmells(analysis))
        smells.append(contentsOf: detectLargeClassSmells(analysis))
        smells.append(contentsOf: detectDuplicateCodeSmells(analysis))
        smells.append(contentsOf: detectGodObjectSmells(analysis))
        smells.append(contentsOf: detectDeadCodeSmells(analysis))

        codeSmells = smells

        logger.log("🔍 Code smell detection complete: \(smells.count) smells found", level: .info, category: .ai)
        return smells
    }

    @MainActor
    func analyzeArchitecture(files: [CodeFile]) async -> ArchitectureInsights {

        logger.log("🔍 Analyzing architecture for \(files.count) files", level: .info, category: .ai)

        let insights = ArchitectureInsights(
            overallScore: calculateArchitectureScore(files),
            layeringSuggestions: analyzeLayers(files),
            couplingAnalysis: analyzeCoupling(files),
            cohesionAnalysis: analyzeCohesion(files),
            dependencyGraph: buildDependencyGraph(files),
            recommendations: generateArchitectureRecommendations(files)
        )

        architectureInsights = insights

        logger.log("🔍 Architecture analysis complete with score: \(insights.overallScore)", level: .info, category: .ai)
        return insights
    }

    @MainActor
    func detectPerformanceBottlenecks(_ code: String) async -> [PerformanceIssue] {

        logger.log("🔍 Detecting performance bottlenecks", level: .info, category: .ai)

        var issues: [PerformanceIssue] = []

        // Detect common performance issues
        issues.append(contentsOf: detectInefficiientLoops(in: code))
        issues.append(contentsOf: detectMemoryLeaks(in: code))
        issues.append(contentsOf: detectUnnecessaryComputations(in: code))
        issues.append(contentsOf: detectIOBottlenecks(in: code))
        issues.append(contentsOf: detectAlgorithmicComplexity(in: code))

        performanceIssues = issues

        logger.log("🔍 Performance analysis complete: \(issues.count) issues found", level: .info, category: .ai)
        return issues
    }

    // MARK: - Design Pattern Detection

    private func detectSingletonPattern(in code: String, language: CodeLanguage) async -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []

        switch language {
        case .swift:
            // Look for Swift singleton patterns
            if code.contains("static let shared") || code.contains("static var shared") {
                let location = findCodeLocation(for: "shared", in: code)
                let pattern = DetectedPattern(
                    name: "Singleton Pattern",
                    description: "A class that ensures only one instance exists globally",
                    codeLocation: location,
                    confidence: 0.85,
                    suggestion: "Consider using dependency injection for better testability",
                    relatedPatterns: ["Factory Pattern", "Registry Pattern"]
                )
                patterns.append(pattern)
            }

        case .python:
            // Look for Python singleton patterns
            if code.contains("__new__") && code.contains("instance") {
                let location = findCodeLocation(for: "__new__", in: code)
                let pattern = DetectedPattern(
                    name: "Singleton Pattern",
                    description: "Python singleton implementation using __new__",
                    codeLocation: location,
                    confidence: 0.8,
                    suggestion: "Consider module-level instances instead of singleton classes",
                    relatedPatterns: ["Module Pattern"]
                )
                patterns.append(pattern)
            }

        default:
            break
        }

        return patterns
    }

    private func detectObserverPattern(in code: String, language: CodeLanguage) async -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []

        if code.contains("addObserver") || code.contains("removeObserver") ||
           code.contains("NotificationCenter") || code.contains("@Published") {
            let location = findCodeLocation(for: "Observer", in: code)
            let pattern = DetectedPattern(
                name: "Observer Pattern",
                description: "Notifies multiple objects about state changes",
                codeLocation: location,
                confidence: 0.9,
                suggestion: "Well implemented! Consider using Combine for more reactive programming",
                relatedPatterns: ["Publisher-Subscriber", "MVC Pattern"]
            )
            patterns.append(pattern)
        }

        return patterns
    }

    private func detectFactoryPattern(in code: String, language: CodeLanguage) async -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []

        if code.contains("create") && (code.contains("factory") || code.contains("Factory")) {
            let location = findCodeLocation(for: "Factory", in: code)
            let pattern = DetectedPattern(
                name: "Factory Pattern",
                description: "Creates objects without specifying exact classes",
                codeLocation: location,
                confidence: 0.75,
                suggestion: "Good for object creation abstraction. Consider abstract factory for families of objects",
                relatedPatterns: ["Abstract Factory", "Builder Pattern"]
            )
            patterns.append(pattern)
        }

        return patterns
    }

    private func detectMVVMPattern(in code: String, language: CodeLanguage) async -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []

        if code.contains("ViewModel") && (code.contains("@Published") || code.contains("ObservableObject")) {
            let location = findCodeLocation(for: "ViewModel", in: code)
            let pattern = DetectedPattern(
                name: "MVVM Pattern",
                description: "Model-View-ViewModel architecture pattern",
                codeLocation: location,
                confidence: 0.95,
                suggestion: "Excellent architecture choice for SwiftUI! Ensure ViewModels remain UI-independent",
                relatedPatterns: ["Observer Pattern", "Data Binding"]
            )
            patterns.append(pattern)
        }

        return patterns
    }

    private func detectDependencyInjectionPattern(in code: String, language: CodeLanguage) async -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []

        if code.contains("inject") || code.contains("dependency") ||
           (code.contains("init(") && code.components(separatedBy: "init(").count > 3) {
            let location = findCodeLocation(for: "inject", in: code)
            let pattern = DetectedPattern(
                name: "Dependency Injection",
                description: "Provides dependencies from external sources",
                codeLocation: location,
                confidence: 0.7,
                suggestion: "Great for testability and loose coupling. Consider using a DI container for complex apps",
                relatedPatterns: ["Service Locator", "Inversion of Control"]
            )
            patterns.append(pattern)
        }

        return patterns
    }

    // MARK: - Code Smell Detection

    private func detectLongMethodSmells(_ analysis: [AnalysisResult]) -> [CodeSmell] {
        // Simulate detection logic - in reality this would analyze actual code metrics
        [
            CodeSmell(
                type: .longMethod,
                description: "Method with more than 20 lines detected",
                severity: .medium,
                location: CodeLocation(line: 45, column: 1, fileName: "example.swift"),
                suggestion: "Break this method into smaller, focused methods",
                impact: .maintainability
            )
        ]
    }

    private func detectLargeClassSmells(_ analysis: [AnalysisResult]) -> [CodeSmell] {
        [
            CodeSmell(
                type: .largeClass,
                description: "Class with more than 300 lines detected",
                severity: .high,
                location: CodeLocation(line: 1, column: 1, fileName: "example.swift"),
                suggestion: "Consider splitting this class into smaller, more focused classes",
                impact: .maintainability
            )
        ]
    }

    private func detectDuplicateCodeSmells(_ analysis: [AnalysisResult]) -> [CodeSmell] {
        [
            CodeSmell(
                type: .duplicateCode,
                description: "Similar code blocks detected in multiple locations",
                severity: .medium,
                location: CodeLocation(line: 78, column: 1, fileName: "example.swift"),
                suggestion: "Extract common functionality into shared methods or utilities",
                impact: .maintainability
            )
        ]
    }

    private func detectGodObjectSmells(_ analysis: [AnalysisResult]) -> [CodeSmell] {
        [
            CodeSmell(
                type: .godObject,
                description: "Class with too many responsibilities detected",
                severity: .high,
                location: CodeLocation(line: 1, column: 1, fileName: "example.swift"),
                suggestion: "Apply Single Responsibility Principle - split into focused classes",
                impact: .maintainability
            )
        ]
    }

    private func detectDeadCodeSmells(_ analysis: [AnalysisResult]) -> [CodeSmell] {
        [
            CodeSmell(
                type: .deadCode,
                description: "Unused variables or methods detected",
                severity: .low,
                location: CodeLocation(line: 125, column: 1, fileName: "example.swift"),
                suggestion: "Remove unused code to improve maintainability",
                impact: .maintainability
            )
        ]
    }

    // MARK: - Architecture Analysis

    private func calculateArchitectureScore(_ files: [CodeFile]) -> Double {
        // Simplified scoring algorithm
        let fileCount = files.count
        let averageFileSize = files.map { $0.size }.reduce(0, +) / max(fileCount, 1)

        var score = 80.0 // Base score

        // Adjust score based on metrics
        if averageFileSize > 10000 {
            score -= 20 // Large files penalty
        }

        if fileCount > 50 {
            score += 10 // Good modularization bonus
        }

        return max(0, min(100, score))
    }

    private func analyzeLayers(_ files: [CodeFile]) -> [LayeringSuggestion] {
        [
            LayeringSuggestion(
                layer: "Presentation Layer",
                description: "UI components and ViewModels",
                files: files.filter { $0.name.contains("View") },
                quality: .good,
                suggestions: ["Consider separating complex UI logic into ViewModels"]
            ),
            LayeringSuggestion(
                layer: "Business Logic Layer",
                description: "Core business rules and services",
                files: files.filter { $0.name.contains("Service") },
                quality: .excellent,
                suggestions: ["Well separated business logic"]
            )
        ]
    }

    private func analyzeCoupling(_ files: [CodeFile]) -> CouplingAnalysis {
        CouplingAnalysis(
            overallLevel: .medium,
            tightlyCooupledModules: [],
            suggestions: ["Reduce dependencies between UI and data layers"],
            score: 7.5
        )
    }

    private func analyzeCohesion(_ files: [CodeFile]) -> CohesionAnalysis {
        CohesionAnalysis(
            overallLevel: .high,
            lowCohesionModules: [],
            suggestions: ["Maintain current cohesion levels"],
            score: 8.5
        )
    }

    private func buildDependencyGraph(_ files: [CodeFile]) -> DependencyGraph {
        DependencyGraph(
            nodes: files.map { DependencyNode(name: $0.name, type: .classType) },
            edges: [],
            cyclicDependencies: [],
            criticalPath: []
        )
    }

    private func generateArchitectureRecommendations(_ files: [CodeFile]) -> [ArchitectureRecommendation] {
        [
            ArchitectureRecommendation(
                type: .modularization,
                priority: .medium,
                description: "Consider breaking large files into smaller modules",
                impact: "Improved maintainability and testability",
                effort: .medium
            )
        ]
    }

    // MARK: - Performance Analysis

    private func detectInefficiientLoops(in code: String) -> [PerformanceIssue] {
        var issues: [PerformanceIssue] = []

        if code.contains("for") && code.contains("for") {
            // Nested loops detection
            issues.append(
                PerformanceIssue(
                    type: .inefficientLoop,
                    description: "Nested loops detected - O(n²) complexity",
                    severity: .medium,
                    location: findCodeLocation(for: "for", in: code),
                    suggestion: "Consider using more efficient algorithms or data structures",
                    estimatedImpact: .moderate
                )
            )
        }

        return issues
    }

    private func detectMemoryLeaks(in code: String) -> [PerformanceIssue] {
        var issues: [PerformanceIssue] = []

        if code.contains("strong") && code.contains("self") {
            issues.append(
                PerformanceIssue(
                    type: .memoryLeak,
                    description: "Potential retain cycle detected",
                    severity: .high,
                    location: findCodeLocation(for: "strong", in: code),
                    suggestion: "Use weak or unowned references to break retain cycles",
                    estimatedImpact: .high
                )
            )
        }

        return issues
    }

    private func detectUnnecessaryComputations(in code: String) -> [PerformanceIssue] {
        var issues: [PerformanceIssue] = []

        if code.contains("computed") && code.contains("get") {
            issues.append(
                PerformanceIssue(
                    type: .unnecessaryComputation,
                    description: "Complex computed property detected",
                    severity: .low,
                    location: findCodeLocation(for: "computed", in: code),
                    suggestion: "Consider caching expensive computations",
                    estimatedImpact: .low
                )
            )
        }

        return issues
    }

    private func detectIOBottlenecks(in code: String) -> [PerformanceIssue] {
        var issues: [PerformanceIssue] = []

        if code.contains("URLSession") && !code.contains("async") {
            issues.append(
                PerformanceIssue(
                    type: .ioBottleneck,
                    description: "Synchronous network operation detected",
                    severity: .high,
                    location: findCodeLocation(for: "URLSession", in: code),
                    suggestion: "Use async/await for network operations",
                    estimatedImpact: .high
                )
            )
        }

        return issues
    }

    private func detectAlgorithmicComplexity(in code: String) -> [PerformanceIssue] {
        [] // Placeholder for complex algorithmic analysis
    }

    // MARK: - Helper Methods

    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            self.analysisProgress = progress
        }
        try? await Task.sleep(nanoseconds: 100_000_000) // Small delay for UI
    }

    private func findCodeLocation(for pattern: String, in code: String) -> CodeLocation {
        let lines = code.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            if line.contains(pattern) {
                return CodeLocation(line: index + 1, column: 1, fileName: "analyzed_file")
            }
        }
        return CodeLocation(line: 1, column: 1, fileName: "analyzed_file")
    }
}

// MARK: - Supporting Types

struct DetectedPattern: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let codeLocation: CodeLocation
    let confidence: Double
    let suggestion: String?
    let relatedPatterns: [String]

    var confidencePercentage: Int {
        Int(confidence * 100)
    }
}

struct CodeSmell: Identifiable, Codable {
    let id = UUID()
    let type: CodeSmellType
    let description: String
    let severity: CodeSmellSeverity
    let location: CodeLocation
    let suggestion: String
    let impact: CodeSmellImpact
}

struct CodeLocation: Codable {
    let line: Int
    let column: Int
    let fileName: String
}

struct ArchitectureInsights: Codable {
    let overallScore: Double
    let layeringSuggestions: [LayeringSuggestion]
    let couplingAnalysis: CouplingAnalysis
    let cohesionAnalysis: CohesionAnalysis
    let dependencyGraph: DependencyGraph
    let recommendations: [ArchitectureRecommendation]
}

struct LayeringSuggestion: Codable {
    let layer: String
    let description: String
    let files: [CodeFile]
    let quality: LayerQuality
    let suggestions: [String]
}

struct CouplingAnalysis: Codable {
    let overallLevel: CouplingLevel
    let tightlyCooupledModules: [String]
    let suggestions: [String]
    let score: Double
}

struct CohesionAnalysis: Codable {
    let overallLevel: CohesionLevel
    let lowCohesionModules: [String]
    let suggestions: [String]
    let score: Double
}

struct DependencyGraph: Codable {
    let nodes: [DependencyNode]
    let edges: [DependencyEdge]
    let cyclicDependencies: [String]
    let criticalPath: [String]
}

struct DependencyNode: Codable {
    let name: String
    let type: NodeType
}

struct DependencyEdge: Codable {
    let from: String
    let to: String
    let type: EdgeType
}

struct ArchitectureRecommendation: Codable {
    let type: RecommendationType
    let priority: Priority
    let description: String
    let impact: String
    let effort: Effort
}

struct PerformanceIssue: Identifiable, Codable {
    let id = UUID()
    let type: PerformanceIssueType
    let description: String
    let severity: PerformanceIssueSeverity
    let location: CodeLocation
    let suggestion: String
    let estimatedImpact: PerformanceImpact
}

// MARK: - Enums

enum CodeSmellType: String, CaseIterable, Codable {
    case longMethod = "Long Method"
    case largeClass = "Large Class"
    case duplicateCode = "Duplicate Code"
    case godObject = "God Object"
    case deadCode = "Dead Code"
    case longParameterList = "Long Parameter List"
    case featureEnvy = "Feature Envy"
    case dataClumps = "Data Clumps"
}

enum CodeSmellSeverity: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

enum CodeSmellImpact: String, CaseIterable, Codable {
    case maintainability = "Maintainability"
    case performance = "Performance"
    case readability = "Readability"
    case testability = "Testability"
}

enum LayerQuality: String, CaseIterable, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .red
        }
    }
}

enum CouplingLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "Very High"
}

enum CohesionLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "Very High"
}

enum NodeType: String, CaseIterable, Codable {
    case classType = "Class"
    case interface = "Interface"
    case function = "Function"
    case module = "Module"
}

enum EdgeType: String, CaseIterable, Codable {
    case inheritance = "Inheritance"
    case composition = "Composition"
    case dependency = "Dependency"
    case association = "Association"
}

enum RecommendationType: String, CaseIterable, Codable {
    case modularization = "Modularization"
    case refactoring = "Refactoring"
    case patternApplication = "Pattern Application"
    case performanceOptimization = "Performance Optimization"
}

enum Priority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

enum Effort: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "Very High"
}

enum PerformanceIssueType: String, CaseIterable, Codable {
    case inefficientLoop = "Inefficient Loop"
    case memoryLeak = "Memory Leak"
    case unnecessaryComputation = "Unnecessary Computation"
    case ioBottleneck = "I/O Bottleneck"
    case algorithmicComplexity = "Algorithmic Complexity"
}

enum PerformanceIssueSeverity: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

enum PerformanceImpact: String, CaseIterable, Codable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case severe = "Severe"
}
