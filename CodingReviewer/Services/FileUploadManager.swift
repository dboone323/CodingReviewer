import OSLog
//
// FileUploadManager.swift
// CodingReviewer
//
// Extracted from FileManagerService - Focused file upload operations
// Created on July 27, 2025
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine

// MARK: - File Upload Error Types

enum FileUploadError: LocalizedError {
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

// MARK: - File Upload Configuration

struct FileUploadConfiguration {
    let maxFileSize: Int
    let maxFilesPerUpload: Int
    let supportedFileTypes: Set<String>

    nonisolated static let `default` = FileUploadConfiguration(
        maxFileSize: 10 * 1024 * 1024, // 10MB
        maxFilesPerUpload: 1000, // Increased from 100 to 1000 for large projects
        supportedFileTypes: [
            "swift", "py", "js", "ts", "java", "cpp", "c", "h", "hpp",
            "go", "rs", "php", "rb", "cs", "kt", "scala", "m", "mm",
            "html", "css", "scss", "less", "xml", "json", "yaml", "yml",
            "md", "txt", "sh", "bash", "zsh", "fish", "ps1", "bat"
        ]
    )
}

// MARK: - Simple File Data Structure

struct FileData {
    let name: String
    let path: String
    let content: String
    let fileExtension: String
    let size: Int

    init(name: String, path: String, content: String) {
        self.name = name
        self.path = path
        self.content = content
        self.fileExtension = URL(fileURLWithPath: name).pathExtension.lowercased()
        self.size = content.utf8.count
    }

    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

struct SimpleUploadResult {
    let successfulFiles: [FileData]
    let failedFiles: [(String, Error)]
    let warnings: [String]

    var hasErrors: Bool { !failedFiles.isEmpty }
    var hasWarnings: Bool { !warnings.isEmpty }
}

// MARK: - File Upload Manager

@MainActor
class FileUploadManager: ObservableObject {
    @Published var isUploading: Bool = false;
    @Published var uploadProgress: Double = 0.0;
    @Published var errorMessage: String?

    private let configuration: FileUploadConfiguration
    private let logger = FileUploadLogger()

    init(configuration: FileUploadConfiguration = .default) {
        self.configuration = configuration
    }

    // MARK: - Main Upload Methods

    func uploadFiles(from urls: [URL]) async throws -> SimpleUploadResult {
        await logger.log("📁 Starting file upload for \(urls.count) items")

        await MainActor.run {
            isUploading = true
            uploadProgress = 0.0
            errorMessage = nil
        }

        defer {
            Task { @MainActor in
                isUploading = false
                uploadProgress = 0.0
            }
        }

        var successfulFiles: [FileData] = [];
        var failedFiles: [(String, Error)] = [];
        var warnings: [String] = [];

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
                await logger.log("❌ Failed to upload \(url.lastPathComponent): \(error)")
            }

            await MainActor.run {
                uploadProgress = Double(index + 1) / Double(totalFiles)
            }
        }

        let result = SimpleUploadResult(
            successfulFiles: successfulFiles,
            failedFiles: failedFiles,
            warnings: warnings
        )

        await logger.log("📁 Upload completed: \(successfulFiles.count) successful, \(failedFiles.count) failed")

        return result
    }

    // MARK: - Private Upload Methods

    private func uploadSingleFile(from url: URL) async throws -> FileData {
        // Check file access - be more lenient with security scoped resource access
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Validate file
        try await validateFile(at: url)

        // Read file content with multiple encoding attempts
        let content = try readFileContent(from: url)

        // Create FileData
        let file = FileData(
            name: url.lastPathComponent,
            path: url.path,
            content: content
        )

        await logger.log("📄 Uploaded file: \(file.name) (\(file.displaySize))")

        return file
    }

