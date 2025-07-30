import XCTest
import SwiftUI
import Combine
@testable import CodingReviewer

@MainActor
final class CrossViewDataSharingTests: XCTestCase {
    
    var sharedDataManager: SharedDataManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        sharedDataManager = SharedDataManager.shared
        cancellables = Set<AnyCancellable>()
        
        // Clear any existing data
        sharedDataManager.fileManager.uploadedFiles.removeAll()
        sharedDataManager.fileManager.analysisRecords.removeAll()
    }
    
    override func tearDown() async throws {
        cancellables.removeAll()
        sharedDataManager = nil
    }
    
    // MARK: - Data Sharing Between Views Tests
    
    func testFileUploadToAnalyticsFlow() async throws {
        // Simulate file upload in FileUploadView
        let testFiles = [
            CodeFile(name: "test1.swift", content: "print(\"Test 1\")", language: .swift, path: "/test1.swift"),
            CodeFile(name: "test2.js", content: "console.log('Test 2');", language: .javascript, path: "/test2.js"),
            CodeFile(name: "test3.py", content: "print('Test 3')", language: .python, path: "/test3.py")
        ]
        
        // Upload files through shared file manager
        sharedDataManager.fileManager.uploadedFiles = testFiles
        
        // Verify files are accessible in analytics views
        let analyticsFiles = sharedDataManager.fileManager.uploadedFiles
        XCTAssertEqual(analyticsFiles.count, 3, "Analytics should see all uploaded files")
        XCTAssertEqual(analyticsFiles[0].name, "test1.swift", "File order should be preserved")
        XCTAssertEqual(analyticsFiles[1].language, .javascript, "File languages should be preserved")
    }
    
    func testAnalysisResultsSharingAcrossViews() async throws {
        // Create test analysis records
        let analysisRecord1 = FileAnalysisRecord(
            fileName: "test.swift",
            filePath: "/test.swift",
            language: .swift,
            complexity: 5,
            suggestions: ["Use guard statements", "Reduce function complexity"],
            issues: ["Long function", "Too many parameters"],
            metrics: FileMetrics(
                lineCount: 100,
                functionCount: 5,
                classCount: 1,
                complexityScore: 25,
                maintainabilityIndex: 75
            )
        )
        
        let analysisRecord2 = FileAnalysisRecord(
            fileName: "helper.js",
            filePath: "/helper.js",
            language: .javascript,
            complexity: 3,
            suggestions: ["Add type annotations", "Use const instead of var"],
            issues: ["Missing semicolons"],
            metrics: FileMetrics(
                lineCount: 50,
                functionCount: 3,
                classCount: 0,
                complexityScore: 15,
                maintainabilityIndex: 85
            )
        )
        
        // Add records to shared manager
        sharedDataManager.fileManager.analysisRecords = [analysisRecord1, analysisRecord2]
        
        // Verify records are accessible from different views
        let sharedRecords = sharedDataManager.fileManager.analysisRecords
        XCTAssertEqual(sharedRecords.count, 2, "All analysis records should be shared")
        
        // Test specific record data
        let swiftRecord = sharedRecords.first { $0.fileName == "test.swift" }
        XCTAssertNotNil(swiftRecord, "Swift analysis record should be accessible")
        XCTAssertEqual(swiftRecord?.complexity, 5, "Complexity data should be preserved")
        XCTAssertEqual(swiftRecord?.suggestions.count, 2, "Suggestions should be preserved")
        
        let jsRecord = sharedRecords.first { $0.fileName == "helper.js" }
        XCTAssertNotNil(jsRecord, "JavaScript analysis record should be accessible")
        XCTAssertEqual(jsRecord?.language, .javascript, "Language should be preserved")
    }
    
    func testMLIntegrationDataSharing() async throws {
        // Setup test file data for ML integration
        let mlTestFiles = [
            CodeFile(name: "model.py", content: "import tensorflow as tf", language: .python, path: "/ml/model.py"),
            CodeFile(name: "utils.py", content: "def helper(): pass", language: .python, path: "/ml/utils.py")
        ]
        
        sharedDataManager.fileManager.uploadedFiles = mlTestFiles
        
        // Simulate ML integration service accessing shared data
        let mlService = MLIntegrationService()
        
        // Verify ML service can access shared file data
        XCTAssertEqual(sharedDataManager.fileManager.uploadedFiles.count, 2, "ML service should access shared files")
        
        let pythonFiles = sharedDataManager.fileManager.uploadedFiles.filter { $0.language == .python }
        XCTAssertEqual(pythonFiles.count, 2, "ML service should filter files correctly")
    }
    
    // MARK: - Real-time Updates Tests
    
    func testRealTimeDataUpdates() async throws {
        let expectation = XCTestExpectation(description: "Real-time update received")
        var updateReceived = false
        
        // Subscribe to changes
        sharedDataManager.fileManager.objectWillChange
            .sink { _ in
                updateReceived = true
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger update
        sharedDataManager.fileManager.uploadedFiles.append(
            CodeFile(name: "new.swift", content: "// New file", language: .swift, path: "/new.swift")
        )
        
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(updateReceived, "Views should receive real-time updates")
    }
    
    func testMultipleViewSubscriptions() async throws {
        let uploadViewExpectation = XCTestExpectation(description: "Upload view update")
        let analyticsViewExpectation = XCTestExpectation(description: "Analytics view update")
        let aiViewExpectation = XCTestExpectation(description: "AI view update")
        
        var uploadViewUpdated = false
        var analyticsViewUpdated = false
        var aiViewUpdated = false
        
        // Simulate multiple view subscriptions
        sharedDataManager.fileManager.objectWillChange
            .sink { _ in
                uploadViewUpdated = true
                uploadViewExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        sharedDataManager.fileManager.objectWillChange
            .sink { _ in
                analyticsViewUpdated = true
                analyticsViewExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        sharedDataManager.fileManager.objectWillChange
            .sink { _ in
                aiViewUpdated = true
                aiViewExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger shared update
        sharedDataManager.refreshAllViews()
        
        wait(for: [uploadViewExpectation, analyticsViewExpectation, aiViewExpectation], timeout: 2.0)
        
        XCTAssertTrue(uploadViewUpdated, "Upload view should receive updates")
        XCTAssertTrue(analyticsViewUpdated, "Analytics view should receive updates")
        XCTAssertTrue(aiViewUpdated, "AI view should receive updates")
    }
    
    // MARK: - Environment Object Tests
    
    func testEnvironmentObjectInjection() throws {
        // Test that environment object is properly injected
        let environmentFileManager = EnvironmentValues()[\.fileManager]
        let sharedFileManager = sharedDataManager.fileManager
        
        XCTAssertTrue(environmentFileManager === sharedFileManager, "Environment should use shared instance")
    }
    
    func testViewExtensionAccess() throws {
        // Create a test view to verify extension access
        struct TestView: View {
            var body: some View {
                Text("Test")
            }
            
            func testSharedAccess() -> FileManagerService {
                return sharedFileManager
            }
        }
        
        let testView = TestView()
        let accessedFileManager = testView.testSharedAccess()
        
        XCTAssertTrue(accessedFileManager === sharedDataManager.fileManager, "View extension should access shared instance")
    }
    
    // MARK: - Data Consistency Tests
    
    func testDataConsistencyAcrossViews() async throws {
        // Add initial data
        let initialFile = CodeFile(name: "initial.swift", content: "// Initial", language: .swift, path: "/initial.swift")
        sharedDataManager.fileManager.uploadedFiles = [initialFile]
        
        // Simulate multiple views accessing and modifying data
        let view1Files = sharedDataManager.fileManager.uploadedFiles
        XCTAssertEqual(view1Files.count, 1, "View 1 should see initial file")
        
        // Add file from another view
        sharedDataManager.fileManager.uploadedFiles.append(
            CodeFile(name: "added.swift", content: "// Added", language: .swift, path: "/added.swift")
        )
        
        let view2Files = sharedDataManager.fileManager.uploadedFiles
        XCTAssertEqual(view2Files.count, 2, "View 2 should see both files")
        
        // Verify consistency
        let view3Files = sharedDataManager.fileManager.uploadedFiles
        XCTAssertEqual(view3Files.count, 2, "View 3 should see consistent data")
        XCTAssertEqual(view3Files[0].name, "initial.swift", "File order should be consistent")
        XCTAssertEqual(view3Files[1].name, "added.swift", "New file should be accessible")
    }
    
    func testMemoryConsistency() async throws {
        // Test that all views reference the same memory location
        let fileManager1 = sharedDataManager.fileManager
        let fileManager2 = sharedDataManager.getFileManager()
        let fileManager3 = SharedDataManager.shared.fileManager
        
        XCTAssertTrue(fileManager1 === fileManager2, "GetFileManager should return same instance")
        XCTAssertTrue(fileManager2 === fileManager3, "All access methods should return same instance")
        
        // Modify through one reference
        fileManager1.uploadedFiles.append(
            CodeFile(name: "memory_test.swift", content: "// Memory test", language: .swift, path: "/memory_test.swift")
        )
        
        // Verify change is visible through all references
        XCTAssertEqual(fileManager2.uploadedFiles.count, 1, "Change should be visible through reference 2")
        XCTAssertEqual(fileManager3.uploadedFiles.count, 1, "Change should be visible through reference 3")
        XCTAssertEqual(fileManager3.uploadedFiles.first?.name, "memory_test.swift", "Data should be consistent")
    }
}

// MARK: - Performance Tests

extension CrossViewDataSharingTests {
    
    func testDataSharingPerformance() throws {
        // Test performance of data sharing with large datasets
        var largeDataset: [CodeFile] = []
        
        for i in 1...1000 {
            largeDataset.append(
                CodeFile(
                    name: "file\(i).swift",
                    content: "// File \(i) content with some data",
                    language: .swift,
                    path: "/files/file\(i).swift"
                )
            )
        }
        
        measure {
            sharedDataManager.fileManager.uploadedFiles = largeDataset
            let _ = sharedDataManager.fileManager.uploadedFiles.count
        }
    }
    
    func testConcurrentViewAccess() throws {
        let testFile = CodeFile(name: "concurrent.swift", content: "// Concurrent test", language: .swift, path: "/concurrent.swift")
        sharedDataManager.fileManager.uploadedFiles = [testFile]
        
        measure {
            // Simulate multiple views accessing data concurrently
            DispatchQueue.concurrentPerform(iterations: 100) { _ in
                let _ = sharedDataManager.fileManager.uploadedFiles
            }
        }
    }
}
