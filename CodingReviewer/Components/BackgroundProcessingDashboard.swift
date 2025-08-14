import Foundation
import SwiftUI

//
//  BackgroundProcessingDashboard.swift
//  CodingReviewer
//
//  Created by Phase 4 Enterprise Features on 8/5/25.
//

// Note: ProcessingJob and related types are defined in BackgroundProcessingTypes.swift

// MARK: - Background Processing Dashboard

struct BackgroundProcessingDashboard: View {
    @StateObject private var processingSystem = BackgroundProcessingSystem()
    @State private var selectedTab: DashboardTab = .overview
    @State private var showingJobCreator = false
    @State private var showingSettings = false
    @State private var refreshTimer: Timer?

    enum DashboardTab: String, CaseIterable {
        case overview = "Overview"
        case activeJobs = "Active Jobs"
        case history = "History"
        case monitoring = "Monitoring"

        var icon: String {
            switch self {
            case .overview: "chart.bar.fill"
            case .activeJobs: "play.circle.fill"
            case .history: "clock.fill"
            case .monitoring: "gauge"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Dashboard Tab", selection: $selectedTab) {
                    ForEach(DashboardTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Content
                TabView(selection: $selectedTab) {
                    OverviewTab(processingSystem: processingSystem)
                        .tag(DashboardTab.overview)

                    ActiveJobsTab(processingSystem: processingSystem)
                        .tag(DashboardTab.activeJobs)

                    HistoryTab(processingSystem: processingSystem)
                        .tag(DashboardTab.history)

                    MonitoringTab(processingSystem: processingSystem)
                        .tag(DashboardTab.monitoring)
                }
                .tabViewStyle(.automatic)
            }
            .navigationTitle("Background Processing")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Button("Create Job") {
                            showingJobCreator = true
                        }

                        Button("Batch Jobs") {
                            processingSystem.addBatchJobs(count: 5, type: .codeAnalysis)
                        }

                        Divider()

                        Button(processingSystem.isProcessingEnabled ? "Pause Processing" : "Resume Processing") {
                            processingSystem.toggleProcessing()
                        }

                        Button("Settings") {
                            showingSettings = true
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                    }

                    Button(action: {
                        // Manual refresh trigger
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .sheet(isPresented: $showingJobCreator) {
            JobCreatorView(processingSystem: processingSystem)
        }
        .sheet(isPresented: $showingSettings) {
            ProcessingSettingsView(processingSystem: processingSystem)
        }
        .onAppear {
            startAutoRefresh()
        }
        .onDisappear {
            stopAutoRefresh()
        }
    }

    /// Initiates process with proper setup and monitoring
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Auto-refresh trigger - the system already updates itself
        }
    }

    /// Completes process and performs cleanup
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    @ObservedObject var processingSystem: BackgroundProcessingSystem

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // System Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("System Status")
                        .font(.headline)

                    HStack(spacing: 16) {
                        StatusCard(
                            title: "Processing",
                            value: processingSystem.isProcessingEnabled ? "Enabled" : "Disabled",
                            color: processingSystem.isProcessingEnabled ? .green : .red,
                            icon: processingSystem.isProcessingEnabled ? "play.fill" : "pause.fill"
                        )

                        StatusCard(
                            title: "System Load",
                            value: processingSystem.systemLoad.loadLevel.rawValue,
                            color: processingSystem.systemLoad.loadLevel.color,
                            icon: "gauge"
                        )
                    }
                }

                // Job Statistics
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ProcessingMetricCard(
                        title: "Active Jobs",
                        value: "\(processingSystem.activeJobs.count)",
                        icon: "play.circle",
                        color: .blue
                    )

                    ProcessingMetricCard(
                        title: "Completed",
                        value: "\(processingSystem.completedJobs.count)",
                        icon: "checkmark.circle",
                        color: .green
                    )

                    ProcessingMetricCard(
                        title: "Failed",
                        value: "\(processingSystem.failedJobs.count)",
                        icon: "xmark.circle",
                        color: .red
                    )

                    ProcessingMetricCard(
                        title: "Queue Length",
                        value: "\(processingSystem.systemLoad.queueLength)",
                        icon: "list.bullet",
                        color: .orange
                    )
                }

                // Performance Metrics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Performance Metrics")
                        .font(.headline)

