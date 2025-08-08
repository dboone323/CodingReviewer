import Foundation

// MARK: - Pure Data Models (Following Architecture.md)
// NO SwiftUI imports, NO Codable conformance, NO circular dependencies

/// Test execution result
struct TestExecutionResult: Identifiable, Sendable {
    let id: UUID
    let testCaseId: UUID
    let testName: String
    let success: Bool
    let actualExecutionTime: TimeInterval
    let expectedExecutionTime: TimeInterval
    let errorMessage: String?
    let output: String?
    let timestamp: Date
    
    init(id: UUID = UUID(), testCaseId: UUID, testName: String, success: Bool,
         actualExecutionTime: TimeInterval, expectedExecutionTime: TimeInterval = 0,
         errorMessage: String? = nil, output: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.testCaseId = testCaseId
        self.testName = testName
        self.success = success
        self.actualExecutionTime = actualExecutionTime
        self.expectedExecutionTime = expectedExecutionTime
        self.errorMessage = errorMessage
        self.output = output
        self.timestamp = timestamp
    }
}

/// Generated test case
struct GeneratedTestCase: Identifiable, Sendable {
    let id: UUID
    let name: String
    let description: String
    let category: TestCategory
    let priority: TestPriority
    let code: String
    let expectedResult: String
    let fileName: String
    let lineNumber: Int
    let estimatedExecutionTime: TimeInterval
    let tags: [String]
    let resultId: UUID? // Reference to result instead of embedding it
    
    init(id: UUID, name: String, description: String, category: TestCategory, priority: TestPriority,
         code: String, expectedResult: String, fileName: String, lineNumber: Int,
         estimatedExecutionTime: TimeInterval, tags: [String], resultId: UUID? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.priority = priority
        self.code = code
        self.expectedResult = expectedResult
        self.fileName = fileName
        self.lineNumber = lineNumber
        self.estimatedExecutionTime = estimatedExecutionTime
        self.tags = tags
        self.resultId = resultId
    }
}

/// Test categories
enum TestCategory: String, CaseIterable, Sendable {
    case function = "Function"
    case initialization = "Initialization"
    case lifecycle = "Lifecycle"
    case concurrency = "Concurrency"
    case errorHandling = "Error Handling"
    case edgeCase = "Edge Case"
}

/// Test priority levels
enum TestPriority: String, CaseIterable, Sendable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

/// Test coverage metrics
struct TestCoverage: Sendable {
    let functionsTestedPercentage: Double
    let classesTestedPercentage: Double
    let linesTestedPercentage: Double
    let edgeCasesTestedPercentage: Double
    let overallCoveragePercentage: Double
    
    init() {
        self.functionsTestedPercentage = 0.0
        self.classesTestedPercentage = 0.0
        self.linesTestedPercentage = 0.0
        self.edgeCasesTestedPercentage = 0.0
        self.overallCoveragePercentage = 0.0
    }
    
    init(functionsTestedPercentage: Double, classesTestedPercentage: Double, 
         linesTestedPercentage: Double, edgeCasesTestedPercentage: Double, 
         overallCoveragePercentage: Double) {
        self.functionsTestedPercentage = functionsTestedPercentage
        self.classesTestedPercentage = classesTestedPercentage
        self.linesTestedPercentage = linesTestedPercentage
        self.edgeCasesTestedPercentage = edgeCasesTestedPercentage
        self.overallCoveragePercentage = overallCoveragePercentage
    }
}

/// Test execution statistics
struct TestExecutionStats: Sendable {
    let totalTests: Int
    let successfulTests: Int
    let failedTests: Int
    let totalExecutionTime: TimeInterval
    let averageExecutionTime: TimeInterval
    let successRate: Double
    let timestamp: Date
    
    init() {
        self.totalTests = 0
        self.successfulTests = 0
        self.failedTests = 0
        self.totalExecutionTime = 0
        self.averageExecutionTime = 0
        self.successRate = 0
        self.timestamp = Date()
    }
    
    init(totalTests: Int, successfulTests: Int, failedTests: Int,
         totalExecutionTime: TimeInterval, averageExecutionTime: TimeInterval,
         successRate: Double, timestamp: Date = Date()) {
        self.totalTests = totalTests
        self.successfulTests = successfulTests
        self.failedTests = failedTests
        self.totalExecutionTime = totalExecutionTime
        self.averageExecutionTime = averageExecutionTime
        self.successRate = successRate
        self.timestamp = timestamp
    }
}

/// Performance metrics
struct PerformanceMetrics: Sendable {
    let memoryUsage: Double // MB
    let cpuUsage: Double // Percentage
    let executionTime: TimeInterval
    
    init(memoryUsage: Double = 0, cpuUsage: Double = 0, executionTime: TimeInterval = 0) {
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.executionTime = executionTime
    }
}

/// Validation result
struct ValidationResult: Sendable {
    let isValid: Bool
    let errorMessage: String?
    let output: String?
    let memoryUsage: Double
    let cpuUsage: Double
    
    init(isValid: Bool, errorMessage: String? = nil, output: String? = nil, 
         memoryUsage: Double = 0, cpuUsage: Double = 0) {
        self.isValid = isValid
        self.errorMessage = errorMessage
        self.output = output
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
    }
}

/// Test report
struct TestReport: Sendable {
    let executionStats: TestExecutionStats
    let failedTestIds: [UUID] // References instead of embedded objects
    let slowestTestIds: [UUID] // References instead of embedded objects
    let performanceSummary: PerformanceSummary
    let recommendations: [String]
    let generatedAt: Date
    
    init(executionStats: TestExecutionStats = TestExecutionStats(), 
         failedTestIds: [UUID] = [], 
         slowestTestIds: [UUID] = [], 
         performanceSummary: PerformanceSummary = PerformanceSummary(), 
         recommendations: [String] = [], 
         generatedAt: Date = Date()) {
        self.executionStats = executionStats
        self.failedTestIds = failedTestIds
        self.slowestTestIds = slowestTestIds
        self.performanceSummary = performanceSummary
        self.recommendations = recommendations
        self.generatedAt = generatedAt
    }
}

/// Performance summary
struct PerformanceSummary: Sendable {
    let averageMemoryUsage: Double
    let maxMemoryUsage: Double
    let averageCpuUsage: Double
    let maxCpuUsage: Double
    let totalResourceUsage: Double
    
    init(averageMemoryUsage: Double = 0, maxMemoryUsage: Double = 0, 
         averageCpuUsage: Double = 0, maxCpuUsage: Double = 0, totalResourceUsage: Double = 0) {
        self.averageMemoryUsage = averageMemoryUsage
        self.maxMemoryUsage = maxMemoryUsage
        self.averageCpuUsage = averageCpuUsage
        self.maxCpuUsage = maxCpuUsage
        self.totalResourceUsage = totalResourceUsage
    }
}
