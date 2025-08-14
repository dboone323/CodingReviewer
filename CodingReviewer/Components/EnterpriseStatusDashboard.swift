import Foundation
import SwiftUI

//
//  EnterpriseStatusDashboard.swift
//  CodingReviewer
//
//  Created by Phase 4 Enterprise Features on 8/5/25.
//

// Note: SystemStatus and related types are defined in BackgroundProcessingTypes.swift

// MARK: - Enterprise Status Dashboard

struct EnterpriseStatusDashboard: View {
    @StateObject private var backgroundProcessing = BackgroundProcessingSystem()
    @StateObject private var usageTracker = UsageTracker()
    @State private var systemStatus: SystemStatus?
    @State private var analyticsReport: AnalyticsReport?
    @State private var isGeneratingReport = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // System Health Overview
                    SystemHealthCard(systemStatus: systemStatus)

                    // Quick Stats Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        EnterpriseQuickStatCard(
                            title: "Active Jobs",
                            value: "\(systemStatus?.activeJobsCount ?? 0)",
                            icon: "gearshape.2",
                            color: .blue
                        )

                        EnterpriseQuickStatCard(
                            title: "Success Rate",
                            value: String(format: "%.1f%%", (systemStatus?.successRate ?? 0) * 100),
                            icon: "checkmark.circle",
                            color: .green
                        )

                        EnterpriseQuickStatCard(
                            title: "Total Processed",
                            value: "\(systemStatus?.totalJobsProcessed ?? 0)",
                            icon: "chart.bar",
                            color: .orange
                        )

                        EnterpriseQuickStatCard(
                            title: "System Health",
                            value: systemStatus?.status ?? "Unknown",
                            icon: "heart.circle",
                            color: healthColor
                        )
                    }

                    // Performance Metrics
                    if let report = analyticsReport {
                        PerformanceMetricsCard(report: report)
                    }

                    // System Insights
                    if let report = analyticsReport, !report.insights.isEmpty {
                        InsightsCard(insights: report.insights)
                    }

                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: refreshData) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }

                        Button(action: generateReport) {
                            HStack {
                                if isGeneratingReport {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "doc.text")
                                }
                                Text("Generate Report")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(10)
                        }
                        .disabled(isGeneratingReport)
                    }
                }
                .padding()
            }
            .navigationTitle("Enterprise Status")
            .onAppear(perform: refreshData)
            .refreshable {
                await refreshDataAsync()
            }
        }
    }

    private var healthColor: Color {
        guard let status = systemStatus else { return .gray }
        switch status.status {
        case "Excellent": return .green
        case "Good": return .blue
        case "Fair": return .yellow
        case "Poor": return .orange
        case "Critical": return .red
        default: return .gray
        }
    }

    private func refreshData() {
        systemStatus = backgroundProcessing.getSystemStatus()
        analyticsReport = EnterpriseAnalyticsDashboard().generateComprehensiveReport()
    }

    private func refreshDataAsync() async {
        refreshData()
    }

    private func generateReport() {
        isGeneratingReport = true

        Task {
            // Simulate report generation
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            await MainActor.run {
                isGeneratingReport = false
                // Here you would typically save or export the report
                usageTracker.trackActivity(
                    action: .aiInsight,
                    details: "Generated comprehensive enterprise status report"
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct SystemHealthCard: View {
    let systemStatus: SystemStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "server.rack")
                    .foregroundColor(.blue)
                Text("System Health")
                    .font(.headline)
                Spacer()
                if let status = systemStatus {
                    Text(status.status)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                }
            }

            if let status = systemStatus {
                VStack(spacing: 8) {
                    ProgressView(value: status.healthScore)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(y: 2)

                    HStack {
                        Text("Health Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f%%", status.healthScore * 100))
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("CPU: \(String(format: "%.1f%%", status.currentLoad.cpuUsage * 100))")
                                .font(.caption)
                            Text("Memory: \(String(format: "%.1f%%", status.currentLoad.memoryUsage * 100))")
                                .font(.caption)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Uptime: \(formatUptime(status.uptime))")
                                .font(.caption)
                            Text(status.isProcessingEnabled ? "Processing: On" : "Processing: Off")
                                .font(.caption)
                                .foregroundColor(status.isProcessingEnabled ? .green : .red)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var statusColor: Color {
        guard let status = systemStatus else { return .gray }
        switch status.status {
        case "Excellent": return .green
        case "Good": return .blue
        case "Fair": return .yellow
        case "Poor": return .orange
        case "Critical": return .red
        default: return .gray
        }
    }

    private func formatUptime(_ uptime: TimeInterval) -> String {
        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct EnterpriseQuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct PerformanceMetricsCard: View {
    let report: AnalyticsReport

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.orange)
                Text("Performance Metrics")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                MetricRow(
                    title: "Avg Actions/Day",
                    value: String(format: "%.1f", report.averageActionsPerDay)
                )
                MetricRow(
                    title: "Peak Usage Hour",
                    value: "\(report.performanceMetrics.peakUsageHour):00"
                )
                MetricRow(
                    title: "Success Rate",
                    value: String(format: "%.1f%%", report.performanceMetrics.successRate * 100)
                )
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct InsightsCard: View {
    let insights: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                Text("Insights")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(insights, id: \.self) { insight in
                    HStack(alignment: .top) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(insight)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Preview

#Preview {
    EnterpriseStatusDashboard()
}
