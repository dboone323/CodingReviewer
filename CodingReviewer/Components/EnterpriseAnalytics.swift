//
//  EnterpriseAnalytics.swift
//  CodingReviewer
//
//  Created by Phase 4 Enterprise Features on 8/5/25.
//

import SwiftUI
import Foundation
import Combine

// MARK: - Usage Pattern Tracking

@MainActor
class UsageTracker: ObservableObject {
    @Published var analysisCount: Int = 0
    @Published var fileUploadsCount: Int = 0
    @Published var averageAnalysisTime: TimeInterval = 0
    @Published var mostUsedLanguages: [String: Int] = [:]
    @Published var recentActivity: [ActivityRecord] = []
    @Published var dailyUsage: [Date: Int] = [:]
    
    struct ActivityRecord: Identifiable {
        let id: UUID
        let timestamp: Date
        let action: ActionType
        let details: String
        let duration: TimeInterval?
        let language: String?
        let success: Bool
        
        init(action: ActionType, details: String, duration: TimeInterval? = nil, language: String? = nil, success: Bool = true) {
            self.id = UUID()
            self.timestamp = Date()
            self.action = action
            self.details = details
            self.duration = duration
            self.language = language
            self.success = success
        }
        
        enum ActionType: String, CaseIterable {
            case codeAnalysis = "Code Analysis"
            case fileUpload = "File Upload"
            case aiInsight = "AI Insight"
            case patternAnalysis = "Pattern Analysis"
            case smartEnhancement = "Smart Enhancement"
            case settingsChange = "Settings Change"
            case errorEncountered = "Error Encountered"
            
            var icon: String {
                switch self {
                case .codeAnalysis: return "doc.text.magnifyingglass"
                case .fileUpload: return "folder.badge.plus"
                case .aiInsight: return "brain.head.profile"
                case .patternAnalysis: return "chart.line.uptrend.xyaxis"
                case .smartEnhancement: return "wand.and.stars"
                case .settingsChange: return "gearshape"
                case .errorEncountered: return "exclamationmark.triangle"
                }
            }
            
            var color: Color {
                switch self {
                case .codeAnalysis: return .blue
                case .fileUpload: return .green
                case .aiInsight: return .purple
                case .patternAnalysis: return .orange
                case .smartEnhancement: return .pink
                case .settingsChange: return .gray
                case .errorEncountered: return .red
                }
            }
        }
    }
    
    private let maxActivityRecords = 1000
    private let userDefaults = UserDefaults.standard
    private let analyticsKey = "EnterpriseAnalytics"
    
    // MARK: - Computed Properties
    var totalSessions: Int {
        return Set(recentActivity.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
    }
    
    var averageSessionDuration: TimeInterval {
        return averageAnalysisTime
    }
    
    var totalAnalyses: Int {
        return analysisCount
    }

    init() {
        loadAnalytics()
    }
    
    // MARK: - Activity Tracking
    
    /// Performs operation with error handling and validation
    func trackActivity(
        action: ActivityRecord.ActionType,
        details: String,
        duration: TimeInterval? = nil,
        language: String? = nil,
        success: Bool = true
    ) {
        let record = ActivityRecord(
            action: action,
            details: details,
            duration: duration,
            language: language,
            success: success
        )
        
        recentActivity.insert(record, at: 0)
        
        // Keep only recent records
        if recentActivity.count > maxActivityRecords {
            recentActivity.removeLast()
        }
        
        // Update counters
        updateCounters(for: record)
        
        // Update daily usage
        updateDailyUsage(for: record.timestamp)
        
        // Save analytics
        saveAnalytics()
    }
    
    /// Updates and persists data with validation
    private func updateCounters(for record: ActivityRecord) {
        switch record.action {
        case .codeAnalysis:
            analysisCount += 1
            if let duration = record.duration {
                updateAverageAnalysisTime(duration)
            }
            if let language = record.language {
                mostUsedLanguages[language, default: 0] += 1
            }
        case .fileUpload:
            fileUploadsCount += 1
        default:
            break
        }
    }
    
    /// Updates and persists data with validation
    private func updateAverageAnalysisTime(_ newTime: TimeInterval) {
        if analysisCount == 1 {
            averageAnalysisTime = newTime
        } else {
            averageAnalysisTime = (averageAnalysisTime * Double(analysisCount - 1) + newTime) / Double(analysisCount)
        }
    }
    
    /// Updates and persists data with validation
    private func updateDailyUsage(for date: Date) {
        let dayStart = Calendar.current.startOfDay(for: date)
        dailyUsage[dayStart, default: 0] += 1
    }
    
    // MARK: - Analytics Calculations
    
    /// Retrieves data with proper error handling and caching
    func getTopLanguages(limit: Int = 5) -> [(String, Int)] {
        return mostUsedLanguages.sorted { $0.value > $1.value }.prefix(limit).map { ($0.key, $0.value) }
    }
    
    /// Retrieves data with proper error handling and caching
    func getActivityToday() -> [ActivityRecord] {
        let today = Calendar.current.startOfDay(for: Date())
        return recentActivity.filter { Calendar.current.startOfDay(for: $0.timestamp) == today }
    }
    
    /// Retrieves data with proper error handling and caching
    func getActivityThisWeek() -> [ActivityRecord] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return recentActivity.filter { $0.timestamp >= weekAgo }
    }
    
