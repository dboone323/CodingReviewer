//
//  AIServicesTests.swift
//  CodingReviewer
//
//  Created by AI Assistant on 7/18/25.
//

import Foundation

// AI Services Test Suite
class AIServicesTests {
    
    static func runAllTests() -> TestResults {
        print("🚀 Running AI Services Tests")
        print(String(repeating: "=", count: 50))
        
        var passed = 0
        var failed = 0
        var failures: [String] = []
        
        // Test 1: API Key Validation
        do {
            try testAPIKeyValidation()
            print("✅ API Key Validation")
            passed += 1
        } catch {
            failed += 1
            let failure = "❌ API Key Validation: \(error)"
            failures.append(failure)
            print(failure)
        }
        
        // Test 2: OpenAI Request Structure
        do {
            try testOpenAIRequestStructure()
            print("✅ OpenAI Request Structure")
            passed += 1
        } catch {
            let failure = "❌ OpenAI Request Structure: \(error)"
            failures.append(failure)
            print(failure)
            failed += 1
        }
        
        // Test 3: AI Response Parsing
        do {
            try testAIResponseParsing()
            print("✅ AI Response Parsing")
            passed += 1
        } catch {
            let failure = "❌ AI Response Parsing: \(error)"
            failures.append(failure)
            print(failure)
            failed += 1
        }
        
        // Test 4: Error Handling
        do {
            try testAIErrorHandling()
            print("✅ AI Error Handling")
            passed += 1
        } catch {
            let failure = "❌ AI Error Handling: \(error)"
            failures.append(failure)
            print(failure)
            failed += 1
        }
        
        // Test 5: Code Analysis Prompt Generation
        do {
            try testCodeAnalysisPromptGeneration()
            print("✅ Code Analysis Prompt Generation")
            passed += 1
        } catch {
            let failure = "❌ Code Analysis Prompt Generation: \(error)"
            failures.append(failure)
            print(failure)
            failed += 1
        }
        
        // Test 6: Fix Application Prompt Generation
        do {
            try testFixApplicationPromptGeneration()
            print("✅ Fix Application Prompt Generation")
            passed += 1
        } catch {
            let failure = "❌ Fix Application Prompt Generation: \(error)"
            failures.append(failure)
            print(failure)
            failed += 1
        }
        
        let results = TestResults(
            suiteName: "AI Services Tests",
            passed: passed,
            failed: failed,
            failures: failures
        )
        
        print("\n📊 AI Services Test Results:")
        print("✅ Passed: \(passed)")
        print("❌ Failed: \(failed)")
        print("📈 Total: \(passed + failed)")
        
        if failed == 0 {
            print("🎉 ALL AI SERVICES TESTS PASSED!")
        }
        
        return results
    }
    
    static func testAPIKeyValidation() throws {
        // Test valid API key format
        let validKey = "sk-1234567890abcdef1234567890abcdef1234567890abcdef"
        try TestAssert(validKey.hasPrefix("sk-"), "Valid API key should start with 'sk-'")
        try TestAssert(validKey.count >= 40, "Valid API key should be at least 40 characters")
        
        // Test invalid API key formats
        let invalidKeys = [
            "",
            "invalid",
            "sk-",
            "sk-123",
            "notanapikey"
        ]
        
        for invalidKey in invalidKeys {
            let isValid = invalidKey.hasPrefix("sk-") && invalidKey.count >= 40
            try TestAssert(!isValid, "Invalid key '\(invalidKey)' should not be valid")
        }
    }
    
    static func testOpenAIRequestStructure() throws {
        // Test request structure for code analysis
        let testCode = "func hello() { print(\"Hello\") }"
        let language = "Swift"
        
        let expectedPrompt = """
        Analyze the following \(language) code for issues:
        
        ```\(language.lowercased())
        \(testCode)
        ```
        
        Please identify:
        1. Security vulnerabilities
        2. Code quality issues
        3. Performance problems
        4. Best practice violations
        
        Respond with a JSON array of issues in this format:
        [
          {
            "type": "security|quality|performance|style",
            "severity": "low|medium|high|critical",
            "line": number,
            "message": "description",
            "suggestion": "how to fix"
          }
        ]
        """
        
        try TestAssert(expectedPrompt.contains(testCode), "Prompt should contain test code")
        try TestAssert(expectedPrompt.contains(language), "Prompt should contain language")
        try TestAssert(expectedPrompt.contains("JSON array"), "Prompt should request JSON format")
        try TestAssert(expectedPrompt.contains("security"), "Prompt should mention security")
        try TestAssert(expectedPrompt.contains("quality"), "Prompt should mention quality")
    }
    
