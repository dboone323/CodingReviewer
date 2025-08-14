import Foundation

// MARK: - Analytics & Reporting Types

// Pure analytics and reporting data models - NO SwiftUI imports, NO Codable

public struct AnalyticsData: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let eventType: String
    public let data: [String: String] // Using String values only to avoid Codable issues
    public let userID: String?
    public let sessionID: String

    // Additional properties for enterprise analytics
    public let totalAnalyses: Int
    public let uniqueUsers: Int
    public let averageAnalysisTime: Double
    public let topIssueTypes: [String]
    public let languageDistribution: [String: Int]
    public let qualityTrends: [String: Double]
    public let averageQualityScore: Double
    public let issueResolutionRate: Double
    public let codeReviewEfficiency: Double

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        eventType: String,
        data: [String: String],
        userID: String? = nil,
        sessionID: String,
        totalAnalyses: Int = 0,
        uniqueUsers: Int = 0,
        averageAnalysisTime: Double = 0.0,
        topIssueTypes: [String] = [],
        languageDistribution: [String: Int] = [:],
        qualityTrends: [String: Double] = [:],
        averageQualityScore: Double = 0.0,
        issueResolutionRate: Double = 0.0,
        codeReviewEfficiency: Double = 0.0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.data = data
        self.userID = userID
        self.sessionID = sessionID
        self.totalAnalyses = totalAnalyses
        self.uniqueUsers = uniqueUsers
        self.averageAnalysisTime = averageAnalysisTime
        self.topIssueTypes = topIssueTypes
        self.languageDistribution = languageDistribution
        self.qualityTrends = qualityTrends
        self.averageQualityScore = averageQualityScore
        self.issueResolutionRate = issueResolutionRate
        self.codeReviewEfficiency = codeReviewEfficiency
    }
}

public struct ReportData: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let reportType: ReportType
    public let generatedAt: Date
    public let summary: String
    public let details: [String]
    public let metrics: [String: String] // Using String values to avoid Codable issues

    public init(
        id: UUID = UUID(),
        title: String,
        reportType: ReportType,
        generatedAt: Date,
        summary: String,
        details: [String],
        metrics: [String: String]
    ) {
        self.id = id
        self.title = title
        self.reportType = reportType
        self.generatedAt = generatedAt
        self.summary = summary
        self.details = details
        self.metrics = metrics
    }
}

public enum ReportType: String, CaseIterable, Sendable {
    case codeQuality = "code_quality"
    case performance
    case security
    case testing
    case documentation
    case analytics

    public var displayName: String {
        switch self {
        case .codeQuality: "Code Quality"
        case .performance: "Performance"
        case .security: "Security"
        case .testing: "Testing"
        case .documentation: "Documentation"
        case .analytics: "Analytics"
        }
    }
}

public struct AnalyticsMetric: Sendable {
    public let name: String
    public let value: Double
    public let unit: String
    public let category: String
    public let trend: TrendDirection

    public init(
        name: String,
        value: Double,
        unit: String = "",
        category: String = "General",
        trend: TrendDirection = .stable
    ) {
        self.name = name
        self.value = value
        self.unit = unit
        self.category = category
        self.trend = trend
    }
}

public enum AnalyticsTimeframe: String, CaseIterable, Sendable {
    case daily = "Daily"
    case last24Hours = "Last 24 Hours"
    case lastWeek = "Last Week"
    case lastMonth = "Last Month"
    case lastQuarter = "Last Quarter"
    case lastYear = "Last Year"
}

public struct ExportOptions: Sendable {
    public let format: ExportFormat
    public let includeDetails: Bool
    public let includeSummary: Bool
    public let includeMetrics: Bool
    public let fileName: String?

    public init(
        format: ExportFormat,
        includeDetails: Bool,
        includeSummary: Bool,
        includeMetrics: Bool,
        fileName: String? = nil
    ) {
        self.format = format
        self.includeDetails = includeDetails
        self.includeSummary = includeSummary
        self.includeMetrics = includeMetrics
        self.fileName = fileName
    }
}

