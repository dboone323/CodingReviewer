//
// FileOperationsService.swift
// CodingReviewer
//
// File operations and management

import Foundation

/// Manages file operations and validation
class FileOperationsService {
    
    static let shared = FileOperationsService()
    private init() {}
    
    /// Validates file before processing
    func validateFile(at path: String) throws -> FileValidationResult {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: path) else {
            throw FileError.fileNotFound
        }
        
        // Check if file is readable
        guard FileManager.default.isReadableFile(atPath: path) else {
            throw FileError.readError("File is not readable")
        }
        
        // Additional validation can be added here
        return FileValidationResult(isValid: true, errors: [])
    }
    
    /// Reads file content safely
    func readFile(at path: String) throws -> String {
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            return content
        } catch {
            throw FileError.readError(error.localizedDescription)
        }
    }
    
    /// Writes content to file safely
    func writeFile(content: String, to path: String) throws {
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw FileError.writeError(error.localizedDescription)
        }
    }
    
    /// Creates directory if it doesn't exist
    func createDirectoryIfNeeded(at path: String) throws {
        let directoryPath = (path as NSString).deletingLastPathComponent
        
        if !FileManager.default.fileExists(atPath: directoryPath) {
            try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    /// Moves file from source to destination
    func moveFile(from sourcePath: String, to destinationPath: String) throws {
        do {
            try createDirectoryIfNeeded(at: destinationPath)
            try FileManager.default.moveItem(atPath: sourcePath, toPath: destinationPath)
        } catch {
            throw FileError.writeError("Failed to move file: \(error.localizedDescription)")
        }
    }
    
    /// Copies file from source to destination
    func copyFile(from sourcePath: String, to destinationPath: String) throws {
        do {
            try createDirectoryIfNeeded(at: destinationPath)
            try FileManager.default.copyItem(atPath: sourcePath, toPath: destinationPath)
        } catch {
            throw FileError.writeError("Failed to copy file: \(error.localizedDescription)")
        }
    }
    
    /// Deletes file at path
    func deleteFile(at path: String) throws {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            throw FileError.writeError("Failed to delete file: \(error.localizedDescription)")
        }
    }
}

/// File validation result
struct FileValidationResult {
    let isValid: Bool
    let errors: [String]
}

/// File operation errors
enum FileError: Error {
    case fileNotFound
    case readError(String)
    case writeError(String)
    case validationError(String)
    
    var localizedDescription: String {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .readError(let message):
            return "Read error: \(message)"
        case .writeError(let message):
            return "Write error: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        }
    }
}
