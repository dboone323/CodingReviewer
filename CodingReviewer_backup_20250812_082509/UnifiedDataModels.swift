import Foundation

// MARK: - Unified Analysis Data Models

// This file contains the single source of truth for all analysis-related data structures

/// Represents a single analysis result from code examination
public struct AnalysisResult: Identifiable, Sendable, @preconcurrency Codable, Hashable {
    public let id: UUID
    public let type: String // "Security", "Performance", "Quality", etc.
    public let severity: String // "High", "Medium", "Low"
    public let message: String
    public let lineNumber: Int
    public let suggestion: String

    public init(
        id: UUID = UUID(),
        type: String,
        severity: String,
        message: String,
        lineNumber: Int,
        suggestion: String = ""
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.message = message
        self.lineNumber = lineNumber
        self.suggestion = suggestion
    }

    /// Severity level for sorting and UI display
    enum SeverityLevel: String, CaseIterable, Codable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        var priority: Int {
            switch self {
            case .critical: 4
            case .high: 3
            case .medium: 2
            case .low: 1
            }
        }

        var color: String {
            switch self {
            case .critical: "red"
            case .high: "red"
            case .medium: "orange"
            case .low: "yellow"
            }
        }
    }

    var severityLevel: SeverityLevel {
        SeverityLevel(rawValue: severity) ?? .low
    }
}

/// File-specific analysis result for batch operations
struct FileAnalysisResult: Identifiable, Sendable, @preconcurrency Codable {
    let id: UUID
    let fileName: String
    let filePath: String
    let fileType: String
    let issuesFound: Int
    let issues: [AnalysisIssue]
    let analysisDate: Date

    init(
        id: UUID = UUID(),
        fileName: String,
        filePath: String,
        fileType: String,
        issuesFound: Int,
        issues: [AnalysisIssue],
        analysisDate: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.filePath = filePath
        self.fileType = fileType
        self.issuesFound = issuesFound
        self.issues = issues
        self.analysisDate = analysisDate
    }
}

/// Individual issue within a file analysis
struct AnalysisIssue: Identifiable, Sendable, @preconcurrency Codable {
    let id: UUID
    let type: String
    let severity: String
    let message: String
    let lineNumber: Int
    let line: String

    init(id: UUID = UUID(), type: String, severity: String, message: String, lineNumber: Int, line: String = "") {
        self.id = id
        self.type = type
        self.severity = severity
        self.message = message
        self.lineNumber = lineNumber
        self.line = line
    }
}

/// File upload and management
struct UploadedFile: Identifiable, Sendable, @preconcurrency Codable {
    let id: UUID
    let name: String
    let path: String
    let size: Int
    let content: String
    let type: String
    let uploadDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        size: Int,
        content: String,
        type: String,
        uploadDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.size = size
        self.content = content
        self.type = type
        self.uploadDate = uploadDate
    }
}

// MARK: - Legacy Support

// These extensions provide compatibility with existing code

extension AnalysisResult {
    /// Legacy support for old AnalysisResult structure
    init(type: ResultType, message: String, line: Int?, severity: Severity) {
        id = UUID()
        self.type = type.displayName
        self.severity = severity.displayName
        self.message = message
        lineNumber = line ?? 0
        suggestion = ""
    }

    enum ResultType {
        case quality
        case security
        case suggestion
        case performance

        var displayName: String {
            switch self {
            case .quality: "Quality"
            case .security: "Security"
            case .suggestion: "Suggestion"
            case .performance: "Performance"
            }
        }
    }

    enum Severity {
        case low
        case medium
        case high
        case critical

        var displayName: String {
            switch self {
            case .low: "Low"
            case .medium: "Medium"
            case .high: "High"
            case .critical: "Critical"
            }
        }
    }
}

// MARK: - Analysis Protocols

protocol CodeAnalyzer {
    func analyze(_ code: String) async -> [AnalysisResult]
}

// MARK: - Helper Extensions

extension [AnalysisResult] {
    var highSeverityCount: Int {
        count(where: { $0.severityLevel == .high || $0.severityLevel == .critical })
    }

    var mediumSeverityCount: Int {
        count(where: { $0.severityLevel == .medium })
    }

    var lowSeverityCount: Int {
        count(where: { $0.severityLevel == .low })
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func sortedBySeverity() -> [AnalysisResult] {
        sorted { $0.severityLevel.priority > $1.severityLevel.priority }
    }
}