    private func uploadDirectory(at url: URL) async throws -> SimpleUploadResult {
        await logger.log("📁 Scanning directory: \(url.lastPathComponent)")

        var successfulFiles: [FileData] = [];
        var failedFiles: [(String, Error)] = [];
        var warnings: [String] = [];

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
            errorHandler: { fileURL, error in
                // Cannot use await in closure, use sync logging
                os_log("%@", "⚠️ Enumeration error for \(fileURL.lastPathComponent): \(error)")
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
                        let file = try await uploadSingleFile(from: fileURL)
                        successfulFiles.append(file)
                    } catch {
                        failedFiles.append((fileURL.lastPathComponent, error))
                    }
                }
            } catch {
                throw FileUploadError.directoryEnumerationFailed(url.path)
            }

            return SimpleUploadResult(successfulFiles: successfulFiles, failedFiles: failedFiles, warnings: warnings)
        }

        // Enumerate through directory - convert to array first to avoid async issues
        var fileCount = 0;
        let enumeratorArray = enumerator.allObjects as! [URL]

        for fileURL in enumeratorArray {
            // Stop if we exceed max files
            guard fileCount < configuration.maxFilesPerUpload else {
                warnings.append("Directory contains more than \(configuration.maxFilesPerUpload) files. Some files were skipped.")
                break
            }

            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])

                if resourceValues.isRegularFile == true {
                    let file = try await uploadSingleFile(from: fileURL)
                    successfulFiles.append(file)
                    fileCount += 1
                }
            } catch {
                failedFiles.append((fileURL.lastPathComponent, error))
                await logger.log("❌ Failed to process file in directory: \(fileURL.lastPathComponent) - \(error)")
            }
        }

        return SimpleUploadResult(successfulFiles: successfulFiles, failedFiles: failedFiles, warnings: warnings)
    }

    // MARK: - File Validation

    private func validateFile(at url: URL) async throws {
        let resourceValues = try url.resourceValues(forKeys: [
            .isRegularFileKey,
            .fileSizeKey,
            .isReadableKey
        ])

        // Check if it's a regular file
        guard resourceValues.isRegularFile == true else {
            throw FileUploadError.notARegularFile(url.lastPathComponent)
        }

        // Check readability
        guard resourceValues.isReadable == true else {
            throw FileUploadError.accessDenied(url.lastPathComponent)
        }

        // Check file size
        if let fileSize = resourceValues.fileSize, fileSize > configuration.maxFileSize {
            throw FileUploadError.fileTooLarge(url.lastPathComponent, fileSize, configuration.maxFileSize)
        }

        // Check file type (optional - we can be more lenient)
        let fileExtension = url.pathExtension.lowercased()
        if !fileExtension.isEmpty && !configuration.supportedFileTypes.contains(fileExtension) {
            await logger.log("⚠️ Uploading unsupported file type: .\(fileExtension)")
            // Don't throw error, just log warning
        }
    }

    // MARK: - Content Reading

    private func readFileContent(from url: URL) throws -> String {
        // Try UTF-8 first
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            // Try other encodings
            do {
                return try String(contentsOf: url, encoding: .ascii)
            } catch {
                do {
                    return try String(contentsOf: url, encoding: .utf16)
                } catch {
                    // Last resort: read as data and convert what we can
                    let data = try Data(contentsOf: url)
                    let content = String(data: data, encoding: .utf8) ??
                                 String(data: data, encoding: .ascii) ??
                                 "// Unable to decode file content"

                    if content == "// Unable to decode file content" {
                        throw FileUploadError.encodingError(url.lastPathComponent)
                    }

                    return content
                }
            }
        }
    }

    // MARK: - Utility Methods

    func getSupportedFileTypes() -> Set<String> {
        configuration.supportedFileTypes
    }

    func getMaxFileSize() -> Int {
        configuration.maxFileSize
    }

    func validateFileTypeSupported(extension fileExtension: String) -> Bool {
        configuration.supportedFileTypes.contains(fileExtension.lowercased())
    }
}

// MARK: - File Upload Logger

private class FileUploadLogger {
    func log(_ message: String, file: String = #file, line: Int = #line) async {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.uploadLogFormatter.string(from: Date())
        os_log("%@", "[\(timestamp)] [\(fileName):\(line)] [FileUpload] \(message)")
    }
}

extension DateFormatter {
    fileprivate static let uploadLogFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
