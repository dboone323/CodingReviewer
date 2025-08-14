//
//  BackgroundProcessingTypes.swift
//  CodingReviewer
//
//  Created by Background Processing System on 8/7/25.
//  Contains all types related to background processing system
//  CLEAN ARCHITECTURE: Data models only, NO UI dependencies
//

import Foundation

// MARK: - Background Processing Types

// ProcessingJob, SystemLoad, ProcessingLimits are centralized in ProcessingTypes.swift

// Additional types specific to background processing that extend the core types

public enum JobType: String, CaseIterable, Sendable {
    case codeAnalysis = "Code Analysis"
    case documentGeneration = "Document Generation"
    case qualityCheck = "Quality Check"
    case securityScan = "Security Scan"
    case performanceAnalysis = "Performance Analysis"
    case testGeneration = "Test Generation"
    case codeRefactoring = "Code Refactoring"
    case dependencyAnalysis = "Dependency Analysis"
    case codeFormat = "Code Formatting"
    case backup = "Backup"
    case dataExport = "Data Export"
    case systemMaintenance = "System Maintenance"
}

public enum JobStatus: String, CaseIterable, Sendable {
    case pending = "Pending"
    case running = "Running"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
    case paused = "Paused"

    public var isActive: Bool {
        self == .running || self == .pending
    }

    public var isTerminated: Bool {
        self == .completed || self == .failed || self == .cancelled
    }
}

public enum JobPriority: String, CaseIterable, Sendable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
    case critical = "Critical"

    public var displayName: String {
        rawValue
    }

    // UI-agnostic color identifier
    public var colorIdentifier: String {
        switch self {
        case .low: "gray"
        case .normal: "blue"
        case .high: "orange"
        case .critical: "red"
        }
    }
}

// MARK: - Queue Management Types

public struct JobQueue: Sendable {
    public let maxSize: Int
    public let currentSize: Int
    public let priorityQueues: [JobPriority: Int]

    public init(maxSize: Int, currentSize: Int, priorityQueues: [JobPriority: Int]) {
        self.maxSize = maxSize
        self.currentSize = currentSize
        self.priorityQueues = priorityQueues
    }

    public var isFull: Bool {
        currentSize >= maxSize
    }

    public var fillPercentage: Double {
        Double(currentSize) / Double(maxSize)
    }
}

public struct ProcessingMetrics: Sendable {
    public let averageCompletionTime: TimeInterval
    public let successRate: Double
    public let throughputPerHour: Double
    public let errorRate: Double
    public let queueWaitTime: TimeInterval

    public init(
        averageCompletionTime: TimeInterval,
        successRate: Double,
        throughputPerHour: Double,
        errorRate: Double,
        queueWaitTime: TimeInterval
    ) {
        self.averageCompletionTime = averageCompletionTime
        self.successRate = successRate
        self.throughputPerHour = throughputPerHour
        self.errorRate = errorRate
        self.queueWaitTime = queueWaitTime
    }
}

// MARK: - Resource Management Types

public struct ResourceUsage: Sendable {
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let diskIO: Double
    public let networkIO: Double
    public let timestamp: Date

    public init(cpuUsage: Double, memoryUsage: Double, diskIO: Double, networkIO: Double, timestamp: Date = Date()) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskIO = diskIO
        self.networkIO = networkIO
        self.timestamp = timestamp
    }

    public var overallUsage: Double {
        (cpuUsage + memoryUsage) / 2.0
    }
}

public struct BackgroundProcessingConfiguration: Sendable {
    public let enableBackgroundProcessing: Bool
    public let maxConcurrentJobs: Int
    public let queueTimeout: TimeInterval
    public let retryAttempts: Int
    public let processingInterval: TimeInterval

    public init(
        enableBackgroundProcessing: Bool = true,
        maxConcurrentJobs: Int = 3,
        queueTimeout: TimeInterval = 300,
        retryAttempts: Int = 3,
        processingInterval: TimeInterval = 1.0
    ) {
        self.enableBackgroundProcessing = enableBackgroundProcessing
        self.maxConcurrentJobs = maxConcurrentJobs
        self.queueTimeout = queueTimeout
        self.retryAttempts = retryAttempts
        self.processingInterval = processingInterval
    }

    public static let `default` = BackgroundProcessingConfiguration()
}
