import Foundation
import OSLog

// MARK: - Automatic Fix Engine for Code Issues

class AutomaticFixEngine {
    static let shared = AutomaticFixEngine()
    private let logger = OSLog(subsystem: "CodingReviewer", category: "AutomaticFixEngine")
    private let learningCoordinator = AILearningCoordinator.shared
    private let codeGenerator = EnhancedAICodeGenerator.shared

    private init() {}

    // MARK: - Fix Application Methods

    func applyAutomaticFixes(to filePath: String) async throws -> FixApplicationResult {
        os_log("Starting automatic fixes for %@", log: logger, type: .debug, filePath)

        let content = try String(contentsOfFile: filePath, encoding: .utf8)

        // Get AI predictions before traditional detection
        let predictedIssues = await learningCoordinator.predictIssues(in: filePath)
        os_log("AI predicted %d potential issues", log: logger, type: .debug, predictedIssues.count)

        let detectedIssues = try await detectIssues(in: content, filePath: filePath)

        // For simplified version, use traditional fixes primarily
        let traditionalFixes = generateFixes(for: detectedIssues)

        // Combine AI recommendations with traditional fixes, prioritizing traditional fixes for now
        let allFixes = traditionalFixes

        let result = try await applyFixes(allFixes, to: content, filePath: filePath)

        // Learn from the results - simplified version
        for appliedFix in result.appliedFixes {
            await learningCoordinator.recordSuccess(fix: appliedFix.description, context: filePath)
        }

        for failedFix in result.failedFixes {
            await learningCoordinator.recordFailure(fix: failedFix.fix.description, error: failedFix.error.localizedDescription, context: filePath)
        }

        os_log("Applied %d automatic fixes to %@", log: logger, type: .info, result.appliedFixes.count, filePath)
        return result
    }

    func detectIssues(in content: String, filePath: String) async throws -> [FixEngineIssue] {
        var issues: [FixEngineIssue] = [];
        let lines = content.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1

            // Detect various types of issues
            issues.append(contentsOf: detectSwiftConcurrencyIssues(line: line, lineNumber: lineNumber))
            issues.append(contentsOf: detectPerformanceIssues(line: line, lineNumber: lineNumber))
            issues.append(contentsOf: detectSecurityIssues(line: line, lineNumber: lineNumber))
            issues.append(contentsOf: detectCodeQualityIssues(line: line, lineNumber: lineNumber))
            issues.append(contentsOf: detectSwiftBestPractices(line: line, lineNumber: lineNumber))
        }

