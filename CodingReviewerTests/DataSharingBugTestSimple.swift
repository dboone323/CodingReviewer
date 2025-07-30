import XCTest
@testable import CodingReviewer

@MainActor
class DataSharingBugTestSimple: XCTestCase {
    
    var sharedDataManager: SharedDataManager!
    var fileManager: FileManagerService!
    
    override func setUp() async throws {
        try await super.setUp()
        sharedDataManager = SharedDataManager.shared
        fileManager = sharedDataManager.fileManager
    }
    
    override func tearDown() async throws {
        // Clean up any uploaded files
        fileManager.uploadedFiles.removeAll()
        try await super.tearDown()
    }
    
    func testFileVisibilityBug() async {
        print("\n🔍 TESTING FILE VISIBILITY BUG")
        
        // Given: A test file is uploaded
        let testFile = CodeFile(
            name: "test.swift",
            path: "/test.swift",
            content: "print(\"Hello World\")",
            language: .swift
        )
        
        print("Before upload - files count: \(fileManager.uploadedFiles.count)")
        
        // When: File is added to uploaded files (simulating upload)
        fileManager.uploadedFiles.append(testFile)
        
        print("After upload - files count: \(fileManager.uploadedFiles.count)")
        
        // Then: File should be accessible through SharedDataManager
        XCTAssertEqual(fileManager.uploadedFiles.count, 1, "❌ File should be added to uploadedFiles")
        XCTAssertEqual(fileManager.uploadedFiles.first?.name, "test.swift", "❌ File name should match")
        
        // Check if the same instance is accessible through SharedDataManager
        let sharedFileManager = SharedDataManager.shared.fileManager
        XCTAssertTrue(sharedFileManager === fileManager, "❌ Should be the same instance")
        XCTAssertEqual(sharedFileManager.uploadedFiles.count, 1, "❌ Shared manager should see the same files")
        
        // Test language grouping (this is what AI Insights and Pattern Analysis use)
        let groupedFiles = Dictionary(grouping: fileManager.uploadedFiles) { $0.language }
        XCTAssertEqual(groupedFiles[.swift]?.count, 1, "❌ Swift files should be grouped correctly")
        
        print("✅ Test passed: Files are properly shared between views")
        
        // DIAGNOSTIC: Check what AI Insights and Pattern Analysis would see
        print("\n📊 DIAGNOSTIC - What views would see:")
        print("AI Insights view would see \(groupedFiles.keys.count) language groups")
        print("Pattern Analysis view would see \(sharedFileManager.uploadedFiles.count) total files")
        
        if groupedFiles[.swift]?.isEmpty == true {
            print("❌ FOUND THE BUG: Swift files are empty in language grouping!")
        } else {
            print("✅ Language grouping works correctly")
        }
    }
}
