import Foundation

// MARK: - Service Types

// Pure service interfaces - NO SwiftUI imports, NO Codable

public enum DataType: String, CaseIterable, Sendable {
    case codeFile = "code_file"
    case documentation
    case configuration
    case test
    case asset
    case other

    // Additional cases for enterprise integration
    case codeAnalysis = "code_analysis"
    case usageAnalytics = "usage_analytics"
    case performanceMetrics = "performance_metrics"
    case insights
    case processingJobs = "processing_jobs"
    case systemConfiguration = "system_configuration"
    case errorLogs = "error_logs"
    case userActivity = "user_activity"

    public var displayName: String {
        switch self {
        case .codeFile: "Code File"
        case .documentation: "Documentation"
        case .configuration: "Configuration"
        case .test: "Test"
        case .asset: "Asset"
        case .other: "Other"
        case .codeAnalysis: "Code Analysis"
        case .usageAnalytics: "Usage Analytics"
        case .performanceMetrics: "Performance Metrics"
        case .insights: "Insights"
        case .processingJobs: "Processing Jobs"
        case .systemConfiguration: "System Configuration"
        case .errorLogs: "Error Logs"
        case .userActivity: "User Activity"
        }
    }
}

public enum ExportFormat: String, CaseIterable, Sendable {
    case json
    case csv
    case pdf
    case html
    case xml
    case markdown

    public var fileExtension: String {
        rawValue
    }

    public var icon: String {
        switch self {
        case .json: "doc.text"
        case .csv: "tablecells"
        case .pdf: "doc.richtext"
        case .html: "globe"
        case .xml: "doc.text"
        case .markdown: "doc.plaintext"
        }
    }
}

public enum TestPriority: String, CaseIterable, Sendable {
    case critical
    case high
    case medium
    case low

    public var sortOrder: Int {
        switch self {
        case .critical: 4
        case .high: 3
        case .medium: 2
        case .low: 1
        }
    }
}

public enum ProgrammingLanguage: String, CaseIterable, Sendable {
    case swift
    case objectiveC = "objc"
    case javascript
    case typescript
    case python
    case java
    case kotlin
    case cpp
    case cPlusPlus
    case c
    case go
    case rust
    case csharp
    case unknown
    case other

    public var displayName: String {
        switch self {
        case .swift: "Swift"
        case .objectiveC: "Objective-C"
        case .javascript: "JavaScript"
        case .typescript: "TypeScript"
        case .python: "Python"
        case .java: "Java"
        case .kotlin: "Kotlin"
        case .cpp: "C++"
        case .cPlusPlus: "C++"
        case .c: "C"
        case .go: "Go"
        case .rust: "Rust"
        case .csharp: "C#"
        case .unknown: "Unknown"
        case .other: "Other"
        }
    }
}
