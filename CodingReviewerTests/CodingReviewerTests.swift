//
//  CodingReviewerTests.swift
//  CodingReviewerTests
//
//  Created by Daniel Stevens on 7/16/25.
//

@testable import CodingReviewer
import XCTest

final class CodingReviewerTests: XCTestCase {
    @MainActor
    /// <#Description#>
    /// - Returns: <#description#>
    func testAppInitialization() async throws {
        // Test that the app initializes without crashing
        let app = CodingReviewerApp()
        XCTAssertNotNil(app, "App should initialize successfully")
    }

    @MainActor
    /// <#Description#>
    /// - Returns: <#description#>
    func testCodeLanguageDetection() async throws {
        // Test language detection from file extensions
        XCTAssertEqual(CodeLanguage.swift.displayName, "Swift")
        XCTAssertEqual(CodeLanguage.python.displayName, "Python")
        XCTAssertEqual(CodeLanguage.javascript.displayName, "JavaScript")

        // Test icon names are valid
        XCTAssertEqual(CodeLanguage.swift.iconName, "swift")
        XCTAssertEqual(CodeLanguage.python.iconName, "snake.circle")
    }

    @MainActor
    /// <#Description#>
    /// - Returns: <#description#>
    func testCodeFileInitialization() async throws {
        let testContent = "print('Hello, World!')"
        let file = CodeFile(
            name: "test.py",
            path: "/test/test.py",
            content: testContent,
            language: .python
        )

        XCTAssertEqual(file.name, "test.py")
        XCTAssertEqual(file.content, testContent)
        XCTAssertEqual(file.language, .python)
        XCTAssertEqual(file.size, testContent.utf8.count)
        XCTAssertEqual(file.fileExtension, "py")
    }

    @MainActor
    /// <#Description#>
    /// - Returns: <#description#>
    func testEnhancedAnalysisItemCreation() async throws {
        let enhancedItem = EnhancedAnalysisItem(
            message: "Test security issue",
            severity: "high",
            lineNumber: 10,
            type: "security"
        )

        XCTAssertEqual(enhancedItem.message, "Test security issue")
        XCTAssertEqual(enhancedItem.severity, "high")
        XCTAssertEqual(enhancedItem.lineNumber, 10)
        XCTAssertEqual(enhancedItem.type, "security")
    }

    @MainActor
    /// <#Description#>
    /// - Returns: <#description#>
    func testFileManagerServiceInitialization() async throws {
        let fileManager = FileManagerService()
        XCTAssertNotNil(fileManager, "FileManagerService should initialize")
        XCTAssertEqual(fileManager.uploadedFiles.count, 0, "Should start with no uploaded files")
        XCTAssertEqual(fileManager.projects.count, 0, "Should start with no projects")
    }
}
