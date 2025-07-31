//
//  FileUploadView.swift
//  CodingReviewer
//
//  Created by AI Assistant on 7/17/25.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct FileUploadView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    @StateObject private var fileManager = FileManagerService();
    @State private var showingFileImporter = false;
    @State private var showingFolderPicker = false;
    @State private var isTargeted = false;
    @State private var uploadResult: FileUploadResult?
    @State private var showingUploadResults = false;
    @State private var selectedFiles: Set<CodeFile.ID> = [];
    @State private var showingAnalysisResults = false;
    @State private var analysisRecords: [FileAnalysisRecord] = [];
    @State private var sheetAnalysisRecords: [FileAnalysisRecord] = [];

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Main content
            if fileManager.uploadedFiles.isEmpty && fileManager.projects.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .navigationTitle("File Management")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarButtons
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.sourceCode, .plainText, .json, .xml],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .alert("Upload Results", isPresented: $showingUploadResults) {
            Button("OK") { uploadResult = nil }
        } message: {
            if let result = uploadResult {
                Text(uploadResultMessage(result))
            }
        }
        .sheet(isPresented: $showingAnalysisResults) {
            AnalysisResultsView(records: $sheetAnalysisRecords)
        }
        .alert("Error", isPresented: .constant(fileManager.errorMessage != nil)) {
            Button("OK") {
                fileManager.errorMessage = nil
            }
        } message: {
            if let errorMessage = fileManager.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.badge.plus")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("File & Project Management")
                        .font(.headline)
                    Text("Upload files or folders for code analysis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if fileManager.isUploading {
                    ProgressView(value: fileManager.uploadProgress)
                        .frame(width: 100)
                        .progressViewStyle(LinearProgressViewStyle())
                }
            }

            // Statistics
            if !fileManager.uploadedFiles.isEmpty || !fileManager.projects.isEmpty {
                statisticsView
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var statisticsView: some View {
        HStack(spacing: 20) {
            StatisticItem(
                icon: "doc.text",
                title: "Files",
                value: "\(fileManager.uploadedFiles.count)",
                color: .blue
            )

            StatisticItem(
                icon: "folder",
                title: "Projects",
                value: "\(fileManager.projects.count)",
                color: .green
            )

            StatisticItem(
                icon: "chart.bar",
                title: "Analyses",
                value: "\(fileManager.analysisHistory.count)",
                color: .orange
            )

            Spacer()

            if !fileManager.uploadedFiles.isEmpty {
                Button("Analyze All") {
                    analyzeAllFiles()
                }
                .buttonStyle(.borderedProminent)
                .disabled(fileManager.isUploading)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Drop zone
            VStack(spacing: 16) {
                Image(systemName: isTargeted ? "folder.fill.badge.plus" : "folder.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(isTargeted ? .accentColor : .secondary)
                    .scaleEffect(isTargeted ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isTargeted)

                VStack(spacing: 8) {
                    Text("Drop files or folders here")
                        .font(.title2)
                        .fontWeight(.medium)

                    Text("Supports Swift, Python, JavaScript, TypeScript, Java, C++, and more")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 16) {
                    Button("Choose Files") {
                        showingFileImporter = true
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Choose Folder") {
                        showFolderPicker()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: 400)
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                            )
                    )
            )
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Content View

    private var contentView: some View {
        HSplitView {
            // Sidebar
            sidebarView
                .frame(minWidth: 250)

            // Main content
            mainContentView
                .frame(minWidth: 400)
        }
    }

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Recent files
            if !fileManager.recentFiles.isEmpty {
                SectionHeaderView(title: "Recent Files", icon: "clock")

                LazyVStack(spacing: 4) {
                    ForEach(fileManager.recentFiles.prefix(5)) { file in
                        FileRowView(file: file, isSelected: selectedFiles.contains(file.id)) {
                            toggleFileSelection(file)
                        }
                    }
                }
                .padding(.horizontal)

                Divider()
                    .padding(.vertical, 8)
            }

            // Projects
            if !fileManager.projects.isEmpty {
                SectionHeaderView(title: "Projects", icon: "folder.fill")

                LazyVStack(spacing: 4) {
                    ForEach(fileManager.projects) { project in
                        ProjectRowView(project: project) {
                            selectProjectFiles(project)
                        } onDelete: {
                            fileManager.removeProject(project)
                        }
                    }
                }
                .padding(.horizontal)

                Divider()
                    .padding(.vertical, 8)
            }

            // All files
            SectionHeaderView(title: "All Files", icon: "doc.text")

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(fileManager.uploadedFiles) { file in
                        FileRowView(file: file, isSelected: selectedFiles.contains(file.id)) {
                            toggleFileSelection(file)
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Selection info
            if !selectedFiles.isEmpty {
                selectionInfoView
                Divider()
            }

            // File details or drop zone
            if selectedFiles.isEmpty {
                secondaryDropZone
            } else {
                fileDetailsView
            }
        }
    }

    private var selectionInfoView: some View {
        HStack {
            Text("\(selectedFiles.count) files selected")
                .font(.headline)

            Spacer()

            HStack(spacing: 12) {
                Button("Analyze Selected") {
                    analyzeSelectedFiles()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedFiles.isEmpty)

                Button("Clear Selection") {
                    selectedFiles.removeAll()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var secondaryDropZone: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("Select files from the sidebar or drop more files here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack {
                Button("Add More Files") {
                    showingFileImporter = true
                }
                .buttonStyle(.bordered)

                Button("Add Folder") {
                    showFolderPicker()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private var fileDetailsView: some View {
        let selectedFilesList = fileManager.uploadedFiles.filter { selectedFiles.contains($0.id) }

        return ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(selectedFilesList) { file in
                    FileDetailCard(file: file) {
                        // Remove file
                        fileManager.removeFile(file)
                        selectedFiles.remove(file.id)
                    }
                }
            }
            .padding()
        }
        .background(Color(NSColor.textBackgroundColor))
    }

    // MARK: - Toolbar

    private var toolbarButtons: some View {
        Group {
            Button("Add Files") {
                showingFileImporter = true
            }

            Button("Add Folder") {
                showFolderPicker()
            }

            if !fileManager.uploadedFiles.isEmpty {
                Menu("Actions") {
                    Button("Analyze All Files") {
                        analyzeAllFiles()
                    }

                    Button("Clear All Files") {
                        fileManager.clearAllFiles()
                        selectedFiles.removeAll()
                    }

                    Divider()

                    Button("Export File List") {
                        exportFileList()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                do {
                    let result = try await fileManager.uploadFiles(from: urls)
                    await MainActor.run {
                        self.uploadResult = result
                        self.showingUploadResults = true
                    }
                } catch {
                    await MainActor.run {
                        fileManager.errorMessage = error.localizedDescription
                    }
                }
            }
        case .failure(let error):
            fileManager.errorMessage = error.localizedDescription
        }
    }

    private func showFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                do {
                    let result = try await fileManager.uploadFiles(from: [url])
                    await MainActor.run {
                        self.uploadResult = result
                        self.showingUploadResults = true
                    }
                } catch {
                    await MainActor.run {
                        fileManager.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = [];

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(url)

                        if urls.count == providers.count {
                            Task {
                                do {
                                    let result = try await fileManager.uploadFiles(from: urls)
                                    await MainActor.run {
                                        self.uploadResult = result
                                        self.showingUploadResults = true
                                    }
                                } catch {
                                    await MainActor.run {
                                        fileManager.errorMessage = error.localizedDescription
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        return !providers.isEmpty
    }

    private func toggleFileSelection(_ file: CodeFile) {
        if selectedFiles.contains(file.id) {
            selectedFiles.remove(file.id)
        } else {
            selectedFiles.insert(file.id)
        }
    }

    private func selectProjectFiles(_ project: ProjectStructure) {
        let projectFileIds = Set(project.files.map(\.id))
        selectedFiles = selectedFiles.symmetricDifference(projectFileIds)
    }

    private func analyzeSelectedFiles() {
        let filesToAnalyze = fileManager.uploadedFiles.filter { selectedFiles.contains($0.id) }

        Task {
            do {
                let records = try await fileManager.analyzeMultipleFiles(filesToAnalyze, withAI: true)
                await AppLogger.shared.debug("✅ Selected files analysis completed. Found \(records.count) records")

                await MainActor.run {
                    // Clear any previous state first
                    self.showingAnalysisResults = false

                    // Set the records
                    self.analysisRecords = records

                    // Force state update and show sheet immediately
                    self.showingAnalysisResults = true
                }
                
                await AppLogger.shared.debug("🔍 Sheet should now be presented with \(records.count) records")
            } catch {
                await MainActor.run {
                    fileManager.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func analyzeAllFiles() {
        guard !fileManager.uploadedFiles.isEmpty else {
            fileManager.errorMessage = "No files to analyze. Please upload some files first."
            return
        }

        Task {
            do {
                let records = try await fileManager.analyzeMultipleFiles(fileManager.uploadedFiles, withAI: true)
                await MainActor.run {
                    // Set both record properties to ensure consistency
                    self.analysisRecords = records
                    self.sheetAnalysisRecords = records

                    // Small delay to ensure records are properly set before showing sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.showingAnalysisResults = true
                    }
                }
            } catch {
                await MainActor.run {
                    fileManager.errorMessage = "Analysis failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func exportFileList() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "file_list.json"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                // Create a simplified exportable format
                struct ExportFileInfo: Codable {
                    let name: String
                    let path: String
                    let language: String
                    let size: Int
                    let lastModified: String
                }

                let exportData = fileManager.uploadedFiles.map { file in
                    ExportFileInfo(
                        name: file.name,
                        path: file.path,
                        language: file.language.displayName,
                        size: file.size,
                        lastModified: ISO8601DateFormatter().string(from: file.lastModified)
                    )
                }

                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(exportData)
                try data.write(to: url)
            } catch {
                fileManager.errorMessage = "Failed to export file list: \(error.localizedDescription)"
            }
        }
    }

    private func uploadResultMessage(_ result: FileUploadResult) -> String {
        var message = "";

        if !result.successfulFiles.isEmpty {
            message += "Successfully uploaded \(result.successfulFiles.count) files.\n"
        }

        if !result.failedFiles.isEmpty {
            message += "Failed to upload \(result.failedFiles.count) files:\n"
            for (filename, error) in result.failedFiles.prefix(3) {
                message += "• \(filename): \(error.localizedDescription)\n"
            }
            if result.failedFiles.count > 3 {
                message += "• ... and \(result.failedFiles.count - 3) more\n"
            }
        }

        if !result.warnings.isEmpty {
            message += "\nWarnings:\n"
            for warning in result.warnings.prefix(3) {
                message += "• \(warning)\n"
            }
            if result.warnings.count > 3 {
                message += "• ... and \(result.warnings.count - 3) more\n"
            }
        }

        return message
    }
}

// MARK: - Supporting Views

struct StatisticItem: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SectionHeaderView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 16)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct FileRowView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    let file: CodeFile
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: file.language.iconName)
                    .foregroundColor(.accentColor)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.body)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text(file.language.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(file.displaySize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
    }
}

struct ProjectRowView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    let project: ProjectStructure
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text("\(project.fileCount) files • \(project.displaySize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Menu {
                    Button("Select All Files", action: onSelect)
                    Button("Remove Project", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 20, height: 20)
            }

            // Language distribution
            if !project.languageDistribution.isEmpty {
                HStack {
                    ForEach(Array(project.languageDistribution.keys.prefix(3)), id: \.self) { languageName in
                        Label(
                            title: { Text("\(project.languageDistribution[languageName] ?? 0)") },
                            icon: { Image(systemName: "doc.text") }
                        )
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }

                    if project.languageDistribution.count > 3 {
                        Text("+\(project.languageDistribution.count - 3) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct FileDetailCard: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    let file: CodeFile
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: file.language.iconName)
                    .foregroundColor(.accentColor)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.headline)
                        .lineLimit(1)

                    HStack {
                        Text(file.language.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.1))
                            )

                        Text(file.displaySize)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(file.lastModified, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }

            // File path
            Text(file.path)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.1))
                )

            // Content preview
            VStack(alignment: .leading, spacing: 4) {
                Text("Content Preview")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ScrollView {
                    Text(file.content.prefix(500) + (file.content.count > 500 ? "..." : ""))
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(NSColor.textBackgroundColor))
                        )
                }
                .frame(maxHeight: 150)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct AnalysisResultsView: View {
    @State private var errorMessage: String?
    @State private var isLoading = false;
    @Binding var records: [FileAnalysisRecord]
    @Environment(\.dismiss) private var dismiss

    // Computed properties for summary statistics
    private var totalIssues: Int {
        records.reduce(0) { $0 + $1.analysisResults.count }
    }

    private var criticalIssues: Int {
        records.flatMap(\.analysisResults).filter { $0.severity == "critical" }.count
    }

    private var highIssues: Int {
        records.flatMap(\.analysisResults).filter { $0.severity == "high" }.count
    }

    private var mediumIssues: Int {
        records.flatMap(\.analysisResults).filter { $0.severity == "medium" }.count
    }

    private var lowIssues: Int {
        records.flatMap(\.analysisResults).filter { $0.severity == "low" }.count
    }

    var body: some View {
        NavigationView {
            Group {
                if records.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No Analysis Results")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Upload some files and try analyzing them again.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        // Empty state
                    }
                } else {
                    VStack(spacing: 0) {
                        // Summary section at the top
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Analysis Complete")
                                        .font(.headline)
                                        .fontWeight(.semibold)

                                    Text("\(records.count) files analyzed • \(totalIssues) issues found")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }

                            if totalIssues > 0 {
                                HStack(spacing: 16) {
                                    Label("\(criticalIssues) Critical", systemImage: "exclamationmark.octagon")
                                        .foregroundColor(.red)
                                        .font(.caption)

                                    Label("\(highIssues) High", systemImage: "exclamationmark.circle")
                                        .foregroundColor(.orange)
                                        .font(.caption)

                                    Label("\(mediumIssues) Medium", systemImage: "exclamationmark.triangle")
                                        .foregroundColor(.yellow)
                                        .font(.caption)

                                    Label("\(lowIssues) Low", systemImage: "info.circle")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))

                        Divider()

                        // Results list
                        List {
                            ForEach(records) { record in
                                EnhancedAnalysisRecordRow(record: record)
                            }
                        }
                    }
                    .onAppear {
                        // Results state
                    }
                }
            }
            .navigationTitle("Analysis Results (\(records.count))")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

#Preview {
    FileUploadView()
}
