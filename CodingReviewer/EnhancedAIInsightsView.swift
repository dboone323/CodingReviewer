//
// EnhancedAIInsightsView.swift
// CodingReviewer
//
// Enhanced AI View with ML Integration
// Created on July 29, 2025
//

import SwiftUI
import Foundation

// MARK: - Enhanced AI Insights View

struct EnhancedAIInsightsView: View {
    @StateObject private var mlService = MLIntegrationService()
    @EnvironmentObject private var fileManager: FileManagerService
    @State private var selectedTab: AIMLTab = .insights
    @State private var showingFullAnalysis = false

    enum AIMLTab: String, CaseIterable {
        case insights = "ML Insights"
        case predictions = "Predictions"
        case learning = "Learning"
        case realtime = "Real-time"

        var systemImage: String {
            switch self {
            case .insights: return "brain.head.profile"
            case .predictions: return "crystal.ball"
            case .learning: return "graduationcap"
            case .realtime: return "waveform.path.ecg"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Header
            AIMLHeaderView(
                mlService: mlService,
                fileManager: fileManager,
                onRunAnalysis: {
                    Task {
                        await mlService.analyzeProjectWithML(fileData: fileManager.uploadedFiles)
                    }
                },
                onShowFullAnalysis: { showingFullAnalysis = true }
            )

            Divider()

            // Tab Selection
            Picker("AI/ML View", selection: $selectedTab) {
                ForEach(AIMLTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)

            // Content
            TabView(selection: $selectedTab) {
                MLInsightsView(mlService: mlService, fileManager: fileManager)
                    .tag(AIMLTab.insights)

                PredictiveAnalysisView(mlService: mlService)
                    .tag(AIMLTab.predictions)

                CrossProjectLearningView(mlService: mlService)
                    .tag(AIMLTab.learning)

                RealtimeMLView(mlService: mlService)
                    .tag(AIMLTab.realtime)
            }
        }
        .sheet(isPresented: $showingFullAnalysis) {
            FullMLAnalysisView(mlService: mlService)
        }
        .task {
            // Load existing data when view appears
            await mlService.refreshMLData()
        }
    }
}

// MARK: - AI/ML Header View

struct AIMLHeaderView: View {
    @ObservedObject var mlService: MLIntegrationService
    @ObservedObject var fileManager: FileManagerService
    let onRunAnalysis: () -> Void
    let onShowFullAnalysis: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("AI/ML Intelligence Center")
                        .font(.title2)
                        .fontWeight(.semibold)

                    if mlService.isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                HStack(spacing: 16) {
                    if let lastUpdate = mlService.lastUpdate {
                        Text("Last update: \(formatRelativeTime(lastUpdate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No ML analysis yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // File count indicator
                    StatusIndicator(
                        title: "Files",
                        count: fileManager.uploadedFiles.count,
                        color: .orange
                    )

                    // Status indicators
                    StatusIndicator(
                        title: "ML Insights",
                        count: mlService.mlInsights.count,
                        color: .blue
                    )

                    if mlService.predictiveData != nil {
                        StatusIndicator(
                            title: "Predictions",
                            count: 1,
                            color: .purple
                        )
                    }

                    StatusIndicator(
                        title: "Learnings",
                        count: mlService.crossProjectLearnings.count,
                        color: .green
                    )
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Run Full Analysis") {
                    onRunAnalysis()
                }
                .buttonStyle(.borderedProminent)
                .disabled(mlService.isAnalyzing)

                Button("Detailed View") {
                    onShowFullAnalysis()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct StatusIndicator: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(count) \(title)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - ML Insights View

struct MLInsightsView: View {
    @ObservedObject var mlService: MLIntegrationService
    @ObservedObject var fileManager: FileManagerService

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Show uploaded files when available
                if !fileManager.uploadedFiles.isEmpty {
                    UploadedFilesDisplayView(files: fileManager.uploadedFiles)
                }

                if mlService.mlInsights.isEmpty {
                    EmptyMLStateView(
                        icon: "brain.head.profile",
                        title: "No ML Insights Yet",
                        description: "Run ML analysis to see intelligent insights about your code patterns and automation.",
                        action: {
                            Task {
                                await mlService.analyzeProjectWithML()
                            }
                        }
                    )
                } else {
                    ForEach(mlService.mlInsights) { insight in
                        MLInsightCard(insight: insight)
                    }
                }
            }
            .padding()
        }
    }
}

struct MLInsightCard: View {
    let insight: MLInsight
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: insight.type.icon)
                        .foregroundColor(insight.type.color)

