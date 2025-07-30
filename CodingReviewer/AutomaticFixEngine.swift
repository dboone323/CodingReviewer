import Foundation
import OSLog

// MARK: - Automatic Fix Engine for Code Issues

class AutomaticFixEngine {
    static let shared = AutomaticFixEngine()
    private let logger = OSLog(subsystem: "CodingReviewer", category: "AutomaticFixEngine")

    private init() {}

    // MARK: - Fix Application Methods

    func applyAutomaticFixes(to filePath: String) async throws -> FixApplicationResult {
        os_log("Starting automatic fixes for %@", log: logger, type: .debug, filePath)

        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let issues = try await detectIssues(in: content, filePath: filePath)
        let fixes = generateFixes(for: issues)

        let result = try await applyFixes(fixes, to: content, filePath: filePath)

        os_log("Applied %d automatic fixes to %@", log: logger, type: .info, result.appliedFixes.count, filePath)
        return result
    }

    func detectIssues(in content: String, filePath: String) async throws -> [DetectedIssue] {
        var issues: [DetectedIssue] = []
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

    private func generateFixes(for issues: [DetectedIssue]) -> [AutomaticFix] {
        issues.compactMap { issue in
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

    private func applyFixes(_ fixes: [AutomaticFix], to content: String, filePath: String) async throws -> FixApplicationResult {
        var modifiedContent = content
        var appliedFixes: [AutomaticFix] = []
        var failedFixes: [FixFailure] = []

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
        var lines = content.components(separatedBy: .newlines)

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

    private func detectSwiftConcurrencyIssues(line: String, lineNumber: Int) -> [DetectedIssue] {
        var issues: [DetectedIssue] = []

        // Detect main actor isolation warnings
        if line.contains("call to main actor-isolated") && line.contains("in a synchronous") {
            issues.append(DetectedIssue(
                type: .concurrencyWarning,
                lineNumber: lineNumber,
                originalCode: line,
                description: "Main actor isolation warning - async/await needed",
                severity: .warning
            ))
        }

        return issues
    }

    private func detectPerformanceIssues(line: String, lineNumber: Int) -> [DetectedIssue] {
        var issues: [DetectedIssue] = []

        // Detect unused variables
        if line.contains("initialization of immutable value") && line.contains("was never used") {
            issues.append(DetectedIssue(
                type: .unusedVariable,
                lineNumber: lineNumber,
                originalCode: line,
                description: "Unused variable should be replaced with _",
                severity: .warning
            ))
        }

        return issues
    }

    private func detectSecurityIssues(line: String, lineNumber: Int) -> [DetectedIssue] {
        var issues: [DetectedIssue] = []

        // Detect force unwrapping
        if line.contains("!") && !line.contains("// ") && !line.contains("\"") {
            let pattern = #"[a-zA-Z_][a-zA-Z0-9_]*!"#
            if line.range(of: pattern, options: .regularExpression) != nil {
                issues.append(DetectedIssue(
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

    private func detectCodeQualityIssues(line: String, lineNumber: Int) -> [DetectedIssue] {
        var issues: [DetectedIssue] = []

        // Detect mutable variables that should be immutable
        if line.contains("variable") && line.contains("was never mutated") && line.contains("consider changing to 'let'") {
            issues.append(DetectedIssue(
                type: .immutableVariable,
                lineNumber: lineNumber,
                originalCode: line,
                description: "Variable should be declared as let instead of var",
                severity: .warning
            ))
        }

        return issues
    }

    private func detectSwiftBestPractices(line: String, lineNumber: Int) -> [DetectedIssue] {
        var issues: [DetectedIssue] = []

        // Detect redundant returns
        if line.trimmed.hasPrefix("return ") && line.contains("single expression") {
            issues.append(DetectedIssue(
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
           !line.contains("// ") && !line.contains("case") {
            issues.append(DetectedIssue(
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

    private func createConcurrencyFix(for issue: DetectedIssue) -> AutomaticFix? {
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

    private func createUnusedVariableFix(for issue: DetectedIssue) -> AutomaticFix? {
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

    private func createSafeUnwrappingFix(for issue: DetectedIssue) -> AutomaticFix? {
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

    private func createStringInterpolationFix(for issue: DetectedIssue) -> AutomaticFix? {
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

    private func createWeakSelfFix(for issue: DetectedIssue) -> AutomaticFix? {
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

    private func createOptionalChainingFix(for issue: DetectedIssue) -> AutomaticFix? {
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

    private func createImmutableVariableFix(for issue: DetectedIssue) -> AutomaticFix? {
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

    private func createRedundantReturnFix(for issue: DetectedIssue) -> AutomaticFix? {
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

    private func createMagicNumberFix(for issue: DetectedIssue) -> AutomaticFix? {
        // This would require more context to generate meaningful constant names
        AutomaticFix(
            type: .magicNumber,
            fixType: .replace(pattern: "", replacement: ""),
            lineNumber: issue.lineNumber,
            description: "Consider extracting magic number to named constant",
            confidence: .low
        )
    }

    private func createFunctionRefactoringFix(for issue: DetectedIssue) -> AutomaticFix? {
        AutomaticFix(
            type: .longFunction,
            fixType: .insert(newLine: "    // TODO: Consider breaking this function into smaller methods"),
            lineNumber: issue.lineNumber,
            description: "Add refactoring suggestion for long function",
            confidence: .low
        )
    }
}

// MARK: - Supporting Types

struct DetectedIssue {
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

struct AutomaticFix {
    let type: DetectedIssue.IssueType
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

    var errorDescription: String? {
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
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
