import Foundation
import Combine
import SwiftUI

/// Advanced Performance Analyzer with trend detection and recommendations
@MainActor
class EnhancedPerformanceAnalyzer: ObservableObject {
    @Published var estimatedCPUUsage: Double = 0.0
    @Published var overallHealthScore: Double = 0.85
    @Published var memoryTrend: Trend = .stable
    @Published var responseTimeTrend: Trend = .stable
    @Published var backgroundJobsTrend: Trend = .stable
    @Published var cpuTrend: Trend = .stable
    @Published var healthTrend: Trend = .stable
    @Published var recommendations: [PerformanceRecommendation] = []
    @Published var recentEvents: [SystemEvent] = []

    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    private var metricsHistory: [MetricsSnapshot] = []

    enum Trend {
        case up(Double), down(Double), stable

        var icon: String {
            switch self {
            case .up: "arrow.up.circle.fill"
            case .down: "arrow.down.circle.fill"
            case .stable: "minus.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .up: .green
            case .down: .red
            case .stable: .gray
            }
        }

        var changePercent: Double {
            switch self {
            case .up(let value), .down(let value): value
            case .stable: 0.0
            }
        }
    }

    struct MetricsSnapshot {
        let timestamp: Date
        let memoryUsage: Double
        let cpuUsage: Double
        let responseTime: Double
        let activeJobs: Int
        let healthScore: Double
    }

    init() {
        generateInitialRecommendations()
        generateInitialEvents()
    }

            /// Function description
            /// - Returns: Return value description
    func startMonitoring() {
        // Start periodic monitoring
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                await self.updateMetrics()
                self.updateTrends()
                self.updateRecommendations()
                self.updateHealthScore()
            }
        }

        // Initial update
        Task {
            await updateMetrics()
        }
    }

            /// Function description
            /// - Returns: Return value description
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }

    private func updateMetrics() async {
        // Simulate realistic CPU usage based on system activity
        let baseUsage = 0.15 + Double.random(in: 0 ... 0.3)
        let activityBoost = estimateActivityBoost()
        estimatedCPUUsage = min(baseUsage + activityBoost, 1.0)

        // Record metrics snapshot
        let snapshot = MetricsSnapshot(
            timestamp: Date(),
            memoryUsage: Double.random(in: 0.4 ... 0.8), // Simulated
            cpuUsage: estimatedCPUUsage,
            responseTime: Double.random(in: 0.5 ... 3.0), // Simulated
            activeJobs: Int.random(in: 0 ... 5), // Simulated
            healthScore: overallHealthScore
        )

        metricsHistory.append(snapshot)

        // Keep only last 100 snapshots
        if metricsHistory.count > 100 {
            metricsHistory.removeFirst()
        }
    }

    private func estimateActivityBoost() -> Double {
        // Estimate CPU boost based on various factors
        var boost = 0.0

        // Time-based activity (higher during business hours)
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 9, hour <= 17 {
            boost += 0.1
        }

        // Random activity spikes
        if Double.random(in: 0 ... 1) < 0.1 {
            boost += Double.random(in: 0 ... 0.3)
        }

        return boost
    }

    private func updateTrends() {
        guard metricsHistory.count >= 2 else { return }

        let recent = Array(metricsHistory.suffix(10))
        let older = Array(metricsHistory.suffix(20).prefix(10))

        guard !recent.isEmpty, !older.isEmpty else { return }

        // Calculate trend for each metric
        memoryTrend = calculateTrend(
            recent: recent.map(\.memoryUsage),
            older: older.map(\.memoryUsage)
        )

        cpuTrend = calculateTrend(
            recent: recent.map(\.cpuUsage),
            older: older.map(\.cpuUsage)
        )

        responseTimeTrend = calculateTrend(
            recent: recent.map(\.responseTime),
            older: older.map(\.responseTime),
            isLowerBetter: true
        )

        healthTrend = calculateTrend(
            recent: recent.map(\.healthScore),
            older: older.map(\.healthScore)
        )
    }

    private func calculateTrend(recent: [Double], older: [Double], isLowerBetter: Bool = false) -> Trend {
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)

        let change = (recentAvg - olderAvg) / olderAvg
        let changePercent = abs(change) * 100

        if abs(change) < 0.05 {
            return .stable
        }

        if isLowerBetter {
            return change < 0 ? .up(changePercent) : .down(changePercent)
        } else {
            return change > 0 ? .up(changePercent) : .down(changePercent)
        }
    }

    private func updateRecommendations() {
        var newRecommendations: [PerformanceRecommendation] = []

        // Memory-based recommendations
        if estimatedCPUUsage > 0.8 {
            newRecommendations.append(PerformanceRecommendation(
                title: "High CPU Usage Detected",
                description: "Consider closing unused applications or optimizing background processes",
                priority: .high,
                category: .performance,
                estimatedImprovement: 0.25
            ))
        }

        // Health score recommendations
        if overallHealthScore < 0.7 {
            newRecommendations.append(PerformanceRecommendation(
                title: "System Health Below Optimal",
                description: "Run system diagnostics and clear temporary files",
                priority: .medium,
                category: .maintenance,
                estimatedImprovement: 0.15
            ))
        }

        // Trend-based recommendations
        if case .down(let percent) = memoryTrend, percent > 10 {
            newRecommendations.append(PerformanceRecommendation(
                title: "Memory Usage Increasing",
                description: "Monitor memory-intensive applications and consider restarting if needed",
                priority: .medium,
                category: .memory,
                estimatedImprovement: 0.2
            ))
        }

        // Proactive recommendations
        if Int.random(in: 1 ... 10) == 1 { // 10% chance per update
            newRecommendations.append(PerformanceRecommendation(
                title: "Optimize Cache",
                description: "Clear application cache to improve performance",
                priority: .low,
                category: .optimization,
                estimatedImprovement: 0.1
            ))
        }

        recommendations = newRecommendations
    }

    private func updateHealthScore() {
        var score = 1.0

        // CPU impact
        if estimatedCPUUsage > 0.8 {
            score -= 0.3
        } else if estimatedCPUUsage > 0.6 {
            score -= 0.1
        }

        // Trend impact
        if case .down = memoryTrend {
            score -= 0.1
        }

        if case .down = responseTimeTrend {
            score += 0.1 // Response time going down is good
        } else if case .up = responseTimeTrend {
            score -= 0.1
        }

        // Add some randomness for realistic variation
        score += Double.random(in: -0.05 ... 0.05)

        overallHealthScore = max(0.0, min(1.0, score))

        // Generate events based on health score changes
        if abs(overallHealthScore - (metricsHistory.last?.healthScore ?? 0.85)) > 0.1 {
            addEvent(SystemEvent(
                title: overallHealthScore > 0.8 ? "System Health Improved" : "System Health Declined",
                severity: overallHealthScore > 0.8 ? .info : .warning,
                hasAction: overallHealthScore <= 0.8
            ))
        }
    }

    private func generateInitialRecommendations() {
        recommendations = [
            PerformanceRecommendation(
                title: "Enable Background Processing Optimization",
                description: "Optimize background job scheduling for better resource utilization",
                priority: .medium,
                category: .optimization,
                estimatedImprovement: 0.15
            ),
            PerformanceRecommendation(
                title: "Update Cache Strategy",
                description: "Implement smart caching to reduce redundant calculations",
                priority: .low,
                category: .performance,
                estimatedImprovement: 0.1
            ),
        ]
    }

    private func generateInitialEvents() {
        recentEvents = [
            SystemEvent(
                title: "System Started",
                severity: .info,
                timestamp: Date().addingTimeInterval(-300), // 5 minutes ago
                hasAction: false
            ),
            SystemEvent(
                title: "Performance Monitoring Enabled",
                severity: .info,
                timestamp: Date().addingTimeInterval(-240), // 4 minutes ago
                hasAction: false
            ),
            SystemEvent(
                title: "Memory Optimization Completed",
                severity: .success,
                timestamp: Date().addingTimeInterval(-120), // 2 minutes ago
                hasAction: false
            ),
        ]
    }

    private func addEvent(_ event: SystemEvent) {
        recentEvents.insert(event, at: 0)

        // Keep only last 20 events
        if recentEvents.count > 20 {
            recentEvents.removeLast()
        }
    }
}