public struct TeamMetrics: Sendable {
    public let activeMembers: Int
    public let completedTasks: Int
    public let pendingTasks: Int
    public let averageCompletionTime: TimeInterval
    public let productivityScore: Double
    public let collaborationScore: Double

    public init(
        activeMembers: Int,
        completedTasks: Int,
        pendingTasks: Int,
        averageCompletionTime: TimeInterval,
        productivityScore: Double,
        collaborationScore: Double
    ) {
        self.activeMembers = activeMembers
        self.completedTasks = completedTasks
        self.pendingTasks = pendingTasks
        self.averageCompletionTime = averageCompletionTime
        self.productivityScore = productivityScore
        self.collaborationScore = collaborationScore
    }
}

public struct ProjectInsights: Sendable {
    public let codebaseSize: Int
    public let testCoverage: Double
    public let technicalDebt: Double
    public let maintainabilityIndex: Double
    public let securityScore: Double
    public let documentationCoverage: Double

    public init(
        codebaseSize: Int,
        testCoverage: Double,
        technicalDebt: Double,
        maintainabilityIndex: Double,
        securityScore: Double,
        documentationCoverage: Double
    ) {
        self.codebaseSize = codebaseSize
        self.testCoverage = testCoverage
        self.technicalDebt = technicalDebt
        self.maintainabilityIndex = maintainabilityIndex
        self.securityScore = securityScore
        self.documentationCoverage = documentationCoverage
    }
}

public struct DashboardData: Sendable {
    public let summary: ProjectInsights
    public let teamMetrics: TeamMetrics
    public let recentReports: [ReportData]
    public let trends: [AnalyticsData]
    public let lastUpdated: Date

    public init(
        summary: ProjectInsights,
        teamMetrics: TeamMetrics,
        recentReports: [ReportData],
        trends: [AnalyticsData],
        lastUpdated: Date
    ) {
        self.summary = summary
        self.teamMetrics = teamMetrics
        self.recentReports = recentReports
        self.trends = trends
        self.lastUpdated = lastUpdated
    }
}

public struct ChartData: Sendable {
    public let labels: [String]
    public let values: [Double]
    public let chartType: ChartType
    public let title: String
    public let xAxisLabel: String
    public let yAxisLabel: String

    public init(
        labels: [String],
        values: [Double],
        chartType: ChartType,
        title: String,
        xAxisLabel: String,
        yAxisLabel: String
    ) {
        self.labels = labels
        self.values = values
        self.chartType = chartType
        self.title = title
        self.xAxisLabel = xAxisLabel
        self.yAxisLabel = yAxisLabel
    }
}

public enum ChartType: String, CaseIterable, Sendable {
    case line
    case bar
    case pie
    case scatter
    case area

    public var displayName: String {
        switch self {
        case .line: "Line Chart"
        case .bar: "Bar Chart"
        case .pie: "Pie Chart"
        case .scatter: "Scatter Plot"
        case .area: "Area Chart"
        }
    }
}

public struct TimeSeriesData: Sendable {
    public let timestamp: Date
    public let value: Double
    public let metric: String

    public init(timestamp: Date, value: Double, metric: String) {
        self.timestamp = timestamp
        self.value = value
        self.metric = metric
    }
}

public struct TrendAnalysis: Sendable {
    public let metric: String
    public let direction: TrendDirection
    public let changePercentage: Double
    public let confidence: Double
    public let dataPoints: [TimeSeriesData]

    public init(
        metric: String,
        direction: TrendDirection,
        changePercentage: Double,
        confidence: Double,
        dataPoints: [TimeSeriesData]
    ) {
        self.metric = metric
        self.direction = direction
        self.changePercentage = changePercentage
        self.confidence = confidence
        self.dataPoints = dataPoints
    }
}

// MARK: - Enterprise Analytics Types

public struct PerformanceMetrics: Sendable {
    public let peakUsageHour: Int
    public let successRate: Double
    public let responseTime: Double
    public let throughput: Double
    public let errorCount: Int

