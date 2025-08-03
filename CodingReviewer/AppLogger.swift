// SECURITY: API key handling - ensure proper encryption and keychain storage
import Foundation
import os.log

// / Comprehensive logging and error handling system
enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

// / Log categories for better organization
enum LogCategory: String, CaseIterable {
    case general = "General"
    case analysis = "Analysis"
    case performance = "Performance"
    case security = "Security"
    case ui = "UI"
    case ai = "AI"
    case network = "Network"

    var emoji: String {
        switch self {
        case .general: return "📝"
        case .analysis: return "🔍"
        case .performance: return "⚡"
        case .security: return "🔒"
        case .ui: return "🖥️"
        case .ai: return "🤖"
        case .network: return "🌐"
        }
    }
}

// / Enhanced application logger with categorization and performance tracking
final class AppLogger {
    private let logger = Logger(subsystem: "com.DanielStevens.CodingReviewer", category: "CodeAnalysis")
    private var performanceMetrics: [String: Date] = [:];

    static let shared = AppLogger()
    private init() {}

    func log(
        _ message: String,
        level: LogLevel = .info,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let filename = (file as NSString).lastPathComponent
        let logMessage = "\(category.emoji) \(level.rawValue) [\(filename):\(line)] \(function) - \(message)"

        switch level {
        case .debug:
            logger.debug("\(logMessage)")
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        case .critical:
            logger.critical("\(logMessage)")
        }
    }

    func startMeasurement(for operation: String) -> Date {
        let startTime = Date()
        performanceMetrics[operation] = startTime
        log("Started measuring: \(operation)", level: .debug, category: .performance)
        return startTime
    }

    func endMeasurement(for operation: String, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        performanceMetrics.removeValue(forKey: operation)
        log("Completed \(operation) in \(String(format: "%.3f", duration))s",
            level: .info, category: .performance)
    }

    func logAnalysisStart(codeLength: Int) {
        log("Starting code analysis for \(codeLength) characters", level: .info, category: .analysis)
    }

    func logAnalysisComplete(resultsCount: Int, duration: TimeInterval) {
        log("Analysis completed: \(resultsCount) results in \(String(format: "%.2f", duration))s",
            level: .info, category: .analysis)
    }

    func logError(_ error: Error, context: String, category: LogCategory = .general) {
        log("Error in \(context): \(error.localizedDescription)", level: .error, category: category)
    }

    func logAIRequest(type: String, tokenCount: Int) {
        log("AI \(type) request - \(tokenCount) tokens", level: .info, category: .ai)
    }

    func logAIResponse(type: String, success: Bool, duration: TimeInterval) {
        let status = success ? "successful" : "failed"
        log("AI \(type) response \(status) in \(String(format: "%.2f", duration))s",
            level: success ? .info : .warning, category: .ai)
    }

    // Convenience method for debug logging
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: .general, file: file, function: function, line: line)
    }

    // Convenience method for warning logging
    func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: .general, file: file, function: function, line: line)
    }

    // Convenience method for security logging
    func logSecurity(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: .security, file: file, function: function, line: line)
    }
}

// / Enhanced error types for better error handling
enum CodeReviewError: LocalizedError {
    case analysisTimeout
    case invalidInput(String)
    case analysisInterrupted
    case systemResourceExhausted

    nonisolated var errorDescription: String? {
        switch self {
        case .analysisTimeout:
            return "Analysis timed out. Please try with a smaller code sample."
        case .invalidInput(let reason):
            return "Invalid input: \(reason)"
        case .analysisInterrupted:
            return "Analysis was interrupted. Please try again."
        case .systemResourceExhausted:
            return "System resources exhausted. Please try again later."
        }
    }

    nonisolated var recoverySuggestion: String? {
        switch self {
        case .analysisTimeout:
            return "Try reducing the code size or simplifying the analysis."
        case .invalidInput:
            return "Please check your input and try again."
        case .analysisInterrupted:
            return "Restart the analysis process."
        case .systemResourceExhausted:
            return "Close other applications and try again."
        }
    }
}

// / Performance monitoring for analysis operations
actor PerformanceMonitor {
    private var analysisMetrics: [String: TimeInterval] = [:];

    func startMeasurement(for operation: String) -> Date {
        Date()
    }

    func endMeasurement(for operation: String, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        analysisMetrics[operation] = duration
        Task {
            await AppLogger.shared.log("Performance: \(operation) took \(String(format: "%.2f", duration))s", level: .debug, category: .performance)
        }
    }

    func getMetrics() -> [String: TimeInterval] {
        analysisMetrics
    }
}
