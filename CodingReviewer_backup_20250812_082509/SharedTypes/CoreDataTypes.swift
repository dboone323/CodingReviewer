import Foundation

// MARK: - Service Types
// Pure service interfaces - NO SwiftUI imports, NO Codable

public enum DataType: String, CaseIterable, Sendable {
    case codeFile = "code_file"
    case documentation = "documentation" 
    case configuration = "configuration"
    case test = "test"
    case asset = "asset"
    case other = "other"
    
    // Additional cases for enterprise integration
    case codeAnalysis = "code_analysis"
    case usageAnalytics = "usage_analytics"
    case performanceMetrics = "performance_metrics"
    case insights = "insights"
    case processingJobs = "processing_jobs"
    case systemConfiguration = "system_configuration"
    case errorLogs = "error_logs"
    case userActivity = "user_activity"
    
    public var displayName: String {
        switch self {
        case .codeFile: return "Code File"
        case .documentation: return "Documentation"
        case .configuration: return "Configuration"
        case .test: return "Test"
        case .asset: return "Asset"
        case .other: return "Other"
        case .codeAnalysis: return "Code Analysis"
        case .usageAnalytics: return "Usage Analytics"
        case .performanceMetrics: return "Performance Metrics"
        case .insights: return "Insights"
        case .processingJobs: return "Processing Jobs"
        case .systemConfiguration: return "System Configuration"
        case .errorLogs: return "Error Logs"
        case .userActivity: return "User Activity"
        }
    }
}

public enum ExportFormat: String, CaseIterable, Sendable {
    case json = "json"
    case csv = "csv"
    case pdf = "pdf"
    case html = "html"
    case xml = "xml"
    case markdown = "markdown"
    
    public var fileExtension: String {
        rawValue
    }
    
    public var icon: String {
        switch self {
        case .json: return "doc.text"
        case .csv: return "tablecells"
        case .pdf: return "doc.richtext"
        case .html: return "globe"
        case .xml: return "doc.text"
        case .markdown: return "doc.plaintext"
        }
    }
}

public enum TestPriority: String, CaseIterable, Sendable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    public var sortOrder: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

public enum ProgrammingLanguage: String, CaseIterable, Sendable {
    case swift = "swift"
    case objectiveC = "objc"
    case javascript = "javascript"
    case typescript = "typescript"
    case python = "python"
    case java = "java"
    case kotlin = "kotlin"
    case cpp = "cpp"
    case cPlusPlus = "cPlusPlus"
    case c = "c"
    case go = "go"
    case rust = "rust"
    case csharp = "csharp"
    case unknown = "unknown"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .objectiveC: return "Objective-C"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .python: return "Python"
        case .java: return "Java"
        case .kotlin: return "Kotlin"
        case .cpp: return "C++"
        case .cPlusPlus: return "C++"
        case .c: return "C"
        case .go: return "Go"
        case .rust: return "Rust"
        case .csharp: return "C#"
        case .unknown: return "Unknown"
        case .other: return "Other"
        }
    }
}
