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

enum CodeLanguage: String, CaseIterable, Codable {
    case swift = "swift"
    case python = "python"
    case javascript = "javascript"
    case typescript = "typescript"
    case java = "java"
    case cpp = "cpp"
    case go = "go"
    case rust = "rust"
    case html = "html"
    case css = "css"
    case xml = "xml"
    case json = "json"
    case yaml = "yaml"
    case markdown = "markdown"
    case kotlin = "kotlin"
    case csharp = "csharp"
    case c = "c"
    case php = "php"
    case ruby = "ruby"
    case unknown = "unknown"
}

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

// Enhanced structure to preserve analysis data while remaining Codable
struct EnhancedAnalysisItem: Codable {
    let message: String
    let severity: String
    let lineNumber: Int?
    let type: String
    
    init(message: String, severity: String, lineNumber: Int? = nil, type: String = "quality") {
        self.message = message
        self.severity = severity
        self.lineNumber = lineNumber
        self.type = type
    }
}

struct FileAnalysisRecord: Identifiable, Codable {
    let id: UUID
    let file: CodeFile
    let analysisResults: [EnhancedAnalysisItem] // Rich analysis data
    let aiAnalysisResult: String? // AI explanation
    let timestamp: Date
    let duration: TimeInterval
    
    init(file: CodeFile, analysisResults: [EnhancedAnalysisItem], aiAnalysisResult: String? = nil, duration: TimeInterval) {
        self.id = UUID()
        self.file = file
        self.analysisResults = analysisResults
        self.aiAnalysisResult = aiAnalysisResult
        self.timestamp = Date()
        self.duration = duration
    }
}

// MARK: - Phase 4 Enhanced Analysis Types

struct Phase4EnhancedAnalysisResult: Codable {
    let fileName: String
    let fileSize: Int
    let language: String
    let originalResults: [String]
    let aiSuggestions: [String]
    let complexity: Double?
    let maintainability: Double?
    let fixes: [String]
    let summary: Phase4AnalysisSummary
}

struct Phase4AnalysisSummary: Codable {
    let totalSuggestions: Int
    let criticalIssues: Int
    let errors: Int
    let warnings: Int
    let infos: Int
    let complexityScore: Int
    let maintainabilityScore: Double
}

// MARK: - Phase 4: Additional computed properties for AI integration
extension FileAnalysisRecord {
    var fileName: String { file.name }
    var originalCode: String? { file.content }
    var language: String? { file.language.rawValue }
    var results: [AnalysisResult] {
        analysisResults.map { item in
            AnalysisResult(
                type: .quality,
                message: item.message,
                line: item.lineNumber,
                severity: mapSeverity(item.severity)
            )
        }
    }
    var enhancedResult: Phase4EnhancedAnalysisResult? {
        guard let aiResult = aiAnalysisResult else { return nil }
        
        return Phase4EnhancedAnalysisResult(
            fileName: fileName,
            fileSize: file.size,
            language: file.language.rawValue,
            originalResults: analysisResults.map { $0.message },
            aiSuggestions: [aiResult],
            complexity: 50.0,
            maintainability: 75.0,
            fixes: [],
            summary: Phase4AnalysisSummary(
                totalSuggestions: analysisResults.count,
                criticalIssues: 0,
                errors: 0,
                warnings: analysisResults.count,
                infos: 0,
                complexityScore: 50,
                maintainabilityScore: 75.0
            )
        )
    }
    var hasAIAnalysis: Bool { aiAnalysisResult != nil }
    
    private func mapSeverity(_ severity: String) -> AnalysisResult.Severity {
        switch severity.lowercased() {
        case "critical": return .critical
        case "high": return .high
        case "medium": return .medium
        default: return .low
        }
    }
}

// MARK: - Hashable conformance for FileAnalysisRecord
extension FileAnalysisRecord: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FileAnalysisRecord, rhs: FileAnalysisRecord) -> Bool {
        lhs.id == rhs.id
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

struct ProjectAnalysisResult {
    let project: ProjectStructure
    let fileAnalyses: [FileAnalysisRecord]
    let insights: [ProjectInsight]
    let duration: TimeInterval
    
    var totalIssues: Int {
        fileAnalyses.flatMap { $0.analysisResults }.count
    }
    