                    Text(insight.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Confidence badge
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(insight.type.color.opacity(0.2))
                    .cornerRadius(8)

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }

            // Description
            Text(insight.description)
                .font(.body)
                .foregroundColor(.secondary)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()

                    // Recommendation
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommendation")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(insight.recommendation)
                            .font(.body)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // Impact
                    HStack {
                        Text("Impact:")
                            .font(.caption)
                            .fontWeight(.medium)

                        Text(insight.impact.description)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Predictive Analysis View

struct PredictiveAnalysisView: View {
    @ObservedObject var mlService: MLIntegrationService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let prediction = mlService.predictiveData {
                    // Project Completion
                    PredictionCard(
                        title: "Project Completion",
                        icon: "calendar.badge.checkmark",
                        color: .green
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Estimated Completion:")
                                    .font(.subheadline)
                                Spacer()
                                Text(formatDate(prediction.projectCompletion.estimatedDate))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }

                            HStack {
                                Text("Confidence:")
                                Spacer()
                                Text("\(Int(prediction.projectCompletion.confidence * 100))%")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }

                            Text("Remaining: \(prediction.projectCompletion.remainingWork)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Risk Assessment
                    PredictionCard(
                        title: "Risk Assessment",
                        icon: "exclamationmark.triangle",
                        color: .orange
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Overall Risk:")
                                Spacer()
                                Text("\(Int(prediction.riskAssessment.overallRisk * 100))%")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Critical Risks:")
                                    .font(.caption)
                                    .fontWeight(.medium)

                                ForEach(prediction.riskAssessment.criticalRisks, id: \.self) { risk in
                                    Text("• \(risk)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text("Mitigation: \(prediction.riskAssessment.mitigation)")
                                .font(.caption)
                                .padding(8)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }

                    // Performance Forecasting
                    PredictionCard(
                        title: "Performance Forecasting",
                        icon: "speedometer",
                        color: .blue
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Build Time Increase:")
                                Spacer()
                                Text("+\(Int(prediction.performanceForecasting.buildTimeIncrease))%")
                                    .fontWeight(.semibold)
                            }

                            HStack {
                                Text("Memory Usage Growth:")
                                Spacer()
                                Text("+\(Int(prediction.performanceForecasting.memoryUsageGrowth))%")
                                    .fontWeight(.semibold)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recommendations:")
                                    .font(.caption)
                                    .fontWeight(.medium)

                                ForEach(prediction.performanceForecasting.recommendations, id: \.self) { rec in
                                    Text("• \(rec)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                } else {
                    EmptyMLStateView(
                        icon: "crystal.ball",
                        title: "No Predictions Available",
                        description: "Run predictive analytics to see project forecasting and risk assessment.",
                        action: {
                            Task {
                                await mlService.analyzeProjectWithML()
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct PredictionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content

    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            content
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Cross-Project Learning View

struct CrossProjectLearningView: View {
    @ObservedObject var mlService: MLIntegrationService

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if mlService.crossProjectLearnings.isEmpty {
                    EmptyMLStateView(
                        icon: "graduationcap",
                        title: "No Cross-Project Learnings",
                        description: "Run cross-project analysis to discover transferable patterns and insights.",
                        action: {
                            Task {
                                await mlService.analyzeProjectWithML()
                            }
                        }
                    )
                } else {
                    ForEach(mlService.crossProjectLearnings) { learning in
                        CrossProjectLearningCard(learning: learning)
                    }
                }
            }
            .padding()
        }
    }
}

struct CrossProjectLearningCard: View {
    let learning: CrossProjectLearning
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(learning.pattern)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(learning.transferability * 100))% transferable")
                        .font(.caption)
                        .foregroundColor(.green)

                    Text("\(Int(learning.successRate * 100))% success rate")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }

            Text(learning.description)
                .font(.body)
                .foregroundColor(.secondary)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    // Implementations
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Key Implementations:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        ForEach(learning.implementations, id: \.self) { impl in
                            Text("• \(impl)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Benefits
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Benefits:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(learning.benefits)
                            .font(.body)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Real-time ML View

struct RealtimeMLView: View {
    @ObservedObject var mlService: MLIntegrationService
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 20) {
            // Real-time status
            VStack(spacing: 12) {
                Text("Real-time ML Monitoring")
                    .font(.title2)
                    .fontWeight(.semibold)

                if mlService.isAnalyzing {
                    VStack(spacing: 8) {
                        ProgressView(value: mlService.analysisProgress)
                            .frame(maxWidth: 300)

                        Text("Running ML analysis: \(Int(mlService.analysisProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 16) {
                        StatusDot(color: .green, label: "ML Systems Online")
                        StatusDot(color: .blue, label: "Data Pipeline Active")
                        StatusDot(color: .orange, label: "Learning Mode")
                    }
                }
            }

            Spacer()

            // Quick stats
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                QuickStatCard(
                    title: "ML Insights",
                    value: "\(mlService.mlInsights.count)",
                    icon: "brain.head.profile",
                    color: .blue
                )

                QuickStatCard(
                    title: "Predictions",
                    value: mlService.predictiveData != nil ? "1" : "0",
                    icon: "crystal.ball",
                    color: .purple
                )

                QuickStatCard(
                    title: "Learnings",
                    value: "\(mlService.crossProjectLearnings.count)",
                    icon: "graduationcap",
                    color: .green
                )

                QuickStatCard(
                    title: "Confidence",
                    value: mlService.mlInsights.isEmpty ? "N/A" : "\(Int(mlService.mlInsights.map(\.confidence).reduce(0, +) / Double(mlService.mlInsights.count) * 100))%",
                    icon: "checkmark.seal",
                    color: .orange
                )
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct StatusDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Empty State View

struct EmptyMLStateView: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Run ML Analysis") {
                action()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Full ML Analysis View

struct FullMLAnalysisView: View {
    @ObservedObject var mlService: MLIntegrationService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Combined analysis view with all ML systems
                    Text("This would be a comprehensive view combining all ML analysis results...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationTitle("Complete ML Analysis")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - Uploaded Files Display View

struct UploadedFilesDisplayView: View {
    let files: [CodeFile]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)

                Text("Uploaded Files")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(files.count) files")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }

            // Language breakdown
            let languageGroups = Dictionary(grouping: files, by: { $0.language })
            let sortedLanguages = Array(Set(files.map { $0.language })).sorted(by: { $0.displayName < $1.displayName })

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(sortedLanguages, id: \.self) { language in
                    let count = languageGroups[language]?.count ?? 0

                    HStack(spacing: 6) {
                        Image(systemName: language.iconName)
                            .foregroundColor(.blue)
                            .font(.caption)

                        Text("\(language.displayName): \(count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
            }

            // Recent files preview
            if !files.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent Files")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(Array(files.prefix(5)), id: \.id) { file in
                        HStack(spacing: 8) {
                            Image(systemName: file.language.iconName)
                                .foregroundColor(.blue)
                                .font(.caption)

                            Text(file.name)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()

                            Text(file.language.displayName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(4)
                    }

                    if files.count > 5 {
                        Text("... and \(files.count - 5) more files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}
