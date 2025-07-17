//
//  FileManagerService.swift
//  CodingReviewer
//
//  Created by AI Assistant on 7/17/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine
import CryptoKit

// MARK: - File Models

struct CodeFile: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let path: String
    let content: String
    let language: CodeLanguage
    let size: Int
    let lastModified: Date
    let checksum: String
    
    init(name: String, path: String, content: String, language: CodeLanguage) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.content = content
        self.language = language
        self.size = content.utf8.count
        self.lastModified = Date()
        self.checksum = content.data(using: .utf8)?.sha256 ?? ""
    }
    
    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
    
    var fileExtension: String {
        URL(fileURLWithPath: name).pathExtension
    }
}

// Enhanced structure to preserve rich analysis data while remaining Codable
struct EnhancedAnalysisItem: Codable {
    let message: String
    let severity: String
    let lineNumber: Int?
    let type: String
    
    init(from analysisResult: AnalysisResult) {
        self.message = analysisResult.message
        self.severity = analysisResult.severity.rawValue
        self.lineNumber = analysisResult.line
        self.type = analysisResult.type.rawValue
    }
}

struct FileAnalysisRecord: Identifiable, Codable {
    let id: UUID
    let file: CodeFile
    let analysisResults: [EnhancedAnalysisItem] // Rich analysis data
    let aiAnalysisResult: String? // AI explanation
    let timestamp: Date
    let duration: TimeInterval
    
    init(file: CodeFile, analysisResults: [AnalysisResult], aiAnalysisResult: AIAnalysisResult? = nil, duration: TimeInterval) {
        self.id = UUID()
        self.file = file
        self.analysisResults = analysisResults.map { EnhancedAnalysisItem(from: $0) }
        self.aiAnalysisResult = aiAnalysisResult?.explanation
        self.timestamp = Date()
        self.duration = duration
    }
}

struct ProjectStructure: Identifiable {
    let id: UUID
    let name: String
    let rootPath: String
    let files: [CodeFile]
    let folders: [String]
    let totalSize: Int
    let fileCount: Int
    let languageDistribution: [String: Int] // Simplified for Codable compliance
    let createdAt: Date
    
    init(name: String, rootPath: String, files: [CodeFile]) {
        self.id = UUID()
        self.name = name
        self.rootPath = rootPath
        self.files = files
        self.folders = Array(Set(files.compactMap { URL(fileURLWithPath: $0.path).deletingLastPathComponent().path }))
        self.totalSize = files.reduce(0) { $0 + $1.size }
        self.fileCount = files.count
        // Convert CodeLanguage to string for Codable compliance
        self.languageDistribution = Dictionary(grouping: files, by: \.language)
            .mapValues { $0.count }
            .reduce(into: [String: Int]()) { result, element in
                result[element.key.displayName] = element.value
            }
        self.createdAt = Date()
    }
    
    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
    }
}

// MARK: - File Upload Result

struct FileUploadResult {
    let successfulFiles: [CodeFile]
    let failedFiles: [(String, Error)]
    let warnings: [String]
    
    var hasErrors: Bool {
        !failedFiles.isEmpty
    }
    
    var hasWarnings: Bool {
        !warnings.isEmpty
    }
}

// MARK: - File Manager Service

@MainActor
final class FileManagerService: ObservableObject {
    @Published var uploadedFiles: [CodeFile] = []
    @Published var analysisHistory: [FileAnalysisRecord] = []
    @Published var projects: [ProjectStructure] = []
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var recentFiles: [CodeFile] = []
    
    private let maxFileSize: Int = 10 * 1024 * 1024 // 10MB
    private let maxFilesPerUpload: Int = 100
    private let supportedFileTypes: Set<String> = [
        "swift", "py", "js", "ts", "java", "cpp", "c", "h", "hpp",
        "go", "rs", "php", "rb", "cs", "kt", "scala", "m", "mm",
        "html", "css", "scss", "less", "xml", "json", "yaml", "yml",
        "md", "txt", "sh", "bash", "zsh", "fish", "ps1", "bat"
    ]
    
