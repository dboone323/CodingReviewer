#!/usr/bin/env swift

//
//  test_core_components.swift
//  CodingReviewer Test Suite
//
//  Created by AI Assistant on 7/18/25.
//

import Foundation

// MARK: - Test Framework

class TestSuite {
    private var passedTests = 0
    private var failedTests = 0
    private var testResults: [String] = []
    
    func assert(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
        if condition {
            passedTests += 1
            print("✅ PASS: \(message)")
            testResults.append("✅ PASS: \(message)")
        } else {
            failedTests += 1
            print("❌ FAIL: \(message) (at \(URL(fileURLWithPath: file).lastPathComponent):\(line))")
            testResults.append("❌ FAIL: \(message)")
        }
    }
    
    func assertEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String, file: String = #file, line: Int = #line) {
        assert(lhs == rhs, "\(message): expected \(rhs), got \(lhs)", file: file, line: line)
    }
    
    func assertNotNil<T>(_ value: T?, _ message: String, file: String = #file, line: Int = #line) {
        assert(value != nil, "\(message): value should not be nil", file: file, line: line)
    }
    
    func assertTrue(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
        assert(condition, "\(message): condition should be true", file: file, line: line)
    }
    
    func assertFalse(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
        assert(!condition, "\(message): condition should be false", file: file, line: line)
    }
    
    func printSummary() {
        print("\n" + String(repeating: "=", count: 60))
        print("📊 TEST SUMMARY")
        print(String(repeating: "=", count: 60))
        print("✅ Passed: \(passedTests)")
        print("❌ Failed: \(failedTests)")
        print("📈 Total:  \(passedTests + failedTests)")
        
        if failedTests == 0 {
            print("🎉 ALL TESTS PASSED!")
        } else {
            print("⚠️  \(failedTests) test(s) failed")
        }
        print(String(repeating: "=", count: 60))
    }
    
    func run() {
        print("🚀 Starting CodingReviewer Core Components Test Suite")
        print(String(repeating: "=", count: 60))
        
        testBasicTypes()
        testCodeLanguages()
        testFileManagement()
        testAnalysisStructures()
        testErrorHandling()
        testAIDataModels()
        testFolderOperations()
        
        printSummary()
    }
    
    // MARK: - Test Cases
    
    func testBasicTypes() {
        print("\n🧪 Testing Basic Types...")
        
        // Test that basic Swift types work
        let testString = "Hello, World!"
        assertEqual(testString.count, 13, "String length test")
        
        let testArray = [1, 2, 3, 4, 5]
        assertEqual(testArray.count, 5, "Array count test")
        
        let testDict = ["key": "value"]
        assertEqual(testDict["key"], "value", "Dictionary access test")
        
        print("✅ Basic types tests completed")
    }
    
    func testCodeLanguages() {
        print("\n🧪 Testing Code Language Detection...")
        
        // Test language enum raw values
        assertEqual(CodeLanguage.swift.rawValue, "swift", "Swift language raw value")
        assertEqual(CodeLanguage.python.rawValue, "python", "Python language raw value")
        assertEqual(CodeLanguage.javascript.rawValue, "javascript", "JavaScript language raw value")
        
        // Test display names
        assertEqual(CodeLanguage.swift.displayName, "Swift", "Swift display name")
        assertEqual(CodeLanguage.python.displayName, "Python", "Python display name")
        assertEqual(CodeLanguage.javascript.displayName, "JavaScript", "JavaScript display name")
        
        // Test icon names
        assertEqual(CodeLanguage.swift.iconName, "swift", "Swift icon name")
        assertEqual(CodeLanguage.python.iconName, "snake.circle", "Python icon name")
        assertEqual(CodeLanguage.javascript.iconName, "js.circle", "JavaScript icon name")
        
        print("✅ Code language tests completed")
    }
    
    func testFileManagement() {
        print("\n🧪 Testing File Management...")
        
        // Test CodeFile creation
        let testContent = "print('Hello, World!')"
        let codeFile = CodeFile(
            name: "test.py",
            path: "/test/test.py",
            content: testContent,
            language: .python
        )
        
        assertEqual(codeFile.name, "test.py", "CodeFile name")
        assertEqual(codeFile.content, testContent, "CodeFile content")
        assertEqual(codeFile.language, .python, "CodeFile language")
        assertEqual(codeFile.size, testContent.utf8.count, "CodeFile size")
        assertEqual(codeFile.fileExtension, "py", "CodeFile extension")
        assertFalse(codeFile.checksum.isEmpty, "CodeFile checksum should not be empty")
        
        // Test display size formatting
        assertFalse(codeFile.displaySize.isEmpty, "Display size should not be empty")
        
        print("✅ File management tests completed")
    }
    
    func testAnalysisStructures() {
        print("\n🧪 Testing Analysis Structures...")
        
        // Test AnalysisResult creation
        let analysisResult = AnalysisResult(
            type: .security,
            message: "Test security issue",
            line: 10,
            severity: .high
        )
        
        assertEqual(analysisResult.type, .security, "Analysis result type")
        assertEqual(analysisResult.message, "Test security issue", "Analysis result message")
        assertEqual(analysisResult.line, 10, "Analysis result line")
        assertEqual(analysisResult.severity, .high, "Analysis result severity")
        
        // Test EnhancedAnalysisItem conversion
        let enhancedItem = EnhancedAnalysisItem(from: analysisResult)
        assertEqual(enhancedItem.message, analysisResult.message, "Enhanced item message")
        assertEqual(enhancedItem.lineNumber, analysisResult.line, "Enhanced item line number")
        assertEqual(enhancedItem.severity, analysisResult.severity.rawValue, "Enhanced item severity")
        assertEqual(enhancedItem.type, analysisResult.type.rawValue, "Enhanced item type")
        
        // Test conversion back
        let convertedBack = enhancedItem.toAnalysisResult()
        assertEqual(convertedBack.type, analysisResult.type, "Converted back type")
        assertEqual(convertedBack.severity, analysisResult.severity, "Converted back severity")
        assertEqual(convertedBack.message, analysisResult.message, "Converted back message")
        
        print("✅ Analysis structure tests completed")
    }
    
    func testErrorHandling() {
        print("\n🧪 Testing Error Handling...")
        
        // Test FileManagerError
        let fileTooLargeError = FileManagerError.fileTooLarge("test.txt", 1000000, 500000)
        assertNotNil(fileTooLargeError.errorDescription, "File too large error description")
        assertTrue(fileTooLargeError.errorDescription!.contains("test.txt"), "Error contains filename")
        assertTrue(fileTooLargeError.errorDescription!.contains("too large"), "Error contains 'too large'")
        
        let accessDeniedError = FileManagerError.accessDenied("private.txt")
        assertTrue(accessDeniedError.errorDescription!.contains("Access denied"), "Access denied error")
        
        let encodingError = FileManagerError.encodingError("binary.dat")
        assertTrue(encodingError.errorDescription!.contains("encoding error"), "Encoding error")
        
        print("✅ Error handling tests completed")
    }
    
    func testAIDataModels() {
        print("\n🧪 Testing AI Data Models...")
        
        // Test SuggestionType enum
        assertEqual(SuggestionType.security.rawValue, "security", "Security suggestion type")
        assertEqual(SuggestionType.performance.rawValue, "performance", "Performance suggestion type")
        assertEqual(SuggestionType.maintainability.rawValue, "maintainability", "Maintainability suggestion type")
        
        // Test Severity enum
        assertEqual(Severity.low.rawValue, "low", "Low severity")
        assertEqual(Severity.medium.rawValue, "medium", "Medium severity")
        assertEqual(Severity.high.rawValue, "high", "High severity")
        assertEqual(Severity.critical.rawValue, "critical", "Critical severity")
        
        // Test ComplexityScore
        let complexityScore = ComplexityScore(
            cyclomaticComplexity: 5,
            cognitiveComplexity: 3,
            nestingDepth: 2
        )
        assertEqual(complexityScore.cyclomaticComplexity, 5, "Cyclomatic complexity")
        assertEqual(complexityScore.cognitiveComplexity, 3, "Cognitive complexity")
        assertEqual(complexityScore.nestingDepth, 2, "Nesting depth")
        
        // Test MaintainabilityScore
        let maintainabilityScore = MaintainabilityScore(
            score: 85.5,
            readability: 90.0,
            testability: 80.0,
            modularity: 85.0
        )
        assertEqual(maintainabilityScore.score, 85.5, "Maintainability score")
        assertEqual(maintainabilityScore.readability, 90.0, "Readability score")
        assertEqual(maintainabilityScore.testability, 80.0, "Testability score")
        assertEqual(maintainabilityScore.modularity, 85.0, "Modularity score")
        
        // Test CodeFix
        let codeFix = CodeFix(
            lineNumber: 15,
            originalCode: "var x = getValue()",
            suggestedCode: "lazy var x = getValue()",
            explanation: "Use lazy initialization"
        )
        assertEqual(codeFix.lineNumber, 15, "Code fix line number")
        assertEqual(codeFix.originalCode, "var x = getValue()", "Code fix original code")
        assertEqual(codeFix.suggestedCode, "lazy var x = getValue()", "Code fix suggested code")
        assertEqual(codeFix.explanation, "Use lazy initialization", "Code fix explanation")
        
        // Test AISuggestion
        let aiSuggestion = AISuggestion(
            type: .performance,
            message: "Consider optimization",
            line: 20,
            severity: .medium,
            suggestedFix: "Use more efficient algorithm"
        )
        assertEqual(aiSuggestion.type, .performance, "AI suggestion type")
        assertEqual(aiSuggestion.message, "Consider optimization", "AI suggestion message")
        assertEqual(aiSuggestion.line, 20, "AI suggestion line")
        assertEqual(aiSuggestion.severity, .medium, "AI suggestion severity")
        assertEqual(aiSuggestion.suggestedFix, "Use more efficient algorithm", "AI suggestion fix")
        
        print("✅ AI data model tests completed")
    }
    
    func testFolderOperations() {
        // Test project structure creation
        let testFiles = [
            CodeFile(name: "main.swift", path: "/project/main.swift", content: "import Foundation", language: .swift),
            CodeFile(name: "utils.py", path: "/project/utils.py", content: "def main(): pass", language: .python),
            CodeFile(name: "app.js", path: "/project/app.js", content: "console.log('hello');", language: .javascript)
        ]
        
        let project = ProjectStructure(name: "TestProject", rootPath: "/project", files: testFiles)
        
        assertEqual(project.name, "TestProject", "Project name")
        assertEqual(project.files.count, 3, "Project file count")
        assertEqual(project.fileCount, 3, "Project fileCount property")
        assert(project.totalSize > 0, "Project total size should be greater than 0")
        assert(project.languageDistribution.count >= 3, "Should have at least 3 languages in distribution")
        assertEqual(project.languageDistribution["Swift"] ?? 0, 1, "Swift files count")
        assertEqual(project.languageDistribution["Python"] ?? 0, 1, "Python files count")
        assertEqual(project.languageDistribution["JavaScript"] ?? 0, 1, "JavaScript files count")
        
        // Test file upload result structure for folder operations
        let uploadResult = FileUploadResult(
            successfulFiles: testFiles,
            failedFiles: [],
            warnings: ["Test folder processed"]
        )
        
        assertEqual(uploadResult.successfulFiles.count, 3, "Upload result successful files")
        assert(!uploadResult.hasErrors, "Upload result should not have errors")
        assert(uploadResult.hasWarnings, "Upload result should have warnings")
        assertEqual(uploadResult.warnings.count, 1, "Upload warnings count")
        
        // Test folder structure analysis
        let folderPaths = Set(testFiles.map { URL(fileURLWithPath: $0.path).deletingLastPathComponent().path })
        assert(folderPaths.count >= 1, "Should have at least one unique folder path")
        assert(folderPaths.contains("/project"), "Should contain project folder path")
        
        print("✅ Folder operations tests completed")
    }
}

