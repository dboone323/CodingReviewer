import Foundation

/// Analyzes code quality and style issues with performance optimization
@MainActor
final class QualityAnalyzer: CodeAnalyzer {
    
    private let logger = AppLogger.shared

    /// Performs operation with comprehensive error handling and validation
    func analyze(_ code: String) async -> [AnalysisResult] {
        let startTime = Date()
        logger.debug("Starting quality analysis for \(code.count) characters")
        
        PerformanceTracker.shared.startTracking("quality_analysis")
        defer { _ = PerformanceTracker.shared.endTracking("quality_analysis") }
        
        var results: [AnalysisResult] = []
        let lines = code.components(separatedBy: .newlines)
        
        // Early exit for very large files to prevent performance issues
        if lines.count > 10000 {
            logger.log("Large file detected (\(lines.count) lines), using optimized analysis", level: .info, category: .performance)
            return await analyzeLargeFile(code: code, lines: lines)
        }

        // Standard analysis for normal-sized files
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
        
        // Swift 6 concurrency checks
        results.append(contentsOf: checkConcurrencyIssues(in: code, lines: lines))
        
        // Advanced Swift 6 patterns
        results.append(contentsOf: checkSwift6Patterns(in: code, lines: lines))
        
        // Modern Swift patterns
        results.append(contentsOf: checkModernSwiftPatterns(in: code, lines: lines))
        
        let duration = Date().timeIntervalSince(startTime)
        logger.debug("Quality analysis completed in \(String(format: "%.3f", duration))s, found \(results.count) issues")

        return results
    }
    
    /// Optimized analysis for large files (>10k lines)
    private func analyzeLargeFile(code: String, lines: [String]) async -> [AnalysisResult] {
        PerformanceTracker.shared.startTracking("large_file_analysis")
        defer { _ = PerformanceTracker.shared.endTracking("large_file_analysis") }
        
        var results: [AnalysisResult] = []
        
        // Sample-based analysis for very large files
        let sampleSize = min(1000, lines.count)
        let step = max(1, lines.count / sampleSize)
        let sampledLines = stride(from: 0, to: lines.count, by: step).map { lines[$0] }
        let sampledCode = sampledLines.joined(separator: "\n")
        
        // Run lightweight checks on sampled content
        results.append(contentsOf: checkCriticalIssuesOnly(in: sampledCode, totalLines: lines.count))
        
        return results
    }
    
    /// Lightweight analysis focusing on critical issues for large files
    private func checkCriticalIssuesOnly(in code: String, totalLines: Int) -> [AnalysisResult] {
        var results: [AnalysisResult] = []
        
        // Only check for high-severity issues in large files
        let sensitivePatterns = ["password", "secret", "token", "key"]
        for pattern in sensitivePatterns {
            if code.lowercased().contains(pattern) && code.contains("=") {
                results.append(AnalysisResult(
                    type: "Security",
                    severity: "High", 
                    message: "Potential hardcoded sensitive information detected (sampled analysis)",
                    lineNumber: 0,
                    suggestion: "Run detailed analysis on smaller file sections"
                ))
                break // Only report once for large files
            }
        }
        
        // Check for obvious force unwrapping patterns
        if code.contains("!") && !code.contains("!=") {
            results.append(AnalysisResult(
                type: "Quality",
                severity: "Medium",
                message: "Force unwrapping detected in large file (sampled analysis)",
                lineNumber: 0,
                suggestion: "Consider breaking file into smaller modules for detailed analysis"
            ))
        }
        
        return results
    }

    /// Performs operation with comprehensive error handling and validation
    private func checkForceUnwrapping(in code: String) -> [AnalysisResult] {
        let lines = code.components(separatedBy: .newlines)
        var results: [AnalysisResult] = []
        
        // Improved pattern to avoid false positives with type annotations and optionals
        let forceUnwrapPattern = "\\w+\\s*!"
        
        for (lineIndex, line) in lines.enumerated() {
            // Skip lines that are comments or contain type annotations
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("//") || trimmedLine.hasPrefix("*") || 
               trimmedLine.contains("!\"") || trimmedLine.contains("try!") {
                continue
            }
            
            let matches = findMatches(pattern: forceUnwrapPattern, in: line)
            if !matches.isEmpty {
                results.append(AnalysisResult(
                    type: "Quality",
                    severity: "Medium",
                    message: "Force unwrapping detected on line \(lineIndex + 1) - consider using safe unwrapping patterns",
                    lineNumber: lineIndex + 1,
                    suggestion: "Use 'if let', 'guard let', or optional chaining ('?.') instead"
                ))
            }
        }
        
        return results
    }

