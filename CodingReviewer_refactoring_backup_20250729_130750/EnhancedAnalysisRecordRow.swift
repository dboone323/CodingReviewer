//
//  EnhancedAnalysisRecordRow.swift
//  CodingReviewer
//
//  Created by AI Assistant on 7/17/25.
//

import SwiftUI

struct EnhancedAnalysisRecordRow: View {
    let record: FileAnalysisRecord
    @State private var isExpanded = true  // Start expanded so users can see results immediately

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with file info and summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.file.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack {
                        Label("\(record.analysisResults.count) issues", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("Analyzed \(formatDuration(record.duration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)

            // Expandable details
            if isExpanded {
                Divider()

                if record.analysisResults.isEmpty {
                    Text("No issues found")
                        .italic()
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(record.analysisResults.enumerated()), id: \.offset) { index, item in
                            analysisItemView(item: item, index: index)
                        }
                    }
                    .padding(.top, 4)
                }

                // AI Analysis Result
                if let aiResult = record.aiAnalysisResult {
                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Label("AI Analysis", systemImage: "brain.head.profile")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)

                        Text(aiResult)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func analysisItemView(item: EnhancedAnalysisItem, index: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // Severity indicator
            Circle()
                .fill(severityColor(for: item.severity))
                .frame(width: 8, height: 8)
                .offset(y: 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.message)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()

                    if let lineNumber = item.lineNumber {
                        Text("Line \(lineNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Text(item.type.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(3)
            }
        }
        .padding(.vertical, 4)
    }

    private func severityColor(for severity: String) -> Color {
        switch severity.lowercased() {
        case "critical":
            return .red
        case "high":
            return .orange
        case "medium":
            return .yellow
        case "low":
            return .blue
        default:
            return .gray
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 1 {
            return String(format: "%.0fms", duration * 1000)
        } else {
            return String(format: "%.1fs", duration)
        }
    }
}

struct EnhancedAnalysisRecordRow_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFile = CodeFile(
            name: "SampleFile.swift",
            path: "/path/to/SampleFile.swift",
            content: "// Sample content",
            language: .swift
        )

        let sampleAnalysisResults = [
            EnhancedAnalysisItem(
                message: "Variable 'unused' is declared but never used",
                severity: "medium",
                lineNumber: 15,
                type: "quality"
            ),
            EnhancedAnalysisItem(
                message: "Force unwrapping may cause runtime crash",
                severity: "high",
                lineNumber: 23,
                type: "security"
            )
        ]

        // Create FileAnalysisRecord using the correct initializer
        let sampleRecord = FileAnalysisRecord(
            file: sampleFile,
            analysisResults: sampleAnalysisResults,
            duration: 0.5
        )

        EnhancedAnalysisRecordRow(record: sampleRecord)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