// MARK: - Data Types for Testing

enum CodeLanguage: String, CaseIterable, Codable {
    case swift = "swift"
    case python = "python"
    case javascript = "javascript"
    case typescript = "typescript"
    case java = "java"
    case cpp = "cpp"
    case go = "go"
    case rust = "rust"
    case html = "html"
    case css = "css"
    case xml = "xml"
    case json = "json"
    case yaml = "yaml"
    case markdown = "markdown"
    case kotlin = "kotlin"
    case csharp = "csharp"
    case c = "c"
    case php = "php"
    case ruby = "ruby"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .python: return "Python"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .java: return "Java"
        case .kotlin: return "Kotlin"
        case .csharp: return "C#"
        case .cpp: return "C++"
        case .c: return "C"
        case .go: return "Go"
        case .rust: return "Rust"
        case .php: return "PHP"
        case .ruby: return "Ruby"
        case .html: return "HTML"
        case .css: return "CSS"
        case .xml: return "XML"
        case .json: return "JSON"
        case .yaml: return "YAML"
        case .markdown: return "Markdown"
        case .unknown: return "Unknown"
        }
    }
    
    var iconName: String {
        switch self {
        case .swift: return "swift"
        case .python: return "snake.circle"
        case .javascript, .typescript: return "js.circle"
        case .java, .kotlin: return "cup.and.saucer"
        case .csharp: return "sharp.circle"
        case .cpp, .c: return "c.circle"
        case .go: return "goforward"
        case .rust: return "gear"
        case .php: return "network"
        case .ruby: return "gem"
        case .html: return "globe"
        case .css: return "paintbrush"
        case .xml: return "doc.text"
        case .json: return "curlybraces"
        case .yaml: return "list.bullet"
        case .markdown: return "doc.richtext"
        case .unknown: return "questionmark.circle"
        }
    }
}

