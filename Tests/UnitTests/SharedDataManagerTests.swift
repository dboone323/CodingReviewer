import XCTest
import SwiftUI
import Combine
@testable import CodingReviewer

@MainActor
final class SharedDataManagerTests: XCTestCase {
    
    var sharedDataManager: SharedDataManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        cancellables = Set<AnyCancellable>()
        sharedDataManager = SharedDataManager.shared
    }
    
    override func tearDown() async throws {
        cancellables.removeAll()
        sharedDataManager = nil
    }
    
    // MARK: - Singleton Tests
    
    func testSharedDataManagerSingleton() throws {
        let instance1 = SharedDataManager.shared
        let instance2 = SharedDataManager.shared
        
        XCTAssertTrue(instance1 === instance2, "SharedDataManager should be a singleton")
    }
    
    func testFileManagerSingleton() throws {
        let fileManager1 = SharedDataManager.shared.fileManager
        let fileManager2 = SharedDataManager.shared.fileManager
        
        XCTAssertTrue(fileManager1 === fileManager2, "FileManager should be the same instance across access")
    }
    
    // MARK: - Data Sharing Tests
    
    func testFileManagerAccessibility() throws {
        let fileManager = sharedDataManager.getFileManager()
        XCTAssertNotNil(fileManager, "FileManager should be accessible")
        XCTAssertTrue(fileManager === sharedDataManager.fileManager, "GetFileManager should return the same instance")
    }
    
    func testRefreshAllViews() throws {
        let expectation = XCTestExpectation(description: "Views should refresh")
        var receivedUpdate = false
        
        sharedDataManager.objectWillChange
            .sink { _ in
                receivedUpdate = true
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sharedDataManager.refreshAllViews()
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedUpdate, "Refresh should trigger objectWillChange")
    }
    
    // MARK: - Environment Integration Tests
    
    func testEnvironmentKeyDefaultValue() throws {
        let defaultFileManager = EnvironmentValues()[\.fileManager]
        XCTAssertNotNil(defaultFileManager, "Environment should have default FileManager")
        XCTAssertTrue(defaultFileManager === SharedDataManager.shared.fileManager, "Default should be shared instance")
    }
    
    // MARK: - Data Persistence Tests
    
    func testDataPersistenceAcrossViews() async throws {
        // Simulate file upload in one view
        let testFile = CodeFile(
            name: "test.swift",
            content: "// Test content",
            language: .swift,
            path: "/test/test.swift"
        )
        
        sharedDataManager.fileManager.uploadedFiles = [testFile]
        
        // Verify data is accessible from another view simulation
        let retrievedFiles = sharedDataManager.getFileManager().uploadedFiles
        XCTAssertEqual(retrievedFiles.count, 1, "Files should persist across view access")
        XCTAssertEqual(retrievedFiles.first?.name, "test.swift", "File data should be preserved")
    }
    
    // MARK: - Thread Safety Tests
    
    func testMainActorIsolation() async throws {
        XCTAssertTrue(Thread.isMainThread, "SharedDataManager should run on main thread")
        
        let fileManager = await sharedDataManager.getFileManager()
        XCTAssertNotNil(fileManager, "FileManager should be accessible from main actor")
    }
}

// MARK: - Performance Tests

extension SharedDataManagerTests {
    
    func testSharedDataManagerPerformance() throws {
        measure {
            for _ in 0..<1000 {
                let _ = SharedDataManager.shared.fileManager
            }
        }
    }
    
    func testRefreshPerformance() throws {
        measure {
            for _ in 0..<100 {
                sharedDataManager.refreshAllViews()
            }
        }
    }
}
