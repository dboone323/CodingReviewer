//
//  BackgroundProcessingTypes.swift
//  CodingReviewer
//
//  Created by Background Processing System on 8/7/25.
//  Contains all types related to background processing system
//  CLEAN ARCHITECTURE: Data models only, NO UI dependencies
//

import Foundation

// MARK: - Processing Job Types

struct ProcessingJob: Identifiable, Sendable {
    let id: UUID
    let type: JobType
    let title: String
    var status: JobStatus
    var progress: Double
    var startTime: Date
    var endTime: Date?
    var errorMessage: String?
    var result: String?
    let data: [String: String] // Simplified from [String: Any] for Sendable compliance
    let priority: JobPriority
    
    init(id: UUID = UUID(), type: JobType, title: String, status: JobStatus, progress: Double = 0.0, startTime: Date, endTime: Date? = nil, errorMessage: String? = nil, data: [String: Any] = [:], priority: JobPriority = .normal) {
        self.id = id
        self.type = type
        self.title = title
        self.status = status
        self.progress = progress
        self.startTime = startTime
        self.endTime = endTime
        self.errorMessage = errorMessage
        self.result = nil
        // Convert [String: Any] to [String: String] for Sendable compliance
        self.data = data.compactMapValues { value in
            if let stringValue = value as? String {
                return stringValue
            } else if let numberValue = value as? NSNumber {
                return numberValue.stringValue
            } else {
                return String(describing: value)
            }
        }
        self.priority = priority
    }
    
    var duration: TimeInterval {
        guard let endTime = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return endTime.timeIntervalSince(startTime)
    }
    
    enum JobType: String, CaseIterable, Sendable {
        case codeAnalysis = "Code Analysis"
        case qualityCheck = "Quality Check"
        case securityScan = "Security Scan"
        case performanceAnalysis = "Performance Analysis"
        case documentation = "Documentation"
        case testing = "Testing"
        case optimization = "Optimization"
        case backup = "Backup"
        
        var estimatedDuration: TimeInterval {
            switch self {
            case .codeAnalysis: return 3.0
            case .qualityCheck: return 2.0
            case .securityScan: return 5.0
            case .performanceAnalysis: return 4.0
            case .documentation: return 2.5
            case .testing: return 6.0
            case .optimization: return 8.0
            case .backup: return 1.0
            }
        }
        
        var description: String {
            return rawValue
        }
        
        // UI-agnostic color identifier
        var colorIdentifier: String {
            switch self {
            case .codeAnalysis: return "blue"
            case .qualityCheck: return "green"
            case .securityScan: return "red"
            case .performanceAnalysis: return "orange"
            case .documentation: return "purple"
            case .testing: return "teal"
            case .optimization: return "indigo"
            case .backup: return "gray"
            }
        }
        
        var icon: String {
            switch self {
            case .codeAnalysis: return "doc.text.magnifyingglass"
            case .qualityCheck: return "checkmark.circle"
            case .securityScan: return "shield"
            case .performanceAnalysis: return "speedometer"
            case .documentation: return "doc.text"
            case .testing: return "testtube.2"
            case .optimization: return "wand.and.rays"
            case .backup: return "externaldrive"
            }
        }
    }
    
    enum JobStatus: String, CaseIterable, Sendable {
        case queued = "Queued"
        case running = "Running"
        case paused = "Paused"
        case completed = "Completed"
        case failed = "Failed"
        case cancelled = "Cancelled"
        
        var isActive: Bool {
            switch self {
            case .queued, .running, .paused:
                return true
            case .completed, .failed, .cancelled:
                return false
            }
        }
        
        // UI-agnostic color identifier
        var colorIdentifier: String {
            switch self {
            case .queued: return "orange"
            case .running: return "blue"
            case .paused: return "yellow"
            case .completed: return "green"
            case .failed: return "red"
            case .cancelled: return "gray"
            }
        }
    }
    
    enum JobPriority: Int, CaseIterable, Sendable, Comparable {
        case low = 1
        case normal = 2
        case high = 3
        case critical = 4
        
