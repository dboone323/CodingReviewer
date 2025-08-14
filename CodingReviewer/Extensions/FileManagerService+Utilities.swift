//
// FileManagerService+Utilities.swift
// CodingReviewer
//
// Utility extensions for FileManagerService

import Foundation

extension FileManagerService {
    /// Utility methods for file validation
            /// Function description
            /// - Returns: Return value description
    func validateFileExtension(_ filename: String) -> Bool {
        let supportedExtensions = ["swift", "m", "h", "cpp", "hpp", "c", "js", "ts", "py", "java"]
        let fileExtension = (filename as NSString).pathExtension.lowercased()
        return supportedExtensions.contains(fileExtension)
    }

    /// Utility method for file size checking
            /// Function description
            /// - Returns: Return value description
    func getFileSize(at path: String) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    /// Utility method for directory operations
            /// Function description
            /// - Returns: Return value description
    func ensureDirectoryExists(at path: String) throws {
        if !FileManager.default.fileExists(atPath: path) {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        }
    }
}