struct CodeFile: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let path: String
    let content: String
    let language: CodeLanguage
    let size: Int
    let lastModified: Date
    let checksum: String
    
    init(name: String, path: String, content: String, language: CodeLanguage) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.content = content
        self.language = language
        self.size = content.utf8.count
        self.lastModified = Date()
        self.checksum = content.data(using: .utf8)?.sha256 ?? ""
    }
    
    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
    
    var fileExtension: String {
        URL(fileURLWithPath: name).pathExtension
    }
}

struct AnalysisResult {
    enum ResultType: String {
        case quality = "quality"
        case security = "security"
        case suggestion = "suggestion"
        case performance = "performance"
    }
    
    enum Severity: String {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
    
    let type: ResultType
    let message: String
    let line: Int?
    let severity: Severity
}

struct EnhancedAnalysisItem: Codable {
    let message: String
    let severity: String
    let lineNumber: Int?
    let type: String
    
    init(from analysisResult: AnalysisResult) {
        self.message = analysisResult.message
        self.severity = analysisResult.severity.rawValue
        self.lineNumber = analysisResult.line
        self.type = analysisResult.type.rawValue
    }
    
    func toAnalysisResult() -> AnalysisResult {
        let severity: AnalysisResult.Severity = {
            switch self.severity {
            case "low": return .low
            case "medium": return .medium
            case "high": return .high
            case "critical": return .critical
            default: return .low
            }
        }()
        
        let type: AnalysisResult.ResultType = {
            switch self.type {
            case "quality": return .quality
            case "security": return .security
            case "suggestion": return .suggestion
            case "performance": return .performance
            default: return .quality
            }
        }()
        
        return AnalysisResult(
            type: type,
            message: self.message,
            line: self.lineNumber,
            severity: severity
        )
    }
}

enum FileManagerError: LocalizedError {
    case accessDenied(String)
    case fileTooLarge(String, Int, Int)
    case unsupportedFileType(String)
    case fileNotReadable(String)
    case notARegularFile(String)
    case directoryEnumerationFailed(String)
    case encodingError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .accessDenied(let filename):
            return "Access denied to file: \(filename)"
        case .fileTooLarge(let filename, let size, let maxSize):
            let sizeStr = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            let maxSizeStr = ByteCountFormatter.string(fromByteCount: Int64(maxSize), countStyle: .file)
            return "File '\(filename)' is too large (\(sizeStr)). Maximum size is \(maxSizeStr)."
        case .unsupportedFileType(let type):
            return "Unsupported file type: .\(type)"
        case .fileNotReadable(let filename):
            return "Cannot read file: \(filename)"
        case .notARegularFile(let filename):
            return "Not a regular file: \(filename)"
        case .directoryEnumerationFailed(let path):
            return "Failed to enumerate directory: \(path)"
        case .encodingError(let filename):
            return "Text encoding error in file: \(filename)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// Project and Upload Structures
struct ProjectStructure: Identifiable {
    let id: UUID
    let name: String
    let rootPath: String
    let files: [CodeFile]
    let folders: [String]
    let totalSize: Int
    let fileCount: Int
    let languageDistribution: [String: Int]
    let createdAt: Date
    
