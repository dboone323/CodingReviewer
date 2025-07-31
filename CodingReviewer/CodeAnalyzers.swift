// SECURITY: API key handling - ensure proper encryption and keychain storage
import Foundation

// / Protocol for code analyzers to enable better testability and modularity
protocol CodeAnalyzer {
    func analyze(_ code: String) async -> [AnalysisResult]
}

// / Represents a single analysis result
struct AnalysisResult {
    let type: ResultType
    let message: String
    let line: Int?
    let severity: Severity

    enum ResultType {
        case quality
        case security
        case suggestion
        case performance

        var rawValue: String {
            switch self {
            case .quality: return "quality"
            case .security: return "security"
            case .suggestion: return "suggestion"
            case .performance: return "performance"
            }
        }
    }

    enum Severity {
        case low
        case medium
        case high
        case critical

        var rawValue: String {
            switch self {
            case .low: return "low"
            case .medium: return "medium"
            case .high: return "high"
            case .critical: return "critical"
            }
        }
    }
}

// / Analyzes code quality and style issues
final class QualityAnalyzer: CodeAnalyzer {

    func analyze(_ code: String) async -> [AnalysisResult] {
        var results: [AnalysisResult] = [];
        let lines = code.components(separatedBy: .newlines)

        // Force unwrapping detection
        results.append(contentsOf: checkForceUnwrapping(in: code))

        // Long lines detection
        results.append(contentsOf: checkLongLines(in: lines))

        // TODO/FIXME detection
        results.append(contentsOf: checkTodoComments(in: code))

        // Access control suggestions
        results.append(contentsOf: checkAccessControl(in: code))

        // Error handling suggestions
        results.append(contentsOf: checkErrorHandling(in: code))

        // Retain cycle potential
        results.append(contentsOf: checkRetainCycles(in: code))

        return results
    }

    private func checkForceUnwrapping(in code: String) -> [AnalysisResult] {
        let forceUnwrapPattern = "\\w+!"
        let matches = findMatches(pattern: forceUnwrapPattern, in: code)

        return matches.isEmpty ? [] : [
            AnalysisResult(
                type: .quality,
                message: "Found \(matches.count) force unwrapping operation(s) - " +
                        "consider using safe unwrapping patterns",
                line: nil,
                severity: .medium
            )
        ]
    }

    private func checkLongLines(in lines: [String]) -> [AnalysisResult] {
        let longLines = lines.enumerated().filter { $0.element.count > 120 }

        return longLines.isEmpty ? [] : [
            AnalysisResult(
                type: .quality,
                message: "Found \(longLines.count) long line(s) (>120 characters) on lines: " +
                        "\(longLines.map { $0.offset + 1 }.prefix(5).map(String.init).joined(separator: ", "))",
                line: longLines.first?.offset.advanced(by: 1),
                severity: .low
            )
        ]
    }

    private func checkTodoComments(in code: String) -> [AnalysisResult] {
        let todoCount = findMatches(pattern: "(?i)(TODO|FIXME|HACK)", in: code).count

        return todoCount > 0 ? [
            AnalysisResult(
                type: .suggestion,
                message: "Found \(todoCount) TODO/FIXME/HACK comment(s) - consider addressing these",
                line: nil,
                severity: .low
            )
        ] : []
    }

    private func checkAccessControl(in code: String) -> [AnalysisResult] {
        let publicDeclarations = findMatches(pattern: "public (class|struct|func|var|let)", in: code).count
        let privateDeclarations = findMatches(pattern: "private (class|struct|func|var|let)", in: code).count

        return publicDeclarations > privateDeclarations * 2 ? [
            AnalysisResult(
                type: .suggestion,
                message: "Consider using more restrictive access control (private/internal) where appropriate",
                line: nil,
                severity: .low
            )
        ] : []
    }

    private func checkErrorHandling(in code: String) -> [AnalysisResult] {
        let hasTry = code.contains("try") && !code.contains("catch") && !code.contains("try?") && !code.contains("try!")

        return hasTry ? [
            AnalysisResult(
                type: .suggestion,
                message: "Consider proper error handling with do-catch blocks",
                line: nil,
                severity: .medium
            )
        ] : []
    }