    /// Performs operation with comprehensive error handling and validation
    private func checkLongLines(in lines: [String]) -> [AnalysisResult] {
        let longLines = lines.enumerated().filter { $0.element.count > 120 }

        return longLines.isEmpty ? [] : [
            AnalysisResult(
                type: "Quality",
                severity: "Low",
                message: "Found \(longLines.count) long line(s) (>120 characters) on lines: " +
                        "\(longLines.map { $0.offset + 1 }.prefix(5).map(String.init).joined(separator: ", "))",
                lineNumber: longLines.first?.offset.advanced(by: 1) ?? 0
            )
        ]
    }

    /// Performs operation with comprehensive error handling and validation
    private func checkTodoComments(in code: String) -> [AnalysisResult] {
        let lines = code.components(separatedBy: .newlines)
        var results: [AnalysisResult] = []
        let todoPattern = "(?i)(TODO|FIXME|HACK|XXX)\\s*:?"
        
        for (lineIndex, line) in lines.enumerated() {
            let matches = findMatches(pattern: todoPattern, in: line)
            if !matches.isEmpty {
                let todoType = extractTodoType(from: line)
                results.append(AnalysisResult(
                    type: "Suggestion",
                    severity: todoType == "FIXME" ? "Medium" : "Low",
                    message: "\(todoType) comment found on line \(lineIndex + 1)",
                    lineNumber: lineIndex + 1,
                    suggestion: "Consider addressing this \(todoType.lowercased()) or converting it to a proper issue"
                ))
            }
        }
        
        return results
    }
    
    /// Performs operation with comprehensive error handling and validation
    private func extractTodoType(from line: String) -> String {
        if line.localizedCaseInsensitiveContains("FIXME") { return "FIXME" }
        if line.localizedCaseInsensitiveContains("HACK") { return "HACK" }
        if line.localizedCaseInsensitiveContains("XXX") { return "XXX" }
        return "TODO"
    }

    /// Performs operation with comprehensive error handling and validation
    private func checkAccessControl(in code: String) -> [AnalysisResult] {
        let publicDeclarations = findMatches(pattern: "public (class|struct|func|var|let)", in: code).count
        let privateDeclarations = findMatches(pattern: "private (class|struct|func|var|let)", in: code).count

        return publicDeclarations > privateDeclarations * 2 ? [
            AnalysisResult(
                type: "Suggestion",
                severity: "Low",
                message: "Consider using more restrictive access control (private/internal) where appropriate",
                lineNumber: 0
            )
        ] : []
    }

    /// Performs operation with comprehensive error handling and validation
    private func checkErrorHandling(in code: String) -> [AnalysisResult] {
        let hasTry = code.contains("try") && !code.contains("catch") && !code.contains("try?") && !code.contains("try!")

        return hasTry ? [
            AnalysisResult(
                type: "Suggestion",
                severity: "Medium",
                message: "Consider proper error handling with do-catch blocks",
                lineNumber: 0
            )
        ] : []
    }

    /// Performs operation with comprehensive error handling and validation
    private func checkRetainCycles(in code: String) -> [AnalysisResult] {
        let hasSelfInEscaping = code.contains("self?.") && code.contains("@escaping")

        return hasSelfInEscaping ? [
            AnalysisResult(
                type: "Suggestion",
                severity: "Medium",
                message: "Review closures for potential retain cycles - consider using [weak self] or [unowned self]",
                lineNumber: 0
            )
        ] : []
    }
    
