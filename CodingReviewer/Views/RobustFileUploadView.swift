import SwiftUI
import UniformTypeIdentifiers
import AppKit

/// Enhanced File Upload View that uses the robust FileUploadManager
/// This replaces the basic FileUploadView with comprehensive error handling and detailed feedback
@MainActor
struct RobustFileUploadView: View {
    @EnvironmentObject private var fileUploadManager: FileUploadManager
    @State private var uploadedFiles: [FileData] = []
    @State private var isDragOver = false
    @State private var selectedFiles: Set<String> = [] // Using file paths as IDs
    @State private var showingFilePicker = false
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var uploadResult: SimpleUploadResult?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with comprehensive information
            HeaderView(
                uploadedFilesCount: uploadedFiles.count,
                selectedFilesCount: selectedFiles.count,
                isUploading: fileUploadManager.isUploading,
                onClearAll: clearAll,
                onSelectAll: selectAllFiles
            )
            
            Divider()
            
            if uploadedFiles.isEmpty {
                // Enhanced Drop Zone with better guidance
                RobustDropZoneView(
                    isDragOver: $isDragOver,
                    isUploading: fileUploadManager.isUploading,
                    onDrop: handleFileDrop,
                    onChooseFiles: { showingFilePicker = true },
                    onChooseFolder: chooseFolderAndUpload
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // File management interface
                HSplitView {
                    // File List (Left Side)
                    FileListView(
                        files: uploadedFiles,
                        selectedFiles: $selectedFiles,
                        onToggleSelection: toggleFileSelection
                    )
                    .frame(minWidth: 350)
                    
                    // File Details and Actions (Right Side)
                    FileDetailsView(
                        selectedFiles: selectedFiles,
                        allFiles: uploadedFiles,
                        uploadResult: uploadResult
                    )
                    .frame(minWidth: 400)
                }
            }
            
            // Progress indicator when uploading
            if fileUploadManager.isUploading {
                ProgressIndicatorView(progress: fileUploadManager.uploadProgress)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.item], // Accept all file types for better compatibility
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .alert("File Upload Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .navigationTitle("Robust File Upload")
    }
    
    // MARK: - File Operations
    
    private func handleFileDrop(_ providers: [NSItemProvider]) {
        Task {
            var urls: [URL] = []
            
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    do {
                        if let item = try await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL {
                            urls.append(item)
                        }
                    } catch {
                        print("Failed to load dropped item: \(error)")
                    }
                }
            }
            
            if !urls.isEmpty {
                await processUploadedFiles(urls)
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                await processUploadedFiles(urls)
            }
        case .failure(let error):
            showAlert("Failed to import files: \(error.localizedDescription)")
        }
    }
    
    private func chooseFolderAndUpload() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.resolvesAliases = true
        panel.title = "Choose Folder to Upload"
        panel.prompt = "Upload Folder"
        panel.message = "Select a folder containing code files to upload"
        panel.allowedContentTypes = [.folder, .directory]
        
        let response = panel.runModal()
        
        if response == .OK, let url = panel.url {
            Task {
                await processUploadedFiles([url])
            }
        }
    }
    
    @MainActor
    private func processUploadedFiles(_ urls: [URL]) async {
        do {
            let result = try await fileUploadManager.uploadFiles(from: urls)
            self.uploadResult = result
            self.uploadedFiles = result.successfulFiles
            
            // Generate comprehensive feedback message
            let message = generateUploadResultMessage(result)
            showAlert(message)
            
        } catch {
            showAlert("Upload failed: \(error.localizedDescription)")
        }
    }
    
    private func generateUploadResultMessage(_ result: SimpleUploadResult) -> String {
        var message = ""
        
        if result.successfulFiles.count > 0 {
            message += "✅ Successfully uploaded \(result.successfulFiles.count) file\(result.successfulFiles.count == 1 ? "" : "s")"
            
            // Show file type breakdown
            let fileTypes = Dictionary(grouping: result.successfulFiles, by: { $0.fileExtension })
            let typesSummary = fileTypes.map { "\($0.value.count) .\($0.key)" }.joined(separator: ", ")
            message += "\n\n📄 File types: \(typesSummary)"
        }
        
        if result.failedFiles.count > 0 {
            message += "\n\n❌ Failed to upload \(result.failedFiles.count) file\(result.failedFiles.count == 1 ? "" : "s"):"
            for (filename, error) in result.failedFiles.prefix(5) {
                message += "\n  • \(filename): \(error.localizedDescription)"
            }
            if result.failedFiles.count > 5 {
                message += "\n  ... and \(result.failedFiles.count - 5) more"
            }
        }
        
        if result.warnings.count > 0 {
            message += "\n\n⚠️ Warnings:"
            for warning in result.warnings.prefix(3) {
                message += "\n  • \(warning)"
            }
            if result.warnings.count > 3 {
                message += "\n  ... and \(result.warnings.count - 3) more warnings"
            }
        }
        
        return message
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    private func clearAll() {
        uploadedFiles.removeAll()
        selectedFiles.removeAll()
        uploadResult = nil
    }
    
    private func selectAllFiles() {
        selectedFiles = Set(uploadedFiles.map { $0.path })
    }
    
    private func toggleFileSelection(_ filePath: String) {
        if selectedFiles.contains(filePath) {
            selectedFiles.remove(filePath)
        } else {
            selectedFiles.insert(filePath)
        }
    }
}

// MARK: - Supporting Views

