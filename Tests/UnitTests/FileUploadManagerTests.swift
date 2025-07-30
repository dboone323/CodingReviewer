import XCTest
import Foundation
@testable import CodingReviewer

final class FileUploadManagerTests: XCTestCase {
    
    var fileUploadManager: FileUploadManager!
    var tempDirectory: URL!
    
    override func setUp() throws {
        fileUploadManager = FileUploadManager()
        
        // Create temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() throws {
        // Clean up temporary directory
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        fileUploadManager = nil
        tempDirectory = nil
    }
    
    // MARK: - File Limit Tests
    
    func testFileLimitConfiguration() throws {
        let config = FileUploadConfiguration.default
        XCTAssertEqual(config.maxFilesPerUpload, 1000, "File limit should be 1000")
        XCTAssertGreaterThan(config.maxFilesPerUpload, 100, "File limit should be increased from 100")
    }
    
    func testFileLimitValidation() throws {
        let config = FileUploadConfiguration.default
        
        // Test within limit
        let validFileCount = 500
        XCTAssertTrue(validFileCount <= config.maxFilesPerUpload, "500 files should be within limit")
        
        // Test at limit
        let atLimitFileCount = 1000
        XCTAssertTrue(atLimitFileCount <= config.maxFilesPerUpload, "1000 files should be at limit")
        
        // Test beyond limit
        let beyondLimitFileCount = 1001
        XCTAssertFalse(beyondLimitFileCount <= config.maxFilesPerUpload, "1001 files should exceed limit")
    }
    
    // MARK: - File Upload Tests
    
    func testSingleFileUpload() async throws {
        // Create test file
        let testFile = tempDirectory.appendingPathComponent("test.swift")
        let testContent = "// Test Swift file\nprint(\"Hello, World!\")"
        try testContent.write(to: testFile, atomically: true, encoding: .utf8)
        
        let result = try await fileUploadManager.uploadFiles(from: [testFile])
        
        XCTAssertEqual(result.count, 1, "Should upload one file")
        XCTAssertEqual(result.first?.name, "test.swift", "File name should be preserved")
        XCTAssertEqual(result.first?.content, testContent, "File content should be preserved")
        XCTAssertEqual(result.first?.language, .swift, "Swift file should be detected")
    }
    
    func testMultipleFileUpload() async throws {
        var testFiles: [URL] = []
        
        // Create multiple test files
        for i in 1...10 {
            let fileName = "test\(i).swift"
            let testFile = tempDirectory.appendingPathComponent(fileName)
            let testContent = "// Test file \(i)\nprint(\"Test \(i)\")"
            try testContent.write(to: testFile, atomically: true, encoding: .utf8)
            testFiles.append(testFile)
        }
        
        let result = try await fileUploadManager.uploadFiles(from: testFiles)
        
        XCTAssertEqual(result.count, 10, "Should upload all 10 files")
        
        for i in 1...10 {
            let fileName = "test\(i).swift"
            let uploadedFile = result.first { $0.name == fileName }
            XCTAssertNotNil(uploadedFile, "File \(fileName) should be uploaded")
            XCTAssertTrue(uploadedFile?.content.contains("Test \(i)") ?? false, "Content should be preserved")
        }
    }
    
    func testLargeFileUpload() async throws {
        var testFiles: [URL] = []
        
        // Create 100 test files to test performance
        for i in 1...100 {
            let fileName = "large_test\(i).swift"
            let testFile = tempDirectory.appendingPathComponent(fileName)
            let testContent = """
            // Large test file \(i)
            import Foundation
            
            class TestClass\(i) {
                func testMethod() {
                    print("Testing large file upload \(i)")
                    // Adding more content to make file larger
                    let data = Array(1...1000).map { "Line \\($0)" }.joined(separator: "\\n")
                    print(data)
                }
            }
            """
            try testContent.write(to: testFile, atomically: true, encoding: .utf8)
            testFiles.append(testFile)
        }
        
        let result = try await fileUploadManager.uploadFiles(from: testFiles)
        
        XCTAssertEqual(result.count, 100, "Should upload all 100 files")
        XCTAssertTrue(result.allSatisfy { !$0.content.isEmpty }, "All files should have content")
    }
    
    // MARK: - File Type Detection Tests
    
    func testFileTypeDetection() async throws {
        let testCases: [(String, String, CodeLanguage)] = [
            ("test.swift", "print(\"Swift\")", .swift),
            ("test.js", "console.log('JavaScript');", .javascript),
            ("test.py", "print('Python')", .python),
            ("test.java", "System.out.println(\"Java\");", .java),
            ("test.cpp", "#include <iostream>", .cpp),
            ("test.html", "<html><body>Test</body></html>", .html),
            ("test.css", "body { color: red; }", .css),
            ("test.json", "{\"test\": true}", .json),
            ("test.xml", "<?xml version=\"1.0\"?><root/>", .xml),
            ("test.txt", "Plain text", .plainText)
        ]
        
        for (fileName, content, expectedLanguage) in testCases {
            let testFile = tempDirectory.appendingPathComponent(fileName)
            try content.write(to: testFile, atomically: true, encoding: .utf8)
            
            let result = try await fileUploadManager.uploadFiles(from: [testFile])
            
            XCTAssertEqual(result.count, 1, "Should upload file \(fileName)")
            XCTAssertEqual(result.first?.language, expectedLanguage, "Language detection failed for \(fileName)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testNonExistentFileHandling() async throws {
        let nonExistentFile = tempDirectory.appendingPathComponent("nonexistent.swift")
        
        do {
            let _ = try await fileUploadManager.uploadFiles(from: [nonExistentFile])
            XCTFail("Should throw error for non-existent file")
        } catch {
            // Expected to throw error
            XCTAssertTrue(error is FileUploadError || error is CocoaError, "Should throw appropriate error")
        }
    }
    
    func testEmptyFileHandling() async throws {
        let emptyFile = tempDirectory.appendingPathComponent("empty.swift")
        try "".write(to: emptyFile, atomically: true, encoding: .utf8)
        
        let result = try await fileUploadManager.uploadFiles(from: [emptyFile])
        
        XCTAssertEqual(result.count, 1, "Should handle empty file")
        XCTAssertEqual(result.first?.content, "", "Empty file content should be empty string")
    }
}

// MARK: - Performance Tests

extension FileUploadManagerTests {
    
    func testUploadPerformance() throws {
        measure {
            Task {
                // Create test file for performance testing
                let testFile = tempDirectory.appendingPathComponent("perf_test.swift")
                try "print(\"Performance test\")".write(to: testFile, atomically: true, encoding: .utf8)
                
                let _ = try await fileUploadManager.uploadFiles(from: [testFile])
            }
        }
    }
}

// MARK: - File Upload Error

enum FileUploadError: Error {
    case fileNotFound
    case invalidFileType
    case fileTooLarge
    case uploadFailed
}