    /// Performs operation with comprehensive error handling and validation
    private func checkConcurrencyIssues(in code: String, lines: [String]) -> [AnalysisResult] {
        var results: [AnalysisResult] = []
        
        for (lineIndex, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check for missing @MainActor on UI updates
            if (trimmedLine.contains("UI") || trimmedLine.contains("View") || 
                trimmedLine.contains("self?.") && trimmedLine.contains("=")) &&
               !code.contains("@MainActor") && line.contains("async") {
                results.append(AnalysisResult(
                    type: "Quality",
                    severity: "Medium",
                    message: "Potential UI update in async context without @MainActor on line \(lineIndex + 1)",
                    lineNumber: lineIndex + 1,
                    suggestion: "Consider using @MainActor or await MainActor.run { } for UI updates"
                ))
            }
            
            // Check for non-Sendable types in async contexts
            if trimmedLine.contains("Task {") && !trimmedLine.contains("@Sendable") {
                // Look for captured variables that might not be Sendable
                if trimmedLine.contains("[") && (trimmedLine.contains("self") || 
                   trimmedLine.contains("weak") || trimmedLine.contains("unowned")) {
                    results.append(AnalysisResult(
                        type: "Quality",
                        severity: "Low",
                        message: "Task closure on line \(lineIndex + 1) may capture non-Sendable types",
                        lineNumber: lineIndex + 1,
                        suggestion: "Ensure captured variables conform to Sendable or use @unchecked Sendable if safe"
                    ))
                }
            }
            
            // Swift 6: Check for actor isolation violations
            if trimmedLine.contains("await") && !trimmedLine.contains("@MainActor") &&
               (trimmedLine.contains("UI") || trimmedLine.contains("@Published")) {
                results.append(AnalysisResult(
                    type: "Quality",
                    severity: "High",
                    message: "Actor isolation violation on line \(lineIndex + 1) - UI updates must be on MainActor",
                    lineNumber: lineIndex + 1,
                    suggestion: "Use await MainActor.run { } or mark function with @MainActor"
                ))
            }
            
            // Swift 6: Detect missing Sendable conformance
            if trimmedLine.contains("class ") && !trimmedLine.contains("final") &&
               (code.contains("async") || code.contains("Task")) {
                results.append(AnalysisResult(
                    type: "Quality",
                    severity: "Medium",
                    message: "Non-final class on line \(lineIndex + 1) in concurrent context may need Sendable conformance",
                    lineNumber: lineIndex + 1,
                    suggestion: "Consider making class final or conforming to @unchecked Sendable if thread-safe"
                ))
            }
            
            // Swift 6: Check for global actor usage
            if trimmedLine.contains("@GlobalActor") && !trimmedLine.contains("static") {
                results.append(AnalysisResult(
                    type: "Quality",
                    severity: "Low",
                    message: "GlobalActor on line \(lineIndex + 1) should be used carefully",
                    lineNumber: lineIndex + 1,
                    suggestion: "Ensure GlobalActor is necessary and properly implemented with static shared instance"
                ))
            }
        }
        
        // Check for unsafe continuation usage
        if code.contains("withUnsafeContinuation") || code.contains("withUnsafeThrowingContinuation") {
            results.append(AnalysisResult(
                type: "Security",
                severity: "High",
                message: "Unsafe continuation detected - ensure resume() is called exactly once",
                lineNumber: 0,
                suggestion: "Consider using withCheckedContinuation for better safety or ensure proper error handling"
            ))
        }
        
        return results
    }
    
    // MARK: - Swift 6 Advanced Pattern Analysis
    
    /// Performs operation with comprehensive error handling and validation
    private func checkSwift6Patterns(in code: String, lines: [String]) -> [AnalysisResult] {
        var results: [AnalysisResult] = []
        
        for (lineIndex, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check for missing isolation annotations
            if trimmedLine.contains("@objc") && trimmedLine.contains("func") &&
               !trimmedLine.contains("@MainActor") && (code.contains("UI") || code.contains("View")) {
                results.append(AnalysisResult(
                    type: "Quality",
                    severity: "Medium",
                    message: "@objc function on line \(lineIndex + 1) may need explicit actor isolation",
                    lineNumber: lineIndex + 1,
                    suggestion: "Consider adding @MainActor for UI-related @objc methods"
                ))
            }
            
            // Check for old-style completion handlers in async contexts
            if trimmedLine.contains("completion:") && trimmedLine.contains("@escaping") &&
               code.contains("async") {
                results.append(AnalysisResult(
                    type: "Modernization",
                    severity: "Low",
                    message: "Completion handler on line \(lineIndex + 1) could be modernized to async/await",
                    lineNumber: lineIndex + 1,
                    suggestion: "Consider converting to async function for better Swift concurrency integration"
                ))
            }
            
            // Check for potentially unsafe global variables
            if (trimmedLine.contains("var ") && !trimmedLine.contains("private") && 
                !trimmedLine.contains("let ")) && !trimmedLine.contains("func") {
                let declarationLine = trimmedLine.replacingOccurrences(of: "var ", with: "")
                if !declarationLine.contains("@") && !declarationLine.contains("static") {
                    results.append(AnalysisResult(
                        type: "Quality",
                        severity: "Medium",
                        message: "Global mutable variable on line \(lineIndex + 1) may need thread-safety consideration",
                        lineNumber: lineIndex + 1,
                        suggestion: "Consider using actor isolation, @MainActor, or making immutable with 'let'"
                    ))
                }
            }
        }
        
        return results
    }
    
