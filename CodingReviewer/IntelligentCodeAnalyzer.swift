import Foundation
import OSLog
import SwiftUI
import Combine

// MARK: - Analysis Error Types

enum AnalyzerError: LocalizedError {
    case fileNotFound(String)
    case invalidPath(String)
    case analysisTimeout
    case networkError(Error)

    nonisolated var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidPath(let path):
            return "Invalid path: \(path)"
        case .analysisTimeout:
            return "Analysis timed out"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Code Issue Types

struct CodeIssue {
    let type: IssueType
    let severity: Severity
    let lineNumber: Int
    let description: String
    let filePath: String
    let suggestedFix: String?
    let category: Category

    enum IssueType {
        case concurrencyIssue
        case missingMainActor
        case unusedVariable
        case mutableToImmutable
        case longLine
        case inefficientStringConcatenation
        case forceUnwrapping
        case insecureLogging
        case hardcodedSecret
        case magicNumber
        case missingAccessControl
        case longFunction
    }

    enum Severity {
        case error, warning, info
    }

    enum Category: String, CaseIterable {
        case concurrency = "Concurrency"
        case codeQuality = "Code Quality"
        case formatting = "Formatting"
        case performance = "Performance"
        case safety = "Safety"
        case security = "Security"
        case maintainability = "Maintainability"
    }
}

// MARK: - Recommendation Types

struct Recommendation {
    let title: String
    let description: String
    let priority: Priority
    let category: String
    let actionable: Bool

    enum Priority: Int, CaseIterable {
        case high = 3
        case medium = 2
        case low = 1

        var rawValue: Int {
            switch self {
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            }
        }
    }
}

// MARK: - Intelligent Code Analyzer

class IntelligentCodeAnalyzer: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var lastAnalysisResult: ProjectAnalysisResult?

    private let logger = OSLog(subsystem: "CodingReviewer", category: "IntelligentCodeAnalyzer")

    func analyzeProject(at projectPath: String, completion: @escaping (ProjectAnalysisResult) -> Void) {
        Task {
            isAnalyzing = true
            analysisProgress = 0.0

            let startTime = Date()
            let projectStructure = ProjectStructure(name: URL(fileURLWithPath: projectPath).lastPathComponent, rootPath: projectPath, files: [])

            let result = ProjectAnalysisResult(
                project: projectStructure,
                fileAnalyses: [],
                insights: [],
                duration: Date().timeIntervalSince(startTime)
            )

            lastAnalysisResult = result

            os_log("Project analysis completed with %d total files", log: logger, type: .info, result.project.files.count)

            Task { @MainActor in
                completion(result)
            }

            isAnalyzing = false
        }
    }

    func analyzeFile(at filePath: String) async throws -> [CodeIssue] {
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw AnalyzerError.fileNotFound(filePath)
        }

        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        var issues: [CodeIssue] = []

        // Run various analysis passes
        issues.append(contentsOf: analyzeSwiftConcurrency(lines: lines, filePath: filePath))
        issues.append(contentsOf: analyzeCodeQuality(lines: lines, filePath: filePath))
        issues.append(contentsOf: analyzePerformance(lines: lines, filePath: filePath))
        issues.append(contentsOf: analyzeSecurity(lines: lines, filePath: filePath))
        issues.append(contentsOf: analyzeSwiftBestPractices(lines: lines, filePath: filePath))
        issues.append(contentsOf: analyzeArchitecturalPatterns(lines: lines, filePath: filePath))