    public init(
        peakUsageHour: Int = 14,
        successRate: Double = 0.95,
        responseTime: Double = 250.0,
        throughput: Double = 1000.0,
        errorCount: Int = 0
    ) {
        self.peakUsageHour = peakUsageHour
        self.successRate = successRate
        self.responseTime = responseTime
        self.throughput = throughput
        self.errorCount = errorCount
    }
}

public struct AnalyticsReport: Sendable {
    public let id: UUID
    public let title: String
    public let summary: String
    public let metrics: [AnalyticsMetric]
    public let trends: [TrendAnalysis]
    public let generatedAt: Date
    public let timeframe: AnalyticsTimeframe

    // Additional properties for enterprise reporting
    public let totalAnalyses: Int
    public let uniqueUsers: Int
    public let averageAnalysisTime: Double
    public let averageActionsPerDay: Double
    public let performanceMetrics: PerformanceMetrics
    public let insights: [String]

    public init(
        title: String,
        summary: String,
        metrics: [AnalyticsMetric],
        trends: [TrendAnalysis],
        timeframe: AnalyticsTimeframe,
        totalAnalyses: Int = 0,
        uniqueUsers: Int = 0,
        averageAnalysisTime: Double = 0.0,
        averageActionsPerDay: Double = 0.0,
        performanceMetrics: PerformanceMetrics = PerformanceMetrics(),
        insights: [String] = []
    ) {
        id = UUID()
        self.title = title
        self.summary = summary
        self.metrics = metrics
        self.trends = trends
        generatedAt = Date()
        self.timeframe = timeframe
        self.totalAnalyses = totalAnalyses
        self.uniqueUsers = uniqueUsers
        self.averageAnalysisTime = averageAnalysisTime
        self.averageActionsPerDay = averageActionsPerDay
        self.performanceMetrics = performanceMetrics
        self.insights = insights
    }
}

public struct UserActivity: Sendable {
    public let id: UUID
    public let userId: String
    public let action: String
    public let timestamp: Date
    public let metadata: [String: String]

    public init(userId: String, action: String, metadata: [String: String] = [:]) {
        id = UUID()
        self.userId = userId
        self.action = action
        timestamp = Date()
        self.metadata = metadata
    }
}

public struct SystemStatus: Sendable {
    public let isHealthy: Bool
    public let uptime: TimeInterval
    public let systemLoad: SystemLoad
    public let activeUsers: Int
    public let errorRate: Double
    public let lastUpdate: Date

    // Additional properties for enterprise dashboard
    public let activeJobsCount: Int
    public let status: String
    public let successRate: Double
    public let healthScore: Double
    public let totalJobsProcessed: Int
    public let isProcessingEnabled: Bool

    // Computed property for compatibility
    public var currentLoad: SystemLoad { systemLoad }

    public init(
        isHealthy: Bool = true,
        uptime: TimeInterval = 0,
        systemLoad: SystemLoad = SystemLoad(),
        activeUsers: Int = 0,
        errorRate: Double = 0.0,
        activeJobsCount: Int = 0,
        status: String = "healthy",
        successRate: Double = 0.95,
        healthScore: Double = 0.9,
        totalJobsProcessed: Int = 0,
        isProcessingEnabled: Bool = true
    ) {
        self.isHealthy = isHealthy
        self.uptime = uptime
        self.systemLoad = systemLoad
        self.activeUsers = activeUsers
        self.errorRate = errorRate
        lastUpdate = Date()
        self.activeJobsCount = activeJobsCount
        self.status = status
        self.successRate = successRate
        self.healthScore = healthScore
        self.totalJobsProcessed = totalJobsProcessed
        self.isProcessingEnabled = isProcessingEnabled
    }
}

public enum TrendDirection: String, CaseIterable, Sendable {
    case increasing
    case decreasing
    case stable
    case volatile

    public var displayName: String {
        switch self {
        case .increasing: "Increasing"
        case .decreasing: "Decreasing"
        case .stable: "Stable"
        case .volatile: "Volatile"
        }
    }
}