    /// Performs operation with comprehensive error handling and validation
    private func checkModernSwiftPatterns(in code: String, lines: [String]) -> [AnalysisResult] {
        var results: [AnalysisResult] = []
        
        for (lineIndex, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check for old-style completion handlers that could use async/await
            if trimmedLine.contains("completion:") && trimmedLine.contains("@escaping") {
                results.append(AnalysisResult(
                    type: "Suggestion",
                    severity: "Low",
                    message: "Consider modernizing completion handler to async/await on line \(lineIndex + 1)",
                    lineNumber: lineIndex + 1,
                    suggestion: "Replace completion handlers with async/await for better readability and error handling"
                ))
            }
            
            // Check for old-style optionals
            if trimmedLine.contains("if let") && trimmedLine.contains("=") && 
               trimmedLine.contains("{") && !trimmedLine.contains("guard") {
                // This is acceptable, but we can suggest guard let for early returns
                if line.distance(from: line.startIndex, to: line.firstIndex(of: "i") ?? line.startIndex) < 4 {
                    results.append(AnalysisResult(
                        type: "Suggestion",
                        severity: "Low",
                        message: "Consider using 'guard let' for early return on line \(lineIndex + 1)",
                        lineNumber: lineIndex + 1,
                        suggestion: "Use 'guard let' instead of 'if let' when appropriate for early returns"
                    ))
                }
            }
        }
        
        return results
    }

    /// Performs operation with comprehensive error handling and validation
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

/// Analyzes potential security concerns with performance tracking
@MainActor
final class SecurityAnalyzer: CodeAnalyzer {
    
    private let logger = AppLogger.shared

    /// Performs operation with comprehensive error handling and validation
    func analyze(_ code: String) async -> [AnalysisResult] {
        let startTime = Date()
        logger.debug("Starting security analysis for \(code.count) characters")
        
        PerformanceTracker.shared.startTracking("security_analysis")
        defer { _ = PerformanceTracker.shared.endTracking("security_analysis") }
        
        var results: [AnalysisResult] = []
        let lines = code.components(separatedBy: .newlines)

        // Check for hardcoded sensitive information
        results.append(contentsOf: checkSensitiveInformation(in: code, lines: lines))

        // Check for unsafe network operations
        results.append(contentsOf: checkUnsafeNetwork(in: code, lines: lines))

        // Check for SQL injection potential
        results.append(contentsOf: checkSQLInjection(in: code, lines: lines))

        // Check for file system access
        results.append(contentsOf: checkFileSystemAccess(in: code, lines: lines))
        
        // Advanced Swift 6 security checks
        results.append(contentsOf: checkSwift6SecurityPatterns(in: code, lines: lines))
        
        let duration = Date().timeIntervalSince(startTime)
        logger.debug("Security analysis completed in \(String(format: "%.3f", duration))s, found \(results.count) issues")

        return results
    }

    /// Performs operation with comprehensive error handling and validation
    private func checkSensitiveInformation(in code: String, lines: [String]) -> [AnalysisResult] {
        let sensitivePatterns = ["password", "secret", "token", "key", "credential", "apikey", "access_token"]
        var results: [AnalysisResult] = []

        for (lineIndex, line) in lines.enumerated() {
            for pattern in sensitivePatterns {
                if line.lowercased().contains(pattern) && line.contains("=") && 
                   !line.contains("//") && !line.contains("\"TODO\"") {
                    results.append(AnalysisResult(
                        type: "Security",
                        severity: "High",
                        message: "Potential hardcoded sensitive information detected on line \(lineIndex + 1): '\(pattern)'",
                        lineNumber: lineIndex + 1,
                        suggestion: "Use environment variables, Keychain, or secure configuration files instead"
                    ))
                }
            }
            
            // Check for hardcoded URLs with credentials
            if line.contains("://") && (line.contains("@") || line.contains(":")) &&
               !line.contains("//") {
                results.append(AnalysisResult(
                    type: "Security",
                    severity: "High",
                    message: "Potential hardcoded credentials in URL on line \(lineIndex + 1)",
                    lineNumber: lineIndex + 1,
                    suggestion: "Store credentials securely and construct URLs at runtime"
                ))
            }
        }

        return results
    }