                    VStack(spacing: 8) {
                        ProgressMetric(
                            title: "CPU Usage",
                            value: processingSystem.systemLoad.cpuUsage,
                            color: .blue
                        )

                        ProgressMetric(
                            title: "Memory Usage",
                            value: processingSystem.systemLoad.memoryUsage,
                            color: .green
                        )

                        HStack {
                            Text("Average Job Duration")
                                .font(.subheadline)

                            Spacer()

                            Text(formatDuration(processingSystem.systemLoad.averageJobDuration))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                }

                // Recent Activity Preview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Activity")
                            .font(.headline)

                        Spacer()

                        Text("View All")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    VStack(spacing: 8) {
                        ForEach(Array(processingSystem.completedJobs.prefix(3))) { job in
                            JobSummaryRow(job: job)
                        }

                        if processingSystem.completedJobs.isEmpty, processingSystem.activeJobs.isEmpty {
                            Text("No recent activity")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    /// Formats and displays data with proper styling
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            String(format: "%.1fs", duration)
        } else {
            String(format: "%.1fm", duration / 60)
        }
    }
}

// MARK: - Active Jobs Tab

struct ActiveJobsTab: View {
    @ObservedObject var processingSystem: BackgroundProcessingSystem
    @State private var sortBy: SortOption = .priority

    enum SortOption: String, CaseIterable {
        case priority = "Priority"
        case created = "Created"
        case type = "Type"
        case status = "Status"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Controls
            HStack {
                Picker("Sort by", selection: $sortBy) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Spacer()

                Text("\(processingSystem.activeJobs.count) active jobs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            // Jobs List
            if processingSystem.activeJobs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                    Text("No Active Jobs")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("All background processing jobs will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(sortedActiveJobs()) { job in
                        ActiveJobRow(job: job, processingSystem: processingSystem)
                    }
                }
            }
        }
    }

    /// Performs operation with error handling and validation
    private func sortedActiveJobs() -> [ProcessingJob] {
        switch sortBy {
        case .priority:
            processingSystem.activeJobs.sorted(by: { $0.priority.rawValue > $1.priority.rawValue })
        case .created:
            processingSystem.activeJobs.sorted(by: { $0.startTime > $1.startTime })
        case .type:
            processingSystem.activeJobs.sorted(by: { $0.type.rawValue < $1.type.rawValue })
        case .status:
            processingSystem.activeJobs.sorted(by: { $0.status.rawValue < $1.status.rawValue })
        }
    }
}

// MARK: - History Tab