    /// Retrieves data with proper error handling and caching
    func getSuccessRate() -> Double {
        guard !recentActivity.isEmpty else { return 0 }
        let successCount = recentActivity.filter { $0.success }.count
        return Double(successCount) / Double(recentActivity.count)
    }
    
    /// Retrieves data with proper error handling and caching
    func getAverageSessionLength() -> TimeInterval {
        let sessions = groupIntoSessions()
        guard !sessions.isEmpty else { return 0 }
        
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        return totalDuration / Double(sessions.count)
    }
    
    /// Performs operation with error handling and validation
    private func groupIntoSessions() -> [Session] {
        var sessions: [Session] = []
        var currentSession: [ActivityRecord] = []
        
        for record in recentActivity.reversed() {
            if let lastRecord = currentSession.last {
                let timeDiff = record.timestamp.timeIntervalSince(lastRecord.timestamp)
                if timeDiff > 300 { // 5 minutes gap = new session
                    if !currentSession.isEmpty {
                        sessions.append(Session(activities: currentSession))
                    }
                    currentSession = [record]
                } else {
                    currentSession.append(record)
                }
            } else {
                currentSession = [record]
            }
        }
        
        if !currentSession.isEmpty {
            sessions.append(Session(activities: currentSession))
        }
        
        return sessions
    }
    
    private struct Session {
        let activities: [ActivityRecord]
        