        static func < (lhs: JobPriority, rhs: JobPriority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
        var description: String {
            switch self {
            case .low: return "Low"
            case .normal: return "Normal"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
        
        var displayName: String {
            return description
        }
        
        // UI-agnostic color identifier
        var colorIdentifier: String {
            switch self {
            case .low: return "gray"
            case .normal: return "blue"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }
}

// MARK: - System Load

struct SystemLoad: Sendable {
    var activeJobs: Int = 0
    var queuedJobs: Int = 0
    var currentConcurrentJobs: Int = 0
    var queueLength: Int = 0
    var averageJobDuration: TimeInterval = 0.0
    var cpuUsage: Double = 0.0
    var memoryUsage: Double = 0.0
    var diskUsage: Double = 0.0
    var networkActivity: Double = 0.0
    var lastUpdated: Date = Date()
    
    var loadLevel: LoadLevel {
        let combinedLoad = (cpuUsage + memoryUsage) / 2.0
        switch combinedLoad {
        case 0.0..<0.3:
            return .low
        case 0.3..<0.6:
            return .moderate
        case 0.6..<0.8:
            return .high
        default:
            return .critical
        }
    }
    
    var isOverloaded: Bool {
        return loadLevel == .critical || cpuUsage > 0.9 || memoryUsage > 0.9
    }
    
    enum LoadLevel: String, CaseIterable, Sendable {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case critical = "Critical"
        
        // UI-agnostic color identifier
        var colorIdentifier: String {
            switch self {
            case .low: return "green"
            case .moderate: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }
}

// MARK: - Processing Limits

struct ProcessingLimits: Sendable {
    var maxConcurrentJobs: Int
    var maxQueueSize: Int
    var jobTimeoutSeconds: TimeInterval
    var maxJobDuration: TimeInterval
    var pauseOnHighLoad: Bool
    var maxMemoryUsage: Double
    var maxCpuUsage: Double
    var cpuThreshold: Double
    var memoryThreshold: Double
    var enableThrottling: Bool
    
    static let `default` = ProcessingLimits(
        maxConcurrentJobs: 5,
        maxQueueSize: 100,
        jobTimeoutSeconds: 300,
        maxJobDuration: 300,
        pauseOnHighLoad: true,
        maxMemoryUsage: 0.8,
        maxCpuUsage: 0.8,
        cpuThreshold: 0.8,
        memoryThreshold: 0.8,
        enableThrottling: true
    )
    
    var isValid: Bool {
        return maxConcurrentJobs > 0 &&
               maxQueueSize > 0 &&
               jobTimeoutSeconds > 0 &&
               maxJobDuration > 0 &&
               maxMemoryUsage > 0 && maxMemoryUsage <= 1.0 &&
               maxCpuUsage > 0 && maxCpuUsage <= 1.0 &&
               cpuThreshold > 0 && cpuThreshold <= 1.0 &&
               memoryThreshold > 0 && memoryThreshold <= 1.0
    }
}

// MARK: - System Status

struct SystemStatus: Sendable {
    let uptime: TimeInterval
    let totalJobsProcessed: Int
    let averageProcessingTime: TimeInterval
    let successRate: Double
    let currentLoad: SystemLoad
    let isHealthy: Bool
    let lastHealthCheck: Date
    let activeJobsCount: Int
    let status: String
    let isProcessingEnabled: Bool
    
    var healthScore: Double {
        // Calculate health score based on various factors
        var score = 1.0
        
        // Reduce score based on system load
        score -= currentLoad.cpuUsage * 0.3
        score -= currentLoad.memoryUsage * 0.3
        
        // Reduce score based on success rate
        score *= successRate
        
        // Reduce score if not processing
        if !isProcessingEnabled {
            score *= 0.5
        }
        
        // Ensure score is between 0 and 1
        return max(0.0, min(1.0, score))
    }
}

// MARK: - Processing Stats

struct ProcessingStats: Sendable {
    let totalJobsProcessed: Int
    let successRate: Double
    let averageProcessingTime: TimeInterval
    let currentLoad: SystemLoad.LoadLevel
    let activeJobs: Int
    let queueLength: Int
    
    var efficiency: Double {
        return successRate * (1.0 - averageProcessingTime / 100.0)
    }
    
    var performanceGrade: String {
        let efficiency = self.efficiency
        switch efficiency {
        case 0.9...1.0:
            return "Excellent"
        case 0.8..<0.9:
            return "Good"
        case 0.7..<0.8:
            return "Fair"
        case 0.5..<0.7:
            return "Poor"
        default:
            return "Critical"
        }
    }
}
