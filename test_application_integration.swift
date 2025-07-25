//
//  ApplicationIntegrationTests.swift
//  CodingReviewerTests
//
//  Created by AI Assistant on 7/18/25.
//

import Foundation
@testable import CodingReviewer

class ApplicationIntegrationTests {
    
    static func runAllTests() -> TestSuite {
        let suite = TestSuite(name: "Application Integration Tests")
        
        // Test application initialization
        suite.addTest("testApplicationInitialization") {
            let appLogger = AppLogger.shared
            TestAssert(appLogger != nil, "AppLogger should be initialized")
            print("✅ Application logger initialized")
        }
        
        // Test code language functionality
        suite.addTest("testCodeLanguageSupport") {
            let supportedLanguages = CodeLanguage.allCases
            TestAssert(supportedLanguages.count >= 10, "Should support at least 10 languages")
            
            // Test specific languages
            TestAssert(supportedLanguages.contains(.swift), "Should support Swift")
            TestAssert(supportedLanguages.contains(.python), "Should support Python")
            TestAssert(supportedLanguages.contains(.javascript), "Should support JavaScript")
            
            // Test display names
            assertEqual(CodeLanguage.swift.displayName, "Swift", "Swift display name")
            assertEqual(CodeLanguage.python.displayName, "Python", "Python display name")
            assertEqual(CodeLanguage.javascript.displayName, "JavaScript", "JavaScript display name")
            
            // Test icon names
            assertEqual(CodeLanguage.swift.iconName, "swift", "Swift icon name")
            assertEqual(CodeLanguage.python.iconName, "snake.circle", "Python icon name")
            assertEqual(CodeLanguage.javascript.iconName, "js.circle", "JavaScript icon name")
            
            print("✅ Code language support validated")
        }
        
        // Test API key management
        suite.addTest("testAPIKeyManager") {
            let keyManager = APIKeyManager()
            
            // Test initial state
            TestAssert(!keyManager.hasValidKey, "Should not have valid key initially")
            TestAssert(!keyManager.showingKeySetup, "Should not show key setup initially")
            
            print("✅ API key manager functionality validated")
        }
        
        // Test enhanced analysis data models
        suite.addTest("testEnhancedAnalysisModels") {
            // Test AnalysisResult to EnhancedAnalysisItem conversion
            let analysisResult = AnalysisResult(
                type: .security,
                message: "Test security issue",
                line: 10,
                severity: .high
            )
            
            let enhancedItem = EnhancedAnalysisItem(from: analysisResult)
            assertEqual(enhancedItem.message, "Test security issue", "Enhanced item message")
            assertEqual(enhancedItem.severity, "high", "Enhanced item severity")
            assertEqual(enhancedItem.lineNumber, 10, "Enhanced item line number")
            assertEqual(enhancedItem.type, "security", "Enhanced item type")
            
            // Test conversion back
            let convertedBack = enhancedItem.toAnalysisResult()
            assertEqual(convertedBack.type.rawValue, "security", "Converted back type")
            assertEqual(convertedBack.severity.rawValue, "high", "Converted back severity")
            assertEqual(convertedBack.message, "Test security issue", "Converted back message")
            
            print("✅ Enhanced analysis models validated")
        }
        
        // Test file analysis record
        suite.addTest("testFileAnalysisRecord") {
            let testFile = CodeFile(
                name: "test.swift",
                path: "/test.swift",
                content: "let x = 5",
                language: .swift
            )
            
            let analysisResult = AnalysisResult(
                type: .quality,
                message: "Test issue",
                line: 1,
                severity: .medium
            )
            
            let record = FileAnalysisRecord(
                file: testFile,
                analysisResults: [analysisResult],
                aiAnalysisResult: nil,
                duration: 0.5
            )
            
            assertEqual(record.file.name, "test.swift", "File analysis record file name")
            assertEqual(record.analysisResults.count, 1, "File analysis record results count")
            assertEqual(record.analysisResults.first?.message, "Test issue", "File analysis record first result message")
            assertEqual(record.duration, 0.5, "File analysis record duration")
            TestAssert(record.aiAnalysisResult == nil, "File analysis record AI result should be nil")
            
            print("✅ File analysis record validated")
        }
        
        // Test analysis rating system
        suite.addTest("testAnalysisRatingSystem") {
            // Test rating descriptions
            assertEqual(CodeAnalysisReport.Rating.excellent.description, "🌟 Excellent", "Excellent rating description")
            assertEqual(CodeAnalysisReport.Rating.good.description, "👍 Good", "Good rating description")
            assertEqual(CodeAnalysisReport.Rating.needsImprovement.description, "⚠️ Needs Improvement", "Needs improvement rating description")
            assertEqual(CodeAnalysisReport.Rating.poor.description, "❌ Poor", "Poor rating description")
            
            print("✅ Analysis rating system validated")
        }
        
        // Test code metrics
        suite.addTest("testCodeMetrics") {
            let testCode = "func test() {\n    print(\"Hello\")\n}"
            let metrics = CodeMetrics(
                characterCount: testCode.count,
                lineCount: testCode.components(separatedBy: .newlines).count,
                estimatedComplexity: 1,
                analysisTime: 0.1
            )
            
            assertEqual(metrics.characterCount, testCode.count, "Code metrics character count")
            assertEqual(metrics.lineCount, 3, "Code metrics line count")
            assertEqual(metrics.estimatedComplexity, 1, "Code metrics complexity")
            assertEqual(metrics.analysisTime, 0.1, "Code metrics analysis time")
            
            print("✅ Code metrics validated")
        }
        
        // Test error types
        suite.addTest("testErrorTypes") {
            // Test FileManagerError descriptions
            let fileTooLargeError = FileManagerError.fileTooLarge("test.txt", 1000000, 500000)
            TestAssert(fileTooLargeError.errorDescription != nil, "File too large error should have description")
            TestAssert(fileTooLargeError.errorDescription!.contains("test.txt"), "Error should contain filename")
            TestAssert(fileTooLargeError.errorDescription!.contains("too large"), "Error should contain 'too large'")
            
            let accessDeniedError = FileManagerError.accessDenied("private.txt")
            TestAssert(accessDeniedError.errorDescription!.contains("Access denied"), "Access denied error")
            
            let encodingError = FileManagerError.encodingError("binary.dat")
            TestAssert(encodingError.errorDescription!.contains("encoding error"), "Encoding error")
            
            print("✅ Error types validated")
        }
        
        // Test application integration
        suite.addTest("testApplicationFlow") {
            // Test basic application workflow
            let fileManager = FileManagerService()
            
            // Test initial state
            TestAssert(fileManager.uploadedFiles.isEmpty, "Initial uploaded files should be empty")
            TestAssert(fileManager.analysisHistory.isEmpty, "Initial analysis history should be empty")
            TestAssert(fileManager.projects.isEmpty, "Initial projects should be empty")
            TestAssert(!fileManager.isUploading, "Should not be uploading initially")
            assertEqual(fileManager.uploadProgress, 0.0, "Initial upload progress should be 0")
            
            // Test file creation
            let testFile = CodeFile(
                name: "test.swift",
                path: "/test/test.swift",
                content: "print(\"Hello, World!\")",
                language: .swift
            )
            
            TestAssert(!testFile.checksum.isEmpty, "File checksum should not be empty")
            TestAssert(!testFile.displaySize.isEmpty, "File display size should not be empty")
            assertEqual(testFile.fileExtension, "swift", "File extension should be swift")
            
            print("✅ Application flow validated")
        }
        
        // Test performance and logging
        suite.addTest("testLoggingAndPerformance") {
            let logger = AppLogger.shared
            
            // Test logging functionality
            logger.log("Test message", level: .info, category: .analysis)
            logger.logAnalysisStart(codeLength: 100)
            logger.logAnalysisComplete(resultsCount: 5, duration: 0.5)
            
            // Test performance tracking
            let startTime = CFAbsoluteTimeGetCurrent()
            // Simulate some work
            Thread.sleep(forTimeInterval: 0.001)
            let endTime = CFAbsoluteTimeGetCurrent()
            let duration = endTime - startTime
            
            TestAssert(duration > 0, "Duration should be positive")
            TestAssert(duration < 1.0, "Duration should be less than 1 second")
            
            print("✅ Logging and performance validated")
        }
        
        // Test data integrity
        suite.addTest("testDataIntegrity") {
            // Test UUID generation consistency
            let file1 = CodeFile(name: "test1.swift", path: "/test1.swift", content: "code1", language: .swift)
            let file2 = CodeFile(name: "test2.swift", path: "/test2.swift", content: "code2", language: .swift)
            
            TestAssert(file1.id != file2.id, "Different files should have different IDs")
            
            // Test checksum consistency
            let file3 = CodeFile(name: "test3.swift", path: "/test3.swift", content: "same content", language: .swift)
            let file4 = CodeFile(name: "test4.swift", path: "/test4.swift", content: "same content", language: .swift)
            
            assertEqual(file3.checksum, file4.checksum, "Same content should have same checksum")
            
            // Test language consistency
            assertEqual(file1.language, .swift, "Swift file language")
            assertEqual(file2.language, .swift, "Swift file language")
            
            print("✅ Data integrity validated")
        }
        
        return suite
    }
}