    var averageIssuesPerFile: Double {
        guard !fileAnalyses.isEmpty else { return 0 }
        return Double(totalIssues) / Double(fileAnalyses.count)
    }
}

struct ProjectInsight {
    let type: InsightType
    let message: String
    let severity: InsightSeverity
    let fileCount: Int
    
    enum InsightType {
        case architecture
        case maintainability
        case quality
        case testing
        case security
        case performance
        
        var icon: String {
            switch self {
            case .architecture: return "🏗️"
            case .maintainability: return "🔧"
            case .quality: return "✨"
            case .testing: return "🧪"
            case .security: return "🔒"
            case .performance: return "⚡"
            }
        }
    }
    
    enum InsightSeverity {
        case low, medium, high, critical
        
        var color: String {
            switch self {
            case .low: return "🟢"
            case .medium: return "🟡"
            case .high: return "🟠"
            case .critical: return "🔴"
            }
        }
    }
}

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
    
    // MARK: - Phase 3 AI Integration (Simple Start)
    @Published var isAIAnalyzing = false
    @Published var aiInsightsAvailable = false
    @Published var showingAIInsights = false
    @Published var lastAIAnalysis: String?
    
    private let maxFileSize: Int = 10 * 1024 * 1024 // 10MB
    private let maxFilesPerUpload: Int = 100
    private let supportedFileTypes: Set<String> = [
        "swift", "py", "js", "ts", "java", "cpp", "c", "h", "hpp",
        "go", "rs", "php", "rb", "cs", "kt", "scala", "m", "mm",
        "html", "css", "scss", "less", "xml", "json", "yaml", "yml",
        "md", "txt", "sh", "bash", "zsh", "fish", "ps1", "bat"
    ]
    
    private let logger = FileManagerLogger()
    
    init() {
        loadPersistedData()
    }
    
    // MARK: - File Upload
    
    func uploadFiles(from urls: [URL]) async throws -> FileUploadResult {
        logger.log("📁 Starting file upload for \(urls.count) items")
        
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
                logger.log("❌ Failed to upload \(url.lastPathComponent): \(error)")
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
        
        logger.log("📁 Upload completed: \(successfulFiles.count) successful, \(failedFiles.count) failed")
        
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
        
        logger.log("📄 Uploaded file: \(file.name) (\(file.displaySize), \(language.displayName))")
        
        return file
    }
    
