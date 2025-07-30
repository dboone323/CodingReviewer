import Foundation
import OSLog

// MARK: - AI-Powered Code Fix Assistant (Standalone)

class AICodeFixAssistant {
    static let shared = AICodeFixAssistant()
    private let logger = OSLog(subsystem: "CodingReviewer", category: "AICodeFix")
    
    private init() {}
    
    // MARK: - Main Fix Methods
    
    func fixSwiftFile(at filePath: String) async throws -> SwiftFileFixResult {
        os_log("Starting AI-powered fixes for file: %@", log: logger, type: .info, filePath)
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw FixError.fileReadError(filePath)
        }
        
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let issues = detectIssues(in: content, filePath: filePath)
        let fixes = createFixes(for: issues)
        
        let result = try await applyFixes(fixes, to: content, filePath: filePath)
        
        os_log("Applied %d fixes to %@", log: logger, type: .info, result.appliedFixes.count, filePath)
        
        return SwiftFileFixResult(
            filePath: filePath,
            originalIssueCount: issues.count,
            appliedFixCount: result.appliedFixes.count,
            failedFixCount: result.failedFixes.count,
            appliedFixes: result.appliedFixes,
            failedFixes: result.failedFixes
        )
    }
}
    
    private func createFixPlan(from analysis: ProjectAnalysisResult) -> FixPlan {
        var fixes: [TargetedFix] = []
        
        // Group issues by file for efficient processing
        let issuesByFile = Dictionary(grouping: analysis.issues) { $0.filePath }
        
        for (filePath, fileIssues) in issuesByFile {
            let prioritizedIssues = fileIssues.sorted { $0.severity.rawValue > $1.severity.rawValue }
            
            for issue in prioritizedIssues where issue.isAutoFixable {
                if let fix = createTargetedFix(for: issue) {
                    fixes.append(fix)
                }
            }
        }
        
        return FixPlan(
            targetedFixes: fixes.sorted { $0.priority.rawValue > $1.priority.rawValue },
            estimatedDuration: estimateFixDuration(fixes),
            riskLevel: assessRiskLevel(fixes)
        )
    }
    
    private func createTargetedFix(for issue: CodeIssue) -> TargetedFix? {
        switch issue.type {
        case .concurrencyIssue:
            return createConcurrencyFix(for: issue)
        case .missingMainActor:
            return createMainActorFix(for: issue)
        case .unusedVariable:
            return createUnusedVariableFix(for: issue)
        case .insecureLogging:
            return createSecureLoggingFix(for: issue)
        case .forceUnwrapping:
            return createSafeUnwrappingFix(for: issue)
        case .mutableToImmutable:
            return createImmutableVariableFix(for: issue)
        case .longLine:
            return createLineBreakFix(for: issue)
        case .magicNumber:
            return createConstantExtractionFix(for: issue)
        default:
            return nil
        }
    }
    
    // MARK: - Specific Fix Creators
    
    private func createConcurrencyFix(for issue: CodeIssue) -> TargetedFix {
        let fixStrategy: FixStrategy
        
        if issue.originalCode.contains(".shared.") {
            fixStrategy = .replacePattern(
                pattern: #"([a-zA-Z_]\w*\.shared\.[a-zA-Z_]\w*)"#,
                replacement: "await $1",
                requiresAsyncContext: true
            )
        } else {
            fixStrategy = .insertBefore(
                content: "await ",
                pattern: issue.originalCode.trimmingCharacters(in: .whitespaces)
            )
        }
        
        return TargetedFix(
            issue: issue,
            strategy: fixStrategy,
            priority: .high,
            confidence: .high,
            description: "Add await for main actor isolated call"
        )
    }
    
    private func createMainActorFix(for issue: CodeIssue) -> TargetedFix {
        return TargetedFix(
            issue: issue,
            strategy: .insertBefore(
                content: "@MainActor\n",
                pattern: issue.originalCode.trimmingCharacters(in: .whitespaces)
            ),
            priority: .high,
            confidence: .high,
            description: "Add @MainActor annotation to ObservableObject class"
        )
    }
    
    private func createUnusedVariableFix(for issue: CodeIssue) -> TargetedFix {
        let pattern = #"let\s+([a-zA-Z_]\w*)\s*="#
        let replacement = "let _ ="
        
        return TargetedFix(
            issue: issue,
            strategy: .replacePattern(
                pattern: pattern,
                replacement: replacement,
                requiresAsyncContext: false
            ),
            priority: .medium,
            confidence: .high,
            description: "Replace unused variable with underscore"
        )
    }
    
    private func createSecureLoggingFix(for issue: CodeIssue) -> TargetedFix {
        let strategy: FixStrategy
        
        if issue.originalCode.contains("AppLogger.shared.log(\"") {
            // Simple string print
            strategy = .replacePattern(
                pattern: #"print\("([^"]+)"\)"#,
                replacement: #"os_log("%@", "\1")"#,
                requiresAsyncContext: false
            )
        } else {
            // Complex print with variables
            strategy = .replacePattern(
                pattern: #"print\(([^)]+)\)"#,
                replacement: "os_log(\"%@\", String(describing: $1))",
                requiresAsyncContext: false
            )
        }
        
        return TargetedFix(
            issue: issue,
            strategy: strategy,
            priority: .high,
            confidence: .medium,
            description: "Replace print with secure logging",
            additionalChanges: [.addImport("OSLog")]
        )
    }
    
    private func createSafeUnwrappingFix(for issue: CodeIssue) -> TargetedFix {
        // This requires more context analysis
        return TargetedFix(
            issue: issue,
            strategy: .manualReview("Force unwrapping requires context-specific safe unwrapping"),
            priority: .medium,
            confidence: .low,
            description: "Convert force unwrapping to safe unwrapping (manual review required)"
        )
    }
    
    private func createImmutableVariableFix(for issue: CodeIssue) -> TargetedFix {
        return TargetedFix(
            issue: issue,
            strategy: .replacePattern(
                pattern: #"var\s+([a-zA-Z_]\w*)"#,
                replacement: "let $1",
                requiresAsyncContext: false
            ),
            priority: .low,
            confidence: .medium,
            description: "Change var to let for immutable variable"
        )
    }
    
    private func createLineBreakFix(for issue: CodeIssue) -> TargetedFix {
        return TargetedFix(
            issue: issue,
            strategy: .manualReview("Long line requires manual formatting"),
            priority: .low,
            confidence: .low,
            description: "Break long line into multiple lines (manual review required)"
        )
    }
    
    private func createConstantExtractionFix(for issue: CodeIssue) -> TargetedFix {
        return TargetedFix(
            issue: issue,
            strategy: .manualReview("Magic number extraction requires semantic understanding"),
            priority: .low,
            confidence: .low,
            description: "Extract magic number to named constant (manual review required)"
        )
    }
    
    // MARK: - Fix Application
    
    private func applyFixPlan(_ plan: FixPlan, projectPath: String) async throws -> FixApplicationResult {
        var appliedFixes: [TargetedFix] = []
        var failedFixes: [FixFailure] = []
        var modifiedFiles: Set<String> = []
        
        os_log("Applying %d targeted fixes", log: logger, type: .info, plan.targetedFixes.count)
        
        // Group fixes by file for efficient processing
        let fixesByFile = Dictionary(grouping: plan.targetedFixes) { $0.issue.filePath }
        
        for (filePath, fileFixes) in fixesByFile {
            do {
                let result = try await applyFixesToFile(fileFixes, filePath: filePath)
                appliedFixes.append(contentsOf: result.applied)
                failedFixes.append(contentsOf: result.failed)
                
                if !result.applied.isEmpty {
                    modifiedFiles.insert(filePath)
                }
            } catch {
                let failures = fileFixes.map { FixFailure(fix: $0, error: error) }
                failedFixes.append(contentsOf: failures)
            }
        }
        
        os_log("Applied %d fixes, %d failed", log: logger, type: .info, appliedFixes.count, failedFixes.count)
        
        return FixApplicationResult(
            appliedFixes: appliedFixes,
            failedFixes: failedFixes,
            modifiedFiles: Array(modifiedFiles)
        )
    }
    
    private func applyFixesToFile(_ fixes: [TargetedFix], filePath: String) async throws -> (applied: [TargetedFix], failed: [FixFailure]) {
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            throw FixError.fileReadError(filePath)
        }
        
        var modifiedContent = content
        var applied: [TargetedFix] = []
        var failed: [FixFailure] = []
        var needsImports: Set<String> = []
        
        // Sort fixes by line number (descending) to avoid line shift issues
        let sortedFixes = fixes.sorted { $0.issue.lineNumber > $1.issue.lineNumber }
        
        for fix in sortedFixes {
            do {
                let (newContent, importsNeeded) = try applyFixToContent(fix, content: modifiedContent)
                modifiedContent = newContent
                applied.append(fix)
                needsImports.formUnion(importsNeeded)
            } catch {
                failed.append(FixFailure(fix: fix, error: error))
            }
        }
        
        // Add needed imports
        if !needsImports.isEmpty {
            modifiedContent = addImports(needsImports, to: modifiedContent)
        }
        
        // Write modified content back to file
        if !applied.isEmpty {
            try modifiedContent.write(toFile: filePath, atomically: true, encoding: .utf8)
        }
        
        return (applied: applied, failed: failed)
    }
    
    private func applyFixToContent(_ fix: TargetedFix, content: String) throws -> (String, Set<String>) {
        var needsImports: Set<String> = []
        
        // Add any additional imports needed
        for change in fix.additionalChanges {
            if case .addImport(let importName) = change {
                needsImports.insert(importName)
            }
        }
        
        switch fix.strategy {
        case .replacePattern(let pattern, let replacement, _):
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: content.count)
            let modifiedContent = regex.stringByReplacingMatches(
                in: content,
                options: [],
                range: range,
                withTemplate: replacement
            )
            return (modifiedContent, needsImports)
            
        case .insertBefore(let insertContent, let pattern):
            if let range = content.range(of: pattern) {
                let modifiedContent = content.replacingCharacters(in: range, with: insertContent + pattern)
                return (modifiedContent, needsImports)
            } else {
                throw FixError.patternNotFound(pattern)
            }
            
        case .insertAfter(let insertContent, let pattern):
            if let range = content.range(of: pattern) {
                let insertPoint = range.upperBound
                let modifiedContent = content.replacingCharacters(in: insertPoint..<insertPoint, with: insertContent)
                return (modifiedContent, needsImports)
            } else {
                throw FixError.patternNotFound(pattern)
            }
            
        case .manualReview:
            throw FixError.manualReviewRequired
        }
    }
    
    private func addImports(_ imports: Set<String>, to content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        var modifiedLines = lines
        
        for importName in imports.sorted() {
            let importStatement = "import \(importName)"
            
            // Check if import already exists
            if !content.contains(importStatement) {
                // Find the best place to insert the import
                var insertIndex = 0
                
                // Look for existing imports
                for (index, line) in lines.enumerated() {
                    if line.hasPrefix("import ") {
                        insertIndex = index + 1
                    } else if line.hasPrefix("import ") == false && line.trimmingCharacters(in: .whitespaces).isEmpty == false {
                        break
                    }
                }
                
                modifiedLines.insert(importStatement, at: insertIndex)
            }
        }
        
        return modifiedLines.joined(separator: "\n")
    }
    
    // MARK: - Helper Methods
    
    private func estimateFixDuration(_ fixes: [TargetedFix]) -> TimeInterval {
        let baseTime: TimeInterval = 2.0 // 2 seconds base
        let perFixTime: TimeInterval = 0.5 // 0.5 seconds per fix
        return baseTime + (Double(fixes.count) * perFixTime)
    }
    
    private func assessRiskLevel(_ fixes: [TargetedFix]) -> RiskLevel {
        let highRiskCount = fixes.filter { $0.confidence == .low }.count
        let totalCount = fixes.count
        
        if totalCount == 0 { return .low }
        
        let riskRatio = Double(highRiskCount) / Double(totalCount)
        
        if riskRatio > 0.3 {
            return .high
        } else if riskRatio > 0.1 {
            return .medium
        } else {
            return .low
        }
    }
}