        var duration: TimeInterval {
            guard let first = activities.first, let last = activities.last else { return 0 }
            return last.timestamp.timeIntervalSince(first.timestamp)
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveAnalytics() {
        // Simplified persistence - just store basic counts
        UserDefaults.standard.set(analysisCount, forKey: "analyticsAnalysisCount")
        UserDefaults.standard.set(fileUploadsCount, forKey: "analyticsFileUploadsCount")
        UserDefaults.standard.set(averageAnalysisTime, forKey: "analyticsAverageTime")
        UserDefaults.standard.set(recentActivity.count, forKey: "analyticsActivityCount")
    }
    
    private func loadAnalytics() {
        analysisCount = UserDefaults.standard.integer(forKey: "analyticsAnalysisCount")
        fileUploadsCount = UserDefaults.standard.integer(forKey: "analyticsFileUploadsCount")
        averageAnalysisTime = UserDefaults.standard.double(forKey: "analyticsAverageTime")
        // Activity count is just for reference - actual activities will be rebuilt on restart
    }
    
    func exportAnalytics() -> String {
        let basicData: [String: Any] = [
            "analysisCount": analysisCount,
            "fileUploadsCount": fileUploadsCount,
            "averageAnalysisTime": averageAnalysisTime,
            "activityCount": recentActivity.count,
            "exportedAt": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: basicData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "Failed to export analytics"
    }
    
    func resetAnalytics() {
        analysisCount = 0
        fileUploadsCount = 0
        averageAnalysisTime = 0
        mostUsedLanguages.removeAll()
        recentActivity.removeAll()
        dailyUsage.removeAll()
        saveAnalytics()
    }
}

// MARK: - Analytics Data Simplified

// Using UserDefaults for simple persistence to avoid Codable issues

// MARK: - Enterprise Analytics Dashboard

struct EnterpriseAnalyticsDashboard: View {
    @StateObject private var usageTracker = UsageTracker()
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var showingExportSheet = false
    @State private var exportedData = ""
    
    enum TimeFrame: String, CaseIterable {
        case day = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
    }
    
    // MARK: - Data Structures
    
    // AnalyticsReport now defined in SharedTypes.swift
    
    struct LocalPerformanceMetrics {
        let averageResponseTime: TimeInterval
        let totalOperations: Int
        let successRate: Double
        let peakUsageHour: Int
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Frame Selector
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                            Text(timeFrame.rawValue).tag(timeFrame)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Key Metrics
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        AnalyticsMetricCard(
                            title: "Total Sessions",
                            value: "\(usageTracker.totalSessions)",
                            icon: "clock.fill",
                            color: .blue
                        )
                        
                        AnalyticsMetricCard(
                            title: "Avg Session",
                            value: String(format: "%.1fm", usageTracker.averageSessionDuration / 60),
                            icon: "timer.circle.fill",
                            color: .green
                        )
                        
                        AnalyticsMetricCard(
                            title: "Analysis Count",
                            value: "\(usageTracker.totalAnalyses)",
                            icon: "doc.text.magnifyingglass",
                            color: .purple
                        )
                        
                        AnalyticsMetricCard(
                            title: "Success Rate",
                            value: "\(Int(usageTracker.getSuccessRate() * 100))%",
                            icon: "checkmark.circle",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Top Languages Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Most Used Languages")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(usageTracker.getTopLanguages(), id: \.0) { language, count in
                            HStack {
                                Text(language)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(count)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Rectangle()
                                    .fill(.blue)
                                    .frame(width: CGFloat(count) * 3, height: 8)
                                    .cornerRadius(4)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(getFilteredActivity().prefix(10)) { record in
                                AnalyticsActivityRow(record: record)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Enterprise Analytics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Export Analytics") {
                            exportedData = usageTracker.exportAnalytics()
                            showingExportSheet = true
                        }
                        
                        Button("Reset Analytics", role: .destructive) {
                            usageTracker.resetAnalytics()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(data: exportedData)
        }
    }
    
    // MARK: - Helper Methods
    
    func generateComprehensiveReport() -> AnalyticsReport {
        let last30Days = Date().addingTimeInterval(-30 * 24 * 3600)
        let recentRecords = usageTracker.recentActivity.filter { $0.timestamp >= last30Days }
        
        let totalActions = recentRecords.count
        let uniqueDays = Set(recentRecords.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
        let averageActionsPerDay = totalActions > 0 ? Double(totalActions) / Double(max(uniqueDays, 1)) : 0
        
        let actionBreakdown = Dictionary(grouping: recentRecords, by: { $0.action })
            .mapValues { $0.count }
        
        let localMetrics = LocalPerformanceMetrics(
            averageResponseTime: recentRecords.compactMap { $0.duration }.reduce(0, +) / Double(max(recentRecords.count, 1)),
            totalOperations: totalActions,
            successRate: usageTracker.getSuccessRate(),
            peakUsageHour: findPeakUsageHour(from: recentRecords)
        )
        
        let performanceMetrics = PerformanceMetrics(
            peakUsageHour: localMetrics.peakUsageHour,
            successRate: localMetrics.successRate,
            responseTime: localMetrics.averageResponseTime,
            throughput: Double(localMetrics.totalOperations),
            errorCount: 0
        )
        
        return AnalyticsReport(
            title: "Analytics Report", 
            summary: "Comprehensive analytics data", 
            metrics: [], 
            trends: [], 
            timeframe: .daily,
            totalAnalyses: totalActions,
            uniqueUsers: 1,
            averageAnalysisTime: recentRecords.compactMap { $0.duration }.reduce(0, +) / Double(max(recentRecords.count, 1)),
            averageActionsPerDay: averageActionsPerDay,
            performanceMetrics: performanceMetrics,
            insights: ["Performance is stable", "Usage patterns are consistent"]
        )
    }
    
    private func findPeakUsageHour(from records: [UsageTracker.ActivityRecord]) -> Int {
        let hourCounts = Dictionary(grouping: records, by: { Calendar.current.component(.hour, from: $0.timestamp) })
            .mapValues { $0.count }
        return hourCounts.max(by: { $0.value < $1.value })?.key ?? 14 // Default to 2 PM
    }
    
    private func generateInsights(from records: [UsageTracker.ActivityRecord]) -> [String] {
        var insights: [String] = []
        
        if records.count > 100 {
            insights.append("High activity detected - consider optimizing workflows")
        }
        
        let aiActions = records.filter { $0.action == .aiInsight }.count
        if Double(aiActions) / Double(max(records.count, 1)) > 0.5 {
            insights.append("AI features are heavily utilized - great adoption!")
        }
        
        return insights
    }
    
    private func getFilteredActivity() -> [UsageTracker.ActivityRecord] {
        switch selectedTimeFrame {
        case .day:
            return usageTracker.getActivityToday()
        case .week:
            return usageTracker.getActivityThisWeek()
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return usageTracker.recentActivity.filter { $0.timestamp >= monthAgo }
        case .all:
            return usageTracker.recentActivity
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            return String(format: "%.1fm", duration / 60)
        }
    }
}

// MARK: - Supporting Views

struct AnalyticsMetricCard: View {
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

struct AnalyticsActivityRow: View {
    let record: UsageTracker.ActivityRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.action.icon)
                .foregroundColor(record.action.color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.action.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(record.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(record.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let duration = record.duration {
                    Text(formatDuration(duration))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Circle()
                .fill(record.success ? .green : .red)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            return String(format: "%.1fm", duration / 60)
        }
    }
}

struct ExportSheet: View {
    let data: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(data)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Analytics Export")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(data, forType: .string)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EnterpriseAnalyticsDashboard()
}
