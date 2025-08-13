import Foundation
import SwiftUI

/// Performance monitoring dashboard for analysis operations
struct PerformanceDashboardView: View {
    @StateObject private var performanceTracker = PerformanceTracker.shared
    @State private var selectedTimeframe = "Last Hour"
    @State private var showingCacheStats = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Performance Overview
                performanceOverview
                
                // Recent Metrics
                recentMetricsSection
                
                // Cache Statistics
                cacheStatsSection
                
                // Performance Chart (placeholder for future implementation)
                performanceChartPlaceholder
                
                Spacer()
            }
            .padding()
                        .navigationTitle("Performance Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") {
                        performanceTracker.refreshMetrics()
                    }
                }
            }
        }
    }
    
    private var performanceOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Overview")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                performanceCard(
                    title: "Total Operations",
                    value: "\(performanceTracker.metrics.count)",
                    color: .blue
                )
                
                performanceCard(
                    title: "Avg Duration",
                    value: formatAverageDuration(),
                    color: .green
                )
                
                performanceCard(
                    title: "Slowest Op",
                    value: formatSlowestOperation(),
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var recentMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Analysis Operations")
                .font(.headline)
                .foregroundColor(.primary)
            
            if performanceTracker.metrics.isEmpty {
                Text("No recent operations")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(performanceTracker.metrics.suffix(10).reversed(), id: \.timestamp) { metric in
                        metricRow(metric)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var cacheStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cache Statistics")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Details") {
                    showingCacheStats.toggle()
                }
            }
            
            let stats = AnalysisCache.shared.getCacheStats()
            
            HStack(spacing: 20) {
                performanceCard(
                    title: "Cache Entries",
                    value: "\(stats.totalEntries)",
                    color: .purple
                )
                
                performanceCard(
                    title: "Hit Rate",
                    value: String(format: "%.1f%%", stats.hitRate * 100),
                    color: .green
                )
                
                performanceCard(
                    title: "Active",
                    value: "\(stats.totalEntries - stats.expiredEntries)",
                    color: .blue
                )
            }
        }
        .padding()
        .cornerRadius(10)
        .sheet(isPresented: $showingCacheStats) {
            cacheDetailsView
        }
    }
    
    private var performanceChartPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Trends")
                .font(.headline)
                .foregroundColor(.primary)
            
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.separatorColor))
                .frame(height: 150)
                .overlay(
                    Text("Chart coming soon...")
                        .foregroundColor(.secondary)
                        .italic()
                )
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    /// Performs operation with error handling and validation
    private func performanceCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    /// Performs operation with error handling and validation
    private func metricRow(_ metric: PerformanceMetric) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.operation.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(metric.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(metric.formattedDuration)s")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(metric.duration > 1.0 ? .red : .green)
                
                Text(metric.formattedMemoryUsage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
    
    private var cacheDetailsView: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                let stats = AnalysisCache.shared.getCacheStats()
                
                Text(stats.description)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Cache Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        showingCacheStats = false
                    }
                }
            }
        }
    }
    
    /// Formats and displays data with proper styling
    private func formatAverageDuration() -> String {
        guard !performanceTracker.metrics.isEmpty else { return "N/A" }
        
        let totalDuration = performanceTracker.metrics
    .reduce(0) {
         $0 + $1.duration 
    }
        let average = totalDuration / Double(performanceTracker.metrics.count)
        return String(format: "%.3fs", average)
    }
    
    /// Formats and displays data with proper styling
    private func formatSlowestOperation() -> String {
        guard let slowest = performanceTracker.metrics.max(by: { $0.duration < $1.duration }) else {
            return "N/A"
        }
        return String(format: "%.3fs", slowest.duration)
    }
    
    /// Creates and configures components with proper initialization
    private func generatePerformanceReport() {
        let report = performanceTracker.generateReport()
        AppLogger.shared.log("Performance report generated", level: .info, category: .performance)
        // In a real app, you might save this to a file or show it in a view
        // AppLogger.shared.log(report) // TODO: Replace print with proper logging
    }
}

#Preview {
    PerformanceDashboardView()
}
