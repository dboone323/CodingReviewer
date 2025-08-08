//
//  FileManagerServiceTestsSimple.swift
//  CodingReviewerTests
//
//  Swift 6 Compatible version
//

import XCTest
@testable import CodingReviewer

final class FileManagerServiceTestsSimple: XCTestCase {
    
    func testFileManagerInitialization() async throws {
        let fileManager = await FileManagerService()
        XCTAssertNotNil(fileManager)
        let uploadedFiles = await fileManager.uploadedFiles
        let analysisHistory = await fileManager.analysisHistory
        let isUploading = await fileManager.isUploading
        let uploadProgress = await fileManager.uploadProgress
        
        XCTAssertTrue(uploadedFiles.isEmpty)
        XCTAssertTrue(analysisHistory.isEmpty)
        XCTAssertFalse(isUploading)
        XCTAssertEqual(uploadProgress, 0.0)
    }
    
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
}