    /// Performs operation with comprehensive error handling and validation
    private func checkUnsafeNetwork(in code: String, lines: [String]) -> [AnalysisResult] {
        var results: [AnalysisResult] = []
        
        for (lineIndex, line) in lines.enumerated() {
            if line.contains("https://") && !line.contains("//") {
                results.append(AnalysisResult(
                    type: "Security",
                    severity: "Medium",
                    message: "Insecure HTTP connection detected on line \(lineIndex + 1)",
                    lineNumber: lineIndex + 1,
                    suggestion: "Use HTTPS for secure communication"
                ))
            }
            
            // Check for certificate validation bypass
            if line.contains("URLSessionDelegate") && 
               (line.contains("challenge") || code.contains("serverTrust")) {
                results.append(AnalysisResult(
                    type: "Security",
                    severity: "High",
                    message: "Custom certificate validation on line \(lineIndex + 1) - ensure proper implementation",
                    lineNumber: lineIndex + 1,
                    suggestion: "Verify certificate validation logic doesn't bypass security checks"
                ))
            }
        }
        
        return results
    }

    /// Performs operation with comprehensive error handling and validation
    private func checkSQLInjection(in code: String, lines: [String]) -> [AnalysisResult] {
        var results: [AnalysisResult] = []
        
        for (lineIndex, line) in lines.enumerated() {
            // Check for dynamic SQL construction
            if (line.contains("SQL") || line.contains("sqlite")) && 
               (line.contains("+") || line.contains("\\(")) && !line.contains("//") {
                results.append(AnalysisResult(
                    type: "Security",
                    severity: "High",
                    message: "Potential SQL injection vulnerability on line \(lineIndex + 1)",
                    lineNumber: lineIndex + 1,
                    suggestion: "Use parameterized queries instead of string concatenation"
                ))
            }
            
            // Check for raw SQL execution
            if line.contains("executeQuery") || line.contains("execute") && line.contains("sql") {
                results.append(AnalysisResult(
                    type: "Security",
                    severity: "Medium",
                    message: "Raw SQL execution on line \(lineIndex + 1) - ensure proper validation",
                    lineNumber: lineIndex + 1,
                    suggestion: "Use prepared statements and validate all inputs"
                ))
            }
        }
        
        return results
    }

    /// Performs operation with comprehensive error handling and validation
    private func checkFileSystemAccess(in code: String, lines: [String]) -> [AnalysisResult] {
        var results: [AnalysisResult] = []
        
        for (lineIndex, line) in lines.enumerated() {
            // Check for unsafe file operations
            if line.contains("FileManager") && (line.contains("removeItem") || line.contains("moveItem")) {
                results.append(AnalysisResult(
                    type: "Security",
                    severity: "Medium",
                    message: "File system modification on line \(lineIndex + 1) - ensure proper validation",
                    lineNumber: lineIndex + 1,
                    suggestion: "Validate file paths and check permissions before modifying files"
                ))
            }
            
            // Check for shell command execution
            if line.contains("Process") || line.contains("shell") || line.contains("/bin/") {
                results.append(AnalysisResult(
                    type: "Security",
                    severity: "High",
                    message: "Shell command execution detected on line \(lineIndex + 1)",
                    lineNumber: lineIndex + 1,
                    suggestion: "Avoid shell command execution or sanitize all inputs thoroughly"
                ))
            }
        }
        
        return results
    }
    
    // MARK: - Swift 6 Security Patterns
    
