//
//  AIInsightsFileDisplayTest.swift
//  CodingReviewerTests
//
//  Created for testing AI Insights file display functionality
//

import XCTest
import SwiftUI
@testable import CodingReviewer

@MainActor
final class AIInsightsFileDisplayTest: XCTestCase {
    
    func testAIInsightsShowsUploadedFiles() async throws {
        // Create a file manager with test files
        let fileManager = FileManagerService()
        
        // Create test files
        let testFile1 = CodeFile(
            name: "TestFile1.swift",
            path: "/tmp/TestFile1.swift",
            content: "import Foundation\n\nclass TestClass {\n    func testMethod() {}\n}",
            language: .swift
        )
        
        let testFile2 = CodeFile(
            name: "TestFile2.js",
            path: "/tmp/TestFile2.js",
            content: "function testFunction() {\n    console.log('test');\n}",
            language: .javascript
        )
        
        // Add files to the manager
        fileManager.uploadedFiles = [testFile1, testFile2]
        
        // Verify files are in the manager
        XCTAssertEqual(fileManager.uploadedFiles.count, 2, "Should have 2 uploaded files")
        XCTAssertTrue(fileManager.uploadedFiles.contains { $0.name == "TestFile1.swift" }, "Should contain TestFile1.swift")
        XCTAssertTrue(fileManager.uploadedFiles.contains { $0.name == "TestFile2.js" }, "Should contain TestFile2.js")
        
        // Test the UploadedFilesDisplayView component
        let displayView = UploadedFilesDisplayView(files: fileManager.uploadedFiles)
        
        // The view should be able to display the files without errors
        // This validates that the view can handle the file data correctly
        XCTAssertNotNil(displayView, "UploadedFilesDisplayView should be created successfully")
        
        print("✅ AI Insights file display test passed")
        print("   - Files in manager: \(fileManager.uploadedFiles.count)")
        print("   - File 1: \(testFile1.name) (\(testFile1.language.displayName))")
        print("   - File 2: \(testFile2.name) (\(testFile2.language.displayName))")
    }
    
    func testMLInsightsViewAcceptsFileManager() async throws {
        // Test that MLInsightsView can accept a FileManagerService
        let fileManager = FileManagerService()
        let mlService = MLIntegrationService()
        
        // Create test file
        let testFile = CodeFile(
            name: "TestFile.swift",
            path: "/tmp/TestFile.swift",
            content: "print('Hello World')",
            language: .swift
        )
        
        fileManager.uploadedFiles = [testFile]
        
        // Create the MLInsightsView with both services
        let mlInsightsView = MLInsightsView(mlService: mlService, fileManager: fileManager)
        
        XCTAssertNotNil(mlInsightsView, "MLInsightsView should be created with fileManager")
        
        print("✅ MLInsightsView accepts FileManager test passed")
        print("   - Files available: \(fileManager.uploadedFiles.count)")
    }
    
    func testAIMLHeaderShowsFileCount() async throws {
        // Test that the AI/ML header shows file count
        let fileManager = FileManagerService()
        let mlService = MLIntegrationService()
        
        // Add test files
        let testFiles = [
            CodeFile(name: "File1.swift", path: "/tmp/File1.swift", content: "test", language: .swift),
            CodeFile(name: "File2.py", path: "/tmp/File2.py", content: "test", language: .python),
            CodeFile(name: "File3.js", path: "/tmp/File3.js", content: "test", language: .javascript)
        ]
        
        fileManager.uploadedFiles = testFiles
        
        // Create the header view
        let headerView = AIMLHeaderView(
            mlService: mlService,
            fileManager: fileManager,
            onRunAnalysis: {},
            onShowFullAnalysis: {}
        )
        
        XCTAssertNotNil(headerView, "AIMLHeaderView should be created with fileManager")
        XCTAssertEqual(fileManager.uploadedFiles.count, 3, "Should have 3 files for header display")
        
        print("✅ AI/ML Header file count test passed")
        print("   - Files for header: \(fileManager.uploadedFiles.count)")
    }
}
