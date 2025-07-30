//
//  FixApplicationView.swift
//  CodingReviewer
//
//  Phase 4: Interactive Fix Application UI
//  Created on July 25, 2025
//

import SwiftUI
import Accessibility

// MARK: - Interactive Fix Application View

struct FixApplicationView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false
    @StateObject private var fixGenerator = IntelligentFixGenerator()
    @State private var selectedFixes: Set<UUID> = []
    @State private var showingDiffPreview = false
    @State private var previewFix: IntelligentFix?
    @State private var appliedFixes: [UUID] = []
    @State private var showingApplyConfirmation = false

    let analysis: EnhancedAnalysisResult
    let originalCode: String
    let onFixesApplied: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            FixApplicationHeader(
                totalFixes: fixGenerator.generatedFixes.count,
                selectedCount: selectedFixes.count,
                onSelectAll: selectAllFixes,
                onDeselectAll: deselectAllFixes
            )

            Divider()

            // Fixes List
            if fixGenerator.isGeneratingFixes {
                FixGenerationProgressView(progress: fixGenerator.fixGenerationProgress)
            } else if fixGenerator.generatedFixes.isEmpty {
                EmptyFixesView()
            } else {
                FixesList(
                    fixes: fixGenerator.generatedFixes,
                    selectedFixes: $selectedFixes,
                    appliedFixes: appliedFixes,
                    onPreviewFix: { fix in
                        previewFix = fix
                        showingDiffPreview = true
                    }
                )
            }

            Divider()

            // Action Bar
            FixActionBar(
                hasSelectedFixes: !selectedFixes.isEmpty,
                onApplySelected: applySelectedFixes,
                onPreviewSelected: previewSelectedFixes
            )
        }
        .task {
            await generateFixes()
        }
        .sheet(isPresented: $showingDiffPreview) {
            if let fix = previewFix {
                DiffPreviewView(fix: fix, originalCode: originalCode)
            }
        }
        .alert("Apply Fixes", isPresented: $showingApplyConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Apply") {
                applyConfirmedFixes()
            }
        } message: {
            Text("Apply \(selectedFixes.count) selected fixes? This action cannot be undone.")
        }
    }

    // MARK: - Actions

    private func generateFixes() async {
        do {
            let context = CodeContext(
                originalCode: originalCode,
                fileName: analysis.fileName,
                language: analysis.language
            )

            _ = try await fixGenerator.generateFixes(for: analysis, context: context)
        } catch {
            await AppLogger.shared.log("Failed to generate fixes: \(error)", level: .error, category: .ai)
        }
    }

    private func selectAllFixes() {
        selectedFixes = Set(fixGenerator.generatedFixes.map { $0.id })
    }

    private func deselectAllFixes() {
        selectedFixes.removeAll()
    }

    private func applySelectedFixes() {
        showingApplyConfirmation = true
    }

    private func previewSelectedFixes() {
        // Show preview of all selected fixes
        if let firstFix = fixGenerator.generatedFixes.first(where: { selectedFixes.contains($0.id) }) {
            previewFix = firstFix
            showingDiffPreview = true
        }
    }

    private func applyConfirmedFixes() {
        var modifiedCode = originalCode
        let sortedFixes = fixGenerator.generatedFixes
            .filter { selectedFixes.contains($0.id) }
            .sorted { $0.startLine > $1.startLine } // Apply from bottom to top

        for fix in sortedFixes {
            do {
                modifiedCode = try fixGenerator.applyFix(fix, to: modifiedCode)
                appliedFixes.append(fix.id)
            } catch {
                AppLogger.shared.log("Failed to apply fix \(fix.id): \(error)", level: .error, category: .ai)
            }
        }

        selectedFixes.removeAll()
        onFixesApplied(modifiedCode)
    }
}

// MARK: - Header Component