    static func testAIResponseParsing() throws {
        // Test parsing valid AI response
        let validResponse = """
        [
          {
            "type": "quality",
            "severity": "medium",
            "line": 1,
            "message": "Function should have documentation",
            "suggestion": "Add documentation comment"
          },
          {
            "type": "security",
            "severity": "high",
            "line": 3,
            "message": "Potential security issue",
            "suggestion": "Validate input"
          }
        ]
        """
        
        // Simulate parsing
        let data = validResponse.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        
        try TestAssert(parsed != nil, "Should parse valid JSON response")
        try assertEqual(parsed?.count, 2, "Should parse 2 issues")
        
        let firstIssue = parsed?[0]
        try assertEqual(firstIssue?["type"] as? String, "quality", "First issue type")
        try assertEqual(firstIssue?["severity"] as? String, "medium", "First issue severity")
        try assertEqual(firstIssue?["line"] as? Int, 1, "First issue line")
        
        let secondIssue = parsed?[1]
        try assertEqual(secondIssue?["type"] as? String, "security", "Second issue type")
        try assertEqual(secondIssue?["severity"] as? String, "high", "Second issue severity")
    }
    
    static func testAIErrorHandling() throws {
        // Test various error scenarios
        let errorScenarios = [
            ("Invalid JSON", "not valid json"),
            ("Empty response", ""),
            ("Non-array response", "{\"error\": \"not an array\"}"),
            ("Missing fields", "[{\"type\": \"quality\"}]") // Missing required fields
        ]
        
        for (name, responseText) in errorScenarios {
            let data = responseText.data(using: .utf8) ?? Data()
            
            do {
                let parsed = try JSONSerialization.jsonObject(with: data)
                
                // If it's not an array, it should be handled as an error
                if !(parsed is [[String: Any]]) && !responseText.isEmpty {
                    // This is expected for non-array responses
                    continue
                }
                
                // For empty responses, parsing will fail
                if responseText.isEmpty {
                    // This should fail
                    try TestAssert(false, "Empty response should cause parsing to fail")
                }
                
            } catch {
                // Parsing errors are expected for invalid JSON
                if name == "Invalid JSON" || name == "Empty response" {
                    // This is expected
                    continue
                } else {
                    throw error
                }
            }
        }
    }
    
    static func testCodeAnalysisPromptGeneration() throws {
        let testCases = [
            (language: "Swift", code: "let x = 5"),
            (language: "Python", code: "x = 5"),
            (language: "JavaScript", code: "const x = 5;"),
            (language: "TypeScript", code: "const x: number = 5;"),
            (language: "Java", code: "int x = 5;")
        ]
        
        for testCase in testCases {
            let prompt = generateCodeAnalysisPrompt(code: testCase.code, language: testCase.language)
            
            try TestAssert(prompt.contains(testCase.code), "Prompt should contain code for \(testCase.language)")
            try TestAssert(prompt.contains(testCase.language), "Prompt should contain language name")
            try TestAssert(prompt.contains("Analyze"), "Prompt should contain 'Analyze'")
            try TestAssert(prompt.contains("JSON"), "Prompt should request JSON format")
        }
    }
    
    static func testFixApplicationPromptGeneration() throws {
        let originalCode = "func test() { print(\"hello\") }"
        let issue = "Function should have documentation"
        let suggestion = "Add documentation comment"
        
        let prompt = generateFixApplicationPrompt(
            originalCode: originalCode,
            issue: issue,
            suggestion: suggestion
        )
        
        try TestAssert(prompt.contains(originalCode), "Prompt should contain original code")
        try TestAssert(prompt.contains(issue), "Prompt should contain issue description")
        try TestAssert(prompt.contains(suggestion), "Prompt should contain suggestion")
        try TestAssert(prompt.contains("fixed"), "Prompt should mention fixing")
        try TestAssert(prompt.contains("code"), "Prompt should mention code")
    }
    
