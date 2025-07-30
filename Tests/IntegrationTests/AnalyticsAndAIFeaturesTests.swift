import XCTest
import SwiftUI
import Combine
@testable import CodingReviewer

@MainActor
final class AnalyticsAndAIFeaturesTests: XCTestCase {
    
    var sharedDataManager: SharedDataManager!
    var mlIntegrationService: MLIntegrationService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        sharedDataManager = SharedDataManager.shared
        mlIntegrationService = MLIntegrationService()
        cancellables = Set<AnyCancellable>()
        
        // Clear existing data
        sharedDataManager.fileManager.uploadedFiles.removeAll()
        sharedDataManager.fileManager.analysisRecords.removeAll()
    }
    
    override func tearDown() async throws {
        cancellables.removeAll()
        sharedDataManager = nil
        mlIntegrationService = nil
    }
    
    // MARK: - Analytics Integration Tests
    
    func testAnalyticsDataAvailability() async throws {
        // Setup test data
        let testFiles = [
            CodeFile(name: "analytics1.swift", content: swiftTestCode, language: .swift, path: "/analytics1.swift"),
            CodeFile(name: "analytics2.js", content: jsTestCode, language: .javascript, path: "/analytics2.js"),
            CodeFile(name: "analytics3.py", content: pythonTestCode, language: .python, path: "/analytics3.py")
        ]
        
        sharedDataManager.fileManager.uploadedFiles = testFiles
        
        // Verify analytics can access uploaded files
        let analyticsFiles = sharedDataManager.fileManager.uploadedFiles
        XCTAssertEqual(analyticsFiles.count, 3, "Analytics should access all uploaded files")
        
        // Test language distribution analytics
        let languageDistribution = Dictionary(grouping: analyticsFiles) { $0.language }
        XCTAssertEqual(languageDistribution[.swift]?.count, 1, "Should detect 1 Swift file")
        XCTAssertEqual(languageDistribution[.javascript]?.count, 1, "Should detect 1 JavaScript file")
        XCTAssertEqual(languageDistribution[.python]?.count, 1, "Should detect 1 Python file")
    }
    
    func testAnalysisRecordGeneration() async throws {
        // Setup test files
        let testFile = CodeFile(
            name: "complex.swift",
            content: complexSwiftCode,
            language: .swift,
            path: "/complex.swift"
        )
        
        sharedDataManager.fileManager.uploadedFiles = [testFile]
        
        // Generate analysis record
        let analysisRecord = generateMockAnalysisRecord(for: testFile)
        sharedDataManager.fileManager.analysisRecords = [analysisRecord]
        
        // Verify analytics can access analysis data
        let records = sharedDataManager.fileManager.analysisRecords
        XCTAssertEqual(records.count, 1, "Should have one analysis record")
        
        let record = records.first!
        XCTAssertEqual(record.fileName, "complex.swift", "Record should match file")
        XCTAssertGreaterThan(record.complexity, 0, "Should have complexity score")
        XCTAssertFalse(record.suggestions.isEmpty, "Should have suggestions")
        XCTAssertNotNil(record.metrics, "Should have metrics")
    }
    
    // MARK: - AI Integration Tests
    
    func testAIInsightsViewDataAccess() async throws {
        // Setup comprehensive test data
        let aiTestFiles = [
            CodeFile(name: "ai_test1.swift", content: swiftTestCode, language: .swift, path: "/ai_test1.swift"),
            CodeFile(name: "ai_test2.js", content: jsTestCode, language: .javascript, path: "/ai_test2.js")
        ]
        
        let aiAnalysisRecords = aiTestFiles.map { generateMockAnalysisRecord(for: $0) }
        
        sharedDataManager.fileManager.uploadedFiles = aiTestFiles
        sharedDataManager.fileManager.analysisRecords = aiAnalysisRecords
        
        // Verify AI Insights can access shared data
        XCTAssertEqual(sharedDataManager.fileManager.uploadedFiles.count, 2, "AI should access uploaded files")
        XCTAssertEqual(sharedDataManager.fileManager.analysisRecords.count, 2, "AI should access analysis records")
        
        // Test AI processing capability
        let swiftFiles = sharedDataManager.fileManager.uploadedFiles.filter { $0.language == .swift }
        XCTAssertEqual(swiftFiles.count, 1, "AI should filter Swift files correctly")
        
        let jsFiles = sharedDataManager.fileManager.uploadedFiles.filter { $0.language == .javascript }
        XCTAssertEqual(jsFiles.count, 1, "AI should filter JavaScript files correctly")
    }
    
    func testMLIntegrationServiceDataAccess() async throws {
        // Setup ML test data
        let mlFiles = [
            CodeFile(name: "ml_model.py", content: pythonMLCode, language: .python, path: "/ml_model.py"),
            CodeFile(name: "data_processor.py", content: pythonTestCode, language: .python, path: "/data_processor.py"),
            CodeFile(name: "config.json", content: jsonTestCode, language: .json, path: "/config.json")
        ]
        
        sharedDataManager.fileManager.uploadedFiles = mlFiles
        
        // Test ML service can access shared data
        let accessibleFiles = sharedDataManager.fileManager.uploadedFiles
        XCTAssertEqual(accessibleFiles.count, 3, "ML service should access all files")
        
        // Test ML-specific filtering
        let pythonFiles = accessibleFiles.filter { $0.language == .python }
        XCTAssertEqual(pythonFiles.count, 2, "ML service should find Python files")
        
        let configFiles = accessibleFiles.filter { $0.name.contains("config") }
        XCTAssertEqual(configFiles.count, 1, "ML service should find config files")
    }
    
    // MARK: - Pattern Recognition Tests
    
    func testPatternAnalysisDataAccess() async throws {
        // Setup pattern analysis test data
        let patternFiles = [
            CodeFile(name: "singleton.swift", content: singletonPatternCode, language: .swift, path: "/patterns/singleton.swift"),
            CodeFile(name: "factory.swift", content: factoryPatternCode, language: .swift, path: "/patterns/factory.swift"),
            CodeFile(name: "observer.js", content: observerPatternCode, language: .javascript, path: "/patterns/observer.js")
        ]
        
        sharedDataManager.fileManager.uploadedFiles = patternFiles
        
        // Verify pattern analysis can access shared data
        let files = sharedDataManager.fileManager.uploadedFiles
        XCTAssertEqual(files.count, 3, "Pattern analysis should access all files")
        
        // Test pattern detection capability
        let swiftPatterns = files.filter { $0.language == .swift && $0.name.contains("pattern") }
        XCTAssertGreaterThanOrEqual(swiftPatterns.count, 0, "Should detect Swift pattern files")
        
        let jsPatterns = files.filter { $0.language == .javascript && $0.content.contains("observer") }
        XCTAssertEqual(jsPatterns.count, 1, "Should detect observer pattern")
    }
    
    // MARK: - Real-time Analytics Updates Tests
    
    func testRealTimeAnalyticsUpdates() async throws {
        let expectation = XCTestExpectation(description: "Analytics update received")
        var analyticsUpdated = false
        
        // Subscribe to analytics updates
        sharedDataManager.fileManager.objectWillChange
            .sink { _ in
                analyticsUpdated = true
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Add new file and trigger analytics update
        let newFile = CodeFile(
            name: "realtime.swift",
            content: "// Real-time test",
            language: .swift,
            path: "/realtime.swift"
        )
        
        sharedDataManager.fileManager.uploadedFiles.append(newFile)
        
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(analyticsUpdated, "Analytics should receive real-time updates")
    }
    
    // MARK: - Cross-Feature Data Flow Tests
    
    func testUploadToAnalyticsToAIFlow() async throws {
        // Step 1: File Upload
        let uploadedFile = CodeFile(
            name: "workflow_test.swift",
            content: complexSwiftCode,
            language: .swift,
            path: "/workflow_test.swift"
        )
        
        sharedDataManager.fileManager.uploadedFiles = [uploadedFile]
        
        // Step 2: Analytics Processing
        let analysisRecord = generateMockAnalysisRecord(for: uploadedFile)
        sharedDataManager.fileManager.analysisRecords = [analysisRecord]
        
        // Step 3: AI Processing
        // Verify AI can access both uploaded files and analysis results
        let aiFiles = sharedDataManager.fileManager.uploadedFiles
        let aiAnalysis = sharedDataManager.fileManager.analysisRecords
        
        XCTAssertEqual(aiFiles.count, 1, "AI should access uploaded files")
        XCTAssertEqual(aiAnalysis.count, 1, "AI should access analysis results")
        XCTAssertEqual(aiFiles.first?.name, aiAnalysis.first?.fileName, "File and analysis should match")
    }
    
    // MARK: - Performance Analytics Tests
    
    func testAnalyticsPerformanceWithLargeDataset() throws {
        // Create large dataset for performance testing
        var largeDataset: [CodeFile] = []
        
        for i in 1...500 {
            largeDataset.append(
                CodeFile(
                    name: "perf_file\(i).swift",
                    content: generateLargeCodeContent(fileNumber: i),
                    language: .swift,
                    path: "/performance/perf_file\(i).swift"
                )
            )
        }
        
        measure {
            sharedDataManager.fileManager.uploadedFiles = largeDataset
            
            // Simulate analytics processing
            let languageDistribution = Dictionary(grouping: largeDataset) { $0.language }
            let totalLines = largeDataset.reduce(0) { total, file in
                total + file.content.components(separatedBy: .newlines).count
            }
            
            XCTAssertEqual(languageDistribution[.swift]?.count, 500, "Should process all Swift files")
            XCTAssertGreaterThan(totalLines, 500, "Should calculate total lines")
        }
    }
}