struct HistoryTab: View {
    @ObservedObject var processingSystem: BackgroundProcessingSystem
    @State private var selectedFilter: HistoryFilter = .all

    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case completed = "Completed"
        case failed = "Failed"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter Controls
            HStack {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(HistoryFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                Spacer()

                Menu {
                    Button("Clear Completed") {
                        processingSystem.clearCompletedJobs()
                    }

                    Button("Clear Failed", role: .destructive) {
                        processingSystem.clearFailedJobs()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .padding()

            // History List
            List {
                ForEach(filteredJobs()) { job in
                    HistoryJobRow(job: job)
                }
            }
        }
    }

    /// Performs operation with error handling and validation
    private func filteredJobs() -> [ProcessingJob] {
        switch selectedFilter {
        case .all:
            (processingSystem.completedJobs + processingSystem.failedJobs)
                .sorted { (job1: ProcessingJob, job2: ProcessingJob) in
                    (job1.startTime) > (job2.startTime)
                }
        case .completed:
            processingSystem.completedJobs
        case .failed:
            processingSystem.failedJobs
        }
    }
}

// MARK: - Monitoring Tab

struct MonitoringTab: View {
    @ObservedObject var processingSystem: BackgroundProcessingSystem

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Real-time Metrics
                VStack(alignment: .leading, spacing: 12) {
                    Text("Real-time Monitoring")
                        .font(.headline)

                    VStack(spacing: 16) {
                        SystemLoadGauge(
                            title: "CPU Usage",
                            value: processingSystem.systemLoad.cpuUsage,
                            threshold: processingSystem.processingLimits.cpuThreshold,
                            color: .blue
                        )

                        SystemLoadGauge(
                            title: "Memory Usage",
                            value: processingSystem.systemLoad.memoryUsage,
                            threshold: processingSystem.processingLimits.memoryThreshold,
                            color: .green
                        )

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Concurrent Jobs")
                                    .font(.subheadline)
                                Text(
                                    "\(processingSystem.systemLoad.currentConcurrentJobs) / \(processingSystem.processingLimits.maxConcurrentJobs)"
                                )
                                .font(.title2)
                                .fontWeight(.bold)
                            }

                            Spacer()

                            BackgroundCircularProgressView(
                                progress: Double(processingSystem.systemLoad.currentConcurrentJobs) /
                                    Double(processingSystem.processingLimits.maxConcurrentJobs),
                                color: .orange
                            )
                            .frame(width: 60, height: 60)
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(12)
                    }
                }

                // System Configuration
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Configuration")
                        .font(.headline)

                    VStack(spacing: 8) {
                        ConfigRow(
                            title: "Max Concurrent Jobs",
                            value: "\(processingSystem.processingLimits.maxConcurrentJobs)"
                        )
                        ConfigRow(title: "Max Queue Size", value: "\(processingSystem.processingLimits.maxQueueSize)")
                        ConfigRow(
                            title: "Max Job Duration",
                            value: "\(Int(processingSystem.processingLimits.maxJobDuration))s"
                        )
                        ConfigRow(
                            title: "Throttling Enabled",
                            value: processingSystem.processingLimits.enableThrottling ? "Yes" : "No"
                        )
                        ConfigRow(
                            title: "Auto-pause on High Load",
                            value: processingSystem.processingLimits.pauseOnHighLoad ? "Yes" : "No"
                        )
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                }

                // Performance Trends
                VStack(alignment: .leading, spacing: 12) {
                    Text("Performance Statistics")
                        .font(.headline)

                    let stats = processingSystem.getProcessingStats()

                    VStack(spacing: 8) {
                        StatRow(title: "Total Jobs Processed", value: "\(stats.totalJobsProcessed)")
                        StatRow(title: "Success Rate", value: "\(Int(stats.successRate * 100))%")
                        StatRow(title: "Average Processing Time", value: formatDuration(stats.averageProcessingTime))
                        StatRow(title: "Current Queue Length", value: "\(stats.queueLength)")
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    /// Formats and displays data with proper styling
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            String(format: "%.1fs", duration)
        } else {
            String(format: "%.1fm", duration / 60)
        }
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ProcessingMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ProgressMetric: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)

                Spacer()

                Text("\(Int(value * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
    }
}

struct JobSummaryRow: View {
    let job: ProcessingJob

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: job.type.icon)
                .foregroundColor(job.type.color)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(job.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let result = job.result {
                    Text(result)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Circle()
                    .fill(job.status.color)
                    .frame(width: 8, height: 8)

                if job.endTime != nil, let duration = job.duration {
                    Text(formatDuration(duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    /// Formats and displays data with proper styling
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            String(format: "%.1fs", duration)
        } else {
            String(format: "%.1fm", duration / 60)
        }
    }
}

struct ActiveJobRow: View {
    let job: ProcessingJob
    let processingSystem: BackgroundProcessingSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: job.type.icon)
                    .foregroundColor(job.type.color)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(job.type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 8) {
                        Text(job.status.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(job.status.color.opacity(0.2))
                            .foregroundColor(job.status.color)
                            .cornerRadius(4)

                        Text(job.priority.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(job.priority.color.opacity(0.2))
                            .foregroundColor(job.priority.color)
                            .cornerRadius(4)
                    }
                }

                Spacer()

                Menu {
                    if job.status == .running {
                        Button("Pause") {
                            processingSystem.pauseJob(id: job.id)
                        }
                    } else if job.status == .paused {
                        Button("Resume") {
                            processingSystem.resumeJob(id: job.id)
                        }
                    }

                    Button("Cancel", role: .destructive) {
                        processingSystem.cancelJob(id: job.id)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            if job.status == .running, job.progress > 0 {
                ProgressView(value: job.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: job.type.color))
            }
        }
        .padding(.vertical, 4)
    }
}

struct HistoryJobRow: View {
    let job: ProcessingJob

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: job.type.icon)
                    .foregroundColor(job.type.color)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(job.type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(job.status.rawValue)
                        .font(.caption)
                        .foregroundColor(job.status.color)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let endTime = job.endTime {
                        Text(endTime, format: .dateTime.hour().minute())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if job.endTime != nil, let duration = job.duration {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let result = job.result {
                Text(result)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else if let error = job.errorMessage {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    /// Formats and displays data with proper styling
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            String(format: "%.1fs", duration)
        } else {
            String(format: "%.1fm", duration / 60)
        }
    }
}

struct SystemLoadGauge: View {
    let title: String
    let value: Double
    let threshold: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)

                Spacer()

                Text("\(Int(value * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(value > threshold ? .red : color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.controlBackgroundColor))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(value > threshold ? .red : color)
                        .frame(width: geometry.size.width * value, height: 8)
                        .cornerRadius(4)

                    // Threshold indicator
                    Rectangle()
                        .fill(.orange)
                        .frame(width: 2, height: 12)
                        .offset(x: geometry.size.width * threshold - 1, y: -2)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct BackgroundCircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.controlBackgroundColor), lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

struct ConfigRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Preview

#Preview {
    BackgroundProcessingDashboard()
}