        return issues
    }

    private func analyzeSwiftConcurrency(lines: [String], filePath: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1

            // Check for main actor isolation issues
            if line.contains(".shared.") && !line.contains("await") &&
               (line.contains("AppLogger") || line.contains("PerformanceTracker")) {
                issues.append(CodeIssue(
                    type: .concurrencyIssue,
                    severity: .warning,
                    lineNumber: lineNumber,
                    description: "Main actor-isolated property access should use await",
                    filePath: filePath,
                    suggestedFix: line.replacingOccurrences(of: ".shared.", with: "await .shared."),
                    category: .concurrency
                ))
            }

            // Check for missing @MainActor annotations
            if line.contains("@Published") && !lines[max(0, index-1)].contains("@MainActor") {
                issues.append(CodeIssue(
                    type: .missingMainActor,
                    severity: .warning,
                    lineNumber: lineNumber,
                    description: "Published properties should be main actor isolated",
                    filePath: filePath,
                    suggestedFix: "@MainActor\n" + line,
                    category: .concurrency
                ))
            }
        }

        return issues
    }

    private func analyzeCodeQuality(lines: [String], filePath: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1

            // Check for unused variables
            let regex = try? NSRegularExpression(pattern: "\\b(let|var)\\s+(\\w+)\\s*=")
            if let regex = regex {
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                if let match = regex.firstMatch(in: line, options: [], range: range),
                   let matchRange = Range(match.range(at: 2), in: line) {
                    let variableName = String(line[matchRange])

                    // Simple heuristic: if variable isn't used elsewhere
                    let usageCount = lines.filter { $0.contains(variableName) }.count
                    if usageCount == 1 { // Only the declaration line
                        issues.append(CodeIssue(
                            type: .unusedVariable,
                            severity: .warning,
                            lineNumber: lineNumber,
                            description: "Variable '\(variableName)' is declared but never used",
                            filePath: filePath,
                            suggestedFix: nil,
                            category: .codeQuality
                        ))
                    }
                }
            }

            // Check for var that should be let
            if line.contains("var ") && !line.contains(" = ") {
                issues.append(CodeIssue(
                    type: .mutableToImmutable,
                    severity: .info,
                    lineNumber: lineNumber,
                    description: "Consider using 'let' if this variable is never modified",
                    filePath: filePath,
                    suggestedFix: line.replacingOccurrences(of: "var ", with: "let "),
                    category: .codeQuality
                ))
            }

            // Check for long lines
            if line.count > 120 {
                issues.append(CodeIssue(
                    type: .longLine,
                    severity: .info,
                    lineNumber: lineNumber,
                    description: "Line exceeds 120 characters (\(line.count) characters)",
                    filePath: filePath,
                    suggestedFix: nil,
                    category: .formatting
                ))
            }
        }

        return issues
    }

    private func analyzePerformance(lines: [String], filePath: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1

            // Check for inefficient string concatenation
            if line.contains("+") && line.contains("\"") && !line.contains("\\(") {
                issues.append(CodeIssue(
                    type: .inefficientStringConcatenation,
                    severity: .warning,
                    lineNumber: lineNumber,
                    description: "Consider using string interpolation instead of concatenation",
                    filePath: filePath,
                    suggestedFix: nil,
                    category: .performance
                ))
            }

            // Check for force unwrapping
            if line.contains("!") && !line.contains("!=") && !line.contains("//") {
                let forceUnwrapCount = line.components(separatedBy: "!").count - 1
                if forceUnwrapCount > 0 {
                    issues.append(CodeIssue(
                        type: .forceUnwrapping,
                        severity: .warning,
                        lineNumber: lineNumber,
                        description: "Force unwrapping can cause crashes - consider using optional binding",
                        filePath: filePath,
                        suggestedFix: nil,
                        category: .safety
                    ))
                }
            }
        }

        return issues
    }

    private func analyzeSecurity(lines: [String], filePath: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1

            // Check for potential logging of sensitive data
            if line.contains("log") && (line.contains("password") || line.contains("token") || line.contains("key")) {
                issues.append(CodeIssue(
                    type: .insecureLogging,
                    severity: .warning,
                    lineNumber: lineNumber,
                    description: "Potential logging of sensitive information",
                    filePath: filePath,
                    suggestedFix: nil,
                    category: .security
                ))
            }

            // Check for hardcoded secrets
            let secretPatterns = ["password", "token", "apikey", "secret"]
            for pattern in secretPatterns {
                if line.lowercased().contains("\(pattern) = \"") || line.lowercased().contains("\(pattern): \"") {
                    issues.append(CodeIssue(
                        type: .hardcodedSecret,
                        severity: .error,
                        lineNumber: lineNumber,
                        description: "Hardcoded secret detected - move to secure storage",
                        filePath: filePath,
                        suggestedFix: nil,
                        category: .security
                    ))
                }
            }
        }

        return issues
    }

    private func analyzeSwiftBestPractices(lines: [String], filePath: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1

            // Check for magic numbers
            let numberRegex = try? NSRegularExpression(pattern: "\\b\\d+\\b")
            if let regex = numberRegex {
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                let matches = regex.matches(in: line, options: [], range: range)
                for match in matches {
                    guard let matchRange = Range(match.range, in: line) else { continue }
                    let numberString = String(line[matchRange])
                    if let number = Int(numberString), number > 1 && number != 0 && number != 100 {
                        issues.append(CodeIssue(
                            type: .magicNumber,
                            severity: .info,
                            lineNumber: lineNumber,
                            description: "Magic number '\(number)' should be named constant",
                            filePath: filePath,
                            suggestedFix: nil,
                            category: .maintainability
                        ))
                    }
                }
            }

            // Check for missing access control
            if (line.contains("class ") || line.contains("struct ") || line.contains("func ")) &&
               !line.contains("private") && !line.contains("public") && !line.contains("internal") {
                issues.append(CodeIssue(
                    type: .missingAccessControl,
                    severity: .info,
                    lineNumber: lineNumber,
                    description: "Consider adding explicit access control",
                    filePath: filePath,
                    suggestedFix: nil,
                    category: .codeQuality
                ))
            }
        }

        return issues
    }

    private func analyzeArchitecturalPatterns(lines: [String], filePath: String) -> [CodeIssue] {
        var issues: [CodeIssue] = []

        // Check for long functions
        var currentFunctionStart: Int?
        var braceCount = 0

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Detect function start
            if trimmedLine.contains("func ") && trimmedLine.contains("{") {
                currentFunctionStart = lineNumber
                braceCount = 1
            } else if let functionStart = currentFunctionStart {
                // Count braces to find function end
                braceCount += trimmedLine.components(separatedBy: "{").count - 1
                braceCount -= trimmedLine.components(separatedBy: "}").count - 1

                if braceCount == 0 {
                    let functionLength = lineNumber - functionStart
                    if functionLength > 50 {
                        issues.append(CodeIssue(
                            type: .longFunction,
                            severity: .warning,
                            lineNumber: functionStart,
                            description: "Function is \(functionLength) lines long - consider breaking it down",
                            filePath: filePath,
                            suggestedFix: nil,
                            category: .maintainability
                        ))
                    }
                    currentFunctionStart = nil
                }
            }
        }

        return issues
    }

    private func generateRecommendations(from issues: [CodeIssue]) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // Group issues by category
        let groupedIssues = Dictionary(grouping: issues, by: { $0.category })

        for (category, categoryIssues) in groupedIssues {
            let count = categoryIssues.count
            let highPriorityCount = categoryIssues.filter { $0.severity == .error }.count

            recommendations.append(Recommendation(
                title: "\(category.rawValue) Issues",
                description: "\(count) \(category.rawValue.lowercased()) issues found (\(highPriorityCount) high-priority)",
                priority: highPriorityCount > 0 ? .high : (count > 5 ? .medium : .low),
                category: category.rawValue,
                actionable: true
            ))
        }

        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
}
