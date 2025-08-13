import Foundation
import SwiftUI
import Combine

/// Enhanced Performance Dashboard with real-time monitoring and analytics
struct EnhancedPerformanceDashboard: View {
    @EnvironmentObject var memoryMonitor: MemoryMonitor
    @EnvironmentObject var responseTracker: ResponseTimeTracker
    @EnvironmentObject var backgroundManager: BackgroundProcessingManager
    @StateObject private var performanceAnalyzer = EnhancedPerformanceAnalyzer()
    
    @State private var selectedTimeRange: TimeRange = .last1Hour
    @State private var showDetailedView = false
    @State private var selectedMetric: MetricType? = nil
    
    enum TimeRange: String, CaseIterable {
        case last5Min = "5m"
        case last1Hour = "1h" 
        case last24Hours = "24h"
        case last7Days = "7d"
        
        var displayName: String {
            switch self {
            case .last5Min: return "Last 5 minutes"
            case .last1Hour: return "Last hour"
            case .last24Hours: return "Last 24 hours"
            case .last7Days: return "Last 7 days"
            }
        }
    }
    
    enum MetricType: String, CaseIterable {
        case memory = "Memory Usage"
        case cpu = "CPU Usage"
        case responseTime = "Response Time"
        case backgroundJobs = "Background Jobs"
        case diskIO = "Disk I/O"
        case networkActivity = "Network Activity"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with time range selector
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Performance Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Real-time system monitoring and analytics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // Real-time metrics overview
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Memory Usage Card
                PerformanceMetricCard(
                    title: "Memory Usage",
                    value: memoryMonitor.formatBytes(memoryMonitor.currentUsage),
                    subtitle: "current usage",
                    progress: Double(memoryMonitor.currentUsage) / Double(memoryMonitor.memoryPressure.threshold),
                    color: Color.blue,
                    trend: performanceAnalyzer.memoryTrend,
                    isSelected: selectedMetric == .memory,
                    onTap: { selectedMetric = .memory }
                )
                
                // Response Time Card
                PerformanceMetricCard(
                    title: "Avg Response",
                    value: String(format: "%.0f", responseTracker.averageResponseTime * 1000),
                    subtitle: "milliseconds",
                    progress: min(responseTracker.averageResponseTime / 5.0, 1.0), // Normalize to 5s max
                    color: responseTimeColor,
                    trend: performanceAnalyzer.responseTimeTrend,
                    isSelected: selectedMetric == .responseTime,
                    onTap: { selectedMetric = .responseTime }
                )
                
                // Background Jobs Card
                PerformanceMetricCard(
                    title: "Active Jobs",
                    value: "\(backgroundManager.activeJobs.count)",
                    subtitle: "\(backgroundManager.totalJobsProcessed) completed",
                    progress: backgroundJobsProgress,
                    color: backgroundJobsColor,
                    trend: performanceAnalyzer.backgroundJobsTrend,
                    isSelected: selectedMetric == .backgroundJobs,
                    onTap: { selectedMetric = .backgroundJobs }
                )
                
                // CPU Usage Card (Estimated)
                PerformanceMetricCard(
                    title: "CPU Usage",
                    value: "\(Int(performanceAnalyzer.estimatedCPUUsage * 100))%",
                    subtitle: "estimated",
                    progress: performanceAnalyzer.estimatedCPUUsage,
                    color: cpuUsageColor,
                    trend: performanceAnalyzer.cpuTrend,
                    isSelected: selectedMetric == .cpu,
                    onTap: { selectedMetric = .cpu }
                )
                
                // System Health Score
                PerformanceMetricCard(
                    title: "Health Score",
                    value: "\(Int(performanceAnalyzer.overallHealthScore * 100))",
                    subtitle: "out of 100",
                    progress: performanceAnalyzer.overallHealthScore,
                    color: healthScoreColor,
                    trend: performanceAnalyzer.healthTrend,
                    isSelected: selectedMetric == .diskIO,
                    onTap: { selectedMetric = .diskIO }
                )
                
                // Quick Actions Card
                QuickActionsCard()
            }
            
            // Detailed View Section
            if let selectedMetric = selectedMetric {
                DetailedMetricView(metric: selectedMetric, timeRange: selectedTimeRange)
                    .transition(.opacity.combined(with: .slide))
            }
            
            // Performance Recommendations
            if !performanceAnalyzer.recommendations.isEmpty {
                RecommendationsCard(recommendations: performanceAnalyzer.recommendations)
            }
            
            // System Status Timeline
            SystemStatusTimeline(analyzer: performanceAnalyzer)
        }
        .padding()
        .onAppear {
            performanceAnalyzer.startMonitoring()
        }
        .onDisappear {
            performanceAnalyzer.stopMonitoring()
        }
    }
    
    private var responseTimeColor: Color {
        let time = responseTracker.averageResponseTime
        if time < 1.0 { return .green }
        if time < 3.0 { return .orange }
        return .red
    }
    
    private var backgroundJobsProgress: Double {
        let total = max(backgroundManager.activeJobs.count + backgroundManager.totalJobsProcessed, 1)
        return Double(backgroundManager.totalJobsProcessed) / Double(total)
    }
    
    private var backgroundJobsColor: Color {
        if backgroundManager.activeJobs.count > 5 { return .red }
        if backgroundManager.activeJobs.count > 2 { return .orange }
        return .green
    }
    
    private var cpuUsageColor: Color {
        let usage = performanceAnalyzer.estimatedCPUUsage
        if usage > 0.8 { return .red }
        if usage > 0.6 { return .orange }
        return .green
    }
    
    private var healthScoreColor: Color {
        let score = performanceAnalyzer.overallHealthScore
        if score > 0.8 { return .green }
        if score > 0.6 { return .orange }
        return .red
    }
}

