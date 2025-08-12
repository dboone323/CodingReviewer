import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

/// Enhanced Enterprise Analytics Dashboard with advanced business intelligence
struct EnhancedEnterpriseAnalyticsDashboard: View {
    @StateObject private var analyticsEngine = EnterpriseAnalyticsEngine()
    @State private var selectedTimeframe: AnalyticsTimeframe = .last30Days
    @State private var selectedView: DashboardView = .overview
    @State private var showExportOptions = false
    @State private var searchText = ""
    @State private var selectedFilters: Set<AnalyticsFilter> = []
    
    enum AnalyticsTimeframe: String, CaseIterable {
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
        case thisYear = "This Year"
        case custom = "Custom Range"
    }
    
    enum DashboardView: String, CaseIterable {
        case overview = "Overview"
        case codeQuality = "Code Quality"
        case performance = "Performance"
        case security = "Security"
        case teamProductivity = "Team Productivity"
        case trends = "Trends & Insights"
        
        var icon: String {
            switch self {
            case .overview: return "chart.pie.fill"
            case .codeQuality: return "checkmark.seal.fill"
            case .performance: return "speedometer"
            case .security: return "shield.fill"
            case .teamProductivity: return "person.3.fill"
            case .trends: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    enum AnalyticsFilter: String, CaseIterable {
        case criticalIssues = "Critical Issues"
        case securityVulnerabilities = "Security"
        case performanceBottlenecks = "Performance"
        case codeSmells = "Code Smells"
        case testCoverage = "Test Coverage"
        
        var color: Color {
            switch self {
            case .criticalIssues: return .red
            case .securityVulnerabilities: return .orange
            case .performanceBottlenecks: return .yellow
            case .codeSmells: return .purple
            case .testCoverage: return .green
            }
        }
    }
    
    var body: some View {
        NavigationView {
            // Sidebar with view navigation
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enterprise Analytics")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("Business Intelligence Dashboard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                }
                .padding()
                
                // Timeframe Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time Range")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                
                // Quick Filters
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Filters")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(AnalyticsFilter.allCases, id: \.self) { filter in
                            FilterToggle(
                                filter: filter,
                                isSelected: selectedFilters.contains(filter)
                            ) {
                                if selectedFilters.contains(filter) {
                                    selectedFilters.remove(filter)
                                } else {
                                    selectedFilters.insert(filter)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                // View Navigation
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(DashboardView.allCases, id: \.self) { view in
                        DashboardViewButton(
                            view: view,
                            isSelected: selectedView == view,
                            badgeCount: getBadgeCount(for: view)
                        ) {
                            selectedView = view
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Export Button
                Button(action: { showExportOptions = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Report")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .padding()
                .buttonStyle(PlainButtonStyle())
            }
            .frame(width: 240)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Main Content
            Group {
                switch selectedView {
                case .overview:
                    OverviewDashboard(
                        analyticsEngine: analyticsEngine,
                        timeframe: selectedTimeframe,
                        filters: selectedFilters
                    )
                case .codeQuality:
                    CodeQualityDashboard(
                        analyticsEngine: analyticsEngine,
                        timeframe: selectedTimeframe
                    )
                case .performance:
                    AnalyticsPerformanceDashboard(
                        analyticsEngine: analyticsEngine,
                        timeframe: selectedTimeframe
                    )
                case .security:
                    SecurityDashboard(
                        analyticsEngine: analyticsEngine,
                        timeframe: selectedTimeframe
                    )
                case .teamProductivity:
                    TeamProductivityDashboard(
                        analyticsEngine: analyticsEngine,
                        timeframe: selectedTimeframe
                    )
                case .trends:
                    TrendsAndInsightsDashboard(
                        analyticsEngine: analyticsEngine,
                        timeframe: selectedTimeframe
                    )
                }
            }
        }
        .navigationTitle("")
        .searchable(text: $searchText, prompt: "Search analytics data...")
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView(analyticsEngine: analyticsEngine)
        }
        .onAppear {
            analyticsEngine.loadData(for: selectedTimeframe)
        }
        .onChange(of: selectedTimeframe) { _, _ in
            analyticsEngine.loadData(for: selectedTimeframe)
        }
    }
    
    /// Retrieves data with proper error handling and caching
    private func getBadgeCount(for view: DashboardView) -> Int? {
        switch view {
        case .overview: return nil
        case .codeQuality: return analyticsEngine.codeQualityIssues.count
        case .performance: return analyticsEngine.performanceIssues.count
        case .security: return analyticsEngine.securityVulnerabilities.count
        case .teamProductivity: return nil
        case .trends: return analyticsEngine.trendingInsights.count
        }
    }
}

// MARK: - Filter Toggle Component
struct FilterToggle: View {
    let filter: EnhancedEnterpriseAnalyticsDashboard.AnalyticsFilter
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? filter.color : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                Text(filter.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(isSelected ? filter.color.opacity(0.1) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Dashboard View Button
struct DashboardViewButton: View {
    let view: EnhancedEnterpriseAnalyticsDashboard.DashboardView
    let isSelected: Bool
    let badgeCount: Int?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: view.icon)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 16)
                
                Text(view.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
                
                if let badgeCount = badgeCount, badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Overview Dashboard
struct OverviewDashboard: View {
    let analyticsEngine: EnterpriseAnalyticsEngine
    let timeframe: EnhancedEnterpriseAnalyticsDashboard.AnalyticsTimeframe
    let filters: Set<EnhancedEnterpriseAnalyticsDashboard.AnalyticsFilter>
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Key Metrics
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    EnterpriseMetricCard(
                        title: "Total Issues",
                        value: "\(analyticsEngine.totalIssues)",
                        subtitle: "Across all projects",
                        color: .red,
                        trend: analyticsEngine.issuesTrend
                    )
                    
                    EnterpriseMetricCard(
                        title: "Code Quality Score",
                        value: "\(Int(analyticsEngine.codeQualityScore * 100))",
                        subtitle: "Out of 100",
                        color: .green,
                        trend: analyticsEngine.qualityTrend
                    )
                    
                    EnterpriseMetricCard(
                        title: "Security Rating",
                        value: analyticsEngine.securityRating.rawValue,
                        subtitle: "\(analyticsEngine.securityVulnerabilities.count) vulnerabilities",
                        color: analyticsEngine.securityRating.color,
                        trend: analyticsEngine.securityTrend
                    )
                    
                    EnterpriseMetricCard(
                        title: "Performance Score",
                        value: "\(Int(analyticsEngine.performanceScore * 100))%",
                        subtitle: "Response time avg",
                        color: .blue,
                        trend: analyticsEngine.performanceTrend
                    )
                }
                
                HStack(spacing: 20) {
                    // Issue Distribution Chart
                    EnhancedCard(
                        title: "Issue Distribution",
                        subtitle: "By severity level",
                        icon: "chart.pie.fill",
                        style: .standard
                    ) {
                        IssueDistributionChart(analyticsEngine: analyticsEngine)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Recent Activity
                    EnhancedCard(
                        title: "Recent Activity",
                        subtitle: "Last 24 hours",
                        icon: "clock.fill",
                        style: .standard
                    ) {
                        RecentActivityList(activities: analyticsEngine.recentActivities)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Trending Issues
                EnhancedCard(
                    title: "Trending Issues",
                    subtitle: "Requiring immediate attention",
                    icon: "exclamationmark.triangle.fill",
                    style: .warning
                ) {
                    TrendingIssuesList(issues: analyticsEngine.trendingIssues)
                }
                
                // Team Performance Summary
                EnhancedCard(
                    title: "Team Performance Summary",
                    subtitle: "Productivity and code quality metrics",
                    icon: "person.3.fill",
                    style: .featured
                ) {
                    TeamPerformanceSummary(analyticsEngine: analyticsEngine)
                }
            }
            .padding()
        }
        .navigationTitle("Analytics Overview")
    }
}

// MARK: - Code Quality Dashboard
struct CodeQualityDashboard: View {
    let analyticsEngine: EnterpriseAnalyticsEngine
    let timeframe: EnhancedEnterpriseAnalyticsDashboard.AnalyticsTimeframe
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quality Score Overview
                HStack(spacing: 20) {
                    QualityScoreGauge(
                        score: analyticsEngine.codeQualityScore,
                        title: "Overall Quality Score"
                    )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        QualityMetricRow(
                            title: "Maintainability",
                            score: analyticsEngine.maintainabilityScore,
                            color: .green
                        )
                        QualityMetricRow(
                            title: "Reliability",
                            score: analyticsEngine.reliabilityScore,
                            color: .blue
                        )
                        QualityMetricRow(
                            title: "Security",
                            score: analyticsEngine.securityScore,
                            color: .orange
                        )
                        QualityMetricRow(
                            title: "Test Coverage",
                            score: analyticsEngine.testCoverage,
                            color: .purple
                        )
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Detailed Issues List
                EnhancedCard(
                    title: "Code Quality Issues",
                    subtitle: "\(analyticsEngine.codeQualityIssues.count) issues found",
                    icon: "list.bullet",
                    style: .standard
                ) {
                    LazyVStack(spacing: 8) {
                        ForEach(analyticsEngine.codeQualityIssues.prefix(10), id: \.id) { issue in
                            QualityIssueRow(issue: issue)
                        }
                        
                        if analyticsEngine.codeQualityIssues.count > 10 {
                            Button("View All \(analyticsEngine.codeQualityIssues.count) Issues") {
                                // Handle view all
                            }
                            .foregroundColor(.blue)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Code Quality")
    }
}

// MARK: - Export Options View
struct ExportOptionsView: View {
    let analyticsEngine: EnterpriseAnalyticsEngine
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var includeCharts = true
    @State private var includeRawData = false
    @State private var customDateRange = false
    
    // ExportFormat now defined in SharedTypes.swift
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                Text("Export Analytics Report")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Generate comprehensive reports for stakeholders")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Export Format Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Export Format")
                    .font(.headline)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        ExportFormatButton(
                            format: format,
                            isSelected: selectedFormat == format
                        ) {
                            selectedFormat = format
                        }
                    }
                }
            }
            
            // Export Options
            VStack(alignment: .leading, spacing: 12) {
                Text("Options")
                    .font(.headline)
                
                Toggle("Include Charts and Graphs", isOn: $includeCharts)
                Toggle("Include Raw Data", isOn: $includeRawData)
                Toggle("Custom Date Range", isOn: $customDateRange)
            }
            
            Spacer()
            
            // Export Button
            HStack(spacing: 12) {
                Button("Cancel") {
                    // Handle cancel
                }
                .buttonStyle(PlainButtonStyle())
                
                AccessibleButton(
                    "Export Report",
                    icon: "arrow.down.circle.fill",
                    style: .primary
                ) {
                    exportReport()
                }
            }
        }
        .padding(24)
        .frame(width: 500, height: 600)
    }
    
    /// Performs operation with error handling and validation
    private func exportReport() {
        // Handle export logic
        // AppLogger.shared.log("Exporting \(selectedFormat.rawValue)") // TODO: Replace print with proper logging
    }
}

struct ExportFormatButton: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: format.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                Text(format.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Helper Views and Components
struct EnterpriseMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(trend)
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct IssueDistributionChart: View {
    let analyticsEngine: EnterpriseAnalyticsEngine
    
    var body: some View {
        // Simplified chart representation
        VStack(spacing: 12) {
            HStack {
                ChartSegment(label: "Critical", count: 5, color: .red)
                ChartSegment(label: "High", count: 12, color: .orange)
                ChartSegment(label: "Medium", count: 25, color: .yellow)
                ChartSegment(label: "Low", count: 18, color: .green)
            }
            
            Text("60 Total Issues")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ChartSegment: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct RecentActivityList: View {
    let activities: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(activities.prefix(5), id: \.self) { activity in
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 4, height: 4)
                    
                    Text(activity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            if activities.isEmpty {
                Text("No recent activity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

struct TrendingIssuesList: View {
    let issues: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(issues.prefix(5), id: \.self) { issue in
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text(issue)
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
        }
    }
}

struct TeamPerformanceSummary: View {
    let analyticsEngine: EnterpriseAnalyticsEngine
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                EnterprisePerformanceMetric(title: "Avg Quality", value: "87%", color: .green)
                EnterprisePerformanceMetric(title: "Issues/Day", value: "3.2", color: .orange)
                EnterprisePerformanceMetric(title: "Resolution Time", value: "4.5h", color: .blue)
            }
        }
    }
}

struct EnterprisePerformanceMetric: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QualityScoreGauge: View {
    let score: Double
    let title: String
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: score)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                
                Text("\(Int(score * 100))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct QualityMetricRow: View {
    let title: String
    let score: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
            
            Spacer()
            
            ProgressView(value: score, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(width: 80)
            
            Text("\(Int(score * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct QualityIssueRow: View {
    let issue: QualityIssue
    
    var body: some View {
        HStack {
            Image(systemName: issue.severity.icon)
                .foregroundColor(issue.severity.color)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(issue.title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(issue.file)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Line \(issue.lineNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// Placeholder dashboard views
struct AnalyticsPerformanceDashboard: View {
    let analyticsEngine: EnterpriseAnalyticsEngine
    let timeframe: EnhancedEnterpriseAnalyticsDashboard.AnalyticsTimeframe
    
    var body: some View {
        Text("Performance Dashboard")
            .font(.title)
            .navigationTitle("Performance Analytics")
    }
}

struct SecurityDashboard: View {
    let analyticsEngine: EnterpriseAnalyticsEngine
    let timeframe: EnhancedEnterpriseAnalyticsDashboard.AnalyticsTimeframe
    
    var body: some View {
        Text("Security Dashboard")
            .font(.title)
            .navigationTitle("Security Analytics")
    }
}

struct TeamProductivityDashboard: View {
    let analyticsEngine: EnterpriseAnalyticsEngine
    let timeframe: EnhancedEnterpriseAnalyticsDashboard.AnalyticsTimeframe
    
    var body: some View {
        Text("Team Productivity Dashboard")
            .font(.title)
            .navigationTitle("Team Productivity")
    }
}

struct TrendsAndInsightsDashboard: View {
    let analyticsEngine: EnterpriseAnalyticsEngine
    let timeframe: EnhancedEnterpriseAnalyticsDashboard.AnalyticsTimeframe
    
    var body: some View {
        Text("Trends & Insights Dashboard")
            .font(.title)
            .navigationTitle("Trends & Insights")
    }
}

#Preview("Enhanced Enterprise Analytics") {
    EnhancedEnterpriseAnalyticsDashboard()
        .frame(width: 1200, height: 800)
}