struct FixApplicationHeader: View {
    @State private var errorMessage: String?
    @State private var isLoading = false
    let totalFixes: Int
    let selectedCount: Int
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Intelligent Fixes")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(totalFixes) fixes available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if totalFixes > 0 {
                HStack(spacing: 12) {
                    Button(selectedCount == totalFixes ? "Deselect All" : "Select All") {
                        if selectedCount == totalFixes {
                            onDeselectAll()
                        } else {
                            onSelectAll()
                        }
                    }
                    .buttonStyle(.bordered)

                    if selectedCount > 0 {
                        Text("\(selectedCount) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Progress View

struct FixGenerationProgressView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false
    let progress: Double

    var body: some View {
        VStack(spacing: 16) {
            ProgressView("Generating intelligent fixes...", value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())

            Text("\(Int(progress * 100))% complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State

struct EmptyFixesView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("No Fixes Needed")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your code looks great! No intelligent fixes are suggested at this time.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Fixes List

struct FixesList: View {
    @State private var errorMessage: String?
    @State private var isLoading = false
    let fixes: [IntelligentFix]
    @Binding var selectedFixes: Set<UUID>
    let appliedFixes: [UUID]
    let onPreviewFix: (IntelligentFix) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(fixes) { fix in
                    FixRowView(
                        fix: fix,
                        isSelected: selectedFixes.contains(fix.id),
                        isApplied: appliedFixes.contains(fix.id),
                        onToggleSelection: {
                            toggleFixSelection(fix.id)
                        },
                        onPreview: {
                            onPreviewFix(fix)
                        }
                    )
                }
            }
            .padding()
        }
    }

    private func toggleFixSelection(_ fixId: UUID) {
        if selectedFixes.contains(fixId) {
            selectedFixes.remove(fixId)
        } else {
            selectedFixes.insert(fixId)
        }
    }
}

// MARK: - Fix Row Component

struct FixRowView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false
    let fix: IntelligentFix
    let isSelected: Bool
    let isApplied: Bool
    let onToggleSelection: () -> Void
    let onPreview: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title3)
            }
            .disabled(isApplied)

            // Fix details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    // Category icon and name
                    HStack(spacing: 4) {
                        Text(fix.category.icon)
                        Text(fix.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(fix.category.color.opacity(0.2))
                            .foregroundColor(fix.category.color)
                            .cornerRadius(4)
                    }

                    Spacer()

                    // Confidence badge
                    ConfidenceBadge(confidence: fix.confidence)

                    // Impact indicator
                    ImpactIndicator(impact: fix.impact)
                }

                // Description
                Text(fix.description)
                    .font(.body)
                    .foregroundColor(.primary)

                // Code preview
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Line \(fix.startLine + 1)")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(fix.originalCode.prefix(60) + (fix.originalCode.count > 60 ? "..." : ""))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Preview", action: onPreview)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }

            // Applied indicator
            if isApplied {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
        .opacity(isApplied ? 0.6 : 1.0)
    }
}

// MARK: - Supporting Components

struct ConfidenceBadge: View {
    @State private var errorMessage: String?
    @State private var isLoading = false
    let confidence: Double

    var body: some View {
        Text("\(Int(confidence * 100))%")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(confidenceColor.opacity(0.2))
            .foregroundColor(confidenceColor)
            .cornerRadius(4)
    }

    private var confidenceColor: Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

struct ImpactIndicator: View {
    @State private var errorMessage: String?
    @State private var isLoading = false
    let impact: FixImpact

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<impact.priority, id: \.self) { _ in
                Circle()
                    .fill(impactColor)
                    .frame(width: 6, height: 6)
            }
            ForEach(impact.priority..<4, id: \.self) { _ in
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var impactColor: Color {
        switch impact {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Action Bar

struct FixActionBar: View {
    @State private var errorMessage: String?
    @State private var isLoading = false
    let hasSelectedFixes: Bool
    let onApplySelected: () -> Void
    let onPreviewSelected: () -> Void

    var body: some View {
        HStack {
            Spacer()

            if hasSelectedFixes {
                Button("Preview Selected", action: onPreviewSelected)
                    .buttonStyle(.bordered)

                Button("Apply Selected", action: onApplySelected)
                    .buttonStyle(.borderedProminent)
            } else {
                Text("Select fixes to apply")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