    private let logger = AppLogger.shared
    
    init() {
        loadPersistedData()
    }
    
    // MARK: - File Upload
    
    func uploadFiles(from urls: [URL]) async throws -> FileUploadResult {
        logger.log("📁 Starting file upload for \(urls.count) items", level: .info, category: .ui)
        
        isUploading = true
        uploadProgress = 0.0
        errorMessage = nil
        
        defer {
            isUploading = false
            uploadProgress = 0.0
        }
        
        var successfulFiles: [CodeFile] = []
        var failedFiles: [(String, Error)] = []
        var warnings: [String] = []
        
        let totalFiles = urls.count
        
        for (index, url) in urls.enumerated() {
            do {
                // Check if it's a directory
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
                
                if resourceValues.isDirectory == true {
                    // Handle directory upload
                    let directoryResult = try await uploadDirectory(at: url)
                    successfulFiles.append(contentsOf: directoryResult.successfulFiles)
                    failedFiles.append(contentsOf: directoryResult.failedFiles)
                    warnings.append(contentsOf: directoryResult.warnings)
                } else {
                    // Handle single file upload
                    let file = try await uploadSingleFile(from: url)
                    successfulFiles.append(file)
                }
            } catch {
                failedFiles.append((url.lastPathComponent, error))
                logger.log("❌ Failed to upload \(url.lastPathComponent): \(error)", level: .error, category: .ui)
            }
            
            uploadProgress = Double(index + 1) / Double(totalFiles)
        }
        
        // Update uploaded files
        let newFiles = successfulFiles.filter { newFile in
            !uploadedFiles.contains { $0.checksum == newFile.checksum }
        }
        
        uploadedFiles.append(contentsOf: newFiles)
        updateRecentFiles(with: newFiles)
        savePersistedData()
        
        let result = FileUploadResult(
            successfulFiles: successfulFiles,
            failedFiles: failedFiles,
            warnings: warnings
        )
        
        logger.log("📁 Upload completed: \(successfulFiles.count) successful, \(failedFiles.count) failed", 
                  level: .info, category: .ui)
        
        return result
    }
    
    private func uploadSingleFile(from url: URL) async throws -> CodeFile {
        // Check file access - be more lenient with security scoped resource access
        let canAccess = url.startAccessingSecurityScopedResource()
        defer { 
            if canAccess {
                url.stopAccessingSecurityScopedResource() 
            }
        }
        
        // Validate file
        try validateFile(at: url)
        
        // Read file content with multiple encoding attempts
        var content: String
        
        // Try UTF-8 first
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            // Try other encodings
            do {
                content = try String(contentsOf: url, encoding: .ascii)
            } catch {
                do {
                    content = try String(contentsOf: url, encoding: .utf16)
                } catch {
                    // Last resort: read as data and convert what we can
                    let data = try Data(contentsOf: url)
                    content = String(data: data, encoding: .utf8) ?? 
                             String(data: data, encoding: .ascii) ?? 
                             "// Unable to decode file content"
                    
                    if content == "// Unable to decode file content" {
                        throw FileManagerError.encodingError(url.lastPathComponent)
                    }
                }
            }
        }
        
        // Detect language
        let language = detectLanguage(from: content, filename: url.lastPathComponent)
        
        // Create CodeFile
        let file = CodeFile(
            name: url.lastPathComponent,
            path: url.path,
            content: content,
            language: language
        )
        
        logger.log("📄 Uploaded file: \(file.name) (\(file.displaySize), \(language.displayName))", 
                  level: .info, category: .ui)
        