// MARK: - Supporting Types for AI Fix Assistant

struct FixProjectResult {
    let analysisResult: ProjectAnalysisResult
    let fixPlan: FixPlan
    let appliedFixes: [TargetedFix]
    let failedFixes: [FixFailure]
    let improvedFiles: [String]
    
    var successRate: Double {
        let total = appliedFixes.count + failedFixes.count
        return total > 0 ? Double(appliedFixes.count) / Double(total) : 0.0
    }
}

struct FixPlan {
    let targetedFixes: [TargetedFix]
    let estimatedDuration: TimeInterval
    let riskLevel: RiskLevel
    
    enum RiskLevel: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
}

struct TargetedFix {
    let issue: CodeIssue
    let strategy: FixStrategy
    let priority: Priority
    let confidence: Confidence
    let description: String
    let additionalChanges: [AdditionalChange]
    
    init(issue: CodeIssue, strategy: FixStrategy, priority: Priority, confidence: Confidence, description: String, additionalChanges: [AdditionalChange] = []) {
        self.issue = issue
        self.strategy = strategy
        self.priority = priority
        self.confidence = confidence
        self.description = description
        self.additionalChanges = additionalChanges
    }
    
    enum Priority: Int {
        case low = 1
        case medium = 2
        case high = 3
    }
    
    enum Confidence: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
}

enum FixStrategy {
    case replacePattern(pattern: String, replacement: String, requiresAsyncContext: Bool)
    case insertBefore(content: String, pattern: String)
    case insertAfter(content: String, pattern: String)
    case manualReview(String)
}

enum AdditionalChange {
    case addImport(String)
    case addAnnotation(String)
    case addMethod(String)
}

struct FixApplicationResult {
    let appliedFixes: [TargetedFix]
    let failedFixes: [FixFailure]
    let modifiedFiles: [String]
}

struct FixFailure {
    let fix: TargetedFix
    let error: Error
}

enum FixError: LocalizedError {
    case fileReadError(String)
    case patternNotFound(String)
    case manualReviewRequired
    case invalidRegex(String)
    
    var errorDescription: String? {
        switch self {
        case .fileReadError(let path):
            return "Could not read file: \(path)"
        case .patternNotFound(let pattern):
            return "Pattern not found: \(pattern)"
        case .manualReviewRequired:
            return "Manual review required for this fix"
        case .invalidRegex(let pattern):
            return "Invalid regex pattern: \(pattern)"
        }
    }
}