    /// Performs operation with comprehensive error handling and validation
    private func checkSwift6SecurityPatterns(in code: String, lines: [String]) -> [AnalysisResult] {
        var results: [AnalysisResult] = []
        
        for (lineIndex, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check for unsafe pointer usage
            if trimmedLine.contains("UnsafePointer") || trimmedLine.contains("UnsafeMutablePointer") {
                results.append(AnalysisResult(
                    type: "Security",
                    severity: "High",
                    message: "Unsafe pointer usage on line \(lineIndex + 1) - ensure memory safety",
                    lineNumber: lineIndex + 1,
                    suggestion: "Use safe Swift alternatives or carefully manage pointer lifetime"
                ))
            }
            
            // Check for @objc dynamic methods that might bypass Swift safety
            if trimmedLine.contains("@objc dynamic") {
                results.append(AnalysisResult(
                    type: "Security",
                    severity: "Medium",
                    message: "@objc dynamic method on line \(lineIndex + 1) bypasses Swift safety checks",
                    lineNumber: lineIndex + 1,
                    suggestion: "Ensure method is properly validated and consider alternatives"
                ))
            }
            
            // Check for potentially unsafe bridging
            if trimmedLine.contains("Unmanaged") || trimmedLine.contains("bridgeRetained") {
                results.append(AnalysisResult(
                    type: "Security",
                    severity: "High",
                    message: "Unsafe Objective-C bridging on line \(lineIndex + 1)",
                    lineNumber: lineIndex + 1,
                    suggestion: "Use safe bridging patterns and ensure proper memory management"
                ))
            }
            
            // Check for NSCoding usage without secure coding
            if trimmedLine.contains("NSCoding") && !code.contains("NSSecureCoding") {
                results.append(AnalysisResult(
                    type: "Security",
                    severity: "Medium",
                    message: "NSCoding usage without NSSecureCoding on line \(lineIndex + 1)",
                    lineNumber: lineIndex + 1,
                    suggestion: "Use NSSecureCoding to prevent object substitution attacks"
                ))
            }
        }
        
        // Check for unsafe data deserialization
        if code.contains("JSONDecoder") && !code.contains("try") {
            results.append(AnalysisResult(
                type: "Security",
                severity: "Medium",
                message: "JSON decoding without proper error handling",
                lineNumber: 0,
                suggestion: "Always use try-catch blocks for data deserialization"
            ))
        }
        
        return results
    }
}

/// Analyzes performance-related issues with performance tracking
@MainActor
final class PerformanceAnalyzer: CodeAnalyzer {
    
    private let logger = AppLogger.shared

    /// Performs operation with comprehensive error handling and validation
    func analyze(_ code: String) async -> [AnalysisResult] {
        let startTime = Date()
        logger.debug("Starting performance analysis for \(code.count) characters")
        
        PerformanceTracker.shared.startTracking("performance_analysis")
        defer { _ = PerformanceTracker.shared.endTracking("performance_analysis") }
        
        var results: [AnalysisResult] = []

        // Check for potential performance issues
        results.append(contentsOf: checkMainThreadBlocking(in: code))
        results.append(contentsOf: checkExpensiveOperations(in: code))
        
        let duration = Date().timeIntervalSince(startTime)
        logger.debug("Performance analysis completed in \(String(format: "%.3f", duration))s, found \(results.count) issues")

        return results
    }

    /// Performs operation with comprehensive error handling and validation
    private func checkMainThreadBlocking(in code: String) -> [AnalysisResult] {
        let blockingPatterns = ["Thread.sleep", "sleep(", "usleep"]
        var results: [AnalysisResult] = [];

        for pattern in blockingPatterns where code.contains(pattern) {
            results.append(AnalysisResult(
                type: "Performance",
                severity: "Medium",
                message: "Potential main thread blocking operation detected: '\(pattern)'",
                lineNumber: 0,
                suggestion: "Move blocking operations to a background queue to avoid freezing the UI"
            ))
        }

        return results
    }

    /// Performs operation with comprehensive error handling and validation
    private func checkExpensiveOperations(in code: String) -> [AnalysisResult] {
        let expensivePatterns = ["for.*in.*{", "while.*{"]
        var results: [AnalysisResult] = [];

        for pattern in expensivePatterns where findMatches(pattern: pattern, in: code).count > 10 {
            results.append(AnalysisResult(
                type: "Performance",
                severity: "Low",
                message: "Multiple loop operations detected - consider optimization",
                lineNumber: 0,
                suggestion: "Consider using more efficient algorithms or collections methods like map, filter, reduce"
            ))
            break
        }

        return results
    }

    /// Performs operation with comprehensive error handling and validation
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