        return file
    }
    
    private func uploadDirectory(at url: URL) async throws -> FileUploadResult {
        logger.log("📁 Scanning directory: \(url.lastPathComponent)", level: .info, category: .ui)
        
        var successfulFiles: [CodeFile] = []
        var failedFiles: [(String, Error)] = []
        var warnings: [String] = []
        
        let fileManager = Foundation.FileManager.default
        
        // First, try to access the security scoped resource
        let canAccess = url.startAccessingSecurityScopedResource()
        defer { 
            if canAccess {
                url.stopAccessingSecurityScopedResource() 
            }
        }
        
        // Try different enumeration approaches
        let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { [self] fileURL, error in
                logger.log("⚠️ Enumeration error for \(fileURL.lastPathComponent): \(error)", level: .warning, category: .ui)
                failedFiles.append((fileURL.lastPathComponent, error))
                return true // Continue enumeration
            }
        )
        
        guard let enumerator = enumerator else {
            // Fallback: try direct directory reading
            do {
                let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
                for fileURL in contents {
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                        if resourceValues.isRegularFile == true {
                            let file = try await uploadSingleFile(from: fileURL)
                            successfulFiles.append(file)
                        }
                    } catch {
                        failedFiles.append((fileURL.lastPathComponent, error))
                    }
                }
            } catch {
                throw FileManagerError.directoryEnumerationFailed(url.path)
            }
            
            return FileUploadResult(
                successfulFiles: successfulFiles,
                failedFiles: failedFiles,
                warnings: warnings
            )
        }
        
        var fileCount = 0
        
        // Convert enumerator to array first to avoid async iteration issues
        var allFiles: [URL] = []
        while let fileURL = enumerator.nextObject() as? URL {
            allFiles.append(fileURL)
        }
        
        for fileURL in allFiles {
            // Check limits
            if fileCount >= maxFilesPerUpload {
                warnings.append("Maximum file limit (\(maxFilesPerUpload)) reached. Some files were skipped.")
                break
            }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                
                if resourceValues.isRegularFile == true {
                    // Validate and upload file
                    try validateFile(at: fileURL)
                    let file = try await uploadSingleFile(from: fileURL)
                    successfulFiles.append(file)
                    fileCount += 1
                }
            } catch {
                failedFiles.append((fileURL.lastPathComponent, error))
                logger.log("⚠️ Failed to process file \(fileURL.lastPathComponent): \(error)", level: .warning, category: .ui)
            }
        }
        
        // Create project structure if we have files
        if !successfulFiles.isEmpty {
            let project = ProjectStructure(
                name: url.lastPathComponent,
                rootPath: url.path,
                files: successfulFiles
            )
            projects.append(project)
        }
        
        return FileUploadResult(
            successfulFiles: successfulFiles,
            failedFiles: failedFiles,
            warnings: warnings
        )
    }
    
    // MARK: - File Validation
    
    private func validateFile(at url: URL) throws {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        
        // Check if it's a regular file
        guard resourceValues.isRegularFile == true else {
            throw FileManagerError.notARegularFile(url.lastPathComponent)
        }
        
        // Check file size
        if let fileSize = resourceValues.fileSize, fileSize > maxFileSize {
            throw FileManagerError.fileTooLarge(url.lastPathComponent, fileSize, maxFileSize)
        }
        
        // Check file extension
        let fileExtension = url.pathExtension.lowercased()
        guard supportedFileTypes.contains(fileExtension) else {
            throw FileManagerError.unsupportedFileType(fileExtension)
        }
        
        // Check if file is readable
        guard Foundation.FileManager.default.isReadableFile(atPath: url.path) else {
            throw FileManagerError.fileNotReadable(url.lastPathComponent)
        }
    }
    
    // MARK: - Language Detection
    
    private func detectLanguage(from content: String, filename: String) -> CodeLanguage {
        let fileExtension = URL(fileURLWithPath: filename).pathExtension.lowercased()
        
        // Primary detection by file extension
        switch fileExtension {
        case "swift": return .swift
        case "py": return .python
        case "js": return .javascript
        case "ts": return .typescript
        case "java": return .java
        case "cpp", "cc", "cxx", "c++", "c", "h", "hpp": return .cpp
        case "go": return .go
        case "rs": return .rust
        case "html", "htm": return .html
        case "css", "scss", "sass": return .css
        case "xml": return .xml
        case "json": return .json
        case "yaml", "yml": return .yaml
        case "md": return .markdown
        // Map unsupported types to closest equivalent or default
        case "php", "rb", "cs", "kt", "scala", "m", "mm", "sh", "bash", "zsh", "fish", "ps1", "bat":
            return .swift // Default to swift for unsupported languages
        default:
            break
        }
        
        // Secondary detection by content analysis
        return detectLanguageByContent(content) ?? .swift // Default to swift instead of plainText
    }
    
    private func detectLanguageByContent(_ content: String) -> CodeLanguage? {
        let lines = content.components(separatedBy: .newlines).prefix(10)
        let contentPrefix = lines.joined(separator: "\n").lowercased()
        
        // Look for language-specific patterns
        if contentPrefix.contains("import swift") || contentPrefix.contains("import foundation") {
            return .swift
        } else if contentPrefix.contains("import ") && contentPrefix.contains("from ") {
            return .python
        } else if contentPrefix.contains("function ") || contentPrefix.contains("const ") || contentPrefix.contains("let ") {
            return .javascript
        } else if contentPrefix.contains("interface ") || contentPrefix.contains("type ") {
            return .typescript
        } else if contentPrefix.contains("public class ") || contentPrefix.contains("private class ") {
            return .java
        } else if contentPrefix.contains("#include") || contentPrefix.contains("using namespace") {
            return .cpp
        }
        
        return nil
    }
    
    // MARK: - File Analysis
    
    func analyzeFile(_ file: CodeFile, withAI: Bool = false) async throws -> FileAnalysisRecord {
        logger.log("🔍 Starting analysis for \(file.name)", level: .info, category: .analysis)
        
        let startTime = Date()
        
        // Run traditional analysis
        let codeReviewService = DefaultCodeReviewService()
        let analysisReport = await codeReviewService.analyzeCode(file.content)
        
        logger.log("📊 Analysis report for \(file.name): \(analysisReport.results.count) results found", level: .info, category: .analysis)
        
        // Run AI analysis if enabled
        let aiAnalysisResult: AIAnalysisResult?
        if withAI {
            // This would integrate with the AI service from Phase 1
            // For now, we'll leave it as nil until AI integration is complete
            aiAnalysisResult = nil
        } else {
            aiAnalysisResult = nil
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        let record = FileAnalysisRecord(
            file: file,
            analysisResults: analysisReport.results,
            aiAnalysisResult: aiAnalysisResult,
            duration: duration
        )
        
        analysisHistory.append(record)
        savePersistedData()
        
        logger.log("✅ Analysis completed for \(file.name) in \(String(format: "%.2f", duration))s with \(record.analysisResults.count) results", 
                  level: .info, category: .analysis)
        
        return record
    }
    
    func analyzeMultipleFiles(_ files: [CodeFile], withAI: Bool = false) async throws -> [FileAnalysisRecord] {
        logger.log("🔍 Starting batch analysis for \(files.count) files", level: .info, category: .analysis)
        
        var results: [FileAnalysisRecord] = []
        
        for file in files {
            do {
                let record = try await analyzeFile(file, withAI: withAI)
                results.append(record)
            } catch {
                logger.log("❌ Failed to analyze \(file.name): \(error)", level: .error, category: .analysis)
                throw error
            }
        }
        
        return results
    }
    
    // MARK: - File Management
    
    func removeFile(_ file: CodeFile) {
        uploadedFiles.removeAll { $0.id == file.id }
        recentFiles.removeAll { $0.id == file.id }
        analysisHistory.removeAll { $0.file.id == file.id }
        savePersistedData()
        
        logger.log("🗑️ Removed file: \(file.name)", level: .info, category: .ui)
    }
    
    func removeProject(_ project: ProjectStructure) {
        projects.removeAll { $0.id == project.id }
        
        // Remove associated files
        let projectFileIds = Set(project.files.map(\.id))
        uploadedFiles.removeAll { projectFileIds.contains($0.id) }
        recentFiles.removeAll { projectFileIds.contains($0.id) }
        analysisHistory.removeAll { projectFileIds.contains($0.file.id) }
        
        savePersistedData()
        
        logger.log("🗑️ Removed project: \(project.name)", level: .info, category: .ui)
    }
    
    func clearAllFiles() {
        uploadedFiles.removeAll()
        recentFiles.removeAll()
        analysisHistory.removeAll()
        projects.removeAll()
        savePersistedData()
        
        logger.log("🗑️ Cleared all files and projects", level: .info, category: .ui)
    }
    
    // MARK: - Recent Files
    
    private func updateRecentFiles(with newFiles: [CodeFile]) {
        // Add new files to recent, removing duplicates
        for file in newFiles {
            recentFiles.removeAll { $0.id == file.id }
            recentFiles.insert(file, at: 0)
        }
        
        // Keep only the most recent 10 files
        if recentFiles.count > 10 {
            recentFiles = Array(recentFiles.prefix(10))
        }
    }
    
    // MARK: - Persistence
    
    private func savePersistedData() {
        // Note: Simplified persistence - in production, consider Core Data or SQLite
        // For now, we'll skip persistence to avoid Codable complexity
        logger.log("📝 Data persistence skipped - implement when needed", level: .info, category: .ui)
    }
    
    private func loadPersistedData() {
        // Note: Simplified persistence - in production, consider Core Data or SQLite
        // For now, we'll skip persistence to avoid Codable complexity
        logger.log("📝 Data loading skipped - implement when needed", level: .info, category: .ui)
    }
}

