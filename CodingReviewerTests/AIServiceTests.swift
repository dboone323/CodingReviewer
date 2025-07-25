//
//  AIServiceTests.swift
//  CodingReviewerTests
//
//  Created by AI Assistant on 7/18/25.
//

import XCTest
@testable import CodingReviewer

@MainActor
final class AIServiceTests: XCTestCase {
    
    func testAIAnalysisResponseInitialization() async throws {
        let suggestion = AISuggestion(
            id: UUID(),
            type: .performance,
            title: "Performance Optimization",
            description: "Consider using lazy evaluation",
            severity: .warning,
            lineNumber: 10,
            columnNumber: 5,
            confidence: 0.85
        )
        
        let complexityScore = ComplexityScore(
            score: 0.75,
            description: "Good complexity level",
            cyclomaticComplexity: 5.0
        )
        
        let maintainabilityScore = MaintainabilityScore(
            score: 0.85,
            description: "High maintainability"
        )
        
        let codeFix = CodeFix(
            id: UUID(),
            suggestionId: suggestion.id,
            title: "Use lazy initialization",
            description: "Replace with lazy var",
            originalCode: "var x = getValue()",
            fixedCode: "lazy var x = getValue()",
            explanation: "Use lazy initialization for better performance",
            confidence: 0.9,
            isAutoApplicable: true
        )
        
        let response = AIAnalysisResponse(
            suggestions: [suggestion],
            fixes: [codeFix],
            documentation: "This code shows good structure but could benefit from performance optimizations",
            complexity: complexityScore,
            maintainability: maintainabilityScore,
            executionTime: 0.5
        )
        
        XCTAssertEqual(response.documentation, "This code shows good structure but could benefit from performance optimizations")
        XCTAssertEqual(response.suggestions.count, 1)
        XCTAssertEqual(response.suggestions.first?.type, .performance)
        XCTAssertEqual(response.complexity?.cyclomaticComplexity, 5.0)
        XCTAssertEqual(response.maintainability?.score, 0.85)
        XCTAssertEqual(response.fixes.count, 1)
        XCTAssertEqual(response.executionTime, 0.5)
    }
    
    func testAISuggestionTypes() async throws {
        XCTAssertEqual(AISuggestion.SuggestionType.security.rawValue, "Security")
        XCTAssertEqual(AISuggestion.SuggestionType.performance.rawValue, "Performance")
        XCTAssertEqual(AISuggestion.SuggestionType.codeQuality.rawValue, "Code Quality")
        XCTAssertEqual(AISuggestion.SuggestionType.bestPractice.rawValue, "Best Practice")
        XCTAssertEqual(AISuggestion.SuggestionType.refactoring.rawValue, "Refactoring")
        XCTAssertEqual(AISuggestion.SuggestionType.documentation.rawValue, "Documentation")
    }
    
    func testSeverityTypes() async throws {
        XCTAssertEqual(AISuggestion.Severity.info.rawValue, "Info")
        XCTAssertEqual(AISuggestion.Severity.warning.rawValue, "Warning")
        XCTAssertEqual(AISuggestion.Severity.error.rawValue, "Error")
        XCTAssertEqual(AISuggestion.Severity.critical.rawValue, "Critical")
        
        // Test color properties
        XCTAssertEqual(AISuggestion.Severity.info.color, "blue")
        XCTAssertEqual(AISuggestion.Severity.warning.color, "orange")
        XCTAssertEqual(AISuggestion.Severity.error.color, "red")
        XCTAssertEqual(AISuggestion.Severity.critical.color, "purple")
    }
    
    func testComplexityScore() async throws {
        let score = ComplexityScore(
            score: 0.6,
            description: "Moderate complexity",
            cyclomaticComplexity: 10.0
        )
        
        XCTAssertEqual(score.score, 0.6)
        XCTAssertEqual(score.description, "Moderate complexity")
        XCTAssertEqual(score.cyclomaticComplexity, 10.0)
    }
    