    private func checkRetainCycles(in code: String) -> [AnalysisResult] {
        let hasSelfInEscaping = code.contains("self?.") && code.contains("@escaping")

        return hasSelfInEscaping ? [
            AnalysisResult(
                type: .suggestion,
                message: "Review closures for potential retain cycles - consider using [weak self] or [unowned self]",
                line: nil,
                severity: .medium
            )
        ] : []
    }

    private func findMatches(pattern: String, in string: String) -> [NSTextCheckingResult] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: string.utf16.count)
            return regex.matches(in: string, options: [], range: range)
        } catch {
            return []
        }
    }
}

// / Analyzes potential security concerns
final class SecurityAnalyzer: CodeAnalyzer {

    func analyze(_ code: String) async -> [AnalysisResult] {
        var results: [AnalysisResult] = [];

        // Check for hardcoded sensitive information
        results.append(contentsOf: checkSensitiveInformation(in: code))

        // Check for unsafe network operations
        results.append(contentsOf: checkUnsafeNetwork(in: code))

        // Check for SQL injection potential
        results.append(contentsOf: checkSQLInjection(in: code))

        // Check for file system access
        results.append(contentsOf: checkFileSystemAccess(in: code))

        return results
    }

    private func checkSensitiveInformation(in code: String) -> [AnalysisResult] {
        let sensitivePatterns = ["password", "secret", "token", "key", "credential"]
        var results: [AnalysisResult] = [];

        for pattern in sensitivePatterns {
            if code.lowercased().contains(pattern) && code.contains("=") {
                results.append(AnalysisResult(
                    type: .security,
                    message: "Potential hardcoded sensitive information detected: '\(pattern)'",
                    line: nil,
                    severity: .high
                ))
            }
        }

        return results
    }

    private func checkUnsafeNetwork(in code: String) -> [AnalysisResult] {
        code.contains("https:// ") ? [
            AnalysisResult(
                type: .security,
                message: "Insecure HTTP connection detected - consider using HTTPS",
                line: nil,
                severity: .medium
            )
        ] : []
    }

    private func checkSQLInjection(in code: String) -> [AnalysisResult] {
        let hasSQL = code.contains("SQL") || code.contains("sqlite")

        return hasSQL ? [
            AnalysisResult(
                type: .security,
                message: "Database operations detected - ensure proper parameterized queries",
                line: nil,
                severity: .medium
            )
        ] : []
    }

    private func checkFileSystemAccess(in code: String) -> [AnalysisResult] {
        let hasFileAccess = code.contains("FileManager") || code.contains("Bundle.main")

        return hasFileAccess ? [
            AnalysisResult(
                type: .security,
                message: "File system access detected - ensure proper permissions and validation",
                line: nil,
                severity: .medium
            )
        ] : []
    }
}

// / Analyzes performance-related issues
final class PerformanceAnalyzer: CodeAnalyzer {

    func analyze(_ code: String) async -> [AnalysisResult] {
        var results: [AnalysisResult] = [];

        // Check for potential performance issues
        results.append(contentsOf: checkMainThreadBlocking(in: code))
        results.append(contentsOf: checkExpensiveOperations(in: code))

        return results
    }

    private func checkMainThreadBlocking(in code: String) -> [AnalysisResult] {
        let blockingPatterns = ["Thread.sleep", "sleep(", "usleep"]
        var results: [AnalysisResult] = [];

        for pattern in blockingPatterns where code.contains(pattern) {
            results.append(AnalysisResult(
                type: .performance,
                message: "Potential main thread blocking operation detected: '\(pattern)'",
                line: nil,
                severity: .medium
            ))
        }

        return results
    }

    private func checkExpensiveOperations(in code: String) -> [AnalysisResult] {
        let expensivePatterns = ["for.*in.*{", "while.*{"]
        var results: [AnalysisResult] = [];

        for pattern in expensivePatterns where findMatches(pattern: pattern, in: code).count > 10 {
            results.append(AnalysisResult(
                type: .performance,
                message: "Multiple loop operations detected - consider optimization",
                line: nil,
                severity: .low
            ))
            break
        }

        return results
    }

    private func findMatches(pattern: String, in string: String) -> [NSTextCheckingResult] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: string.utf16.count)
            return regex.matches(in: string, options: [], range: range)
        } catch {
            return []
        }
    }
}
