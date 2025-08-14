@testable import CodingReviewer
import XCTest

@MainActor
final class DataSharingBugTestSimple: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here
    }

    override func tearDownWithError() throws {
        // Put teardown code here
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testSharedDataManagerSingleton() async throws {
        let instance1 = SharedDataManager.shared
        let instance2 = SharedDataManager.shared

        XCTAssertTrue(instance1 === instance2)
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func testFileManagerServiceInitialization() async throws {
        let fileManager = FileManagerService()
        XCTAssertNotNil(fileManager)
        XCTAssertTrue(fileManager.uploadedFiles.isEmpty)
        XCTAssertTrue(fileManager.analysisHistory.isEmpty)
        XCTAssertFalse(fileManager.isUploading)
        XCTAssertEqual(fileManager.uploadProgress, 0.0)
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
}