    private func uploadDirectory(at url: URL) async throws -> FileUploadResult {
        logger.log("📁 Scanning directory: \(url.lastPathComponent)")
        
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
                logger.log("⚠️ Enumeration error for \(fileURL.lastPathComponent): \(error)")
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
                logger.log("⚠️ Failed to process file \(fileURL.lastPathComponent): \(error)")
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
    
    // MARK: - Enhanced Language Detection
    
    private func detectLanguage(from content: String, filename: String) -> CodeLanguage {
        let fileExtension = URL(fileURLWithPath: filename).pathExtension.lowercased()
        
        // Primary detection by file extension with improved mapping
        switch fileExtension {
        case "swift": return .swift
        case "py", "pyw": return .python
        case "js", "mjs": return .javascript
        case "ts", "tsx": return .typescript
        case "java": return .java
        case "cpp", "cc", "cxx", "c++": return .cpp
        case "c", "h": return .c
        case "go": return .go
        case "rs": return .rust
        case "html", "htm": return .html
        case "css", "scss", "sass", "less": return .css
        case "xml", "xsd", "xsl": return .xml
        case "json", "jsonc": return .json
        case "yaml", "yml": return .yaml
        case "md", "markdown": return .markdown
        case "kt", "kts": return .kotlin
        case "cs": return .csharp
        case "php": return .php
        case "rb": return .ruby
        // Map additional types to closest equivalent
        case "m", "mm": return .c  // Objective-C to C
        case "sh", "bash", "zsh", "fish": return .unknown // Shell scripts
        case "ps1", "bat": return .unknown // Windows scripts
        case "scala": return .java // Scala to Java (similar syntax)
        default:
            break
        }
        
        // Enhanced secondary detection by content analysis
        return detectLanguageByContentAdvanced(content) ?? detectLanguageBySimplePatterns(content) ?? .unknown
    }
    
    private func detectLanguageByContentAdvanced(_ content: String) -> CodeLanguage? {
        let lines = content.components(separatedBy: .newlines).prefix(20)
        let contentPrefix = lines.joined(separator: "\n").lowercased()
        
        // Weighted scoring system for language detection
        var scores: [CodeLanguage: Int] = [:]
        
        // Swift patterns
        if contentPrefix.contains("import swift") || contentPrefix.contains("import foundation") {
            scores[.swift, default: 0] += 10
        }
        if contentPrefix.contains("var ") || contentPrefix.contains("let ") {
            scores[.swift, default: 0] += 3
        }
        if contentPrefix.contains("func ") && contentPrefix.contains("->") {
            scores[.swift, default: 0] += 5
        }
        
        // Python patterns
        if contentPrefix.contains("def ") || contentPrefix.contains("import ") {
            scores[.python, default: 0] += 5
        }
        if contentPrefix.contains("if __name__ == \"__main__\":") {
            scores[.python, default: 0] += 10
        }
        if contentPrefix.contains("from ") && contentPrefix.contains(" import ") {
            scores[.python, default: 0] += 7
        }
        
        // JavaScript/TypeScript patterns
        if contentPrefix.contains("function ") || contentPrefix.contains("const ") {
            scores[.javascript, default: 0] += 5
        }
        if contentPrefix.contains("interface ") || contentPrefix.contains("type ") {
            scores[.typescript, default: 0] += 8
        }
        if contentPrefix.contains("export ") || contentPrefix.contains("import ") {
            scores[.javascript, default: 0] += 3
            scores[.typescript, default: 0] += 3
        }
        
        // Java patterns
        if contentPrefix.contains("public class ") || contentPrefix.contains("private class ") {
            scores[.java, default: 0] += 8
        }
        if contentPrefix.contains("package ") {
            scores[.java, default: 0] += 6
        }
        
        // C/C++ patterns
        if contentPrefix.contains("#include") || contentPrefix.contains("using namespace") {
            scores[.cpp, default: 0] += 8
        }
        if contentPrefix.contains("#include <stdio.h>") {
            scores[.c, default: 0] += 10
        }
        
        // Return language with highest score
        return scores.max(by: { $0.value < $1.value })?.key
    }
    
    private func detectLanguageBySimplePatterns(_ content: String) -> CodeLanguage? {
        let contentLower = content.lowercased()
        
        // Simple fallback patterns
        if contentLower.contains("println!") || contentLower.contains("fn main") {
            return .rust
        } else if contentLower.contains("fmt.println") || contentLower.contains("package main") {
            return .go
        } else if contentLower.contains("<!doctype html") || contentLower.contains("<html") {
            return .html
        } else if contentLower.contains("{") && contentLower.contains("}") && contentLower.contains(":") {
            return .json
        }
        
        return nil
    }
    
    private func detectLanguageByContent(_ content: String) -> CodeLanguage? {
        // Keep the original method for backward compatibility
        return detectLanguageByContentAdvanced(content)
    }
    
    // MARK: - File Analysis
    
    func analyzeFile(_ file: CodeFile, withAI: Bool = false) async throws -> FileAnalysisRecord {
        logger.log("🔍 Starting analysis for \(file.name)")
        
        let startTime = Date()
        
        // Run enhanced analysis based on language
        let analysisResults = await performLanguageSpecificAnalysis(for: file)
        
        logger.log("📊 Analysis report for \(file.name): \(analysisResults.count) results found")
        
        // Run AI analysis if enabled (placeholder for future implementation)
        let aiAnalysisResult: String?
        if withAI {
            // TODO: Integrate with AI service when available
            logger.log("🤖 AI analysis requested but not yet implemented for \(file.name)")
            aiAnalysisResult = "AI analysis will be implemented in future version"
        } else {
            aiAnalysisResult = nil
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        let record = FileAnalysisRecord(
            file: file,
            analysisResults: analysisResults,
            aiAnalysisResult: aiAnalysisResult,
            duration: duration
        )
        
        analysisHistory.append(record)
        savePersistedData()
        
        logger.log("✅ Analysis completed for \(file.name) in \(String(format: "%.2f", duration))s with \(record.analysisResults.count) results")
        
        return record
    }
    
    private func performLanguageSpecificAnalysis(for file: CodeFile) async -> [EnhancedAnalysisItem] {
        var results: [EnhancedAnalysisItem] = []
        
        // Basic file metrics
        let lineCount = file.content.components(separatedBy: .newlines).count
        let characterCount = file.content.count
        
        // Language-specific analysis
        switch file.language {
        case .swift:
            results.append(contentsOf: analyzeSwiftCode(file.content, lineCount: lineCount))
        case .python:
            results.append(contentsOf: analyzePythonCode(file.content, lineCount: lineCount))
        case .javascript, .typescript:
            results.append(contentsOf: analyzeJavaScriptCode(file.content, lineCount: lineCount))
        case .java:
            results.append(contentsOf: analyzeJavaCode(file.content, lineCount: lineCount))
        default:
            results.append(contentsOf: analyzeGenericCode(file.content, lineCount: lineCount))
        }
        
        // Add file size analysis
        if characterCount > 50000 {
            results.append(EnhancedAnalysisItem(
                message: "Large file detected (\(characterCount) characters). Consider breaking into smaller modules.",
                severity: "medium",
                type: "maintainability"
            ))
        }
        
        return results
    }
    
    private func analyzeSwiftCode(_ content: String, lineCount: Int) -> [EnhancedAnalysisItem] {
        var results: [EnhancedAnalysisItem] = []
        
        // Check for force unwrapping
        if content.contains("!") {
            let forceUnwrapCount = content.components(separatedBy: "!").count - 1
            if forceUnwrapCount > 5 {
                results.append(EnhancedAnalysisItem(
                    message: "High number of force unwraps (\(forceUnwrapCount)) detected. Consider using safe unwrapping.",
                    severity: "high",
                    type: "safety"
                ))
            }
        }
        
        // Check for TODO/FIXME comments
        if content.lowercased().contains("todo") || content.lowercased().contains("fixme") {
            results.append(EnhancedAnalysisItem(
                message: "TODO or FIXME comments found. Consider addressing them.",
                severity: "low",
                type: "maintenance"
            ))
        }
        
        // Check for long functions (more than 50 lines)
        let functionPattern = "func .+?\\{[\\s\\S]*?^\\}"
        if let regex = try? NSRegularExpression(pattern: functionPattern, options: [.anchorsMatchLines]) {
            let matches = regex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
            for match in matches {
                if let range = Range(match.range, in: content) {
                    let functionCode = String(content[range])
                    let functionLineCount = functionCode.components(separatedBy: .newlines).count
                    if functionLineCount > 50 {
                        results.append(EnhancedAnalysisItem(
                            message: "Long function detected (\(functionLineCount) lines). Consider breaking into smaller functions.",
                            severity: "medium",
                            type: "maintainability"
                        ))
                    }
                }
            }
        }
        
        return results
    }
    
    private func analyzePythonCode(_ content: String, lineCount: Int) -> [EnhancedAnalysisItem] {
        var results: [EnhancedAnalysisItem] = []
        
        // Check for proper imports
        if !content.contains("import ") && lineCount > 10 {
            results.append(EnhancedAnalysisItem(
                message: "No import statements found in Python file with \(lineCount) lines.",
                severity: "low",
                type: "style"
            ))
        }
        
        // Check for print statements (potential debugging code)
        let printCount = content.components(separatedBy: "print(").count - 1
        if printCount > 3 {
            results.append(EnhancedAnalysisItem(
                message: "Multiple print statements (\(printCount)) found. Consider using proper logging.",
                severity: "low",
                type: "best_practice"
            ))
        }
        
        return results
    }
    
    private func analyzeJavaScriptCode(_ content: String, lineCount: Int) -> [EnhancedAnalysisItem] {
        var results: [EnhancedAnalysisItem] = []
        
        // Check for console.log statements
        let consoleLogCount = content.components(separatedBy: "console.log").count - 1
        if consoleLogCount > 3 {
            results.append(EnhancedAnalysisItem(
                message: "Multiple console.log statements (\(consoleLogCount)) found. Consider removing before production.",
                severity: "low",
                type: "debugging"
            ))
        }
        
        // Check for var usage (prefer let/const)
        if content.contains(" var ") {
            results.append(EnhancedAnalysisItem(
                message: "Usage of 'var' detected. Consider using 'let' or 'const' for better scoping.",
                severity: "medium",
                type: "best_practice"
            ))
        }
        
        return results
    }
    
    private func analyzeJavaCode(_ content: String, lineCount: Int) -> [EnhancedAnalysisItem] {
        var results: [EnhancedAnalysisItem] = []
        
        // Check for System.out.println
        let printCount = content.components(separatedBy: "System.out.println").count - 1
        if printCount > 2 {
            results.append(EnhancedAnalysisItem(
                message: "Multiple System.out.println statements (\(printCount)) found. Consider using a logging framework.",
                severity: "low",
                type: "best_practice"
            ))
        }
        
        return results
    }
    
    private func analyzeGenericCode(_ content: String, lineCount: Int) -> [EnhancedAnalysisItem] {
        var results: [EnhancedAnalysisItem] = []
        
        // Basic analysis for any code type
        let averageLineLength = content.count / max(lineCount, 1)
        if averageLineLength > 120 {
            results.append(EnhancedAnalysisItem(
                message: "Long average line length (\(averageLineLength) chars). Consider breaking lines for readability.",
                severity: "low",
                type: "readability"
            ))
        }
        
        return results
    }
    
    func analyzeMultipleFiles(_ files: [CodeFile], withAI: Bool = false) async throws -> [FileAnalysisRecord] {
        logger.log("🔍 Starting batch analysis for \(files.count) files")
        
        var results: [FileAnalysisRecord] = []
        
        for file in files {
            do {
                let record = try await analyzeFile(file, withAI: withAI)
                results.append(record)
            } catch {
                logger.log("❌ Failed to analyze \(file.name): \(error)")
                throw error
            }
        }
        
        return results
    }
    
    // MARK: - Phase 3 AI Integration Methods
    
    func performAIAnalysis(for files: [CodeFile]) async {
        guard !files.isEmpty else { return }
        
        isAIAnalyzing = true
        aiInsightsAvailable = false
        
        logger.log("🤖 Starting Phase 3 AI analysis for \(files.count) files")
        
        defer {
            isAIAnalyzing = false
        }
        
        // Get AI provider selection from UserDefaults
        let selectedProvider = UserDefaults.standard.string(forKey: "selectedAIProvider") ?? "openai"
        let apiKey: String?
        
        if selectedProvider == "gemini" {
            // Try to get from UserDefaults temporarily, then environment variable as fallback
            apiKey = UserDefaults.standard.string(forKey: "gemini_api_key") ??
                     ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
        } else {
            // Try to get from UserDefaults temporarily, then environment variable as fallback
            apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ??
                     ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        }
        
        guard let validApiKey = apiKey, !validApiKey.isEmpty else {
            let providerName = selectedProvider == "gemini" ? "Google Gemini" : "OpenAI"
            lastAIAnalysis = "# 🤖 AI Analysis Results\n\nNo API key configured for \(providerName). Please add your API key in settings."
            aiInsightsAvailable = true
            return
        }
        
        // Perform AI analysis
        var allInsights: [String] = []
        
        for file in files {
            let analysis = await performSimpleAIAnalysis(
                code: file.content,
                language: file.language,
                fileName: file.name,
                provider: selectedProvider,
                apiKey: validApiKey
            )
            
            if !analysis.isEmpty && !analysis.contains("Error:") {
                let fileInsight = "**\(file.name)** (\(file.language.displayName)):\n\(analysis)"
                allInsights.append(fileInsight)
            }
        }
        
        // Combine all insights
        if !allInsights.isEmpty {
            lastAIAnalysis = "# 🤖 AI Analysis Results (\(selectedProvider))\n\n" + allInsights.joined(separator: "\n\n")
            aiInsightsAvailable = true
            logger.log("✅ Phase 3 AI analysis completed with insights for \(allInsights.count) files using \(selectedProvider)")
        } else {
            lastAIAnalysis = "# 🤖 AI Analysis Results\n\nNo specific recommendations found. Your code looks good! 👍"
            aiInsightsAvailable = true
            logger.log("✅ Phase 3 AI analysis completed - no issues found")
        }
    }
    
    private func performSimpleAIAnalysis(code: String, language: CodeLanguage, fileName: String, provider: String, apiKey: String) async -> String {
        let prompt = "Analyze this \(language.displayName) code file '\(fileName)' and provide helpful suggestions for improvement:\n\n\(code)"
        
        if provider == "gemini" {
            return await callGeminiAPI(prompt: prompt, apiKey: apiKey)
        } else {
            return await callOpenAIAPI(prompt: prompt, apiKey: apiKey)
        }
    }
    
    private func callOpenAIAPI(prompt: String, apiKey: String) async -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return "Error: Invalid OpenAI URL"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 500,
            "temperature": 0.1
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            return "OpenAI API Error: \(error.localizedDescription)"
        }
        
        return "No response from OpenAI"
    }
    