        return issues
    }

    private func generateFixes(for issues: [FixEngineIssue]) -> [AutomaticFix] {
        return issues.compactMap { issue in
            switch issue.type {
            case .concurrencyWarning:
                return createConcurrencyFix(for: issue)
            case .unusedVariable:
                return createUnusedVariableFix(for: issue)
            case .forceUnwrapping:
                return createSafeUnwrappingFix(for: issue)
            case .stringInterpolation:
                return createStringInterpolationFix(for: issue)
            case .weakSelfUsage:
                return createWeakSelfFix(for: issue)
            case .optionalChaining:
                return createOptionalChainingFix(for: issue)
            case .immutableVariable:
                return createImmutableVariableFix(for: issue)
            case .redundantReturn:
                return createRedundantReturnFix(for: issue)
            case .magicNumber:
                return createMagicNumberFix(for: issue)
            case .longFunction:
                return createFunctionRefactoringFix(for: issue)
            }
        }
    }

    // Commented out for simplified AI learning system
    // Will be re-enabled when full AI features are activated
    /*
    private func prioritizeFixes(recommended: [RecommendedFix], traditional: [AutomaticFix]) -> [AutomaticFix] {
        var prioritizedFixes: [AutomaticFix] = []

        // Add high-confidence AI recommendations first
        let highConfidenceRecommended = recommended.filter { $0.confidence > 0.8 }
        prioritizedFixes.append(contentsOf: highConfidenceRecommended.map { $0.suggestedFix })

        // Add traditional fixes not covered by AI recommendations
        let coveredTypes = Set(highConfidenceRecommended.map { $0.issue.type })
        let uncoveredTraditionalFixes = traditional.filter { !coveredTypes.contains($0.type) }
        prioritizedFixes.append(contentsOf: uncoveredTraditionalFixes)

        // Add medium-confidence AI recommendations
        let mediumConfidenceRecommended = recommended.filter { $0.confidence > 0.5 && $0.confidence <= 0.8 }
        prioritizedFixes.append(contentsOf: mediumConfidenceRecommended.map { $0.suggestedFix })

        return prioritizedFixes
    }
    */

    private func applyFixes(_ fixes: [AutomaticFix], to content: String, filePath: String) async throws -> FixApplicationResult {
        var modifiedContent = content;
        var appliedFixes: [AutomaticFix] = [];
        var failedFixes: [FixFailure] = [];

        // Sort fixes by line number (descending) to avoid line number shifts
        let sortedFixes = fixes.sorted { $0.lineNumber > $1.lineNumber }

        for fix in sortedFixes {
            do {
                modifiedContent = try applyFix(fix, to: modifiedContent)
                appliedFixes.append(fix)
                os_log("Applied fix: %@ at line %d", log: logger, type: .debug, fix.description, fix.lineNumber)
            } catch {
                let failure = FixFailure(fix: fix, error: error)
                failedFixes.append(failure)
                os_log("Failed to apply fix: %@ - %@", log: logger, type: .error, fix.description, error.localizedDescription)
            }
        }

        // Write the modified content back to file
        if !appliedFixes.isEmpty {
            try modifiedContent.write(toFile: filePath, atomically: true, encoding: .utf8)
            os_log("Successfully wrote %d fixes to %@", log: logger, type: .info, appliedFixes.count, filePath)
        }

        return FixApplicationResult(
            appliedFixes: appliedFixes,
            failedFixes: failedFixes,
            modifiedContent: modifiedContent
        )
    }

    private func applyFix(_ fix: AutomaticFix, to content: String) throws -> String {
        var lines = content.components(separatedBy: .newlines);

        guard fix.lineNumber > 0 && fix.lineNumber <= lines.count else {
            throw FixEngineError.invalidLineNumber(fix.lineNumber)
        }

        let lineIndex = fix.lineNumber - 1
        let originalLine = lines[lineIndex]

        switch fix.fixType {
        case .replace(let pattern, let replacement):
            let newLine = originalLine.replacingOccurrences(of: pattern, with: replacement)
            lines[lineIndex] = newLine

        case .insert(let newLine):
            lines.insert(newLine, at: lineIndex)

        case .delete:
            lines.remove(at: lineIndex)

        case .multiLineReplace(let startLine, let endLine, let newLines):
            let startIndex = startLine - 1
            let endIndex = min(endLine - 1, lines.count - 1)
            lines.replaceSubrange(startIndex...endIndex, with: newLines)
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Issue Detection Methods

extension AutomaticFixEngine {

    private func detectSwiftConcurrencyIssues(line: String, lineNumber: Int) -> [FixEngineIssue] {
        var issues: [FixEngineIssue] = [];

        // Detect main actor isolation warnings
        if line.contains("call to main actor-isolated") && line.contains("in a synchronous") {
            issues.append(FixEngineIssue(
                type: .concurrencyWarning,
                lineNumber: lineNumber,
                originalCode: line,
                description: "Main actor isolation warning - async/await needed",
                severity: .warning
            ))
        }

        return issues
    }

    private func detectPerformanceIssues(line: String, lineNumber: Int) -> [FixEngineIssue] {
        var issues: [FixEngineIssue] = [];

        // Detect unused variables
        if line.contains("initialization of immutable value") && line.contains("was never used") {
            issues.append(FixEngineIssue(
                type: .unusedVariable,
                lineNumber: lineNumber,
                originalCode: line,
                description: "Unused variable should be replaced with _",
                severity: .warning
            ))
        }

        return issues
    }

    private func detectSecurityIssues(line: String, lineNumber: Int) -> [FixEngineIssue] {
        var issues: [FixEngineIssue] = [];

        // Detect force unwrapping
        if line.contains("!") && !line.contains("//") && !line.contains("\"") {
            let pattern = #"[a-zA-Z_][a-zA-Z0-9_]*!"#
            if line.range(of: pattern, options: .regularExpression) != nil {
                issues.append(FixEngineIssue(
                    type: .forceUnwrapping,
                    lineNumber: lineNumber,
                    originalCode: line,
                    description: "Force unwrapping should be replaced with safe unwrapping",
                    severity: .warning
                ))
            }
        }

        return issues
    }

    private func detectCodeQualityIssues(line: String, lineNumber: Int) -> [FixEngineIssue] {
        var issues: [FixEngineIssue] = [];

        // Detect mutable variables that should be immutable
        if line.contains("variable") && line.contains("was never mutated") && line.contains("consider changing to 'let'") {
            issues.append(FixEngineIssue(
                type: .immutableVariable,
                lineNumber: lineNumber,
                originalCode: line,
                description: "Variable should be declared as let instead of var",
                severity: .warning
            ))
        }

        return issues
    }

    private func detectSwiftBestPractices(line: String, lineNumber: Int) -> [FixEngineIssue] {
        var issues: [FixEngineIssue] = [];

        // Detect redundant returns
        if line.trimmed.hasPrefix("return ") && line.contains("single expression") {
            issues.append(FixEngineIssue(
                type: .redundantReturn,
                lineNumber: lineNumber,
                originalCode: line,
                description: "Redundant return in single expression function",
                severity: .info
            ))
        }

        // Detect magic numbers
        let magicNumberPattern = #"\b([2-9]|[1-9][0-9]+)\b"#
        if line.range(of: magicNumberPattern, options: .regularExpression) != nil &&
           !line.contains("//") && !line.contains("case") {
            issues.append(FixEngineIssue(
                type: .magicNumber,
                lineNumber: lineNumber,
                originalCode: line,
                description: "Magic number should be replaced with named constant",
                severity: .info
            ))
        }

        return issues
    }
}

// MARK: - Fix Generation Methods

extension AutomaticFixEngine {

    private func createConcurrencyFix(for issue: FixEngineIssue) -> AutomaticFix? {
        let pattern = #"([a-zA-Z_][a-zA-Z0-9_]*\.shared\.[a-zA-Z_][a-zA-Z0-9_]*\()"#
        let replacement = "await $1"

        return AutomaticFix(
            type: .concurrencyWarning,
            fixType: .replace(pattern: pattern, replacement: replacement),
            lineNumber: issue.lineNumber,
            description: "Add await for main actor isolated call",
            confidence: .medium
        )
    }

    private func createUnusedVariableFix(for issue: FixEngineIssue) -> AutomaticFix? {
        // Extract variable name from the warning
        let pattern = #"let ([a-zA-Z_][a-zA-Z0-9_]*) ="#
        let replacement = "let _ ="

        return AutomaticFix(
            type: .unusedVariable,
            fixType: .replace(pattern: pattern, replacement: replacement),
            lineNumber: issue.lineNumber,
            description: "Replace unused variable with _",
            confidence: .high
        )
    }

    private func createSafeUnwrappingFix(for issue: FixEngineIssue) -> AutomaticFix? {
        let pattern = #"([a-zA-Z_][a-zA-Z0-9_]*)!"#
        let replacement = "$1 ?? defaultValue"

        return AutomaticFix(
            type: .forceUnwrapping,
            fixType: .replace(pattern: pattern, replacement: replacement),
            lineNumber: issue.lineNumber,
            description: "Replace force unwrapping with nil coalescing",
            confidence: .medium
        )
    }

    private func createStringInterpolationFix(for issue: FixEngineIssue) -> AutomaticFix? {
        let pattern = #"print\("([^"]+)"\)"#
        let replacement = #"logger.logInfo("$1")"#

        return AutomaticFix(
            type: .stringInterpolation,
            fixType: .replace(pattern: pattern, replacement: replacement),
            lineNumber: issue.lineNumber,
            description: "Replace print with secure logging",
            confidence: .high
        )
    }

    private func createWeakSelfFix(for issue: FixEngineIssue) -> AutomaticFix? {
        let pattern = #"{ self\."#
        let replacement = "{ [weak self] in self?."

        return AutomaticFix(
            type: .weakSelfUsage,
            fixType: .replace(pattern: pattern, replacement: replacement),
            lineNumber: issue.lineNumber,
            description: "Add weak self capture to prevent retain cycles",
            confidence: .medium
        )
    }

    private func createOptionalChainingFix(for issue: FixEngineIssue) -> AutomaticFix? {
        let pattern = #"if let ([a-zA-Z_][a-zA-Z0-9_]*) = ([a-zA-Z_][a-zA-Z0-9_]*) {"#
        let replacement = "$2?."

        return AutomaticFix(
            type: .optionalChaining,
            fixType: .replace(pattern: pattern, replacement: replacement),
            lineNumber: issue.lineNumber,
            description: "Use optional chaining instead of if-let",
            confidence: .low
        )
    }

    private func createImmutableVariableFix(for issue: FixEngineIssue) -> AutomaticFix? {
        let pattern = #"var ([a-zA-Z_][a-zA-Z0-9_]*)"#
        let replacement = "let $1"

        return AutomaticFix(
            type: .immutableVariable,
            fixType: .replace(pattern: pattern, replacement: replacement),
            lineNumber: issue.lineNumber,
            description: "Change var to let for immutable variable",
            confidence: .high
        )
    }

    private func createRedundantReturnFix(for issue: FixEngineIssue) -> AutomaticFix? {
        let pattern = #"return (.+)"#
        let replacement = "$1"

        return AutomaticFix(
            type: .redundantReturn,
            fixType: .replace(pattern: pattern, replacement: replacement),
            lineNumber: issue.lineNumber,
            description: "Remove redundant return statement",
            confidence: .high
        )
    }

    private func createMagicNumberFix(for issue: FixEngineIssue) -> AutomaticFix? {
        // This would require more context to generate meaningful constant names
        return AutomaticFix(
            type: .magicNumber,
            fixType: .replace(pattern: "", replacement: ""),
            lineNumber: issue.lineNumber,
            description: "Consider extracting magic number to named constant",
            confidence: .low
        )
    }

    private func createFunctionRefactoringFix(for issue: FixEngineIssue) -> AutomaticFix? {
        return AutomaticFix(
            type: .longFunction,
            fixType: .insert(newLine: "    // TODO: Consider breaking this function into smaller methods"),
            lineNumber: issue.lineNumber,
            description: "Add refactoring suggestion for long function",
            confidence: .low
        )
    }
}

// MARK: - Supporting Types

// MARK: - Fix Engine Specific Types
struct FixEngineIssue {
    let type: IssueType
    let lineNumber: Int
    let originalCode: String
    let description: String
    let severity: Severity

    enum IssueType {
        case concurrencyWarning
        case unusedVariable
        case forceUnwrapping
        case stringInterpolation
        case weakSelfUsage
        case optionalChaining
        case immutableVariable
        case redundantReturn
        case magicNumber
        case longFunction
    }

    enum Severity {
        case error, warning, info
    }
}

// Type alias for backward compatibility
typealias AutoFixEngineIssue = FixEngineIssue

struct AutomaticFix {
    let type: FixEngineIssue.IssueType
    let fixType: FixType
    let lineNumber: Int
    let description: String
    let confidence: Confidence

    enum FixType {
        case replace(pattern: String, replacement: String)
        case insert(newLine: String)
        case delete
        case multiLineReplace(startLine: Int, endLine: Int, newLines: [String])
    }

    enum Confidence {
        case high, medium, low
    }
}

struct FixApplicationResult {
    let appliedFixes: [AutomaticFix]
    let failedFixes: [FixFailure]
    let modifiedContent: String

    var successRate: Double {
        let total = appliedFixes.count + failedFixes.count
        return total > 0 ? Double(appliedFixes.count) / Double(total) : 0.0
    }
}

struct FixFailure {
    let fix: AutomaticFix
    let error: Error
}

enum FixEngineError: LocalizedError {
    case invalidLineNumber(Int)
    case patternNotFound(String)
    case fileNotWritable(String)

    nonisolated var errorDescription: String? {
        switch self {
        case .invalidLineNumber(let line):
            return "Invalid line number: \(line)"
        case .patternNotFound(let pattern):
            return "Pattern not found: \(pattern)"
        case .fileNotWritable(let path):
            return "File not writable: \(path)"
        }
    }
}

// MARK: - String Extensions for Fix Engine

extension String {
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
