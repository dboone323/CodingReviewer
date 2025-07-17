import Foundation
import os.log

/// Comprehensive logging and error handling system
enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

/// Application logger with proper categorization
final class AppLogger {
    private let logger = Logger(subsystem: "com.DanielStevens.CodingReviewer", category: "CodeAnalysis")
    
    static let shared = AppLogger()
    private init() {}
    
    func log(
        _ message: String, 
        level: LogLevel = .info, 
        file: String = #file, 
        function: String = #function, 
        line: Int = #line
    ) {
        let filename = (file as NSString).lastPathComponent
        let logMessage = "\(level.rawValue) [\(filename):\(line)] \(function) - \(message)"
        
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
    
    func logAnalysisStart(codeLength: Int) {
        log("Starting code analysis for \(codeLength) characters", level: .info)
    }
    
    func logAnalysisComplete(resultsCount: Int, duration: TimeInterval) {
        log("Analysis completed: \(resultsCount) results in \(String(format: "%.2f", duration))s", level: .info)
    }
    
    func logError(_ error: Error, context: String) {
        log("Error in \(context): \(error.localizedDescription)", level: .error)
    }
}

/// Enhanced error types for better error handling
enum CodeReviewError: LocalizedError {
    case analysisTimeout
    case invalidInput(String)
    case analysisInterrupted
    case systemResourceExhausted
    
    var errorDescription: String? {
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
    
    var recoverySuggestion: String? {
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

/// Performance monitoring for analysis operations
actor PerformanceMonitor {
    private var analysisMetrics: [String: TimeInterval] = [:]
    
    func startMeasurement(for operation: String) -> Date {
        Date()
    }
    
    func endMeasurement(for operation: String, startTime: Date) {
        let duration = Date().timeIntervalSince(startTime)
        analysisMetrics[operation] = duration
        AppLogger.shared.log("Performance: \(operation) took \(String(format: "%.2f", duration))s", level: .debug)
    }
    
    func getMetrics() -> [String: TimeInterval] {
        analysisMetrics
    }
}