/// Individual Performance Metric Card Component
struct PerformanceMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    let color: Color
    let trend: EnhancedPerformanceAnalyzer.Trend
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    TrendIndicator(trend: trend)
                }
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title): \(value)")
        .accessibilityValue(subtitle)
        .accessibilityHint("Tap for detailed view")
    }
}

/// Trend Indicator Component
struct TrendIndicator: View {
    let trend: EnhancedPerformanceAnalyzer.Trend
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .foregroundColor(trend.color)
                .font(.caption2)
            
            switch trend {
            case .up(let percent), .down(let percent):
                Text(String(format: "%.1f%%", abs(percent)))
                    .font(.caption2)
                    .foregroundColor(trend.color)
            case .stable:
                EmptyView()
            }
        }
    }
}

/// Quick Actions Card
struct QuickActionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Actions")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 6) {
                QuickActionButton(
                    title: "Clear Cache",
                    icon: "trash.fill",
                    color: .orange
                ) {
                    // Implement cache clearing
                }
                
                QuickActionButton(
                    title: "Optimize Memory",
                    icon: "arrow.clockwise",
                    color: .blue
                ) {
                    // Implement memory optimization
                }
                
                QuickActionButton(
                    title: "Export Report",
                    icon: "square.and.arrow.up",
                    color: .green
                ) {
                    // Implement report export
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Detailed Metric View
struct DetailedMetricView: View {
    let metric: EnhancedPerformanceDashboard.MetricType
    let timeRange: EnhancedPerformanceDashboard.TimeRange
    
    var body: some View {
        EnhancedCard(
            title: metric.rawValue,
            subtitle: "Detailed view for \(timeRange.displayName.lowercased())",
            icon: "chart.line.uptrend.xyaxis",
            style: .featured
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Mini chart placeholder
                Rectangle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.3), .blue.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 80)
                    .cornerRadius(8)
                    .overlay(
                        Text("📈 Performance chart\n(Simulated data)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    )
                
                // Statistics
                HStack {
                    StatisticView(title: "Average", value: getAverageValue(), color: .blue)
                    Spacer()
                    StatisticView(title: "Peak", value: getPeakValue(), color: .red)
                    Spacer()
                    StatisticView(title: "Min", value: getMinValue(), color: .green)
                }
            }
        }
    }
    
    private func getAverageValue() -> String {
        switch metric {
        case .memory: return "2.1 GB"
        case .cpu: return "45%"
        case .responseTime: return "1.2s"
        case .backgroundJobs: return "3"
        case .diskIO: return "15 MB/s"
        case .networkActivity: return "5 MB/s"
        }
    }
    
    private func getPeakValue() -> String {
        switch metric {
        case .memory: return "3.8 GB"
        case .cpu: return "85%"
        case .responseTime: return "4.1s"
        case .backgroundJobs: return "8"
        case .diskIO: return "45 MB/s"
        case .networkActivity: return "25 MB/s"
        }
    }
    
    private func getMinValue() -> String {
        switch metric {
        case .memory: return "1.2 GB"
        case .cpu: return "12%"
        case .responseTime: return "0.3s"
        case .backgroundJobs: return "0"
        case .diskIO: return "2 MB/s"
        case .networkActivity: return "0.5 MB/s"
        }
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

/// Performance Recommendations Card
struct RecommendationsCard: View {
    let recommendations: [PerformanceRecommendation]
    @State private var isExpanded = false
    
    var body: some View {
        EnhancedCard(
            title: "Performance Recommendations",
            subtitle: "\(recommendations.count) suggestions available",
            icon: "lightbulb.fill",
            style: .warning
        ) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(recommendations.prefix(isExpanded ? recommendations.count : 3), id: \.id) { recommendation in
                    RecommendationRow(recommendation: recommendation)
                }
                
                if recommendations.count > 3 {
                    Button(action: { isExpanded.toggle() }) {
                        HStack {
                            Text(isExpanded ? "Show Less" : "Show \(recommendations.count - 3) More")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct RecommendationRow: View {
    let recommendation: PerformanceRecommendation
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: recommendation.priority.icon)
                .foregroundColor(recommendation.priority.color)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(recommendation.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let impact = recommendation.estimatedImprovement {
                Text("+\(Int(impact * 100))%")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 4)
    }
}

/// System Status Timeline
struct SystemStatusTimeline: View {
    let analyzer: EnhancedPerformanceAnalyzer
    
    var body: some View {
        EnhancedCard(
            title: "System Status Timeline",
            subtitle: "Recent system events and status changes",
            icon: "clock.fill"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(analyzer.recentEvents, id: \.id) { event in
                    HStack {
                        Circle()
                            .fill(event.severity.color)
                            .frame(width: 6, height: 6)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text(event.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if event.hasAction {
                            Button("View") {
                                // Handle event action
                            }
                            .font(.caption2)
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                if analyzer.recentEvents.isEmpty {
                    Text("No recent events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
    }
}

#Preview("Enhanced Performance Dashboard") {
    EnhancedPerformanceDashboard()
        .environmentObject(MemoryMonitor())
        .environmentObject(ResponseTimeTracker())
        .environmentObject(BackgroundProcessingManager())
        .frame(width: 800, height: 1000)
}
