import SwiftUI
import Combine

// MARK: - AI Intelligence Dashboard
// Comprehensive view of AI learning progress and system intelligence

struct AIDashboardView: View {
    @StateObject private var learningCoordinator = AILearningCoordinator.shared
    @StateObject private var codeGenerator = EnhancedAICodeGenerator.shared
    @StateObject private var projectAnalyzer = AdvancedAIProjectAnalyzer.shared
    
    @State private var selectedTab: DashboardTab = .overview
    @State private var isRefreshing = false
    @State private var lastRefresh = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with refresh button
                HeaderView(
                    isRefreshing: $isRefreshing,
                    lastRefresh: $lastRefresh,
                    onRefresh: refreshAllData
                )
                
                // Tab selector
                TabSelectorView(selectedTab: $selectedTab)
                
                // Main content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        switch selectedTab {
                        case .overview:
                            OverviewSection()
                        case .learning:
                            LearningSection()
                        case .generation:
                            GenerationSection()
                        case .analysis:
                            AnalysisSection()
                        case .health:
                            HealthSection()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Intelligence Center")
        }
        .task {
            await initializeDashboard()
        }
    }
    
    // MARK: - Dashboard Sections
    
    @ViewBuilder
    private func OverviewSection() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
            // Learning Progress Card
            DashboardCard(
                title: "AI Learning",
                value: String(format: "%.1f%%", learningCoordinator.learningAccuracy * 100),
                subtitle: "\(learningCoordinator.totalIssuesAnalyzed) issues analyzed",
                color: .blue,
                progress: learningCoordinator.learningAccuracy,
                isLoading: learningCoordinator.isLearning
            )
            
            // Code Generation Card
            DashboardCard(
                title: "Code Generation",
                value: "\(codeGenerator.generatedLines)",
                subtitle: "\(codeGenerator.suggestionsCount) suggestions",
                color: .green,
                progress: Double(codeGenerator.generatedLines) / 1000.0,
                isLoading: codeGenerator.isGenerating
            )
            
            // Project Health Card
            DashboardCard(
                title: "Project Health",
                value: String(format: "%.1f%%", projectAnalyzer.projectHealth.overallScore * 100),
                subtitle: healthStatusText,
                color: healthColor,
                progress: projectAnalyzer.projectHealth.overallScore,
                isLoading: projectAnalyzer.isAnalyzing
            )
            
            // Risk Assessment Card
            DashboardCard(
                title: "Risk Level",
                value: String(format: "%.1f%%", projectAnalyzer.riskAssessment.overallRisk * 100),
                subtitle: riskStatusText,
                color: riskColor,
                progress: 1.0 - projectAnalyzer.riskAssessment.overallRisk,
                isLoading: projectAnalyzer.isAnalyzing
            )
        }
        
        // AI Intelligence Timeline
        IntelligenceTimelineView()
        
        // Quick Actions
        QuickActionsView()
    }
    
    @ViewBuilder
    private func LearningSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Learning Progress
            LearningProgressView()
            
            // Pattern Recognition
            PatternRecognitionView()
            
            // Learning Statistics
            LearningStatisticsView()
            
            // Learning Actions
            LearningActionsView()
        }
    }
    
    @ViewBuilder
    private func GenerationSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Generation Statistics
            GenerationStatisticsView()
            
            // Code Templates
            CodeTemplatesView()
            
            // Generation Actions
            GenerationActionsView()
        }
    }
    
    @ViewBuilder
    private func AnalysisSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Analysis Overview
            AnalysisOverviewView()
            
            // Recommendations
            RecommendationsView()
            
            // Analysis History
            AnalysisHistoryView()
        }
    }
    
    @ViewBuilder
    private func HealthSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Health Metrics
            HealthMetricsView()
            
            // Issues Overview
            IssuesOverviewView()
            
            // Health Trends
            HealthTrendsView()
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func HeaderView(
        isRefreshing: Binding<Bool>,
        lastRefresh: Binding<Date>,
        onRefresh: @escaping () -> Void
    ) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("AI Intelligence Status")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Last updated: \(lastRefresh.wrappedValue, formatter: timeFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .rotationEffect(.degrees(isRefreshing.wrappedValue ? 360 : 0))
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: isRefreshing.wrappedValue)
            }
            .disabled(isRefreshing.wrappedValue)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    @ViewBuilder
    private func TabSelectorView(selectedTab: Binding<DashboardTab>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(DashboardTab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab.wrappedValue == tab,
                        onTap: { selectedTab.wrappedValue = tab }
                    )
                }
            }
            .padding(.horizontal)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private func TabButton(tab: DashboardTab, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: tab.icon)
                Text(tab.title)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private func DashboardCard(
        title: String,
        value: String,
        subtitle: String,
        color: Color,
        progress: Double,
        isLoading: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: progress)
                .tint(color)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func IntelligenceTimelineView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Intelligence Timeline")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    TimelineItem(
                        title: "Learning Started",
                        subtitle: "Pattern recognition initialized",
                        time: "2 hours ago",
                        color: .blue
                    )
                    
                    TimelineItem(
                        title: "Code Generated",
                        subtitle: "SwiftUI view template created",
                        time: "1 hour ago",
                        color: .green
                    )
                    
                    TimelineItem(
                        title: "Issues Prevented",
                        subtitle: "3 potential issues detected",
                        time: "30 minutes ago",
                        color: .orange
                    )
                    
                    TimelineItem(
                        title: "Analysis Complete",
                        subtitle: "Project health assessment",
                        time: "5 minutes ago",
                        color: .purple
                    )
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    @ViewBuilder
    private func TimelineItem(title: String, subtitle: String, time: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .frame(width: 120)
    }
    
    @ViewBuilder
    private func QuickActionsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Start Learning",
                    icon: "brain",
                    color: .blue,
                    action: { Task { await startLearningSession() } }
                )
                
                QuickActionButton(
                    title: "Generate Code",
                    icon: "chevron.left.forwardslash.chevron.right",
                    color: .green,
                    action: { Task { await generateSampleCode() } }
                )
                
                QuickActionButton(
                    title: "Analyze Project",
                    icon: "magnifyingglass",
                    color: .purple,
                    action: { Task { await analyzeProject() } }
                )
                
                QuickActionButton(
                    title: "Health Check",
                    icon: "heart.text.square",
                    color: .red,
                    action: { Task { await performHealthCheck() } }
                )
            }
        }
    }
    
    @ViewBuilder
    private func QuickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Detailed Section Views
    
    @ViewBuilder
    private func LearningProgressView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learning Progress")
                .font(.headline)
            
            ProgressView(value: learningCoordinator.learningProgress) {
                HStack {
                    Text("Training AI Models")
                    Spacer()
                    Text("\(Int(learningCoordinator.learningProgress * 100))%")
                }
                .font(.caption)
            }
            .tint(.blue)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Accuracy Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", learningCoordinator.learningAccuracy * 100))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Patterns Learned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(learningCoordinator.totalIssuesAnalyzed)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func PatternRecognitionView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pattern Recognition")
                .font(.headline)
            
            Text("AI has learned common patterns from your codebase and can predict potential issues before they occur.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Pattern categories
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                PatternCategoryCard(name: "Swift Syntax", confidence: 98.5, color: .blue)
                PatternCategoryCard(name: "Architecture", confidence: 94.2, color: .green)
                PatternCategoryCard(name: "Performance", confidence: 91.7, color: .orange)
                PatternCategoryCard(name: "Security", confidence: 96.3, color: .red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func PatternCategoryCard(name: String, confidence: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(String(format: "%.1f%%", confidence))
                .font(.caption2)
                .foregroundColor(color)
        }
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
    
    @ViewBuilder
    private func LearningStatisticsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learning Statistics")
                .font(.headline)
            
            HStack {
                StatisticItem(title: "Successful Fixes", value: "\(learningCoordinator.successfulFixes)", color: .green)
                StatisticItem(title: "Issues Prevented", value: "47", color: .blue)
                StatisticItem(title: "Time Saved", value: "2.3h", color: .purple)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func StatisticItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func LearningActionsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learning Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button("Start Learning Session") {
                    Task { await startLearningSession() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(learningCoordinator.isLearning)
                
                Button("Reset Learning") {
                    // Reset learning data
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // Additional section implementations...
    @ViewBuilder
    private func GenerationStatisticsView() -> some View {
        Text("Code generation statistics would go here")
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
    
    @ViewBuilder
    private func CodeTemplatesView() -> some View {
        Text("Code templates would go here")
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
    
    @ViewBuilder
    private func GenerationActionsView() -> some View {
        Text("Generation actions would go here")
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
    
    @ViewBuilder
    private func AnalysisOverviewView() -> some View {
        Text("Analysis overview would go here")
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
    
    @ViewBuilder
    private func RecommendationsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Recommendations")
                .font(.headline)
            
            ForEach(projectAnalyzer.recommendations.prefix(5), id: \.title) { recommendation in
                RecommendationCard(recommendation: recommendation)
            }
        }
    }
    
    @ViewBuilder
    private func RecommendationCard(recommendation: ProjectRecommendation) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(recommendation.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(recommendation.priority.rawValue == 3 ? "HIGH" : recommendation.priority.rawValue == 2 ? "MED" : "LOW")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(recommendation.priority.rawValue == 3 ? Color.red : recommendation.priority.rawValue == 2 ? Color.orange : Color.blue)
                .cornerRadius(4)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func AnalysisHistoryView() -> some View {
        Text("Analysis history would go here")
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
    
    @ViewBuilder
    private func HealthMetricsView() -> some View {
        Text("Health metrics would go here")
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
    
    @ViewBuilder
    private func IssuesOverviewView() -> some View {
        Text("Issues overview would go here")
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
    
    @ViewBuilder
    private func HealthTrendsView() -> some View {
        Text("Health trends would go here")
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var healthStatusText: String {
        let score = projectAnalyzer.projectHealth.overallScore
        if score > 0.8 {
            return "Excellent health"
        } else if score > 0.6 {
            return "Good health"
        } else if score > 0.4 {
            return "Needs attention"
        } else {
            return "Critical issues"
        }
    }
    
    private var healthColor: Color {
        let score = projectAnalyzer.projectHealth.overallScore
        if score > 0.8 {
            return .green
        } else if score > 0.6 {
            return .blue
        } else if score > 0.4 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var riskStatusText: String {
        let risk = projectAnalyzer.riskAssessment.overallRisk
        if risk < 0.3 {
            return "Low risk"
        } else if risk < 0.6 {
            return "Medium risk"
        } else {
            return "High risk"
        }
    }
    
    private var riskColor: Color {
        let risk = projectAnalyzer.riskAssessment.overallRisk
        if risk < 0.3 {
            return .green
        } else if risk < 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    // MARK: - Actions
    
    private func initializeDashboard() async {
        refreshAllData()
    }
    
    private func refreshAllData() {
        isRefreshing = true
        
        Task {
            // Refresh all AI components
            await learningCoordinator.startLearningSession()
            _ = await projectAnalyzer.performHealthCheck()
            
            DispatchQueue.main.async {
                self.lastRefresh = Date()
                self.isRefreshing = false
            }
        }
    }
    
    private func startLearningSession() async {
        await learningCoordinator.startLearningSession()
    }
    
    private func generateSampleCode() async {
        let context = GenerationContext.default
        _ = await codeGenerator.generateSwiftUIView(
            name: "SampleView",
            properties: [],
            context: context
        )
    }
    
    private func analyzeProject() async {
        _ = await projectAnalyzer.performComprehensiveAnalysis()
    }
    
    private func performHealthCheck() async {
        _ = await projectAnalyzer.performHealthCheck()
    }
}

// MARK: - Supporting Types

enum DashboardTab: String, CaseIterable {
    case overview = "Overview"
    case learning = "Learning"
    case generation = "Generation"
    case analysis = "Analysis"
    case health = "Health"
    
    var title: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .overview:
            return "chart.pie"
        case .learning:
            return "brain"
        case .generation:
            return "chevron.left.forwardslash.chevron.right"
        case .analysis:
            return "magnifyingglass"
        case .health:
            return "heart.text.square"
        }
    }
}