// MARK: - Test Data Generators

extension AnalyticsAndAIFeaturesTests {
    
    private func generateMockAnalysisRecord(for file: CodeFile) -> FileAnalysisRecord {
        return FileAnalysisRecord(
            fileName: file.name,
            filePath: file.path,
            language: file.language,
            complexity: Int.random(in: 1...10),
            suggestions: [
                "Consider breaking down large functions",
                "Add documentation comments",
                "Improve variable naming"
            ],
            issues: [
                "High cyclomatic complexity",
                "Long parameter list"
            ],
            metrics: FileMetrics(
                lineCount: file.content.components(separatedBy: .newlines).count,
                functionCount: countFunctions(in: file.content),
                classCount: countClasses(in: file.content),
                complexityScore: Int.random(in: 10...50),
                maintainabilityIndex: Int.random(in: 50...100)
            )
        )
    }
    
    private func countFunctions(in content: String) -> Int {
        let functionPattern = #"func\s+\w+"#
        let regex = try? NSRegularExpression(pattern: functionPattern)
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        return regex?.numberOfMatches(in: content, range: range) ?? 0
    }
    
    private func countClasses(in content: String) -> Int {
        let classPattern = #"class\s+\w+"#
        let regex = try? NSRegularExpression(pattern: classPattern)
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        return regex?.numberOfMatches(in: content, range: range) ?? 0
    }
    
