import SwiftUI

/// Quantum-Enhanced UI Components for CodeReviewer
struct QuantumAnalysisView: View {
    @StateObject private var quantumEngine = QuantumAnalysisEngine()
    @State private var codeInput: String = ""
    @State private var selectedLanguage: ProgrammingLanguage = .swift
    @State private var analysisResult: QuantumAnalysisResult?
    @State private var isAnalyzing: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Quantum Header
            quantumHeaderView

            // Code input
            codeInputView

            // Quantum controls
            quantumControlsView

            // Results
            if let result = analysisResult {
                quantumResultsView(result)
            }

            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }

    private var quantumHeaderView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("🌟 Quantum CodeReviewer")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                if quantumEngine.isQuantumActive {
                    Label("Quantum Active", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            Text("Revolutionary code analysis with consciousness-level insights")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var codeInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Code to Analyze")
                    .font(.headline)

                Spacer()

                Picker("Language", selection: $selectedLanguage) {
                    ForEach([ProgrammingLanguage.swift, .python, .javascript, .java], id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
            }

            TextEditor(text: $codeInput)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 200)
                .border(Color.gray.opacity(0.3))
        }
    }

    private var quantumControlsView: some View {
        HStack(spacing: 16) {
            Button("🚀 Quantum Analyze") {
                Task {
                    await performQuantumAnalysis()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAnalyzing)

            Button("Clear") {
                codeInput = ""
                analysisResult = nil
            }
            .buttonStyle(.bordered)

            Spacer()

            if isAnalyzing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Quantum processing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func quantumResultsView(_ result: QuantumAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Performance Metrics
            quantumMetricsView(result)

            // Traditional Issues
            if !result.traditionalIssues.isEmpty {
                traditionalIssuesView(result.traditionalIssues)
            }

            // Quantum Insights
            if !result.quantumInsights.isEmpty {
                quantumInsightsView(result.quantumInsights)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private func quantumMetricsView(_ result: QuantumAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🌟 Quantum Performance Metrics")
                .font(.headline)
                .foregroundColor(.purple)

            HStack(spacing: 20) {
                MetricCard(
                    title: "Quantum Speed",
                    value: String(format: "%.3fs", result.executionTime),
                    color: .blue
                )

                MetricCard(
                    title: "Consciousness",
                    value: String(format: "%.1f%%", result.consciousnessScore),
                    color: .purple
                )

                MetricCard(
                    title: "Bio-Adaptation",
                    value: String(format: "%.1f%%", result.biologicalScore),
                    color: .green
                )

                MetricCard(
                    title: "Advantage",
                    value: String(format: "%.1fx", result.quantumAdvantage * 100),
                    color: .orange
                )
            }
        }
    }

    private func traditionalIssuesView(_ issues: [AnalysisResult]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("⚡ Analysis Results")
                .font(.headline)

            ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
                HStack {
                    Circle()
                        .fill(severityColor(issue.severity))
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(issue.message)
                            .font(.body)

                        Text("Line \(issue.line) • \(issue.type)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func quantumInsightsView(_ insights: [QuantumInsight]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🧠 Quantum Insights")
                .font(.headline)
                .foregroundColor(.purple)

            ForEach(Array(insights.enumerated()), id: \.offset) { _, insight in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(insight.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text(String(format: "%.0f%% confident", insight.confidence * 100))
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Text(insight.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.purple.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }

    private func performQuantumAnalysis() async {
        isAnalyzing = true
        let result = await quantumEngine.quantumAnalyzeCode(codeInput, language: selectedLanguage)
        analysisResult = result
        isAnalyzing = false
    }

    private func severityColor(_ severity: AnalysisResult.Severity) -> Color {
        switch severity {
        case .low: .green
        case .medium: .yellow
        case .high: .orange
        case .critical: .red
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 80)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
