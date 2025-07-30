// SECURITY: API key handling - ensure proper encryption and keychain storage
//
// IntelligentFixGenerator.swift
// CodingReviewer
//
// Phase 4: Intelligent Fix Generation System
// Created on July 25, 2025
//

import Foundation
import SwiftUI
import Combine

// MARK: - Intelligent Fix Generation System

final class IntelligentFixGenerator: ObservableObject {

    @Published var isGeneratingFixes = false
    @Published var fixGenerationProgress: Double = 0.0
    @Published var generatedFixes: [IntelligentFix] = []

    private let logger = AppLogger.shared

    init() {
        logger.log("🔧 Intelligent Fix Generator initialized", level: .info, category: .ai)
    }

    // MARK: - Main Fix Generation Interface

    @MainActor
    func generateFixes(
        for analysis: EnhancedAnalysisResult,
        context: CodeContext
    ) async throws -> [IntelligentFix] {

        isGeneratingFixes = true
        fixGenerationProgress = 0.0

        logger.log("🔧 Generating intelligent fixes for \(analysis.fileName)", level: .info, category: .ai)

        var fixes: [IntelligentFix] = []

        // Generate different types of fixes based on analysis
        let securityFixes = generateSecurityFixes(analysis: analysis, context: context)
        await updateProgress(0.25)

        let performanceFixes = generatePerformanceFixes(analysis: analysis, context: context)
        await updateProgress(0.50)

        let styleFixes = generateStyleFixes(analysis: analysis, context: context)
        await updateProgress(0.75)

        let logicFixes = generateLogicFixes(analysis: analysis, context: context)
        await updateProgress(1.0)

        fixes.append(contentsOf: securityFixes)
        fixes.append(contentsOf: performanceFixes)
        fixes.append(contentsOf: styleFixes)
        fixes.append(contentsOf: logicFixes)

        // Sort by confidence and impact
        let sortedFixes = fixes.sorted { $0.confidence > $1.confidence }

        generatedFixes = sortedFixes
        isGeneratingFixes = false

        logger.log("✅ Generated \(fixes.count) intelligent fixes", level: .info, category: .ai)

        return sortedFixes
    }

    // MARK: - Fix Application

    func applyFix(_ fix: IntelligentFix, to code: String) throws -> String {
        let lines = code.components(separatedBy: .newlines)

        guard fix.startLine >= 0 && fix.startLine < lines.count else {
            throw FixApplicationError.invalidLineRange
        }

        var modifiedLines = lines

        // Handle single-line fixes
        if fix.startLine == fix.endLine {
            modifiedLines[fix.startLine] = fix.fixedCode
        } else {
            // Handle multi-line fixes
            let lineRange = fix.startLine...min(fix.endLine, lines.count - 1)
            modifiedLines.removeSubrange(lineRange)

            let fixedLines = fix.fixedCode.components(separatedBy: .newlines)
            modifiedLines.insert(contentsOf: fixedLines, at: fix.startLine)
        }

        return modifiedLines.joined(separator: "\n")
    }

    func validateFix(_ fix: IntelligentFix, in context: CodeContext) async -> FixValidation {
        // Simulate validation logic
        let isValid = fix.confidence > 0.7
        let compilationCheck = await performCompilationCheck(fix: fix, context: context)

        return FixValidation(
            isValid: isValid && compilationCheck.passes,
            confidence: fix.confidence,
            compilationCheck: compilationCheck,
            potentialIssues: compilationCheck.passes ? [] : ["Compilation may fail"],
            recommendation: isValid ? .apply : .review
        )
    }

    // MARK: - Security Fixes

    private func generateSecurityFixes(
        analysis: EnhancedAnalysisResult,
        context: CodeContext
    ) -> [IntelligentFix] {

        var fixes: [IntelligentFix] = []
        let code = context.originalCode

        // Force unwrapping fixes for Swift
        if analysis.language == "swift" && code.contains("!") {
            fixes.append(contentsOf: generateForceUnwrappingFixes(code: code, context: context))
        }

        // SQL injection fixes
        if code.contains("SELECT") && code.contains("+") {
            fixes.append(contentsOf: generateSQLInjectionFixes(code: code, context: context))
        }

        // Hardcoded credentials fixes
        if containsHardcodedCredentials(code) {
            fixes.append(contentsOf: generateCredentialFixes(code: code, context: context))
        }

        return fixes
    }

