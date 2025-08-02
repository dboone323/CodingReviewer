//
//  QuantumEnhancementView.swift
//  CodingReviewer - Quantum AI Enhancement Interface
//
//  Created by Quantum AI Assistant on August 1, 2025
//

import SwiftUI
import Combine

struct QuantumEnhancementView: View {
    @StateObject private var quantumAI = QuantumAIEnhancer()
    @EnvironmentObject private var fileManager: FileManagerService
    @State private var selectedEnhancement: AIEnhancement?
    @State private var selectedTab: EnhancementTab = .overview
    @State private var showingAutoFixDialog = false
    @State private var autoFixTarget: AIEnhancement?
    
    enum EnhancementTab: String, CaseIterable {
        case overview = "Overview"
        case security = "Security"
        case performance = "Performance"
        case quality = "Quality"
        case testing = "Testing"
        case insights = "AI Insights"
        
        var icon: String {
            switch self {
            case .overview: return "brain.head.profile"
            case .security: return "shield.checkerboard"
            case .performance: return "speedometer"
            case .quality: return "star.circle"
            case .testing: return "testtube.2"
            case .insights: return "lightbulb.max"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with tabs
            sidebarView
        } detail: {
            // Main content area
            mainContentView
        }
        .navigationTitle("🚀 Quantum AI Enhancement")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                enhanceButton
            }
        }
        .alert("Auto-Fix Available", isPresented: $showingAutoFixDialog) {
            Button("Apply Fix") {
                applyAutomatedFix()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let fix = autoFixTarget {
                Text("Apply automated fix for: \\(fix.title)?")
            }
        }
    }
    
    // MARK: - Sidebar View
    
