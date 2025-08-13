import Foundation

// MARK: - Processing & System Types
// Pure processing and system data models - NO SwiftUI imports, NO Codable

public struct ProcessingJob: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let type: JobType
    public let status: JobStatus
    public let priority: JobPriority
    public let progress: Double
    
    public init(id: UUID = UUID(), name: String, type: JobType = .codeAnalysis, status: JobStatus = .pending, priority: JobPriority = .normal, progress: Double = 0.0) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
        self.priority = priority
        self.progress = progress
    }
    
    public enum JobType: String, CaseIterable, Sendable {
        case codeAnalysis = "Code Analysis"
        case documentation = "Documentation"
        case testing = "Testing"
        case refactoring = "Refactoring"
        case optimization = "Optimization"
        
        public var icon: String {
            switch self {
            case .codeAnalysis: return "doc.text.magnifyingglass"
            case .documentation: return "doc.text"
            case .testing: return "checkmark.seal"
            case .refactoring: return "wand.and.rays"
            case .optimization: return "speedometer"
            }
        }
    }
    
    public enum JobStatus: String, CaseIterable, Sendable {
        case pending = "Pending"
        case running = "Running"
        case completed = "Completed"
        case failed = "Failed"
        case cancelled = "Cancelled"
    }
    
    public enum JobPriority: String, CaseIterable, Sendable {
        case low = "Low"
        case normal = "Normal"
        case high = "High"
        case critical = "Critical"
    }
}

public struct SystemLoad: Sendable {
    public let cpu: Double
    public let memory: Double
    public let disk: Double
    public let level: LoadLevel
    
    // Additional properties for enterprise monitoring
    public let queueLength: Int
    public let currentConcurrentJobs: Int
    public let loadLevel: LoadLevel  // Alternative accessor for load level
    
    public init(cpu: Double = 0.0, memory: Double = 0.0, disk: Double = 0.0, queueLength: Int = 0, currentConcurrentJobs: Int = 0) {
        self.cpu = cpu
        self.memory = memory
        self.disk = disk
        self.level = LoadLevel.from(cpu: cpu, memory: memory, disk: disk)
        self.queueLength = queueLength
        self.currentConcurrentJobs = currentConcurrentJobs
        self.loadLevel = self.level  // Alias for compatibility
    }
    
    public enum LoadLevel: String, CaseIterable, Sendable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        static func from(cpu: Double, memory: Double, disk: Double) -> LoadLevel {
            let maxLoad = max(cpu, memory, disk)
            if maxLoad < 0.3 { return .low }
            else if maxLoad < 0.6 { return .medium }
            else if maxLoad < 0.8 { return .high }
            else { return .critical }
        }
    }
}

public struct ProcessingLimits: Sendable {
    public var maxConcurrentJobs: Int  // Changed to var for mutability
    public let maxMemoryUsage: Int
    public let timeoutSeconds: Int
    
    // Additional properties for enterprise settings
    public let maxQueueSize: Int
    public let maxJobDuration: TimeInterval
    public let enableThrottling: Bool
    public let pauseOnHighLoad: Bool
    
    public init(maxConcurrentJobs: Int = 5, maxMemoryUsage: Int = 1024, timeoutSeconds: Int = 300, maxQueueSize: Int = 100, maxJobDuration: TimeInterval = 3600, enableThrottling: Bool = true, pauseOnHighLoad: Bool = true) {
        self.maxConcurrentJobs = maxConcurrentJobs
        self.maxMemoryUsage = maxMemoryUsage
        self.timeoutSeconds = timeoutSeconds
        self.maxQueueSize = maxQueueSize
        self.maxJobDuration = maxJobDuration
        self.enableThrottling = enableThrottling
        self.pauseOnHighLoad = pauseOnHighLoad
    }
    
    public static let `default` = ProcessingLimits()
}

public struct ProcessingStats: Sendable {
    public let totalJobs: Int
    public let completedJobs: Int
    public let failedJobs: Int
    public let averageProcessingTime: TimeInterval
    public let systemLoad: SystemLoad
    
    // Additional properties for enterprise dashboard
    public let totalJobsProcessed: Int
    public let successRate: Double
    public let currentLoad: SystemLoad.LoadLevel
    public let activeJobs: Int
    public let queueLength: Int
    
    public init(totalJobs: Int = 0, completedJobs: Int = 0, failedJobs: Int = 0, averageProcessingTime: TimeInterval = 0, systemLoad: SystemLoad = SystemLoad(), totalJobsProcessed: Int = 0, successRate: Double = 0.0, currentLoad: SystemLoad.LoadLevel = .low, activeJobs: Int = 0, queueLength: Int = 0) {
        self.totalJobs = totalJobs
        self.completedJobs = completedJobs
        self.failedJobs = failedJobs
        self.averageProcessingTime = averageProcessingTime
        self.systemLoad = systemLoad
        self.totalJobsProcessed = totalJobsProcessed
        self.successRate = successRate
        self.currentLoad = currentLoad
        self.activeJobs = activeJobs
        self.queueLength = queueLength
    }
}

