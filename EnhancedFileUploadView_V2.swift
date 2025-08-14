import SwiftUI
import UniformTypeIdentifiers

struct EnhancedFileUploadView: View {
    @State private var uploadedFiles: [UploadedFile] = []
    @State private var isDragOver = false
    @State private var isAnalyzing = false
    @State private var selectedFiles: Set<UUID> = []
    @State private var showingFilePicker = false
    @State private var analysisResults: [FileAnalysisResult] = []
    @State private var showingResults = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("File Manager")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Upload and analyze files or entire projects")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 12) {
                    if !uploadedFiles.isEmpty {
                        Button("Analyze Selected") {
                            analyzeSelectedFiles()
                        }
                        .disabled(selectedFiles.isEmpty || isAnalyzing)
                        .buttonStyle(.borderedProminent)
                    }

                    Menu {
                        Button("Choose Files...") {
                            showingFilePicker = true
                        }

                        Button("Choose Folder...") {
                            chooseFolderAndUpload()
                        }

                        Divider()

                        Button("Clear All") {
                            uploadedFiles.removeAll()
                            selectedFiles.removeAll()
                            analysisResults.removeAll()
                        }
                        .disabled(uploadedFiles.isEmpty)
                    } label: {
                        Label("Upload", systemImage: "plus.circle.fill")
                    }
                    .menuStyle(.borderlessButton)
                }
            }
            .padding()

            Divider()

            if uploadedFiles.isEmpty {
                // Drop Zone
                DropZoneView(isDragOver: $isDragOver) {
                    handleFileDrop($0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // File List and Results
                HSplitView {
                    // File List (Left Side)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Files (\(uploadedFiles.count))")
                                .font(.headline)

                            Spacer()

                            if !selectedFiles.isEmpty {
                                Button("Select All") {
                                    selectedFiles = Set(uploadedFiles.map(\.id))
                                }
                                .font(.caption)
                            }
                        }
                        .padding()

                        Divider()

                        ScrollView {
                            LazyVStack(spacing: 1) {
                                ForEach(uploadedFiles) { file in
                                    FileRowView(
                                        file: file,
                                        isSelected: selectedFiles.contains(file.id)
                                    ) {
                                        toggleFileSelection(file.id)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(minWidth: 300)

                    // Results Panel (Right Side)
                    if showingResults, !analysisResults.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Analysis Results")
                                    .font(.headline)

                                Spacer()

                                Button("Export Report") {
                                    exportAnalysisReport()
                                }
                                .font(.caption)
                            }
                            .padding()

                            Divider()

                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(analysisResults) { result in
                                        FileAnalysisCard(result: result)
                                    }
                                }
                                .padding()
                            }
                        }
                        .frame(minWidth: 400)
                    } else if isAnalyzing {
                        AnalysisProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Empty results state
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)

                            Text("Select files and click 'Analyze' to see results")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.sourceCode, .plainText, .json, .xml],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
    }

    private func toggleFileSelection(_ id: UUID) {
        if selectedFiles.contains(id) {
            selectedFiles.remove(id)
        } else {
            selectedFiles.insert(id)
        }
    }

    private func handleFileDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    if let url = item as? URL {
                        DispatchQueue.main.async {
                            loadFile(from: url)
                        }
                    }
                }
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                loadFile(from: url)
            }
        case .failure(let error):
            print("File import failed: \(error)")
        }
    }

    private func chooseFolderAndUpload() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false

        if panel.runModal() == .OK {
            if let url = panel.url {
                loadDirectory(from: url)
            }
        }
    }

    private func loadFile(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0

            let uploadedFile = UploadedFile(
                id: UUID(),
                name: url.lastPathComponent,
                path: url.path,
                size: fileSize,
                content: content,
                type: determineFileType(from: url),
                uploadDate: Date()
            )

            uploadedFiles.append(uploadedFile)
        } catch {
            print("Failed to load file: \(error)")
        }
    }

    private func loadDirectory(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        let fileManager = FileManager.default

        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey]
        ) {
            for case let fileURL as URL in enumerator {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                   resourceValues.isRegularFile == true,
                   isSourceCodeFile(url: fileURL)
                {
                    loadFile(from: fileURL)
                }
            }
        }
    }

    private func isSourceCodeFile(url: URL) -> Bool {
        let sourceExtensions = [
            "swift",
            "py",
            "js",
            "ts",
            "java",
            "cpp",
            "c",
            "h",
            "go",
            "rs",
            "php",
            "rb",
            "kt",
            "cs",
            "scala",
            "sh",
            "json",
            "xml",
            "yaml",
            "yml",
        ]
        return sourceExtensions.contains(url.pathExtension.lowercased())
    }

    private func determineFileType(from url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "swift": "Swift"
        case "py": "Python"
        case "js": "JavaScript"
        case "ts": "TypeScript"
        case "java": "Java"
        case "cpp", "c": "C++"
        case "go": "Go"
        case "rs": "Rust"
        case "php": "PHP"
        case "rb": "Ruby"
        case "kt": "Kotlin"
        case "cs": "C#"
        case "json": "JSON"
        case "xml": "XML"
        case "yaml", "yml": "YAML"
        default: "Text"
        }
    }

    private func analyzeSelectedFiles() {
        isAnalyzing = true
        showingResults = true
        analysisResults.removeAll()

        let filesToAnalyze = uploadedFiles.filter { selectedFiles.contains($0.id) }

        // Simulate analysis with progress
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            var results: [FileAnalysisResult] = []

            for file in filesToAnalyze {
                let issues = generateAnalysisIssues(for: file)
                let result = FileAnalysisResult(
                    id: UUID(),
                    fileName: file.name,
                    filePath: file.path,
                    fileType: file.type,
                    issuesFound: issues.count,
                    issues: issues,
                    analysisDate: Date()
                )
                results.append(result)
            }

            analysisResults = results
            isAnalyzing = false
        }
    }

    private func generateAnalysisIssues(for file: UploadedFile) -> [AnalysisIssue] {
        var issues: [AnalysisIssue] = []

        // Simulate realistic analysis based on file content
        let lines = file.content.components(separatedBy: .newlines)

        for (lineIndex, line) in lines.enumerated() {
            // Check for common issues
            if line.contains("TODO") || line.contains("FIXME") {
                issues.append(AnalysisIssue(
                    type: "Code Quality",
                    severity: "Low",
                    message: "TODO/FIXME comment found",
                    lineNumber: lineIndex + 1,
                    line: line.trimmingCharacters(in: .whitespaces)
                ))
            }

            if line.contains("console.log") || line.contains("print(") {
                issues.append(AnalysisIssue(
                    type: "Code Quality",
                    severity: "Low",
                    message: "Debug statement found",
                    lineNumber: lineIndex + 1,
                    line: line.trimmingCharacters(in: .whitespaces)
                ))
            }

            if line.contains("password"), !line.contains("//") {
                issues.append(AnalysisIssue(
                    type: "Security",
                    severity: "High",
                    message: "Potential hardcoded password",
                    lineNumber: lineIndex + 1,
                    line: line.trimmingCharacters(in: .whitespaces)
                ))
            }
        }

        // Add some random issues for demo
        if issues.isEmpty {
            issues.append(AnalysisIssue(
                type: "Code Quality",
                severity: "Low",
                message: "File looks good! No major issues found",
                lineNumber: 1,
                line: ""
            ))
        }

        return issues
    }

    private func exportAnalysisReport() {
        let panel = NSSavePanel()
        panel.allowsOtherFileTypes = false
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "analysis_report.txt"

        if panel.runModal() == .OK {
            if let url = panel.url {
                exportReport(to: url)
            }
        }
    }

    private func exportReport(to url: URL) {
        var reportContent = "Code Analysis Report\n"
        reportContent += "Generated: \(Date())\n"
        reportContent += "=================================\n\n"

        for result in analysisResults {
            reportContent += "File: \(result.fileName)\n"
            reportContent += "Type: \(result.fileType)\n"
            reportContent += "Issues Found: \(result.issuesFound)\n"
            reportContent += "---------------------------------\n"

            for issue in result.issues {
                reportContent += "• \(issue.type) (\(issue.severity)): \(issue.message)\n"
                reportContent += "  Line \(issue.lineNumber): \(issue.line)\n\n"
            }

            reportContent += "\n"
        }

        do {
            try reportContent.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to export report: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct DropZoneView: View {
    @Binding var isDragOver: Bool
    let onDrop: ([NSItemProvider]) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: isDragOver ? "folder.fill.badge.plus" : "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(isDragOver ? .blue : .gray)

            VStack(spacing: 8) {
                Text(isDragOver ? "Drop files here!" : "Drag & Drop Files")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(isDragOver ? .blue : .primary)

                Text("Support for Swift, Python, JavaScript, and more")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                Button("Choose Files") {
                    // This will be handled by the parent view
                }
                .buttonStyle(.borderedProminent)

                Text("or")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Choose Folder") {
                    // This will be handled by the parent view
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isDragOver ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isDragOver ? Color.blue : Color.gray.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                )
        )
        .padding()
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            onDrop(providers)
            return true
        }
    }
}

