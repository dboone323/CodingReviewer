//
// DataFlowDiagnostics.swift
// CodingReviewer
//
// Runtime diagnostics to verify data sharing between views
// Created on July 29, 2025
//

import SwiftUI
import Foundation

// MARK: - Runtime Data Flow Diagnostics

struct DataFlowDiagnosticsView: View {
    @EnvironmentObject var fileManager: FileManagerService
    @State private var diagnosticResults: [DiagnosticResult] = [];
    @State private var isRunning = false;

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Data Flow Diagnostics")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: runDiagnostics) {
                    HStack {
                        if isRunning {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isRunning ? "Running..." : "Run Diagnostics")
                    }
                }
                .disabled(isRunning)
            }

            Divider()

            if diagnosticResults.isEmpty {
                Text("Click 'Run Diagnostics' to test data flow between views")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(diagnosticResults, id: \.id) { result in
                            DiagnosticResultRow(result: result)
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func runDiagnostics() {
        isRunning = true
        diagnosticResults.removeAll()

        Task {
            await performDiagnostics()
            await MainActor.run {
                isRunning = false
            }
        }
    }

    private func performDiagnostics() async {
        var results: [DiagnosticResult] = [];

        // Test 1: Verify SharedDataManager singleton
        let test1 = await testSharedDataManagerSingleton()
        results.append(test1)

        // Test 2: Verify FileManagerService consistency
        let test2 = await testFileManagerConsistency()
        results.append(test2)

        // Test 3: Test uploaded files accessibility
        let test3 = await testUploadedFilesAccess()
        results.append(test3)

        // Test 4: Test cross-view data sharing
        let test4 = await testCrossViewDataSharing()
        results.append(test4)

        // Test 5: Test AI Insights view state
        let test5 = await testAIInsightsViewState()
        results.append(test5)

        // Test 6: Test Pattern Analysis view state
        let test6 = await testPatternAnalysisViewState()
        results.append(test6)

        await MainActor.run {
            self.diagnosticResults = results
        }
    }

    // MARK: - Individual Diagnostic Tests

    private func testSharedDataManagerSingleton() async -> DiagnosticResult {
        let manager1 = SharedDataManager.shared
        let manager2 = SharedDataManager.shared

        let isEqualReference = manager1 === manager2

        return DiagnosticResult(
            id: UUID(),
            testName: "SharedDataManager Singleton",
            description: "Verifies SharedDataManager is a proper singleton",
            passed: isEqualReference,
            details: isEqualReference ? "✅ Same instance reference" : "❌ Different instance references",
            severity: isEqualReference ? .success : .critical
        )
    }

    private func testFileManagerConsistency() async -> DiagnosticResult {
        let sharedManager = SharedDataManager.shared
        let fileManager1 = sharedManager.fileManager
        let fileManager2 = sharedManager.getFileManager()

        let isConsistent = fileManager1 === fileManager2

        return DiagnosticResult(
            id: UUID(),
            testName: "FileManager Consistency",
            description: "Verifies FileManagerService instance consistency",
            passed: isConsistent,
            details: isConsistent ? "✅ Same FileManagerService instance" : "❌ Different FileManagerService instances",
            severity: isConsistent ? .success : .critical
        )
    }

    private func testUploadedFilesAccess() async -> DiagnosticResult {
        let initialCount = fileManager.uploadedFiles.count

        // Add a test file
        let testFile = CodeFile(
            name: "DiagnosticTest.swift",
            path: "/tmp/DiagnosticTest.swift",
            content: "// Diagnostic test file",
            language: .swift
        )

        await MainActor.run {
            fileManager.uploadedFiles.append(testFile)
        }

        let newCount = fileManager.uploadedFiles.count
        let canAccess = newCount == initialCount + 1

        // Clean up test file
        await MainActor.run {
            if let index = fileManager.uploadedFiles.firstIndex(where: { $0.id == testFile.id }) {
                fileManager.uploadedFiles.remove(at: index)
            }
        }

        return DiagnosticResult(
            id: UUID(),
            testName: "Uploaded Files Access",
            description: "Tests ability to read and modify uploaded files",
            passed: canAccess,
            details: canAccess ? "✅ Can access and modify uploaded files" : "❌ Cannot access uploaded files properly",
            severity: canAccess ? .success : .critical
        )
    }

    private func testCrossViewDataSharing() async -> DiagnosticResult {
        let sharedManager = SharedDataManager.shared
        let environmentFileManager = fileManager

        let isSameInstance = sharedManager.fileManager === environmentFileManager

        return DiagnosticResult(
            id: UUID(),
            testName: "Cross-View Data Sharing",
            description: "Verifies environment object matches shared instance",
            passed: isSameInstance,
            details: isSameInstance ? "✅ Environment object matches shared instance" : "❌ Environment object is different from shared instance",
            severity: isSameInstance ? .success : .critical
        )
    }

    private func testAIInsightsViewState() async -> DiagnosticResult {
        let hasFiles = !fileManager.uploadedFiles.isEmpty
        let hasAnalysis = !fileManager.analysisHistory.isEmpty

        let expectedState: String
        if hasFiles && !hasAnalysis {
            expectedState = "Should show uploaded files for analysis"
        } else if hasAnalysis {
            expectedState = "Should show analysis history"
        } else {
            expectedState = "Should show empty state"
        }

        return DiagnosticResult(
            id: UUID(),
            testName: "AI Insights View State",
            description: "Analyzes expected AI Insights view state",
            passed: true, // This is informational
            details: "📊 Files: \(fileManager.uploadedFiles.count), Analysis: \(fileManager.analysisHistory.count). \(expectedState)",
            severity: .info
        )
    }

    private func testPatternAnalysisViewState() async -> DiagnosticResult {
        let files = fileManager.uploadedFiles
        let languageGroups = Dictionary(grouping: files, by: { $0.language })
        let uniqueLanguages = languageGroups.keys.count

        let canGroup = !files.isEmpty && uniqueLanguages > 0

        return DiagnosticResult(
            id: UUID(),
            testName: "Pattern Analysis View State",
            description: "Tests language grouping for pattern analysis",
            passed: files.isEmpty || canGroup, // Pass if no files or can group properly
            details: files.isEmpty ? "📊 No files to analyze" : "📊 \(files.count) files across \(uniqueLanguages) languages",
            severity: .info
        )
    }
}

// MARK: - Diagnostic Result Models

struct DiagnosticResult {
    let id: UUID
    let testName: String
    let description: String
    let passed: Bool
    let details: String
    let severity: DiagnosticSeverity
}

enum DiagnosticSeverity {
    case success
    case warning
    case critical
    case info

    var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .critical: return .red
        case .info: return .blue
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct DiagnosticResultRow: View {
    let result: DiagnosticResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.severity.icon)
                    .foregroundColor(result.severity.color)

                Text(result.testName)
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                Text(result.passed ? "PASS" : "FAIL")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(result.passed ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(result.passed ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .cornerRadius(4)
            }

            Text(result.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(result.details)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
        }
        .padding()
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Debug Helper Views

struct DebugDataStateView: View {
    @EnvironmentObject var fileManager: FileManagerService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Debug: Data State")
                .font(.headline)
                .fontWeight(.bold)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Uploaded Files:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(fileManager.uploadedFiles.count)")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                HStack {
                    Text("Analysis History:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(fileManager.analysisHistory.count)")
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                if !fileManager.uploadedFiles.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Files by Language:")
                            .fontWeight(.medium)
                            .padding(.top, 8)

                        let languageGroups = Dictionary(grouping: fileManager.uploadedFiles, by: { $0.language })
                        ForEach(Array(languageGroups.keys.sorted(by: { $0.displayName < $1.displayName })), id: \.self) { language in
                            HStack {
                                Image(systemName: language.iconName)
                                    .foregroundColor(.blue)
                                Text(language.displayName)
                                Spacer()
                                Text("\(languageGroups[language]?.count ?? 0)")
                                    .fontWeight(.bold)
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Integration with Main Views

extension ContentView {
    func addDiagnosticsTab() -> some View {
        // This would be added as a debug tab in development builds
        TabView {
            // ... existing tabs

            #if DEBUG
            DataFlowDiagnosticsView()
                .environmentObject(SharedDataManager.shared.fileManager)
                .tabItem {
                    Label("Diagnostics", systemImage: "stethoscope")
                }
            #endif
        }
    }
}
