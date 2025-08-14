//
// FileMetadataService.swift
// CodingReviewer
//
// File metadata analysis and management

import Foundation

// CoreDataTypes is automatically available in the same target

/// Manages file metadata and analysis information
class FileMetadataService {
    static let shared = FileMetadataService()
    private init() {}

    /// Extracts comprehensive metadata from file
            /// Function description
            /// - Returns: Return value description
    func extractMetadata(from filePath: String) -> FileMetadata {
        let fileURL = URL(fileURLWithPath: filePath)
        let filename = fileURL.lastPathComponent
        let fileExtension = fileURL.pathExtension

        var metadata = FileMetadata(
            filename: filename,
            path: filePath,
            fileExtension: fileExtension,
            size: getFileSize(at: filePath),
            creationDate: getCreationDate(at: filePath),
            modificationDate: getModificationDate(at: filePath),
            language: detectLanguage(from: fileExtension),
            lineCount: getLineCount(at: filePath),
            characterCount: getCharacterCount(at: filePath)
        )

        // Add code-specific metadata
        if isCodeFile(fileExtension: fileExtension) {
            metadata.codeMetadata = extractCodeMetadata(from: filePath)
        }

        return metadata
    }

    /// Detects programming language from file extension
            /// Function description
            /// - Returns: Return value description
    func detectLanguage(from fileExtension: String) -> ProgrammingLanguage {
        switch fileExtension.lowercased() {
        case "swift": .swift
        case "m", "mm": .objectiveC
        case "h", "hpp": .cPlusPlus
        case "cpp", "cc", "cxx": .cPlusPlus
        case "c": .c
        case "js": .javascript
        case "ts": .typescript
        case "py": .python
        case "java": .java
        case "kt": .kotlin
        case "go": .go
        case "rs": .rust
        default: .unknown
        }
    }

    /// Extracts code-specific metadata
    private func extractCodeMetadata(from filePath: String) -> CodeMetadata? {
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else { return nil }

        let lines = content.components(separatedBy: .newlines)

        var functionCount = 0
        var classCount = 0
        var commentLines = 0
        var imports: [String] = []

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.hasPrefix("func ") || trimmedLine.contains(" func ") {
                functionCount += 1
            }

            if trimmedLine.hasPrefix("class ") || trimmedLine.hasPrefix("struct ") || trimmedLine.hasPrefix("enum ") {
                classCount += 1
            }

            if trimmedLine.hasPrefix("//") || trimmedLine.hasPrefix("/*") || trimmedLine.hasPrefix("*") {
                commentLines += 1
            }

            if trimmedLine.hasPrefix("import ") {
                let importName = String(trimmedLine.dropFirst(7))
                imports.append(importName)
            }
        }

        return CodeMetadata(
            functionCount: functionCount,
            classCount: classCount,
            commentLines: commentLines,
            imports: imports,
            complexity: calculateComplexity(content: content)
        )
    }

    /// Calculates basic code complexity
    private func calculateComplexity(content: String) -> Int {
        let complexityKeywords = ["if", "else", "for", "while", "switch", "case", "catch", "guard"]
        var complexity = 1 // Base complexity

        for keyword in complexityKeywords {
            complexity += content.components(separatedBy: keyword).count - 1
        }

        return complexity
    }

    /// Gets file size in bytes
    private func getFileSize(at path: String) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    /// Gets file creation date
    private func getCreationDate(at path: String) -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.creationDate] as? Date
        } catch {
            return nil
        }
    }

    /// Gets file modification date
    private func getModificationDate(at path: String) -> Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }

    /// Gets line count
    private func getLineCount(at path: String) -> Int {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return 0 }
        return content.components(separatedBy: .newlines).count
    }

    /// Gets character count
    private func getCharacterCount(at path: String) -> Int {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return 0 }
        return content.count
    }

    /// Checks if file is a code file
    private func isCodeFile(fileExtension: String) -> Bool {
        let codeExtensions = ["swift", "m", "mm", "h", "hpp", "cpp", "c", "js", "ts", "py", "java", "kt", "go", "rs"]
        return codeExtensions.contains(fileExtension.lowercased())
    }
}

/// File metadata structure
struct FileMetadata {
    let filename: String
    let path: String
    let fileExtension: String
    let size: Int64
    let creationDate: Date?
    let modificationDate: Date?
    let language: ProgrammingLanguage
    let lineCount: Int
    let characterCount: Int
    var codeMetadata: CodeMetadata?
}

/// Code-specific metadata
struct CodeMetadata {
    let functionCount: Int
    let classCount: Int
    let commentLines: Int
    let imports: [String]
    let complexity: Int
}

/// Programming language enumeration - now imported from CoreDataTypes.swift
// ProgrammingLanguage is imported from CoreDataTypes

// Extension for service-specific functionality
extension ProgrammingLanguage {
    var objectiveCAlias: String {
        "Objective-C"
    }
}