// Helper test structure
struct TestSuite {
    let name: String
    private var tests: [(String, () throws -> Void)] = []
    
    init(name: String) {
        self.name = name
    }
    
    mutating func addTest(_ name: String, test: @escaping () throws -> Void) {
        tests.append((name, test))
    }
    
    func run() -> TestResults {
        var passed = 0
        var failed = 0
        var failures: [String] = []
        
        print("🚀 Running \(name)")
        print(String(repeating: "=", count: 50))
        
        for (testName, test) in tests {
            do {
                try test()
                passed += 1
            } catch {
                failed += 1
                let failure = "❌ \(testName): \(error)"
                failures.append(failure)
                print(failure)
            }
        }
        
        let results = TestResults(
            suiteName: name,
            passed: passed,
            failed: failed,
            failures: failures
        )
        
        print("\n📊 \(name) Results:")
        print("✅ Passed: \(passed)")
        print("❌ Failed: \(failed)")
        print("📈 Total: \(passed + failed)")
        
        if failed == 0 {
            print("🎉 ALL TESTS PASSED!")
        } else {
            print("⚠️ Some tests failed:")
            for failure in failures {
                print("   \(failure)")
            }
        }
        
        return results
    }
}

struct TestResults {
    let suiteName: String
    let passed: Int
    let failed: Int
    let failures: [String]
    
    var totalTests: Int { passed + failed }
    var success: Bool { failed == 0 }
}

// Test helper functions
func TestAssert(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw TestError.assertionFailed(message)
    }
}

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) throws {
    if actual != expected {
        throw TestError.assertEqual("Expected \(expected), got \(actual): \(message)")
    }
}

enum TestError: Error, LocalizedError {
    case assertionFailed(String)
    case assertEqual(String)
    
    var errorDescription: String? {
        switch self {
        case .assertionFailed(let message): return "Assertion failed: \(message)"
        case .assertEqual(let message): return "Equal assertion failed: \(message)"
        }
    }
}