// MARK: - File Manager Errors

enum FileManagerError: LocalizedError {
    case accessDenied(String)
    case fileTooLarge(String, Int, Int)
    case unsupportedFileType(String)
    case fileNotReadable(String)
    case notARegularFile(String)
    case directoryEnumerationFailed(String)
    case encodingError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .accessDenied(let filename):
            return "Access denied to file: \(filename)"
        case .fileTooLarge(let filename, let size, let maxSize):
            let sizeStr = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            let maxSizeStr = ByteCountFormatter.string(fromByteCount: Int64(maxSize), countStyle: .file)
            return "File '\(filename)' is too large (\(sizeStr)). Maximum size is \(maxSizeStr)."
        case .unsupportedFileType(let type):
            return "Unsupported file type: .\(type)"
        case .fileNotReadable(let filename):
            return "Cannot read file: \(filename)"
        case .notARegularFile(let filename):
            return "Not a regular file: \(filename)"
        case .directoryEnumerationFailed(let path):
            return "Failed to enumerate directory: \(path)"
        case .encodingError(let filename):
            return "Text encoding error in file: \(filename)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

extension CodeLanguage {
    var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .python: return "Python"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .java: return "Java"
        case .cpp: return "C++"
        case .go: return "Go"
        case .rust: return "Rust"
        case .html: return "HTML"
        case .css: return "CSS"
        case .xml: return "XML"
        case .json: return "JSON"
        case .yaml: return "YAML"
        case .markdown: return "Markdown"
        }
    }
    
    var iconName: String {
        switch self {
        case .swift: return "swift"
        case .python: return "snake.circle"
        case .javascript, .typescript: return "js.circle"
        case .java: return "cup.and.saucer"
        case .cpp: return "c.circle"
        case .go: return "goforward"
        case .rust: return "gear"
        case .html: return "globe"
        case .css: return "paintbrush"
        case .xml: return "doc.text"
        case .json: return "curlybraces"
        case .yaml: return "list.bullet"
        case .markdown: return "doc.richtext"
        }
    }
}

extension Data {
    var sha256: String {
        let hash = SHA256.hash(data: self)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
