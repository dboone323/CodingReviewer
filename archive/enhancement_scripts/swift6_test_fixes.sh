#!/bin/bash

# Swift 6 Test Fixes Script
# Fixes concurrency and actor isolation issues in test files

echo "🔧 Applying Swift 6 concurrency fixes to test files..."

# Fix for CodeAnalyzersEnhancedTests.swift - properly handle @MainActor isolation
cat > /Users/danielstevens/Desktop/CodingReviewer/CodingReviewerTests/CodeAnalyzersEnhancedTests.swift << 'EOF'
import XCTest
@testable import CodingReviewer

@MainActor
final class CodeAnalyzersEnhancedTests: XCTestCase {
    
    var qualityAnalyzer: QualityAnalyzer!
    var securityAnalyzer: SecurityAnalyzer!
    var performanceAnalyzer: PerformanceAnalyzer!
    
    override func setUpWithError() throws {
        qualityAnalyzer = QualityAnalyzer()
        securityAnalyzer = SecurityAnalyzer()
        performanceAnalyzer = PerformanceAnalyzer()
    }
    
    override func tearDownWithError() throws {
        qualityAnalyzer = nil
        securityAnalyzer = nil
        performanceAnalyzer = nil
    }
    
    // MARK: - Quality Analyzer Tests
    
    func testForceUnwrappingDetectionWithLineNumbers() async throws {
        let testCode = """
        func testFunction() {
            let array = [1, 2, 3]
            let firstElement = array.first!  // This should be detected
            let safeElement = array.first ?? 0
            // let commented = array.first!  // This should be ignored
            let validTypeAnnotation: String! = nil  // This should be ignored
        }
        """
        
        let results = await qualityAnalyzer.analyze(testCode)
        let forceUnwrapResults = results.filter { $0.message.contains("Force unwrapping") }
        
        XCTAssertEqual(forceUnwrapResults.count, 1)
        XCTAssertEqual(forceUnwrapResults.first?.lineNumber, 3)
        XCTAssertEqual(forceUnwrapResults.first?.severity, "Medium")
        if let suggestion = forceUnwrapResults.first?.suggestion {
            XCTAssertTrue(suggestion.contains("if let"))
        }
    }
    
    func testTodoDetectionWithTypes() async throws {
        let testCode = """
        func example() {
            // TODO: Implement this feature
            let value = 42
            // FIXME: This is broken
            // HACK: Temporary workaround
            // XXX: This needs review
        }
        """
        
        let results = await qualityAnalyzer.analyze(testCode)
        let todoResults = results.filter { $0.message.contains("comment found") }
        
        XCTAssertEqual(todoResults.count, 4)
        
        // Test different severities
        let fixmeResult = todoResults.first { $0.message.contains("FIXME") }
        XCTAssertEqual(fixmeResult?.severity, "Medium")
        
        let todoResult = todoResults.first { $0.message.contains("TODO") }
        XCTAssertEqual(todoResult?.severity, "Low")
    }
    
    func testConcurrencyIssueDetection() async throws {
        let testCode = """
        class ViewModel {
            func updateUI() async {
                self.isLoading = true  // Potential UI update without @MainActor
                
                Task {
                    self.data = await fetchData()  // Capturing self in Task
                }
            }
        }
        """
        
        let results = await qualityAnalyzer.analyze(testCode)
        let concurrencyResults = results.filter { 
            $0.message.contains("@MainActor") || $0.message.contains("non-Sendable") 
        }
        
        XCTAssertGreaterThan(concurrencyResults.count, 0)
    }
    
    func testModernSwiftPatternSuggestions() async throws {
        let testCode = """
        func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
            // Old style completion handler
        }
        
        func processData() {
            if let data = getData() {
                // Could suggest guard let for early return
                return
            }
        }
        """
        
        let results = await qualityAnalyzer.analyze(testCode)
        let modernizationResults = results.filter { 
            $0.message.contains("async/await") || $0.message.contains("guard let") 
        }
        
        XCTAssertGreaterThan(modernizationResults.count, 0)
    }
    
    // MARK: - Security Analyzer Tests
    
    func testSensitiveInformationDetection() async throws {
        let testCode = """
        let apiKey = "sk-1234567890abcdef"
        let password = "mySecretPassword"
        let regularVariable = "just a string"
        """
        
        let results = await securityAnalyzer.analyze(testCode)
        let securityResults = results.filter { $0.type == "Security" }
        
        XCTAssertEqual(securityResults.count, 2) // apiKey and password
        XCTAssertTrue(securityResults.allSatisfy { $0.severity == "High" })
    }
    
    func testHTTPSuggestions() async throws {
        let testCode = """
        let secureURL = "https://api.example.com"
        let insecureURL = "http://api.example.com"
        """
        
        let results = await securityAnalyzer.analyze(testCode)
        let httpResults = results.filter { $0.message.contains("HTTP") }
        
        XCTAssertEqual(httpResults.count, 1)
        XCTAssertEqual(httpResults.first?.severity, "Medium")
    }
    
    // MARK: - Performance Analyzer Tests
    
