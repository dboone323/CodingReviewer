import Foundation
import Combine
import SwiftUI
import XCTest

@testable import CodingReviewer

@MainActor
final class FileManagerServiceTests: XCTestCase {
    var fileManagerService: FileManagerService!
    var cancellables: Set<AnyCancellable>!
    var tempDirectory: URL!

    override func setUp() async throws {
        fileManagerService = FileManagerService()
        cancellables = Set<AnyCancellable>()

        // Create temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        // Clean up
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }

        cancellables.removeAll()
        fileManagerService = nil
        tempDirectory = nil
    }

    // MARK: - Basic Functionality Tests

    /// <#Description#>
    /// - Returns: <#description#>
    func testFileManagerInitialization() throws {
        XCTAssertNotNil(fileManagerService, "FileManagerService should initialize")
        XCTAssertTrue(fileManagerService.uploadedFiles.isEmpty, "Should start with empty files")
        XCTAssertTrue(fileManagerService.analysisRecords.isEmpty, "Should start with empty analysis records")
        XCTAssertFalse(fileManagerService.isUploading, "Should not be uploading initially")
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testFileUploadState() async throws {
        XCTAssertFalse(fileManagerService.isUploading, "Should not be uploading initially")

        // Create test file
        let testFile = tempDirectory.appendingPathComponent("state_test.swift")
        try "print(\"State test\")".write(to: testFile, atomically: true, encoding: .utf8)

        // Monitor upload state changes
        let expectation = XCTestExpectation(description: "Upload state changes")
        var stateChanges: [Bool] = []

        fileManagerService.$isUploading
            .sink { isUploading in
                stateChanges.append(isUploading)
                if stateChanges.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Trigger upload
        _ = try await fileManagerService.uploadFiles(from: [testFile])

        wait(for: [expectation], timeout: 5.0)

        // Verify state changes: false -> true -> false
        XCTAssertEqual(stateChanges.first, false, "Should start as not uploading")
        XCTAssertTrue(stateChanges.contains(true), "Should show uploading state")
        XCTAssertFalse(fileManagerService.isUploading, "Should end as not uploading")
    }

    // MARK: - File Upload Tests

    /// <#Description#>
    /// - Returns: <#description#>
    func testSingleFileUpload() async throws {
        let testFile = tempDirectory.appendingPathComponent("single.swift")
        let testContent = "// Single file test\nprint(\"Hello, World!\")"
        try testContent.write(to: testFile, atomically: true, encoding: .utf8)

        let result = try await fileManagerService.uploadFiles(from: [testFile])

        XCTAssertEqual(result.count, 1, "Should return one uploaded file")
        XCTAssertEqual(fileManagerService.uploadedFiles.count, 1, "Should store one file")

        let uploadedFile = fileManagerService.uploadedFiles.first!
        XCTAssertEqual(uploadedFile.name, "single.swift", "File name should be preserved")
        XCTAssertEqual(uploadedFile.content, testContent, "File content should be preserved")
        XCTAssertEqual(uploadedFile.language, .swift, "Language should be detected correctly")
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testMultipleFileUpload() async throws {
        var testFiles: [URL] = []
        let fileContents = [
            ("file1.swift", "// Swift file\nprint(\"Swift\")", CodeLanguage.swift),
            ("file2.js", "// JavaScript file\nconsole.log('JavaScript');", CodeLanguage.javascript),
            ("file3.py", "# Python file\nprint('Python')", CodeLanguage.python),
            ("file4.html", "<html><body>HTML</body></html>", CodeLanguage.html),
            ("file5.json", "{\"test\": true}", CodeLanguage.json),
        ]

        for (fileName, content, _) in fileContents {
            let file = tempDirectory.appendingPathComponent(fileName)
            try content.write(to: file, atomically: true, encoding: .utf8)
            testFiles.append(file)
        }

        let result = try await fileManagerService.uploadFiles(from: testFiles)

        XCTAssertEqual(result.count, 5, "Should return all uploaded files")
        XCTAssertEqual(fileManagerService.uploadedFiles.count, 5, "Should store all files")

        // Verify each file
        for (fileName, content, expectedLanguage) in fileContents {
            let uploadedFile = fileManagerService.uploadedFiles.first { $0.name == fileName }
            XCTAssertNotNil(uploadedFile, "File \(fileName) should be uploaded")
            XCTAssertEqual(uploadedFile?.content, content, "Content should be preserved for \(fileName)")
            XCTAssertEqual(uploadedFile?.language, expectedLanguage, "Language should be detected for \(fileName)")
        }
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testFileUploadWithLargeDataset() async throws {
        var testFiles: [URL] = []

        // Create 50 test files
        for i in 1 ... 50 {
            let fileName = "large_test\(i).swift"
            let testFile = tempDirectory.appendingPathComponent(fileName)
            let content = """
            // Large test file \(i)
            class TestClass\(i) {
                private var data: [String] = [];

    /// <#Description#>
    /// - Returns: <#description#>
                func processData() {
                    for j in 1...100 {
                        data.append("Item \\(j) from file \\(i)")
                    }
                }

    /// <#Description#>
    /// - Returns: <#description#>
                func getData() -> [String] {
                    return data
                }
            }
            """
            try content.write(to: testFile, atomically: true, encoding: .utf8)
            testFiles.append(testFile)
        }

        let result = try await fileManagerService.uploadFiles(from: testFiles)

        XCTAssertEqual(result.count, 50, "Should upload all 50 files")
        XCTAssertEqual(fileManagerService.uploadedFiles.count, 50, "Should store all 50 files")

        // Verify file order and content
        for i in 1 ... 50 {
            let fileName = "large_test\(i).swift"
            let uploadedFile = fileManagerService.uploadedFiles.first { $0.name == fileName }
            XCTAssertNotNil(uploadedFile, "File \(fileName) should be uploaded")
            XCTAssertTrue(uploadedFile?.content.contains("TestClass\(i)") ?? false, "Content should contain class name")
        }
    }

    // MARK: - Data Management Tests

    /// <#Description#>
    /// - Returns: <#description#>
    func testDataPersistence() async throws {
        // Upload initial files
        let file1 = tempDirectory.appendingPathComponent("persist1.swift")
        try "// File 1".write(to: file1, atomically: true, encoding: .utf8)

        _ = try await fileManagerService.uploadFiles(from: [file1])
        XCTAssertEqual(fileManagerService.uploadedFiles.count, 1, "Should have one file")

        // Upload additional files
        let file2 = tempDirectory.appendingPathComponent("persist2.swift")
        try "// File 2".write(to: file2, atomically: true, encoding: .utf8)

        _ = try await fileManagerService.uploadFiles(from: [file2])
        XCTAssertEqual(fileManagerService.uploadedFiles.count, 2, "Should have two files")

        // Verify both files are preserved
        let file1Data = fileManagerService.uploadedFiles.first { $0.name == "persist1.swift" }
        let file2Data = fileManagerService.uploadedFiles.first { $0.name == "persist2.swift" }

        XCTAssertNotNil(file1Data, "First file should be preserved")
        XCTAssertNotNil(file2Data, "Second file should be preserved")
        XCTAssertEqual(file1Data?.content, "// File 1", "First file content should be preserved")
        XCTAssertEqual(file2Data?.content, "// File 2", "Second file content should be preserved")
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testDataClearing() async throws {
        // Upload test files
        let testFile = tempDirectory.appendingPathComponent("clear_test.swift")
        try "// Clear test".write(to: testFile, atomically: true, encoding: .utf8)

        _ = try await fileManagerService.uploadFiles(from: [testFile])
        XCTAssertEqual(fileManagerService.uploadedFiles.count, 1, "Should have uploaded file")

        // Clear data
        fileManagerService.uploadedFiles.removeAll()
        XCTAssertTrue(fileManagerService.uploadedFiles.isEmpty, "Files should be cleared")

        // Add analysis record and clear
        let mockRecord = FileAnalysisRecord(
            fileName: "test.swift",
            filePath: "/test.swift",
            language: .swift,
            complexity: 5,
            suggestions: ["Test"],
            issues: ["Test issue"],
            metrics: FileMetrics(
                lineCount: 10,
                functionCount: 1,
                classCount: 1,
                complexityScore: 15,
                maintainabilityIndex: 85
            )
        )

        fileManagerService.analysisRecords = [mockRecord]
        XCTAssertEqual(fileManagerService.analysisRecords.count, 1, "Should have analysis record")

        fileManagerService.analysisRecords.removeAll()
        XCTAssertTrue(fileManagerService.analysisRecords.isEmpty, "Analysis records should be cleared")
    }

    // MARK: - Analysis Records Tests

    /// <#Description#>
    /// - Returns: <#description#>
    func testAnalysisRecordManagement() throws {
        XCTAssertTrue(fileManagerService.analysisRecords.isEmpty, "Should start with no analysis records")

        // Add analysis records
        let record1 = FileAnalysisRecord(
            fileName: "test1.swift",
            filePath: "/test1.swift",
            language: .swift,
            complexity: 3,
            suggestions: ["Use guard statements"],
            issues: ["Long function"],
            metrics: FileMetrics(
                lineCount: 50,
                functionCount: 2,
                classCount: 1,
                complexityScore: 12,
                maintainabilityIndex: 88
            )
        )

        let record2 = FileAnalysisRecord(
            fileName: "test2.js",
            filePath: "/test2.js",
            language: .javascript,
            complexity: 7,
            suggestions: ["Break down function", "Add error handling"],
            issues: ["High complexity", "Missing documentation"],
            metrics: FileMetrics(
                lineCount: 120,
                functionCount: 8,
                classCount: 2,
                complexityScore: 35,
                maintainabilityIndex: 65
            )
        )

        fileManagerService.analysisRecords = [record1, record2]

        XCTAssertEqual(fileManagerService.analysisRecords.count, 2, "Should have two analysis records")

        // Verify record data
        let swiftRecord = fileManagerService.analysisRecords.first { $0.fileName == "test1.swift" }
        XCTAssertNotNil(swiftRecord, "Swift record should exist")
        XCTAssertEqual(swiftRecord?.complexity, 3, "Swift record complexity should be preserved")
        XCTAssertEqual(swiftRecord?.suggestions.count, 1, "Swift record suggestions should be preserved")

        let jsRecord = fileManagerService.analysisRecords.first { $0.fileName == "test2.js" }
        XCTAssertNotNil(jsRecord, "JavaScript record should exist")
        XCTAssertEqual(jsRecord?.complexity, 7, "JavaScript record complexity should be preserved")
        XCTAssertEqual(jsRecord?.issues.count, 2, "JavaScript record issues should be preserved")
    }

    // MARK: - Observable Object Tests

    /// <#Description#>
    /// - Returns: <#description#>
    func testObservableObjectUpdates() async throws {
        let expectation = XCTestExpectation(description: "Observable object update")
        var updateReceived = false

        fileManagerService.objectWillChange
            .sink { _ in
                updateReceived = true
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Trigger update by uploading file
        let testFile = tempDirectory.appendingPathComponent("observable_test.swift")
        try "// Observable test".write(to: testFile, atomically: true, encoding: .utf8)

        _ = try await fileManagerService.uploadFiles(from: [testFile])

        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(updateReceived, "Should receive observable object update")
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testMultipleSubscriptions() async throws {
        let subscriber1Expectation = XCTestExpectation(description: "Subscriber 1 update")
        let subscriber2Expectation = XCTestExpectation(description: "Subscriber 2 update")
        let subscriber3Expectation = XCTestExpectation(description: "Subscriber 3 update")

        var subscriber1Updated = false
        var subscriber2Updated = false
        var subscriber3Updated = false

        // Multiple subscribers
        fileManagerService.objectWillChange
            .sink { _ in
                subscriber1Updated = true
                subscriber1Expectation.fulfill()
            }
            .store(in: &cancellables)

        fileManagerService.objectWillChange
            .sink { _ in
                subscriber2Updated = true
                subscriber2Expectation.fulfill()
            }
            .store(in: &cancellables)

        fileManagerService.objectWillChange
            .sink { _ in
                subscriber3Updated = true
                subscriber3Expectation.fulfill()
            }
            .store(in: &cancellables)

        // Trigger update
        fileManagerService.uploadedFiles.append(
            CodeFile(
                name: "multi_sub.swift",
                content: "// Multi subscriber test",
                language: .swift,
                path: "/multi_sub.swift"
            )
        )

        wait(for: [subscriber1Expectation, subscriber2Expectation, subscriber3Expectation], timeout: 2.0)

        XCTAssertTrue(subscriber1Updated, "Subscriber 1 should be updated")
        XCTAssertTrue(subscriber2Updated, "Subscriber 2 should be updated")
        XCTAssertTrue(subscriber3Updated, "Subscriber 3 should be updated")
    }

    // MARK: - Error Handling Tests

    /// <#Description#>
    /// - Returns: <#description#>
    func testErrorHandlingForInvalidFiles() async throws {
        let nonExistentFile = tempDirectory.appendingPathComponent("nonexistent.swift")

        do {
            _ = try await fileManagerService.uploadFiles(from: [nonExistentFile])
            XCTFail("Should throw error for non-existent file")
        } catch {
            // Expected to throw error
            XCTAssertFalse(fileManagerService.isUploading, "Should not be in uploading state after error")
            XCTAssertTrue(fileManagerService.uploadedFiles.isEmpty, "Should not have uploaded files after error")
        }
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testErrorHandlingForCorruptedFiles() async throws {
        // Create a file with invalid encoding
        let corruptedFile = tempDirectory.appendingPathComponent("corrupted.swift")
        let invalidData = Data([0xFF, 0xFE, 0xFD, 0xFC]) // Invalid UTF-8 data
        try invalidData.write(to: corruptedFile)

        do {
            _ = try await fileManagerService.uploadFiles(from: [corruptedFile])
            // This might succeed with replacement characters, so we check the result
            if !fileManagerService.uploadedFiles.isEmpty {
                XCTAssertNotNil(
                    fileManagerService.uploadedFiles.first?.content,
                    "Should handle corrupted files gracefully"
                )
            }
        } catch {
            // Error is also acceptable for corrupted files
            XCTAssertTrue(error is CocoaError || error is DecodingError, "Should throw appropriate error type")
        }
    }
}

// MARK: - Performance Tests

extension FileManagerServiceTests {
    /// <#Description#>
    /// - Returns: <#description#>
    func testUploadPerformance() throws {
        // Test upload performance with moderate dataset
        var testFiles: [URL] = []

        for i in 1 ... 20 {
            let fileName = "perf\(i).swift"
            let testFile = tempDirectory.appendingPathComponent(fileName)
            let content = "// Performance test file \(i)\nprint(\"File \(i)\")"
            try content.write(to: testFile, atomically: true, encoding: .utf8)
            testFiles.append(testFile)
        }

        measure {
            Task {
                let _ = try await fileManagerService.uploadFiles(from: testFiles)
            }
        }
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testDataAccessPerformance() throws {
        // Setup large dataset
        var largeDataset: [CodeFile] = []
        for i in 1 ... 100 {
            largeDataset.append(
                CodeFile(
                    name: "access_perf\(i).swift",
                    content: "// Access performance test \(i)",
                    language: .swift,
                    path: "/access_perf\(i).swift"
                )
            )
        }

        fileManagerService.uploadedFiles = largeDataset

        measure {
            // Simulate various data access patterns
            _ = fileManagerService.uploadedFiles.count
            _ = fileManagerService.uploadedFiles.filter { $0.language == .swift }
            _ = fileManagerService.uploadedFiles.map(\.name)
            _ = fileManagerService.uploadedFiles.first { $0.name.contains("50") }
        }
    }
}