    private var sidebarView: some View {
        List(selection: $selectedTab) {
            Section("Quantum Analysis") {
                ForEach(EnhancementTab.allCases, id: \\.self) { tab in
                    NavigationLink(value: tab) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tab.rawValue)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Text(tabDescription(for: tab))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: tab.icon)
                                .foregroundColor(.blue)
                        }
                    }
                    .badge(badgeCount(for: tab))
                }
            }
            
            Section("Enhancement Summary") {
                enhancementSummaryView
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 250)
    }
    
    private var enhancementSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            SummaryStatCard(
                title: "Issues Found",
                value: "\\(quantumAI.enhancementResults.count)",
                icon: "exclamationmark.triangle",
                color: .orange
            )
            
            SummaryStatCard(
                title: "Auto-Fixable",
                value: "\\(quantumAI.enhancementResults.filter { $0.automatedFix != nil }.count)",
                icon: "wrench.and.screwdriver",
                color: .green
            )
            
            SummaryStatCard(
                title: "Tests Run",
                value: "\\(quantumAI.automatedTestResults.count)",
                icon: "checkmark.circle",
                color: .blue
            )
            
            SummaryStatCard(
                title: "AI Insights",
                value: "\\(quantumAI.quantumInsights.count)",
                icon: "brain",
                color: .purple
            )
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Progress bar (when analyzing)
            if quantumAI.isAnalyzing {
                quantumProgressView
                Divider()
            }
            
            // Tab content
            Group {
                switch selectedTab {
                case .overview:
                    overviewContent
                case .security:
                    enhancementListView(type: .security)
                case .performance:
                    enhancementListView(type: .performance)
                case .quality:
                    enhancementListView(type: .codeQuality)
                case .testing:
                    testingResultsView
                case .insights:
                    quantumInsightsView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Overview Content
    
    private var overviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Quantum AI Enhancement")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Advanced code analysis powered by quantum AI algorithms")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
                
                // Quick stats
                quickStatsView
                
                // Recent enhancements
                if !quantumAI.enhancementResults.isEmpty {
                    recentEnhancementsView
                }
                
                // AI insights preview
                if !quantumAI.quantumInsights.isEmpty {
                    insightsPreviewView
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var quickStatsView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            QuickStatCard(
                title: "Critical Issues",
                value: quantumAI.enhancementResults.filter { $0.severity == .critical }.count,
                icon: "exclamationmark.octagon.fill",
                color: .red
            )
            
            QuickStatCard(
                title: "Security Fixes",
                value: quantumAI.enhancementResults.filter { $0.type == .security }.count,
                icon: "shield.fill",
                color: .orange
            )
            
            QuickStatCard(
                title: "Performance Boosts",
                value: quantumAI.enhancementResults.filter { $0.type == .performance }.count,
                icon: "speedometer",
                color: .green
            )
            
            QuickStatCard(
                title: "Code Quality",
                value: quantumAI.enhancementResults.filter { $0.type == .codeQuality }.count,
                icon: "star.fill",
                color: .blue
            )
        }
    }
    
    private var recentEnhancementsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Enhancements")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array(quantumAI.enhancementResults.prefix(5))) { enhancement in
                EnhancementRowView(enhancement: enhancement) {
                    selectedEnhancement = enhancement
                    if enhancement.automatedFix != nil {
                        autoFixTarget = enhancement
                        showingAutoFixDialog = true
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var insightsPreviewView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array(quantumAI.quantumInsights.prefix(3))) { insight in
                InsightPreviewCard(insight: insight)
            }
            
            NavigationLink("View All Insights") {
                // Navigate to insights view
            }
            .font(.footnote)
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    // MARK: - Enhancement List View
    
    private func enhancementListView(type: EnhancementType) -> some View {
        let filteredEnhancements = quantumAI.enhancementResults.filter { $0.type == type }
        
        return Group {
            if filteredEnhancements.isEmpty {
                emptyStateView(for: type)
            } else {
                List {
                    ForEach(filteredEnhancements) { enhancement in
                        EnhancementDetailCard(enhancement: enhancement) {
                            if enhancement.automatedFix != nil {
                                autoFixTarget = enhancement
                                showingAutoFixDialog = true
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private func emptyStateView(for type: EnhancementType) -> some View {
        VStack(spacing: 20) {
            Image(systemName: type == .security ? "shield.checkered" : 
                              type == .performance ? "speedometer" : "star.circle")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No \\(type.rawValue) Issues Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your code looks great for \\(type.rawValue.lowercased()) standards!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Testing Results View
    
    private var testingResultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if quantumAI.automatedTestResults.isEmpty {
                emptyTestingStateView
            } else {
                testResultsListView
            }
        }
        .padding()
    }
    
    private var emptyTestingStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "testtube.2")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Test Results Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Run Quantum AI enhancement to generate comprehensive test results")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var testResultsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(quantumAI.automatedTestResults) { result in
                    TestResultCard(result: result)
                }
            }
        }
    }
    
    // MARK: - Quantum Insights View
    
    private var quantumInsightsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if quantumAI.quantumInsights.isEmpty {
                emptyInsightsStateView
            } else {
                insightsListView
            }
        }
        .padding()
    }
    
    private var emptyInsightsStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.max")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No AI Insights Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Upload files and run Quantum AI analysis to discover deep insights")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var insightsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(quantumAI.quantumInsights) { insight in
                    QuantumInsightCard(insight: insight)
                }
            }
        }
    }
    
    // MARK: - Progress View
    
    private var quantumProgressView: some View {
        VStack(spacing: 12) {
            HStack {
                ProgressView(value: quantumAI.progressValue, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                
                Text("\\(Int(quantumAI.progressValue * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: 40)
            }
            
            HStack {
                Text(quantumAI.currentTask)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if quantumAI.isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: - Enhance Button
    
    private var enhanceButton: some View {
        Button(action: {
            Task {
                await quantumAI.enhanceApplication(uploadedFiles: convertToUploadedFiles())
            }
        }) {
            HStack {
                if quantumAI.isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing...")
                } else {
                    Image(systemName: "brain.filled.head.profile")
                    Text("Enhance with AI")
                }
            }
        }
        .disabled(quantumAI.isAnalyzing || fileManager.uploadedFiles.isEmpty)
        .buttonStyle(.borderedProminent)
    }
    
    // MARK: - Helper Functions
    
    private func tabDescription(for tab: EnhancementTab) -> String {
        switch tab {
        case .overview: return "Complete analysis overview"
        case .security: return "Security vulnerabilities"
        case .performance: return "Performance optimizations"
        case .quality: return "Code quality improvements"
        case .testing: return "Automated test results"
        case .insights: return "AI-powered insights"
        }
    }
    
    private func badgeCount(for tab: EnhancementTab) -> Int {
        switch tab {
        case .overview: return 0
        case .security: return quantumAI.enhancementResults.filter { $0.type == .security }.count
        case .performance: return quantumAI.enhancementResults.filter { $0.type == .performance }.count
        case .quality: return quantumAI.enhancementResults.filter { $0.type == .codeQuality }.count
        case .testing: return quantumAI.automatedTestResults.count
        case .insights: return quantumAI.quantumInsights.count
        }
    }
    
    private func applyAutomatedFix() {
        guard let fix = autoFixTarget, let automatedFix = fix.automatedFix else { return }
        
        // Apply the automated fix
        // This would integrate with the file system to apply changes
        print("Applying automated fix for \\(fix.title): \\(automatedFix)")
        
        // Remove the fixed enhancement from results
        quantumAI.enhancementResults.removeAll { $0.id == fix.id }
        
        autoFixTarget = nil
    }
    
    private func convertToUploadedFiles() -> [UploadedFile] {
        return fileManager.uploadedFiles.map { file in
            UploadedFile(
                id: file.id,
                name: file.name,
                path: file.path,
                content: file.content,
                size: file.size,
                type: file.language.displayName,
                uploadDate: file.lastModified
            )
        }
    }
}

// MARK: - Supporting Views

struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct QuickStatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
                
                Text("\\(value)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct EnhancementRowView: View {
    let enhancement: AIEnhancement
    let onTap: () -> Void
    
    private var severityColor: Color {
        switch enhancement.severity {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Severity indicator
                Circle()
                    .fill(severityColor)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(enhancement.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(enhancement.fileName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if enhancement.automatedFix != nil {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Text(enhancement.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.gray.opacity(0.2)))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancementDetailCard: View {
    let enhancement: AIEnhancement
    let onAutoFix: () -> Void
    
    private var severityColor: Color {
        switch enhancement.severity {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(enhancement.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text(enhancement.fileName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Line \\(enhancement.lineNumber)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.gray.opacity(0.2)))
                    }
                }
                
                Spacer()
                
                // Severity badge
                Text(enhancement.severity.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(severityColor.opacity(0.2)))
                    .foregroundColor(severityColor)
            }
            
            // Description
            Text(enhancement.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            // Suggestion
            VStack(alignment: .leading, spacing: 4) {
                Text("Suggestion:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(enhancement.suggestion)
                    .font(.body)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Actions
            HStack {
                Text("Confidence: \\(Int(enhancement.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if enhancement.automatedFix != nil {
                    Button("Auto-Fix Available") {
                        onAutoFix()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(severityColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TestResultCard: View {
    let result: AutomatedTestResult
    
    private var statusColor: Color {
        switch result.status {
        case .passed: return .green
        case .failed: return .red
        case .warning: return .orange
        case .skipped: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: result.status == .passed ? "checkmark.circle.fill" : 
                                result.status == .failed ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(statusColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\\(result.testType.rawValue) Test")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(result.fileName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\\(String(format: "%.2f", result.duration))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(result.status.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                }
            }
            
            if !result.issuesFound.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Issues Found:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(result.issuesFound.enumerated()), id: \\.offset) { _, issue in
                        Text("• \\(issue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !result.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendations:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(result.recommendations.enumerated()), id: \\.offset) { _, recommendation in
                        Text("• \\(recommendation)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct QuantumInsightCard: View {
    let insight: QuantumInsight
    
    private var impactColor: Color {
        switch insight.potentialImpact {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(insight.type.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.purple.opacity(0.2)))
                        .foregroundColor(.purple)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Impact: \\(insight.potentialImpact.rawValue)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(impactColor)
                    
                    Text("\\(Int(insight.confidence * 100))% confident")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            if !insight.affectedFiles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Affected Files:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(insight.affectedFiles, id: \\.self) { file in
                        Text("• \\(file)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Recommendation:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(insight.recommendation)
                    .font(.body)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}

struct InsightPreviewCard: View {
    let insight: QuantumInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.max")
                .foregroundColor(.yellow)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(insight.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(insight.potentialImpact.rawValue)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.yellow.opacity(0.2)))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    QuantumEnhancementView()
        .environmentObject(FileManagerService())
}