    private func callGeminiAPI(prompt: String, apiKey: String) async -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=\(apiKey)") else {
            return "Error: Invalid Gemini URL"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 500
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            return "Gemini API Error: \(error.localizedDescription)"
        }
        
        return "No response from Gemini"
    }
    
    private func generateIntelligentSuggestions(for file: CodeFile) async -> [String] {
        // Use the same intelligent analysis logic from Phase 3 AI service
        var suggestions: [String] = []
        
        switch file.language {
        case .swift:
            suggestions.append(contentsOf: generateSwiftSuggestions(content: file.content))
        case .python:
            suggestions.append(contentsOf: generatePythonSuggestions(content: file.content))
        case .javascript, .typescript:
            suggestions.append(contentsOf: generateJavaScriptSuggestions(content: file.content))
        case .java:
            suggestions.append(contentsOf: generateJavaSuggestions(content: file.content))
        default:
            suggestions.append(contentsOf: generateGenericSuggestions(content: file.content))
        }
        
        return suggestions
    }
    
    private func generateSwiftSuggestions(content: String) -> [String] {
        var suggestions: [String] = []
        
        if content.contains("!") && !content.contains("// Force unwrap necessary") {
            suggestions.append("🔒 Consider using safe unwrapping patterns (if let, guard let) instead of force unwrapping")
        }
        
        if content.contains("@State") || content.contains("@ObservedObject") {
            suggestions.append("✨ Good use of SwiftUI property wrappers - consider @StateObject for object initialization")
        }
        
        if content.contains("async") && !content.contains("await") {
            suggestions.append("⚡ Async function detected - ensure proper await usage")
        }
        
        return suggestions
    }
    
    private func generatePythonSuggestions(content: String) -> [String] {
        var suggestions: [String] = []
        
        if !content.contains("->") && content.contains("def ") {
            suggestions.append("📝 Consider adding type hints to function definitions")
        }
        
        if content.contains(".format(") || content.contains("% ") {
            suggestions.append("🎯 Consider using f-strings for more readable string formatting")
        }
        
        return suggestions
    }
    
    private func generateJavaScriptSuggestions(content: String) -> [String] {
        var suggestions: [String] = []
        
        if content.contains("var ") {
            suggestions.append("📦 Consider using 'const' or 'let' instead of 'var' for better scoping")
        }
        
        if content.contains("function(") && !content.contains("=>") {
            suggestions.append("➡️ Consider using arrow functions for cleaner syntax")
        }
        
        return suggestions
    }
    
    private func generateJavaSuggestions(content: String) -> [String] {
        var suggestions: [String] = []
        
        if content.contains("new ArrayList<>()") {
            suggestions.append("📋 Consider using List.of() for immutable collections")
        }
        
        return suggestions
    }
    
    private func generateGenericSuggestions(content: String) -> [String] {
        var suggestions: [String] = []
        
        let lines = content.components(separatedBy: CharacterSet.newlines)
        if lines.count > 500 {
            suggestions.append("📏 Large file detected (\(lines.count) lines) - consider breaking into modules")
        }
        
        if !content.lowercased().contains("//") && !content.lowercased().contains("/*") {
            suggestions.append("📚 Consider adding comments to explain complex logic")
        }
        
        return suggestions
    }
    
    // MARK: - Enhanced Project Analysis
    
    func analyzeProject(_ project: ProjectStructure, withAI: Bool = false) async throws -> ProjectAnalysisResult {
        logger.log("🏗️ Starting project analysis for \(project.name)")
        
        let startTime = Date()
        var allAnalysisResults: [FileAnalysisRecord] = []
        
        // Analyze all files in the project
        for file in project.files {
            let record = try await analyzeFile(file, withAI: withAI)
            allAnalysisResults.append(record)
        }
        
        // Generate project-level insights
        let projectInsights = generateProjectInsights(from: allAnalysisResults, project: project)
        
        let duration = Date().timeIntervalSince(startTime)
        
        let result = ProjectAnalysisResult(
            project: project,
            fileAnalyses: allAnalysisResults,
            insights: projectInsights,
            duration: duration
        )
        
        logger.log("✅ Project analysis completed for \(project.name) in \(String(format: "%.2f", duration))s")
        
        return result
    }
    
    private func generateProjectInsights(from analyses: [FileAnalysisRecord], project: ProjectStructure) -> [ProjectInsight] {
        var insights: [ProjectInsight] = []
        
        // Language distribution analysis
        let languageStats = project.files.reduce(into: [:]) { counts, file in
            counts[file.language, default: 0] += 1
        }
        
        if languageStats.count > 3 {
            insights.append(ProjectInsight(
                type: .architecture,
                message: "Multi-language project detected (\(languageStats.count) languages). Consider language consistency for maintainability.",
                severity: .medium,
                fileCount: languageStats.values.reduce(0, +)
            ))
        }
        
        // File size analysis
        let largFiles = project.files.filter { $0.size > 10000 } // 10KB+
        if largFiles.count > project.files.count / 3 {
            insights.append(ProjectInsight(
                type: .maintainability,
                message: "Many large files detected (\(largFiles.count)/\(project.files.count)). Consider breaking into smaller modules.",
                severity: .medium,
                fileCount: largFiles.count
            ))
        }
        
        // Issue aggregation
        let allIssues = analyses.flatMap { $0.analysisResults }
        let totalIssues = allIssues.count
        let highSeverityIssues = allIssues.filter { issue in
            issue.severity == "high" || issue.severity == "critical"
        }.count
        
        if highSeverityIssues > 0 {
            insights.append(ProjectInsight(
                type: .quality,
                message: "High-priority issues found: \(highSeverityIssues) out of \(totalIssues) total issues.",
                severity: .high,
                fileCount: analyses.count
            ))
        }
        
        // Test coverage estimation (basic heuristic)
        let testFiles = project.files.filter { $0.name.lowercased().contains("test") }
        let testCoverage = Double(testFiles.count) / Double(project.files.count) * 100
        
        if testCoverage < 20 {
            insights.append(ProjectInsight(
                type: .testing,
                message: "Low test coverage estimated at \(String(format: "%.1f", testCoverage))%. Consider adding more tests.",
                severity: .medium,
                fileCount: testFiles.count
            ))
        }
        
        return insights
    }
    
    // MARK: - File Search and Filtering
    
    func searchFiles(query: String) -> [CodeFile] {
        let lowercaseQuery = query.lowercased()
        return uploadedFiles.filter { file in
            file.name.lowercased().contains(lowercaseQuery) ||
            file.content.lowercased().contains(lowercaseQuery) ||
            file.language.displayName.lowercased().contains(lowercaseQuery)
        }
    }
    
    func filterFilesByLanguage(_ language: CodeLanguage) -> [CodeFile] {
        return uploadedFiles.filter { $0.language == language }
    }
    
    func filterFilesBySize(minSize: Int = 0, maxSize: Int = Int.max) -> [CodeFile] {
        return uploadedFiles.filter { file in
            file.size >= minSize && file.size <= maxSize
        }
    }
    
    // MARK: - Export and Reporting
    
    func generateAnalysisReport(for analyses: [FileAnalysisRecord]) -> String {
        var report = "# Code Analysis Report\n\n"
        report += "Generated on: \(DateFormatter.reportFormatter.string(from: Date()))\n\n"
        
        // Summary
        let allIssues = analyses.flatMap { $0.analysisResults }
        let totalIssues = allIssues.count
        let fileCount = analyses.count
        let avgIssuesPerFile = fileCount > 0 ? Double(totalIssues) / Double(fileCount) : 0
        
        report += "## Summary\n"
        report += "- Files analyzed: \(fileCount)\n"
        report += "- Total issues found: \(totalIssues)\n"
        report += "- Average issues per file: \(String(format: "%.1f", avgIssuesPerFile))\n\n"
        
        // Issues by severity
        let issuesBySeverity = allIssues.reduce(into: [:]) { counts, item in
            counts[item.severity, default: 0] += 1
        }
        
        report += "## Issues by Severity\n"
        for (severity, count) in issuesBySeverity.sorted(by: { $0.key < $1.key }) {
            report += "- \(severity.capitalized): \(count)\n"
        }
        report += "\n"
        
        // File details
        report += "## File Details\n"
        for analysis in analyses {
            report += "### \(analysis.file.name)\n"
            report += "- Language: \(analysis.file.language.displayName)\n"
            report += "- Size: \(analysis.file.displaySize)\n"
            report += "- Issues: \(analysis.analysisResults.count)\n"
            
            if !analysis.analysisResults.isEmpty {
                report += "- Issues found:\n"
                for issue in analysis.analysisResults {
                    report += "  - [\(issue.severity.uppercased())] \(issue.message)\n"
                }
            }
            report += "\n"
        }
        
        return report
    }
    
    // MARK: - File Management
    
    func removeFile(_ file: CodeFile) {
        uploadedFiles.removeAll { $0.id == file.id }
        recentFiles.removeAll { $0.id == file.id }
        analysisHistory.removeAll { $0.file.id == file.id }
        savePersistedData()
        
        logger.log("🗑️ Removed file: \(file.name)")
    }
    
    func removeProject(_ project: ProjectStructure) {
        projects.removeAll { $0.id == project.id }
        
        // Remove associated files
        let projectFileIds = Set(project.files.map(\.id))
        uploadedFiles.removeAll { projectFileIds.contains($0.id) }
        recentFiles.removeAll { projectFileIds.contains($0.id) }
        analysisHistory.removeAll { projectFileIds.contains($0.file.id) }
        
        savePersistedData()
        
        logger.log("🗑️ Removed project: \(project.name)")
    }
    
    func clearAllFiles() {
        uploadedFiles.removeAll()
        recentFiles.removeAll()
        analysisHistory.removeAll()
        projects.removeAll()
        savePersistedData()
        
        logger.log("🗑️ Cleared all files and projects")
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
        logger.log("📝 Data persistence skipped - implement when needed")
    }
    
    private func loadPersistedData() {
        // Note: Simplified persistence - in production, consider Core Data or SQLite
        // For now, we'll skip persistence to avoid Codable complexity
        logger.log("📝 Data loading skipped - implement when needed")
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
        case .kotlin: return "Kotlin"
        case .csharp: return "C#"
        case .cpp: return "C++"
        case .c: return "C"
        case .go: return "Go"
        case .rust: return "Rust"
        case .php: return "PHP"
        case .ruby: return "Ruby"
        case .html: return "HTML"
        case .css: return "CSS"
        case .xml: return "XML"
        case .json: return "JSON"
        case .yaml: return "YAML"
        case .markdown: return "Markdown"
        case .unknown: return "Unknown"
        }
    }
    
    var iconName: String {
        switch self {
        case .swift: return "swift"
        case .python: return "snake.circle"
        case .javascript, .typescript: return "js.circle"
        case .java, .kotlin: return "cup.and.saucer"
        case .csharp: return "sharp.circle"
        case .cpp, .c: return "c.circle"
        case .go: return "goforward"
        case .rust: return "gear"
        case .php: return "network"
        case .ruby: return "gem"
        case .html: return "globe"
        case .css: return "paintbrush"
        case .xml: return "doc.text"
        case .json: return "curlybraces"
        case .yaml: return "list.bullet"
        case .markdown: return "doc.richtext"
        case .unknown: return "questionmark.circle"
        }
    }
}

extension Data {
    var sha256: String {
        let hash = SHA256.hash(data: self)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Simple Logger for File Manager

internal class FileManagerLogger {
    func log(_ message: String, file: String = #file, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("[\(timestamp)] [\(fileName):\(line)] \(message)")
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    static let reportFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy 'at' HH:mm:ss"
        return formatter
    }()
}

// Simple logger for FileManagerService
struct SimpleLogger {
    func log(_ message: String) {
        print("FileManagerService: \(message)")
    }
}