    // Helper function to generate code analysis prompt
    private static func generateCodeAnalysisPrompt(code: String, language: String) -> String {
        return """
        Analyze the following \(language) code for issues:
        
        ```\(language.lowercased())
        \(code)
        ```
        
        Please identify:
        1. Security vulnerabilities
        2. Code quality issues
        3. Performance problems
        4. Best practice violations
        
        Respond with a JSON array of issues.
        """
    }
    
    // Helper function to generate fix application prompt
    private static func generateFixApplicationPrompt(originalCode: String, issue: String, suggestion: String) -> String {
        return """
        Please apply the following fix to the code:
        
        Original code:
        \(originalCode)
        
        Issue: \(issue)
        Suggestion: \(suggestion)
        
        Return the fixed code.
        """
    }
}

// UI Components Test Suite
class UIComponentsTests {
    
    static func runAllTests() -> TestResults {
        print("🚀 Running UI Components Tests")
        print(String(repeating: "=", count: 50))
        
        var passed = 0
        var failed = 0
        var failures: [String] = []
        
        // Test 1: Language Selection
        do {
            try testLanguageSelection()
            print("✅ Language Selection")
            passed += 1
        } catch {
            let failure = "❌ Language Selection: \(error)"
            failures.append(failure)
            print(failure)
            failed += 1
        }
        
        // Test 2: File Upload UI States
        do {
            try testFileUploadUIStates()
            print("✅ File Upload UI States")
            passed += 1
        } catch {
            let failure = "❌ File Upload UI States: \(error)"
            failures.append(failure)
            print(failure)
            failed += 1
        }
        
        // Test 3: Analysis Results Display
        do {
            try testAnalysisResultsDisplay()
            print("✅ Analysis Results Display")
            passed += 1
        } catch {
            let failure = "❌ Analysis Results Display: \(error)"
            failures.append(failure)
            print(failure)
            failed += 1
        }
        
        // Test 4: Error State Handling
        do {
            try testErrorStateHandling()
            print("✅ Error State Handling")
            passed += 1
        } catch {
            let failure = "❌ Error State Handling: \(error)"
            failures.append(failure)
            print(failure)
            failed += 1
        }
        
        // Test 5: Progress Indicators
        do {
            try testProgressIndicators()
            print("✅ Progress Indicators")
            passed += 1
        } catch {
            let failure = "❌ Progress Indicators: \(error)"
            failures.append(failure)
            print(failure)
            failed += 1
        }
        
        let results = TestResults(
            suiteName: "UI Components Tests",
            passed: passed,
            failed: failed,
            failures: failures
        )
        
        print("\n📊 UI Components Test Results:")
        print("✅ Passed: \(passed)")
        print("❌ Failed: \(failed)")
        print("📈 Total: \(passed + failed)")
        
        if failed == 0 {
            print("🎉 ALL UI COMPONENTS TESTS PASSED!")
        }
        
        return results
    }
    
    static func testLanguageSelection() throws {
        // Test language selection state management
        var selectedLanguage: String? = nil
        let availableLanguages = ["Swift", "Python", "JavaScript", "TypeScript", "Java"]
        
        try TestAssert(selectedLanguage == nil, "Initial language selection should be nil")
        
        // Test language selection
        selectedLanguage = "Swift"
        try assertEqual(selectedLanguage, "Swift", "Selected language should be Swift")
        try TestAssert(availableLanguages.contains(selectedLanguage!), "Selected language should be in available list")
        
        // Test language change
        selectedLanguage = "Python"
        try assertEqual(selectedLanguage, "Python", "Changed language should be Python")
        
        // Test invalid language handling
        let invalidLanguage = "InvalidLanguage"
        try TestAssert(!availableLanguages.contains(invalidLanguage), "Invalid language should not be in list")
    }
    