    private func generateForceUnwrappingFixes(code: String, context: CodeContext) -> [IntelligentFix] {
        var fixes: [IntelligentFix] = []
        let lines = code.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            if line.contains("!") && !line.contains("// ") {
                // Find force unwrapping patterns
                if let range = line.range(of: #"(\w+)!"#, options: .regularExpression) {
                    let variableName = String(line[range]).dropLast()
                    let safeFix = line.replacingOccurrences(of: "\(variableName)!", with: "\(variableName) ?? defaultValue")

                    let fix = IntelligentFix(
                        id: UUID(),
                        description: "Replace force unwrapping with nil coalescing for safer code",
                        originalCode: line.trimmingCharacters(in: .whitespaces),
                        fixedCode: safeFix,
                        startLine: index,
                        endLine: index,
                        confidence: 0.85,
                        category: .security,
                        explanation: "Force unwrapping can cause runtime crashes. Using nil coalescing (??) provides a safer alternative with a default value.",
                        impact: .medium
                    )

                    fixes.append(fix)
                }
            }
        }

        return fixes
    }

    // MARK: - Performance Fixes

    private func generatePerformanceFixes(
        analysis: EnhancedAnalysisResult,
        context: CodeContext
    ) -> [IntelligentFix] {

        var fixes: [IntelligentFix] = []
        let code = context.originalCode

        // String concatenation in loops
        fixes.append(contentsOf: generateStringConcatenationFixes(code: code, context: context))

        // Inefficient collection operations
        fixes.append(contentsOf: generateCollectionOptimizationFixes(code: code, context: context))

        return fixes
    }

    private func generateStringConcatenationFixes(code: String, context: CodeContext) -> [IntelligentFix] {
        var fixes: [IntelligentFix] = []
        let lines = code.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            // Detect string concatenation in loops
            if line.contains("for ") && index + 1 < lines.count {
                let nextLine = lines[index + 1]
                if nextLine.contains("+=") && nextLine.contains("\"") {

                    let fix = IntelligentFix(
                        id: UUID(),
                        description: "Use StringBuilder/String interpolation for better performance",
                        originalCode: "\(line)\n\(nextLine)",
                        fixedCode: generateStringBuilderFix(forLoop: line, concatenation: nextLine),
                        startLine: index,
                        endLine: index + 1,
                        confidence: 0.90,
                        category: .performance,
                        explanation: "String concatenation in loops creates multiple string objects. Using StringBuilder or array joining is more efficient.",
                        impact: .high
                    )

                    fixes.append(fix)
                }
            }
        }

        return fixes
    }

    // MARK: - Style Fixes

    private func generateStyleFixes(
        analysis: EnhancedAnalysisResult,
        context: CodeContext
    ) -> [IntelligentFix] {

        var fixes: [IntelligentFix] = []
        let code = context.originalCode

        // Naming convention fixes
        fixes.append(contentsOf: generateNamingFixes(code: code, context: context))

        // Formatting fixes
        fixes.append(contentsOf: generateFormattingFixes(code: code, context: context))

        return fixes
    }

    // MARK: - Logic Fixes

    private func generateLogicFixes(
        analysis: EnhancedAnalysisResult,
        context: CodeContext
    ) -> [IntelligentFix] {

        var fixes: [IntelligentFix] = []
        let code = context.originalCode

        // Null check fixes
        fixes.append(contentsOf: generateNullCheckFixes(code: code, context: context))

        // Exception handling fixes
        fixes.append(contentsOf: generateExceptionHandlingFixes(code: code, context: context))

        return fixes
    }

    // MARK: - Helper Methods

    @MainActor
    private func updateProgress(_ progress: Double) async {
        fixGenerationProgress = progress
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second
    }

    private func containsHardcodedCredentials(_ code: String) -> Bool {
        // TODO: Replace with secure credential storage
        let patterns = [
            "password\\s*=\\s*[\"'][^\"']*[\"']",
            "key\\s*=\\s*[\"'][^\"']*[\"']",
            "token\\s*=\\s*[\"'][^\"']*[\"']",
            "secret\\s*=\\s*[\"'][^\"']*[\"']"
        ]
        return patterns.contains { pattern in
            code.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private func generateStringBuilderFix(forLoop: String, concatenation: String) -> String {
        """
        var components: [String] = []
        \(forLoop)
            components.append(/* value */)
        }
        let result = components.joined()
        """
    }

    private func generateNamingFixes(code: String, context: CodeContext) -> [IntelligentFix] {
        // Implementation for naming convention fixes
        []
    }

    private func generateFormattingFixes(code: String, context: CodeContext) -> [IntelligentFix] {
        // Implementation for formatting fixes
        []
    }

    private func generateNullCheckFixes(code: String, context: CodeContext) -> [IntelligentFix] {
        // Implementation for null check fixes
        []
    }

    private func generateExceptionHandlingFixes(code: String, context: CodeContext) -> [IntelligentFix] {
        // Implementation for exception handling fixes
        []
    }

    private func generateSQLInjectionFixes(code: String, context: CodeContext) -> [IntelligentFix] {
        // Implementation for SQL injection fixes
        []
    }

    private func generateCredentialFixes(code: String, context: CodeContext) -> [IntelligentFix] {
        // Implementation for credential fixes
        []
    }

    private func generateCollectionOptimizationFixes(code: String, context: CodeContext) -> [IntelligentFix] {
        // Implementation for collection optimization fixes
        []
    }

    private func performCompilationCheck(fix: IntelligentFix, context: CodeContext) async -> CompilationCheck {
        // Simulate compilation check
        CompilationCheck(
            passes: fix.confidence > 0.8,
            errors: [],
            warnings: [],
            duration: 0.1
        )
    }
}

// MARK: - Supporting Types

struct IntelligentFix: Identifiable, Codable {
    let id: UUID
    let description: String
    let originalCode: String
    let fixedCode: String
    let startLine: Int
    let endLine: Int
    let confidence: Double
    let category: FixCategory
    let explanation: String
    let impact: FixImpact

    var confidencePercentage: Int {
        Int(confidence * 100)
    }
}

struct CodeContext {
    let originalCode: String
    let fileName: String
    let language: String
    let projectContext: [String: Any]?

    init(originalCode: String, fileName: String, language: String, projectContext: [String: Any]? = nil) {
        self.originalCode = originalCode
        self.fileName = fileName
        self.language = language
        self.projectContext = projectContext
    }
}

struct FixValidation {
    let isValid: Bool
    let confidence: Double
    let compilationCheck: CompilationCheck
    let potentialIssues: [String]
    let recommendation: FixRecommendation
}

struct CompilationCheck {
    let passes: Bool
    let errors: [String]
    let warnings: [String]
    let duration: TimeInterval
}

enum FixCategory: String, CaseIterable, Codable {
    case security = "Security"
    case performance = "Performance"
    case style = "Style"
    case logic = "Logic"
    case naming = "Naming"
    case architecture = "Architecture"

    var icon: String {
        switch self {
        case .security: return "🔒"
        case .performance: return "⚡"
        case .style: return "🎨"
        case .logic: return "🧠"
        case .naming: return "📝"
        case .architecture: return "🏗️"
        }
    }

    var color: Color {
        switch self {
        case .security: return .red
        case .performance: return .orange
        case .style: return .blue
        case .logic: return .purple
        case .naming: return .green
        case .architecture: return .gray
        }
    }
}

enum FixImpact: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var priority: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

enum FixRecommendation {
    case apply
    case review
    case skip
}

enum FixApplicationError: Error, LocalizedError {
    case invalidLineRange
    case compilationFailure
    case contextMismatch

    var errorDescription: String? {
        switch self {
        case .invalidLineRange:
            return "Fix references invalid line range"
        case .compilationFailure:
            return "Fix would cause compilation errors"
        case .contextMismatch:
            return "Fix context doesn't match current code"
        }
    }
}