    func testMaintainabilityScore() async throws {
        let score = MaintainabilityScore(
            score: 0.75,
            description: "Good maintainability"
        )
        
        XCTAssertEqual(score.score, 0.75)
        XCTAssertEqual(score.description, "Good maintainability")
    }
    
    func testCodeFix() async throws {
        let suggestionId = UUID()
        let fix = CodeFix(
            id: UUID(),
            suggestionId: suggestionId,
            title: "Remove redundant boolean comparison",
            description: "Simplify the condition",
            originalCode: "if (condition == true)",
            fixedCode: "if condition",
            explanation: "Remove redundant boolean comparison for cleaner code",
            confidence: 0.95,
            isAutoApplicable: true
        )
        
        XCTAssertEqual(fix.suggestionId, suggestionId)
        XCTAssertEqual(fix.title, "Remove redundant boolean comparison")
        XCTAssertEqual(fix.originalCode, "if (condition == true)")
        XCTAssertEqual(fix.fixedCode, "if condition")
        XCTAssertEqual(fix.explanation, "Remove redundant boolean comparison for cleaner code")
        XCTAssertEqual(fix.confidence, 0.95)
        XCTAssertTrue(fix.isAutoApplicable)
    }
    
    func testAISuggestion() async throws {
        let suggestion = AISuggestion(
            id: UUID(),
            type: .security,
            title: "Avoid hardcoded credentials",
            description: "Use environment variables or secure storage for sensitive data",
            severity: .error,
            lineNumber: 42,
            columnNumber: 10,
            confidence: 0.92
        )
        
        XCTAssertEqual(suggestion.type, .security)
        XCTAssertEqual(suggestion.title, "Avoid hardcoded credentials")
        XCTAssertEqual(suggestion.description, "Use environment variables or secure storage for sensitive data")
        XCTAssertEqual(suggestion.severity, .error)
        XCTAssertEqual(suggestion.lineNumber, 42)
        XCTAssertEqual(suggestion.columnNumber, 10)
        XCTAssertEqual(suggestion.confidence, 0.92)
    }
    
    func testAIAnalysisRequest() async throws {
        let context = AIAnalysisRequest.AnalysisContext(
            fileName: "ViewController.swift",
            projectType: .ios,
            dependencies: ["UIKit", "Foundation"],
            targetFramework: "iOS 15.0"
        )
        
        let request = AIAnalysisRequest(
            code: "import UIKit\nclass ViewController: UIViewController {}",
            language: .swift,
            analysisType: .comprehensive,
            context: context
        )
        
        XCTAssertEqual(request.code, "import UIKit\nclass ViewController: UIViewController {}")
        XCTAssertEqual(request.language, .swift)
        XCTAssertEqual(request.analysisType, .comprehensive)
        XCTAssertNotNil(request.context)
        XCTAssertEqual(request.context?.fileName, "ViewController.swift")
        XCTAssertEqual(request.context?.projectType, .ios)
        XCTAssertEqual(request.context?.dependencies?.count, 2)
    }
    
    func testAPIKeyManagerInitialization() async throws {
        let keyManager = APIKeyManager()
        XCTAssertNotNil(keyManager)
        
        // Test that we can create the key manager without throwing
        // In a real implementation, we'd test the actual keychain functionality
        // but for now we just verify initialization
    }
    
    func testAIServiceErrors() async throws {
        let networkError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test network error"])
        let aiError = AIServiceError.networkError(networkError)
        
        XCTAssertNotNil(aiError.errorDescription)
        XCTAssertTrue(aiError.errorDescription!.contains("Network error"))
        
        let invalidKeyError = AIServiceError.invalidAPIKey
        XCTAssertTrue(invalidKeyError.errorDescription!.contains("Invalid API key"))
        
        let rateLimitError = AIServiceError.rateLimitExceeded
        XCTAssertTrue(rateLimitError.errorDescription!.contains("Rate limit exceeded"))
    }
}
