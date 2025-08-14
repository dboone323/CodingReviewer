import Foundation

// MARK: - Testing Types

// Pure testing-related data models - NO SwiftUI imports, NO Codable

public struct GeneratedTestCase: Identifiable, Sendable {
    public let id: UUID
    public let testName: String
    public let targetFunction: String
    public let testType: TestType
    public let priority: TestPriority
    public let testCode: String
    public let expectedOutcome: String
    public let estimatedExecutionTime: TimeInterval

    // Additional properties for compatibility
    public let fileName: String
    public let lineNumber: Int
    public let tags: [String]

    public init(
        id: UUID = UUID(),
        testName: String,
        targetFunction: String,
        testType: TestType,
        priority: TestPriority,
        testCode: String,
        expectedOutcome: String,
        estimatedExecutionTime: TimeInterval = 1.0,
        fileName: String = "",
        lineNumber: Int = 0,
        tags: [String] = []
    ) {
        self.id = id
        self.testName = testName
        self.targetFunction = targetFunction
        self.testType = testType
        self.priority = priority
        self.testCode = testCode
        self.expectedOutcome = expectedOutcome
        self.estimatedExecutionTime = estimatedExecutionTime
        self.fileName = fileName
        self.lineNumber = lineNumber
        self.tags = tags
    }

    // Backward compatibility properties
    public var category: TestType {
        testType
    }

    public var name: String {
        testName
    }

    public var description: String {
        "Test: \(testName) for \(targetFunction)"
    }

    public var code: String {
        testCode
    }

    public var expectedResult: String {
        expectedOutcome
    }
}

public enum TestCategory: String, CaseIterable, Sendable {
    case function
    case initialization
    case lifecycle
    case concurrency
    case errorHandling = "error_handling"
    case edgeCase = "edge_case"

    public var displayName: String {
        switch self {
        case .function: "Function Test"
        case .initialization: "Initialization Test"
        case .lifecycle: "Lifecycle Test"
        case .concurrency: "Concurrency Test"
        case .errorHandling: "Error Handling Test"
        case .edgeCase: "Edge Case Test"
        }
    }
}

public enum TestType: String, CaseIterable, Sendable {
    case unit
    case integration
    case function
    case performance
    case security
    case quality
    case syntax
    case edgeCase = "edge_case"
    case coverage

    public var displayName: String {
        switch self {
        case .unit: "Unit Test"
        case .integration: "Integration Test"
        case .function: "Function Test"
        case .performance: "Performance Test"
        case .security: "Security Test"
        case .quality: "Quality Test"
        case .syntax: "Syntax Test"
        case .edgeCase: "Edge Case Test"
        case .coverage: "Coverage Test"
        }
    }
}

public struct TestExecutionResult: Identifiable, Sendable {
    public let id: UUID
    public let testCase: GeneratedTestCase
    public let passed: Bool
    public let executionTime: TimeInterval
    public let output: String
    public let error: String?

    public init(
        id: UUID = UUID(),
        testCase: GeneratedTestCase,
        passed: Bool,
        executionTime: TimeInterval,
        output: String,
        error: String? = nil
    ) {
        self.id = id
        self.testCase = testCase
        self.passed = passed
        self.executionTime = executionTime
        self.output = output
        self.error = error
    }

    // Backward compatibility properties
    public var success: Bool {
        passed
    }

    public var actualExecutionTime: TimeInterval {
        executionTime
    }
}

public struct TestExecutionStats: Sendable {
    public let totalTests: Int
    public let passedTests: Int
    public let failedTests: Int
    public let skippedTests: Int
    public let totalExecutionTime: TimeInterval
    public let averageExecutionTime: TimeInterval

    public init(
        totalTests: Int,
        passedTests: Int,
        failedTests: Int,
        skippedTests: Int,
        totalExecutionTime: TimeInterval,
        averageExecutionTime: TimeInterval
    ) {
        self.totalTests = totalTests
        self.passedTests = passedTests
        self.failedTests = failedTests
        self.skippedTests = skippedTests
        self.totalExecutionTime = totalExecutionTime
        self.averageExecutionTime = averageExecutionTime
    }

    public var passRate: Double {
        guard totalTests > 0 else { return 0.0 }
        return Double(passedTests) / Double(totalTests)
    }
}

public struct TestCoverage: Sendable {
    public let functionsCovered: Int
    public let totalFunctions: Int
    public let linesCovered: Int
    public let totalLines: Int
    public let branchesCovered: Int
    public let totalBranches: Int

    public init(
        functionsCovered: Int,
        totalFunctions: Int,
        linesCovered: Int,
        totalLines: Int,
        branchesCovered: Int,
        totalBranches: Int
    ) {
        self.functionsCovered = functionsCovered
        self.totalFunctions = totalFunctions
        self.linesCovered = linesCovered
        self.totalLines = totalLines
        self.branchesCovered = branchesCovered
        self.totalBranches = totalBranches
    }

    public var functionCoverage: Double {
        guard totalFunctions > 0 else { return 0.0 }
        return Double(functionsCovered) / Double(totalFunctions)
    }

    public var lineCoverage: Double {
        guard totalLines > 0 else { return 0.0 }
        return Double(linesCovered) / Double(totalLines)
    }

    public var branchCoverage: Double {
        guard totalBranches > 0 else { return 0.0 }
        return Double(branchesCovered) / Double(totalBranches)
    }

    // Backward compatibility properties
    public var functionsTestedPercentage: Double {
        functionCoverage * 100.0
    }

    public var classesTestedPercentage: Double {
        functionCoverage * 100.0 // Using function coverage as proxy
    }

    public var edgeCasesTestedPercentage: Double {
        branchCoverage * 100.0 // Using branch coverage as proxy for edge cases
    }
}

public struct ValidationResult: Sendable {
    public let isValid: Bool
    public let errors: [String]
    public let warnings: [String]
    public let suggestions: [String]

    public init(isValid: Bool, errors: [String], warnings: [String], suggestions: [String]) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
        self.suggestions = suggestions
    }
}

public struct TestReport: Sendable {
    public let timestamp: Date
    public let stats: TestExecutionStats
    public let coverage: TestCoverage
    public let results: [TestExecutionResult]
    public let summary: String

    public init(
        timestamp: Date,
        stats: TestExecutionStats,
        coverage: TestCoverage,
        results: [TestExecutionResult],
        summary: String
    ) {
        self.timestamp = timestamp
        self.stats = stats
        self.coverage = coverage
        self.results = results
        self.summary = summary
    }
}

public struct PerformanceSummary: Sendable {
    public let averageExecutionTime: TimeInterval
    public let maxExecutionTime: TimeInterval
    public let minExecutionTime: TimeInterval
    public let memoryUsage: Int
    public let cpuUsage: Double

    public init(
        averageExecutionTime: TimeInterval,
        maxExecutionTime: TimeInterval,
        minExecutionTime: TimeInterval,
        memoryUsage: Int,
        cpuUsage: Double
    ) {
        self.averageExecutionTime = averageExecutionTime
        self.maxExecutionTime = maxExecutionTime
        self.minExecutionTime = minExecutionTime
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
    }
}