/// Performance Recommendation Model
struct PerformanceRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: Priority
    let category: Category
    let estimatedImprovement: Double?

    enum Priority {
        case low, medium, high, critical

        var icon: String {
            switch self {
            case .low: "info.circle.fill"
            case .medium: "exclamationmark.circle.fill"
            case .high: "exclamationmark.triangle.fill"
            case .critical: "exclamationmark.octagon.fill"
            }
        }

        var color: Color {
            switch self {
            case .low: .blue
            case .medium: .orange
            case .high: .red
            case .critical: .purple
            }
        }
    }

    enum Category {
        case performance, memory, optimization, maintenance, security
    }
}

/// System Event Model
struct SystemEvent: Identifiable {
    let id = UUID()
    let title: String
    let severity: Severity
    let timestamp: Date
    let hasAction: Bool

    enum Severity {
        case info, success, warning, error

        var color: Color {
            switch self {
            case .info: .blue
            case .success: .green
            case .warning: .orange
            case .error: .red
            }
        }
    }

    init(title: String, severity: Severity, timestamp: Date = Date(), hasAction: Bool = false) {
        self.title = title
        self.severity = severity
        self.timestamp = timestamp
        self.hasAction = hasAction
    }
}

/// Export Functionality for Performance Data
enum PerformanceExporter {
    static func exportReport(analyzer: EnhancedPerformanceAnalyzer) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var report = """
        # Performance Report
        Generated: \(formatter.string(from: Date()))

        ## System Overview
        - Overall Health Score: \(Int(analyzer.overallHealthScore * 100))%
        - Estimated CPU Usage: \(Int(analyzer.estimatedCPUUsage * 100))%

        ## Trends
        - Memory: \(analyzer.memoryTrend.description)
        - CPU: \(analyzer.cpuTrend.description)
        - Response Time: \(analyzer.responseTimeTrend.description)
        - Health: \(analyzer.healthTrend.description)

        ## Active Recommendations (\(analyzer.recommendations.count))
        """

        for (index, recommendation) in analyzer.recommendations.enumerated() {
            report += """

            \(index + 1). \(recommendation.title)
               Priority: \(recommendation.priority)
               Description: \(recommendation.description)
            """

            if let improvement = recommendation.estimatedImprovement {
                report += "\n   Estimated Improvement: +\(Int(improvement * 100))%"
            }
        }

        report += """

        ## Recent Events (\(analyzer.recentEvents.count))
        """

        for event in analyzer.recentEvents.prefix(10) {
            report += """

            - \(event.title) (\(event.severity)) - \(formatter.string(from: event.timestamp))
            """
        }

        return report
    }
}

extension EnhancedPerformanceAnalyzer.Trend {
    var description: String {
        switch self {
        case .up(let percent):
            "Increasing (\(String(format: "%.1f", percent))%)"
        case .down(let percent):
            "Decreasing (\(String(format: "%.1f", percent))%)"
        case .stable:
            "Stable"
        }
    }
}
