//
//  FileManagerServiceTests.swift
//  CodingReviewerTests
//
//  Created by AI Assistant on 7/18/25.
//

@testable import CodingReviewer
import XCTest

@MainActor
final class FileManagerServiceTests: XCTestCase {
    var fileManagerService: FileManagerService!

    override func setUp() async throws {
        try await super.setUp()
        fileManagerService = FileManagerService()
    }

    override func tearDown() async throws {
        fileManagerService = nil
        try await super.tearDown()
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testFileManagerInitialization() async throws {
        XCTAssertNotNil(fileManagerService)
        XCTAssertTrue(fileManagerService.uploadedFiles.isEmpty)
        XCTAssertTrue(fileManagerService.analysisHistory.isEmpty)
        XCTAssertTrue(fileManagerService.projects.isEmpty)
        XCTAssertFalse(fileManagerService.isUploading)
        XCTAssertEqual(fileManagerService.uploadProgress, 0.0)
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testCodeFileCreation() async throws {
        let testContent = "print('Hello, World!')"
        let codeFile = CodeFile(
            name: "test.py",
            path: "/test/test.py",
            content: testContent,
            language: .python
        )

        XCTAssertEqual(codeFile.name, "test.py")
        XCTAssertEqual(codeFile.content, testContent)
        XCTAssertEqual(codeFile.language, .python)
        XCTAssertEqual(codeFile.size, testContent.utf8.count)
        XCTAssertEqual(codeFile.fileExtension, "py")
        XCTAssertFalse(codeFile.checksum.isEmpty)
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testProjectStructureCreation() async throws {
        let file1 = CodeFile(
            name: "main.swift",
            path: "/project/main.swift",
            content: "print(\"Hello\")",
            language: .swift
        )

        let file2 = CodeFile(
            name: "utils.swift",
            path: "/project/utils.swift",
            content: "func utility() {}",
            language: .swift
        )

        let files = [file1, file2]
        let project = ProjectStructure(
            name: "TestProject",
            rootPath: "/project",
            files: files
        )

        XCTAssertEqual(project.name, "TestProject")
        XCTAssertEqual(project.rootPath, "/project")
        XCTAssertEqual(project.files.count, 2)
        XCTAssertEqual(project.fileCount, 2)
        XCTAssertTrue(project.totalSize > 0)
        XCTAssertTrue(project.languageDistribution.keys.contains("Swift"))
        XCTAssertEqual(project.languageDistribution["Swift"], 2)
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testFileAnalysisRecord() async throws {
        let testFile = CodeFile(
            name: "test.swift",
            path: "/test.swift",
            content: "let x = 5",
            language: .swift
        )

        let analysisResult = EnhancedAnalysisItem(
            message: "Test issue",
            severity: "medium",
            lineNumber: 1,
            type: "quality"
        )

        let record = FileAnalysisRecord(
            file: testFile,
            analysisResults: [analysisResult],
            aiAnalysisResult: nil,
            duration: 0.5
        )

        XCTAssertEqual(record.file.name, "test.swift")
        XCTAssertEqual(record.analysisResults.count, 1)
        XCTAssertEqual(record.analysisResults.first?.message, "Test issue")
        XCTAssertEqual(record.duration, 0.5)
        XCTAssertNil(record.aiAnalysisResult)
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testFileUploadResult() async throws {
        let successfulFile = CodeFile(
            name: "success.swift",
            path: "/success.swift",
            content: "// Success",
            language: .swift
        )

        let error = FileManagerError.fileTooLarge("large.txt", 1_000_000, 500_000)

        let result = FileUploadResult(
            successfulFiles: [successfulFile],
            failedFiles: [("large.txt", error)],
            warnings: ["Warning: File was modified during upload"]
        )

        XCTAssertEqual(result.successfulFiles.count, 1)
        XCTAssertEqual(result.failedFiles.count, 1)
        XCTAssertTrue(result.hasErrors)
        XCTAssertTrue(result.hasWarnings)
        XCTAssertEqual(result.warnings.count, 1)
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testFileManagerError() async throws {
        let error = FileManagerError.fileTooLarge("test.txt", 1_000_000, 500_000)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("test.txt"))
        XCTAssertTrue(error.errorDescription!.contains("too large"))

        let accessError = FileManagerError.accessDenied("private.txt")
        XCTAssertTrue(accessError.errorDescription!.contains("Access denied"))

        let encodingError = FileManagerError.encodingError("binary.dat")
        XCTAssertTrue(encodingError.errorDescription!.contains("encoding error"))
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testRemoveFile() async throws {
        let testFile = CodeFile(
            name: "remove_test.swift",
            path: "/remove_test.swift",
            content: "// To be removed",
            language: .swift
        )

        // Add file to uploaded files
        fileManagerService.uploadedFiles.append(testFile)
        XCTAssertEqual(fileManagerService.uploadedFiles.count, 1)

        // Remove file
        fileManagerService.removeFile(testFile)
        XCTAssertEqual(fileManagerService.uploadedFiles.count, 0)
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testClearAllFiles() async throws {
        let testFile = CodeFile(
            name: "clear_test.swift",
            path: "/clear_test.swift",
            content: "// To be cleared",
            language: .swift
        )

        // Add some test data
        fileManagerService.uploadedFiles.append(testFile)
        fileManagerService.recentFiles.append(testFile)

        XCTAssertEqual(fileManagerService.uploadedFiles.count, 1)
        XCTAssertEqual(fileManagerService.recentFiles.count, 1)

        // Clear all files
        fileManagerService.clearAllFiles()

        XCTAssertTrue(fileManagerService.uploadedFiles.isEmpty)
        XCTAssertTrue(fileManagerService.recentFiles.isEmpty)
        XCTAssertTrue(fileManagerService.analysisHistory.isEmpty)
        XCTAssertTrue(fileManagerService.projects.isEmpty)
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testCodeLanguageExtension() async throws {
        // Test language display names
        XCTAssertEqual(CodeLanguage.swift.displayName, "Swift")
        XCTAssertEqual(CodeLanguage.python.displayName, "Python")
        XCTAssertEqual(CodeLanguage.javascript.displayName, "JavaScript")

        // Test language icon names
        XCTAssertEqual(CodeLanguage.swift.iconName, "swift")
        XCTAssertEqual(CodeLanguage.python.iconName, "snake.circle")
        XCTAssertEqual(CodeLanguage.javascript.iconName, "js.circle")
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testAnalysisFile() async throws {
        let testFile = CodeFile(
            name: "analysis_test.swift",
            path: "/analysis_test.swift",
            content: "let example = \"test\"",
            language: .swift
        )

        // Test file analysis without AI
        do {
            let record = try await fileManagerService.analyzeFile(testFile, withAI: false)
            XCTAssertEqual(record.file.name, "analysis_test.swift")
            XCTAssertNotNil(record.analysisResults)
            XCTAssertNil(record.aiAnalysisResult)
            XCTAssertTrue(record.duration >= 0)
        } catch {
            XCTFail("File analysis should not throw: \(error)")
        }
    }

    // MARK: - Folder Upload Tests

    /// <#Description#>
    /// - Returns: <#description#>
    func testFolderUploadFromTestDirectory() async throws {
        // Get the test directory URL
        let testFolderURL = URL(fileURLWithPath: "/Users/danielstevens/Desktop/CodingReviewer/TestFiles")

        // Verify test directory exists and has files
        let fileManager = Foundation.FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: testFolderURL.path), "TestFiles directory should exist")

        // Test folder upload
        do {
            let result = try await fileManagerService.uploadFiles(from: [testFolderURL])

            // Verify upload results
            XCTAssertFalse(result.hasErrors, "Folder upload should not have errors")
            XCTAssertTrue(
                result.successfulFiles.count >= 3,
                "Should upload at least 3 files (sample.swift, sample.py, sample.js)"
            )

            // Check that files were added to uploaded files
            XCTAssertTrue(fileManagerService.uploadedFiles.count >= 3, "Should have at least 3 uploaded files")

            // Check that a project was created
            XCTAssertEqual(fileManagerService.projects.count, 1, "Should create one project for the folder")

            let project = fileManagerService.projects.first!
            XCTAssertEqual(project.name, "TestFiles")
            XCTAssertTrue(project.files.count >= 3)
            XCTAssertTrue(project.totalSize > 0)

            // Verify language detection worked
            let languages = Set(project.files.map(\.language))
            XCTAssertTrue(languages.contains(.swift), "Should detect Swift files")
            XCTAssertTrue(languages.contains(.python), "Should detect Python files")
            XCTAssertTrue(languages.contains(.javascript), "Should detect JavaScript files")

        } catch {
            XCTFail("Folder upload should not throw: \(error)")
        }
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testUploadDirectoryStructure() async throws {
        let testFile1 = CodeFile(
            name: "main.swift",
            path: "/project/main.swift",
            content: "import Foundation\nprint(\"Hello, World!\")",
            language: .swift
        )

        let testFile2 = CodeFile(
            name: "utils.py",
            path: "/project/utils.py",
            content: "def hello():\n    print('Hello from Python')",
            language: .python
        )

        // Simulate directory upload by adding files manually
        fileManagerService.uploadedFiles.append(contentsOf: [testFile1, testFile2])

        // Create project structure
        let project = ProjectStructure(
            name: "TestProject",
            rootPath: "/project",
            files: [testFile1, testFile2]
        )
        fileManagerService.projects.append(project)

        // Verify project structure
        XCTAssertEqual(fileManagerService.projects.count, 1)
        XCTAssertEqual(project.files.count, 2)
        XCTAssertEqual(project.fileCount, 2)
        XCTAssertTrue(project.folders.count >= 1) // At least one folder

        // Test language distribution
        XCTAssertTrue(project.languageDistribution.keys.contains("Swift"))
        XCTAssertTrue(project.languageDistribution.keys.contains("Python"))
        XCTAssertEqual(project.languageDistribution["Swift"], 1)
        XCTAssertEqual(project.languageDistribution["Python"], 1)
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testRemoveProject() async throws {
        let testFile = CodeFile(
            name: "project_test.swift",
            path: "/project_test.swift",
            content: "// Test project file",
            language: .swift
        )

        // Create and add project
        let project = ProjectStructure(
            name: "TestProject",
            rootPath: "/test",
            files: [testFile]
        )

        fileManagerService.uploadedFiles.append(testFile)
        fileManagerService.projects.append(project)

        XCTAssertEqual(fileManagerService.projects.count, 1)
        XCTAssertEqual(fileManagerService.uploadedFiles.count, 1)

        // Remove project
        fileManagerService.removeProject(project)

        // Verify project and associated files are removed
        XCTAssertEqual(fileManagerService.projects.count, 0)
        XCTAssertEqual(fileManagerService.uploadedFiles.count, 0)
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testBatchFileAnalysis() async throws {
        let files = [
            CodeFile(
                name: "test1.swift",
                path: "/test1.swift",
                content: "let x = 1",
                language: .swift
            ),
            CodeFile(
                name: "test2.py",
                path: "/test2.py",
                content: "x = 1",
                language: .python
            ),
        ]

        do {
            let records = try await fileManagerService.analyzeMultipleFiles(files, withAI: false)

            XCTAssertEqual(records.count, 2)
            XCTAssertEqual(records[0].file.name, "test1.swift")
            XCTAssertEqual(records[1].file.name, "test2.py")

            // Verify analysis records were added to history
            XCTAssertEqual(fileManagerService.analysisHistory.count, 2)

        } catch {
            XCTFail("Batch analysis should not throw: \(error)")
        }
    }
}