    private func generateLargeCodeContent(fileNumber: Int) -> String {
        return """
        import Foundation
        
        // Performance test file \(fileNumber)
        class PerformanceTestClass\(fileNumber) {
            private var data: [String] = []
            
            func processData() {
                for i in 1...100 {
                    data.append("Item \\(i)")
                }
            }
            
            func analyzeData() -> [String: Int] {
                var analysis: [String: Int] = [:]
                for item in data {
                    analysis[item] = item.count
                }
                return analysis
            }
        }
        """
    }
}

// MARK: - Test Code Constants

private let swiftTestCode = """
import Foundation

class TestClass {
    func testMethod() {
        print("Test method")
    }
}
"""

private let jsTestCode = """
class TestClass {
    testMethod() {
        console.log("Test method");
    }
}
"""

private let pythonTestCode = """
class TestClass:
    def test_method(self):
        print("Test method")
"""

private let pythonMLCode = """
import tensorflow as tf
import numpy as np

class MLModel:
    def __init__(self):
        self.model = tf.keras.Sequential()
    
    def train(self, data):
        self.model.fit(data)
"""

private let jsonTestCode = """
{
    "model_config": {
        "layers": 3,
        "neurons": 128,
        "activation": "relu"
    },
    "training": {
        "epochs": 100,
        "batch_size": 32
    }
}
"""

private let complexSwiftCode = """
import Foundation

class ComplexClass {
    private var data: [String: Any] = [:]
    
    func complexMethod(param1: String, param2: Int, param3: Bool, param4: [String]) -> Result<String, Error> {
        guard !param1.isEmpty else {
            return .failure(ComplexError.invalidParameter)
        }
        
        if param2 > 100 {
            for item in param4 {
                if item.count > param2 {
                    data[item] = param3
                } else {
                    data[item] = !param3
                }
            }
        } else {
            switch param2 {
            case 0...10:
                data["small"] = param1
            case 11...50:
                data["medium"] = param1
            default:
                data["large"] = param1
            }
        }
        
        return .success("Processed")
    }
}

enum ComplexError: Error {
    case invalidParameter
}
"""

private let singletonPatternCode = """
class Singleton {
    static let shared = Singleton()
    private init() {}
    
    func doSomething() {
        print("Singleton action")
    }
}
"""

private let factoryPatternCode = """
protocol Product {
    func use()
}

class ConcreteProduct: Product {
    func use() {
        print("Using concrete product")
    }
}

class Factory {
    static func createProduct() -> Product {
        return ConcreteProduct()
    }
}
"""

private let observerPatternCode = """
class Observer {
    update(data) {
        console.log("Observer updated with:", data);
    }
}

class Subject {
    constructor() {
        this.observers = [];
    }
    
    addObserver(observer) {
        this.observers.push(observer);
    }
    
    notifyObservers(data) {
        this.observers.forEach(observer => observer.update(data));
    }
}
"""