struct HeaderView: View {
    let uploadedFilesCount: Int
    let selectedFilesCount: Int
    let isUploading: Bool
    let onClearAll: () -> Void
    let onSelectAll: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Robust File Upload")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if uploadedFilesCount > 0 {
                    Text("\(uploadedFilesCount) files uploaded • \(selectedFilesCount) selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Upload files or entire folders with comprehensive error handling")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if uploadedFilesCount > 0 {
                HStack(spacing: 12) {
                    if selectedFilesCount < uploadedFilesCount {
                        Button("Select All") {
                            onSelectAll()
                        }
                        .font(.caption)
                    }
                    
                    Button("Clear All") {
                        onClearAll()
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .disabled(isUploading)
    }
}

struct RobustDropZoneView: View {
    @Binding var isDragOver: Bool
    let isUploading: Bool
    let onDrop: ([NSItemProvider]) -> Void
    let onChooseFiles: () -> Void
    let onChooseFolder: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Main drop icon
            Image(systemName: isDragOver ? "folder.fill.badge.plus" : isUploading ? "arrow.clockwise" : "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(isDragOver ? .blue : isUploading ? .orange : .gray)
                .symbolEffect(.pulse, isActive: isUploading)
                .animation(.easeInOut, value: isDragOver)
            
            // Instructions
            VStack(spacing: 8) {
                if isUploading {
                    Text("Processing files...")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                } else {
                    Text(isDragOver ? "Drop files here!" : "Drag & Drop Files or Folders")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(isDragOver ? .blue : .primary)
                }
                
                Text("Supports Swift, Python, JavaScript, TypeScript, Java, C/C++, Go, Rust, PHP, Ruby, Kotlin, C#, HTML, CSS, JSON, YAML, Markdown, Xcode projects, and more")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Action buttons
            if !isUploading {
                VStack(spacing: 12) {
                    Button("Choose Files") {
                        onChooseFiles()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text("or")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Choose Folder") {
                        onChooseFolder()
                    }
                    .buttonStyle(.bordered)
                }
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
        .animation(.easeInOut(duration: 0.2), value: isDragOver)
    }
}

struct FileListView: View {
    let files: [FileData]
    @Binding var selectedFiles: Set<String>
    let onToggleSelection: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Files (\(files.count))")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                Spacer()
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // File list
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(files, id: \.path) { file in
                        RobustFileRowView(
                            file: file,
                            isSelected: selectedFiles.contains(file.path)
                        ) {
                            onToggleSelection(file.path)
                        }
                    }
                }
            }
        }
    }
}

struct RobustFileRowView: View {
    let file: FileData
    let isSelected: Bool
    let onToggle: () -> Void
    
    private var fileIcon: String {
        switch file.fileExtension.lowercased() {
        case "swift": return "swift"
        case "py": return "doc.text"
        case "js", "ts": return "doc.text"
        case "json": return "doc.badge.gearshape"
        case "xml": return "doc.text.below.ecg"
        case "md": return "doc.richtext"
        case "plist": return "list.bullet.rectangle"
        case "pbxproj": return "hammer"
        case "xcworkspacedata": return "building"
        default: return "doc.text"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { _ in onToggle() }
            ))
            .toggleStyle(CheckboxToggleStyle())
            
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
                    Text(file.fileExtension.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(file.displaySize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
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

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .font(.title3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FileDetailsView: View {
    let selectedFiles: Set<String>
    let allFiles: [FileData]
    let uploadResult: SimpleUploadResult?
    
    private var selectedFileObjects: [FileData] {
        allFiles.filter { selectedFiles.contains($0.path) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("File Details")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                Spacer()
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if selectedFiles.isEmpty {
                        // No selection state
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("Select files to view details")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        // Selection details
                        SelectionSummaryView(selectedFiles: selectedFileObjects)
                        
                        Divider()
                        
                        // Individual file details
                        ForEach(selectedFileObjects.prefix(5), id: \.path) { file in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(file.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(file.path)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if selectedFileObjects.count > 5 {
                            Text("... and \(selectedFileObjects.count - 5) more files")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Upload result summary
                    if let result = uploadResult {
                        Divider()
                        UploadResultSummaryView(result: result)
                    }
                }
                .padding()
            }
        }
    }
}

struct SelectionSummaryView: View {
    let selectedFiles: [FileData]
    
    private var totalSize: Int {
        selectedFiles.reduce(0) { $0 + $1.size }
    }
    
    private var fileTypeBreakdown: [(String, Int)] {
        let grouped = Dictionary(grouping: selectedFiles, by: { $0.fileExtension })
        return grouped.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selection Summary")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(selectedFiles.count)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Files Selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file))
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Total Size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !fileTypeBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("File Types:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 4) {
                        ForEach(fileTypeBreakdown.prefix(6), id: \.0) { type, count in
                            HStack {
                                Text(".\(type)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct UploadResultSummaryView: View {
    let result: SimpleUploadResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upload Summary")
                .font(.headline)
            
            // Success count
            if result.successfulFiles.count > 0 {
                Label("\(result.successfulFiles.count) files uploaded successfully", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            // Failure count
            if result.failedFiles.count > 0 {
                Label("\(result.failedFiles.count) files failed to upload", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
            
            // Warnings
            if result.warnings.count > 0 {
                Label("\(result.warnings.count) warnings", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct ProgressIndicatorView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("Uploading files... \(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}