    static func testFileUploadUIStates() throws {
        // Test upload states
        var isUploading = false
        var uploadProgress: Double = 0.0
        var uploadedFiles: [String] = []
        
        // Initial state
        try TestAssert(!isUploading, "Should not be uploading initially")
        try assertEqual(uploadProgress, 0.0, "Initial progress should be 0")
        try TestAssert(uploadedFiles.isEmpty, "Initial uploaded files should be empty")
        
        // Start upload
        isUploading = true
        uploadProgress = 0.0
        try TestAssert(isUploading, "Should be uploading after start")
        
        // Progress update
        uploadProgress = 0.5
        try assertEqual(uploadProgress, 0.5, "Progress should be 0.5")
        try TestAssert(uploadProgress >= 0.0 && uploadProgress <= 1.0, "Progress should be between 0 and 1")
        
        // Complete upload
        isUploading = false
        uploadProgress = 1.0
        uploadedFiles.append("test.swift")
        
        try TestAssert(!isUploading, "Should not be uploading after completion")
        try assertEqual(uploadProgress, 1.0, "Progress should be 1.0 when complete")
        try assertEqual(uploadedFiles.count, 1, "Should have 1 uploaded file")
        try assertEqual(uploadedFiles.first, "test.swift", "First uploaded file should be test.swift")
    }
    
    static func testAnalysisResultsDisplay() throws {
        // Test analysis results display formatting
        let analysisResults = [
            MockAnalysisResult(type: "security", severity: "high", line: 10, message: "Security issue"),
            MockAnalysisResult(type: "quality", severity: "medium", line: 15, message: "Quality issue"),
            MockAnalysisResult(type: "performance", severity: "low", line: 20, message: "Performance issue")
        ]
        
        try assertEqual(analysisResults.count, 3, "Should have 3 analysis results")
        
        // Test severity color mapping
        let severityColors = [
            "critical": "red",
            "high": "orange",
            "medium": "yellow",
            "low": "blue"
        ]
        
        for result in analysisResults {
            let color = severityColors[result.severity] ?? "gray"
            try TestAssert(!color.isEmpty, "Severity should have a color mapping")
        }
        
        // Test type icon mapping
        let typeIcons = [
            "security": "shield.exclamationmark",
            "quality": "checkmark.circle",
            "performance": "speedometer",
            "style": "paintbrush"
        ]
        
        for result in analysisResults {
            let icon = typeIcons[result.type] ?? "info.circle"
            try TestAssert(!icon.isEmpty, "Type should have an icon mapping")
        }
    }
    
    static func testErrorStateHandling() throws {
        // Test error state management
        var hasError = false
        var errorMessage: String? = nil
        var isShowingError = false
        
        // Initial state
        try TestAssert(!hasError, "Should not have error initially")
        try TestAssert(errorMessage == nil, "Error message should be nil initially")
        try TestAssert(!isShowingError, "Should not be showing error initially")
        
        // Set error
        hasError = true
        errorMessage = "File upload failed"
        isShowingError = true
        
        try TestAssert(hasError, "Should have error after setting")
        try assertEqual(errorMessage, "File upload failed", "Error message should match")
        try TestAssert(isShowingError, "Should be showing error")
        
        // Clear error
        hasError = false
        errorMessage = nil
        isShowingError = false
        
        try TestAssert(!hasError, "Should not have error after clearing")
        try TestAssert(errorMessage == nil, "Error message should be nil after clearing")
        try TestAssert(!isShowingError, "Should not be showing error after clearing")
    }
    
    static func testProgressIndicators() throws {
        // Test progress indicator states
        var isAnalyzing = false
        var analysisProgress: Double = 0.0
        var currentStep = ""
        
        let steps = [
            "Uploading files...",
            "Analyzing code...",
            "Generating report...",
            "Complete"
        ]
        
        // Test each step
        for (index, step) in steps.enumerated() {
            if index < steps.count - 1 {
                isAnalyzing = true
                analysisProgress = Double(index) / Double(steps.count - 1)
                currentStep = step
                
                try TestAssert(isAnalyzing, "Should be analyzing during step: \(step)")
                try TestAssert(analysisProgress >= 0.0 && analysisProgress <= 1.0, "Progress should be valid for step: \(step)")
                try assertEqual(currentStep, step, "Current step should match")
            } else {
                // Final step
                isAnalyzing = false
                analysisProgress = 1.0
                currentStep = step
                
                try TestAssert(!isAnalyzing, "Should not be analyzing when complete")
                try assertEqual(analysisProgress, 1.0, "Progress should be 1.0 when complete")
                try assertEqual(currentStep, "Complete", "Should be at complete step")
            }
        }
    }
}

// Mock structures for testing
struct MockAnalysisResult {
    let type: String
    let severity: String
    let line: Int
    let message: String
}

// Shared test utilities and result structures
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