    func testMainThreadBlockingDetection() async throws {
        let testCode = """
        func slowFunction() {
            Thread.sleep(forTimeInterval: 1.0)
            sleep(5)
            usleep(1000000)
        }
        """
        
        let results = await performanceAnalyzer.analyze(testCode)
        let blockingResults = results.filter { $0.message.contains("blocking") }
        
        XCTAssertEqual(blockingResults.count, 3)
        XCTAssertTrue(blockingResults.allSatisfy { $0.severity == "Medium" })
    }
    
    func testExpensiveOperationsDetection() async throws {
        // Create code with many loops
        var testCode = "func manyLoops() {\n"
        for i in 1...15 {
            testCode += "    for item\(i) in array\(i) {\n"
            testCode += "        // process\n"
            testCode += "    }\n"
        }
        testCode += "}"
        
        let results = await performanceAnalyzer.analyze(testCode)
        let loopResults = results.filter { $0.message.contains("loop") }
        
        XCTAssertGreaterThan(loopResults.count, 0)
        XCTAssertEqual(loopResults.first?.severity, "Low")
    }
    
    // MARK: - Integration Tests
    
    func testComplexCodeAnalysis() async throws {
        let complexCode = """
        import Foundation
        
        class UserManager {
            var users: [User] = []
            
            func fetchUsers(completion: @escaping ([User]) -> Void) {
                // TODO: Implement caching
                let url = "http://api.example.com/users"  // HTTP issue
                let apiKey = "secret-key-123"  // Hardcoded secret
                
                DispatchQueue.global().async {
                    Thread.sleep(forTimeInterval: 0.5)  // Blocking operation
                    
                    // Force unwrapping
                    let data = self.loadData()!
                    
                    for i in 0..<1000 {  // Expensive loop
                        for j in 0..<1000 {
                            // Nested loops
                        }
                    }
                    
                    DispatchQueue.main.async {
                        completion(self.users)
                    }
                }
            }
        }
        """
        
        let qualityResults = await qualityAnalyzer.analyze(complexCode)
        let securityResults = await securityAnalyzer.analyze(complexCode)
        let performanceResults = await performanceAnalyzer.analyze(complexCode)
        
        let allResults = qualityResults + securityResults + performanceResults
        
        // Should detect multiple issues
        XCTAssertGreaterThan(allResults.count, 5)
        
        // Should have different severity levels
        let severities = Set(allResults.map { $0.severity })
        XCTAssertTrue(severities.contains("High"))
        XCTAssertTrue(severities.contains("Medium"))
        XCTAssertTrue(severities.contains("Low"))
        
        // Should have line numbers for most issues
        let resultsWithLineNumbers = allResults.filter { $0.lineNumber > 0 }
        XCTAssertGreaterThan(resultsWithLineNumbers.count, 0)
    }
}
EOF

echo "✅ Fixed CodeAnalyzersEnhancedTests.swift for Swift 6 concurrency"

# Fix for DataSharingBugTestSimple.swift - mark as @MainActor and fix async issues
cat > /Users/danielstevens/Desktop/CodingReviewer/CodingReviewerTests/DataSharingBugTestSimple.swift << 'EOF'
import XCTest
@testable import CodingReviewer

@MainActor
final class DataSharingBugTestSimple: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here
    }
    
    func testSharedDataManagerSingleton() async throws {
        let instance1 = SharedDataManager.shared
        let instance2 = SharedDataManager.shared
        
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testFileManagerServiceInitialization() async throws {
        let fileManager = FileManagerService()
        XCTAssertNotNil(fileManager)
        XCTAssertTrue(fileManager.uploadedFiles.isEmpty)
        XCTAssertTrue(fileManager.analysisHistory.isEmpty)
        XCTAssertFalse(fileManager.isUploading)
        XCTAssertEqual(fileManager.uploadProgress, 0.0)
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
}
EOF

echo "✅ Fixed DataSharingBugTestSimple.swift for Swift 6 concurrency"

# Check and fix other test files that might have issues
if [ -f "/Users/danielstevens/Desktop/CodingReviewer/CodingReviewerTests/AIInsightsFileDisplayTest.swift" ]; then
    echo "🔍 Checking AIInsightsFileDisplayTest.swift..."
    
    # Add @MainActor to the class if it doesn't have it
    sed -i '' 's/^final class AIInsightsFileDisplayTest/@MainActor\nfinal class AIInsightsFileDisplayTest/' "/Users/danielstevens/Desktop/CodingReviewer/CodingReviewerTests/AIInsightsFileDisplayTest.swift"
    
    echo "✅ Fixed AIInsightsFileDisplayTest.swift for Swift 6 concurrency"
fi

echo "🧪 Running test compilation to verify fixes..."
cd /Users/danielstevens/Desktop/CodingReviewer
xcodebuild -target CodingReviewerTests -configuration Debug build

if [ $? -eq 0 ]; then
    echo "✅ All Swift 6 test fixes applied successfully!"
    echo "🎯 Tests are now ready for execution"
else
    echo "⚠️  Some issues remain - checking for additional fixes needed"
fi