public struct FileUploadProgress: Sendable {
    public let fileName: String
    public let progress: Double
    public let status: String
    
    public init(fileName: String, progress: Double = 0.0, status: String = "uploading") {
        self.fileName = fileName
        self.progress = progress
        self.status = status
    }
}

public struct UploadResult: Sendable {
    public let success: Bool
    public let message: String
    public let fileId: String?
    
    public init(success: Bool, message: String, fileId: String? = nil) {
        self.success = success
        self.message = message
        self.fileId = fileId
    }
}

public struct SecurityConfig: Sendable {
    public let enableSSL: Bool
    public let apiKeyRequired: Bool
    public let rateLimitPerMinute: Int
    
    public init(enableSSL: Bool = true, apiKeyRequired: Bool = true, rateLimitPerMinute: Int = 60) {
        self.enableSSL = enableSSL
        self.apiKeyRequired = apiKeyRequired
        self.rateLimitPerMinute = rateLimitPerMinute
    }
}

public struct RiskAssessment: Sendable {
    public let level: String
    public let score: Double
    public let factors: [String]
    public let overallRisk: Double  // Added for compatibility
    public let criticalRisks: [String]  // Added for compatibility
    public let mitigation: String  // Added for compatibility
    
    // Primary initializer
    public init(level: String = "Low", score: Double = 0.0, factors: [String] = []) {
        self.level = level
        self.score = score
        self.factors = factors
        self.overallRisk = score  // Map score to overallRisk
        self.criticalRisks = factors  // Map factors to criticalRisks
        self.mitigation = "No specific mitigation required"  // Default mitigation
    }
    
    // Backward-compatible initializer
    public init(overallRisk: Double, criticalRisks: [String], mitigation: String) {
        self.level = overallRisk < 0.3 ? "Low" : overallRisk < 0.7 ? "Medium" : "High"
        self.score = overallRisk
        self.factors = criticalRisks + [mitigation]
        self.overallRisk = overallRisk
        self.criticalRisks = criticalRisks
        self.mitigation = mitigation
    }
}

public struct CodeImprovement: Identifiable, Sendable {
    public let id: UUID
    public let type: String
    public let description: String
    public let suggestedCode: String
    public let priority: String
    public let severity: Severity
    
    public init(id: UUID = UUID(), type: String, description: String, suggestedCode: String, priority: String = "Medium", severity: Severity = .info) {
        self.id = id
        self.type = type
        self.description = description
        self.suggestedCode = suggestedCode
        self.priority = priority
        self.severity = severity
    }
    
    public enum Severity: String, CaseIterable, Sendable {
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
    }
}

public struct CodeFix: Identifiable, Sendable {
    public let id: UUID
    public let description: String
    public let originalCode: String
    public let fixedCode: String
    public let confidence: Double
    
    public init(id: UUID = UUID(), description: String, originalCode: String, fixedCode: String, confidence: Double = 0.8) {
        self.id = id
        self.description = description
        self.originalCode = originalCode
        self.fixedCode = fixedCode
        self.confidence = confidence
    }
}

public struct CodeAnalysisReport: Sendable {
    public let rating: Rating
    public let summary: String
    public let timestamp: Date
    public let results: [AnalysisResult]
    public let metrics: CodeMetrics
    
    public init(rating: Rating = .good, summary: String = "", timestamp: Date = Date(), results: [AnalysisResult] = [], metrics: CodeMetrics = CodeMetrics()) {
        self.rating = rating
        self.summary = summary
        self.timestamp = timestamp
        self.results = results
        self.metrics = metrics
    }
    
    public enum Rating: String, CaseIterable, Sendable {
        case excellent, good, fair, poor
    }
}

public struct CodeMetrics: Sendable {
    public let characterCount: Int
    public let lineCount: Int
    public let functionCount: Int
    public let complexityScore: Double
    
    public init(characterCount: Int = 0, lineCount: Int = 0, functionCount: Int = 0, complexityScore: Double = 0.0) {
        self.characterCount = characterCount
        self.lineCount = lineCount
        self.functionCount = functionCount
        self.complexityScore = complexityScore
    }
}

public struct EnhancedAnalysisItem: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let description: String
    public let severity: String
    public let category: String
    public let message: String  // Added for compatibility
    public let lineNumber: Int  // Added for compatibility
    public let type: String  // Added for compatibility
    
    public init(id: UUID = UUID(), title: String, description: String, severity: String = "Medium", category: String = "General", message: String? = nil, lineNumber: Int = 0, type: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.severity = severity
        self.category = category
        self.message = message ?? description  // Use description as fallback
        self.lineNumber = lineNumber
        self.type = type ?? category  // Use category as fallback
    }
}