struct FileRowView: View {
    let file: UploadedFile
    let isSelected: Bool
    let onToggle: () -> Void

    private var fileIcon: String {
        switch file.type.lowercased() {
        case "swift": "swift"
        case "python": "doc.text"
        case "javascript", "typescript": "doc.text"
        case "json": "doc.badge.gearshape"
        case "xml": "doc.text.below.ecg"
        default: "doc.text"
        }
    }

    private var fileSizeString: String {
        ByteCountFormatter.string(fromByteCount: Int64(file.size), countStyle: .file)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())

            // File icon
            Image(systemName: fileIcon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 20)

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack {
                    Text(file.type)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(fileSizeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Upload date
            Text(file.uploadDate, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

struct FileAnalysisCard: View {
    let result: FileAnalysisResult
    @State private var isExpanded = false

    private var severityColor: Color {
        let highSeverityCount = result.issues.count(where: { $0.severity == "High" })
        let mediumSeverityCount = result.issues.count(where: { $0.severity == "Medium" })

        if highSeverityCount > 0 { return .red }
        if mediumSeverityCount > 0 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.fileName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    HStack {
                        Text(result.fileType)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)

                        Text("\(result.issuesFound) issue\(result.issuesFound == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Overall status indicator
                Circle()
                    .fill(severityColor)
                    .frame(width: 12, height: 12)
            }

            // Issue summary
            if !result.issues.isEmpty {
                Button(action: { isExpanded.toggle() }) {
                    HStack {
                        Text(isExpanded ? "Hide Details" : "Show Details")
                            .font(.caption)
                            .fontWeight(.medium)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())

                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(result.issues.enumerated()), id: \.offset) { _, issue in
                            IssueRowView(issue: issue)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct IssueRowView: View {
    let issue: AnalysisIssue

    private var severityColor: Color {
        switch issue.severity.lowercased() {
        case "high": .red
        case "medium": .orange
        case "low": .yellow
        default: .blue
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(severityColor)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(issue.type)
                        .font(.caption)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("Line \(issue.lineNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(issue.message)
                    .font(.caption)
                    .foregroundColor(.primary)

                if !issue.line.isEmpty {
                    Text(issue.line)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct AnalysisProgressView: View {
    @State private var progress: Double = 0.0
    @State private var currentFile = "Analyzing files..."

    var body: some View {
        VStack(spacing: 24) {
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 200)

            VStack(spacing: 8) {
                Text("Analyzing Code")
                    .font(.headline)

                Text(currentFile)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            startProgressAnimation()
        }
    }

    private func startProgressAnimation() {
        let files = ["Checking syntax...", "Analyzing security...", "Reviewing patterns...", "Generating report..."]

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.25
                if Int(progress * 4) - 1 < files.count {
                    currentFile = files[Int(progress * 4) - 1]
                }
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Data Models

struct UploadedFile: Identifiable {
    let id: UUID
    let name: String
    let path: String
    let size: Int
    let content: String
    let type: String
    let uploadDate: Date
}

struct FileAnalysisResult: Identifiable {
    let id: UUID
    let fileName: String
    let filePath: String
    let fileType: String
    let issuesFound: Int
    let issues: [AnalysisIssue]
    let analysisDate: Date
}

struct AnalysisIssue {
    let type: String
    let severity: String
    let message: String
    let lineNumber: Int
    let line: String
}