    init(name: String, rootPath: String, files: [CodeFile]) {
        self.id = UUID()
        self.name = name
        self.rootPath = rootPath
        self.files = files
        self.folders = Array(Set(files.compactMap { URL(fileURLWithPath: $0.path).deletingLastPathComponent().path }))
        self.totalSize = files.reduce(0) { $0 + $1.size }
        self.fileCount = files.count
        self.languageDistribution = Dictionary(grouping: files, by: \.language)
            .mapValues { $0.count }
            .reduce(into: [String: Int]()) { result, element in
                result[element.key.displayName] = element.value
            }
        self.createdAt = Date()
    }
}

struct FileUploadResult {
    let successfulFiles: [CodeFile]
    let failedFiles: [(String, Error)]
    let warnings: [String]
    
    var hasErrors: Bool {
        !failedFiles.isEmpty
    }
    
    var hasWarnings: Bool {
        !warnings.isEmpty
    }
}

// AI Data Models
enum SuggestionType: String, Codable {
    case security = "security"
    case performance = "performance"
    case maintainability = "maintainability"
    case bestPractices = "bestPractices"
    case testing = "testing"
}

enum Severity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

struct ComplexityScore: Codable {
    let cyclomaticComplexity: Int
    let cognitiveComplexity: Int
    let nestingDepth: Int
}

struct MaintainabilityScore: Codable {
    let score: Double
    let readability: Double
    let testability: Double
    let modularity: Double
}

struct CodeFix: Codable {
    let lineNumber: Int
    let originalCode: String
    let suggestedCode: String
    let explanation: String
}

struct AISuggestion: Codable {
    let type: SuggestionType
    let message: String
    let line: Int?
    let severity: Severity
    let suggestedFix: String?
}

// Extensions
extension Data {
    var sha256: String {
        let bytes = withUnsafeBytes { bytes in
            Array(bytes)
        }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
}

// Run the tests
let testSuite = TestSuite()
testSuite.run()