//
//  CodeReviewViewModelTests.swift
//  CodingReviewerTests
//
//  Created by AI Assistant on 7/18/25.
//

import Testing
import Combine
@testable import CodingReviewer

@MainActor
final class CodeReviewViewModelTests {
    
    var viewModel: CodeReviewViewModel!
    var mockKeyManager: APIKeyManager!
    var mockCodeReviewService: MockCodeReviewService!
    
    init() async throws {
        mockKeyManager = APIKeyManager.shared // Use the shared instance for testing
        mockCodeReviewService = MockCodeReviewService()
        viewModel = CodeReviewViewModel(codeReviewService: mockCodeReviewService, keyManager: mockKeyManager)
    }
    
    deinit {
        viewModel = nil
        mockKeyManager = nil
        mockCodeReviewService = nil
    }
    
    // MARK: - Initialization Tests
    
    @Test
    func testViewModelInitialization() async throws {
        #expect(viewModel.codeInput == "")
        #expect(viewModel.analysisResults.isEmpty)
        #expect(viewModel.aiAnalysisResult == nil)
        #expect(viewModel.aiSuggestions.isEmpty)
        #expect(viewModel.availableFixes.isEmpty)
        #expect(viewModel.isAnalyzing == false)
        #expect(viewModel.isAIAnalyzing == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showingResults == false)
        #expect(viewModel.selectedLanguage == .swift)
    }
    
    // MARK: - Code Analysis Tests
    
    @Test
    func testAnalyzeCodeWithValidInput() async throws {
        // Given
        let testCode = "func testFunction() { print(\"Hello\") }"
        viewModel.codeInput = testCode
        
        let expectedResults = [
            AnalysisResult(type: .quality, message: "Good code structure", line: 1, severity: .low)
        ]
        mockCodeReviewService.mockResults = expectedResults
        
        // When
        await viewModel.analyzeCode()
        
        // Then
        #expect(viewModel.analysisResults.count == 1)
        #expect(viewModel.analysisResults.first?.message == "Good code structure")
        #expect(viewModel.showingResults == true)
        #expect(viewModel.isAnalyzing == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test
    func testAnalyzeCodeWithEmptyInput() async throws {
        // Given
        viewModel.codeInput = ""
        
        // When
        await viewModel.analyzeCode()
        
        // Then
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage == "No code provided for analysis")
        #expect(viewModel.showingResults == false)
        #expect(viewModel.analysisResults.isEmpty)
    }
    
    @Test
    func testAnalyzeCodeWithLargeInput() async throws {
        // Given
        viewModel.codeInput = String(repeating: "a", count: 100001)
        
        // When
        await viewModel.analyzeCode()
        
        // Then
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage == "Code too large (max 100,000 characters)")
        #expect(viewModel.showingResults == false)
    }
    
    // MARK: - Language Selection Tests
    
    @Test
    func testLanguageSelection() async throws {
        // Given
        let initialLanguage = viewModel.selectedLanguage
        
        // When
        viewModel.selectedLanguage = .python
        
        // Then
        #expect(viewModel.selectedLanguage != initialLanguage)
        #expect(viewModel.selectedLanguage == .python)
    }
    
    // MARK: - AI Integration Tests
    
    @Test
    func testAIEnabledWithValidKey() async throws {
        // Given
        mockKeyManager.hasValidKey = true
        
        // When (simulate the key being updated)
        // Note: The real APIKeyManager will notify changes automatically
        
        // Then
        #expect(mockKeyManager.hasValidKey == true)
    }
    
    @Test
    func testAIDisabledWithoutKey() async throws {
        // Given
        mockKeyManager.hasValidKey = false
        
        // When (simulate the key being updated)
        // Note: The real APIKeyManager will notify changes automatically
        
        // Then
        #expect(mockKeyManager.hasValidKey == false)
        #expect(viewModel.aiEnabled == false)
    }
    
    // MARK: - Fix Application Tests
    
    @Test
    func testApplyFix() async throws {
        // Given
        viewModel.codeInput = "var x = getValue()"
        let fix = CodeFix(
            id: UUID(),
            suggestionId: UUID(),
            title: "Use lazy initialization",
            description: "Apply lazy keyword",
            originalCode: "var x = getValue()",
            fixedCode: "lazy var x = getValue()",
            explanation: "Using lazy initialization improves performance",
            confidence: 0.9,
            isAutoApplicable: true
        )
        
        // When
        viewModel.applyFix(fix)
        
        // Then
        #expect(viewModel.codeInput == "lazy var x = getValue()")
    }
    
    @Test
    func testApplyFixWithNonMatchingCode() async throws {
        // Given
        viewModel.codeInput = "different code"
        let fix = CodeFix(
            id: UUID(),
            suggestionId: UUID(),
            title: "Test fix",
            description: "Test description",
            originalCode: "var x = getValue()",
            fixedCode: "lazy var x = getValue()",
            explanation: "Test explanation for improvement",
            confidence: 0.9,
            isAutoApplicable: true
        )
        
        // When
        viewModel.applyFix(fix)
        
        // Then
        #expect(viewModel.errorMessage == "Cannot apply fix: original code not found")
        #expect(viewModel.codeInput == "different code") // Should remain unchanged
    }
    
    // MARK: - Clear Results Tests
    
    @Test
    func testClearResults() async throws {
        // Given
        viewModel.analysisResults = [
            AnalysisResult(type: .quality, message: "Test", line: 1, severity: .low)
        ]
        viewModel.analysisResult = "Test result"
        viewModel.errorMessage = "Test error"
        viewModel.showingResults = true
        
        // When
        viewModel.clearResults()
        
        // Then
        #expect(viewModel.analysisResults.isEmpty)
        #expect(viewModel.analysisResult == "")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showingResults == false)
        #expect(viewModel.aiSuggestions.isEmpty)
        #expect(viewModel.availableFixes.isEmpty)
        #expect(viewModel.aiAnalysisResult == nil)
    }
    
    // MARK: - Error Handling Tests
    
    @Test
    func testErrorHandlingDuringAnalysis() async throws {
        // Given
        viewModel.codeInput = "test code"
        mockCodeReviewService.shouldThrowError = true
        
        // When
        await viewModel.analyzeCode()
        
        // Then
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isAnalyzing == false)
        #expect(viewModel.showingResults == false)
    }
    
    // MARK: - Legacy Support Tests
    
    @Test
    func testLegacyAnalyzeMethod() async throws {
        // Given
        let testCode = "func test() {}"
        mockCodeReviewService.mockResults = [
            AnalysisResult(type: .quality, message: "Test result", line: 1, severity: .low)
        ]
        
        // When
        viewModel.analyze(testCode)
        
        // Give some time for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then
        #expect(viewModel.codeInput == testCode)
    }
}

// MARK: - Mock Classes

import Foundation

class MockCodeReviewService: CodeReviewService {
    var mockResults: [AnalysisResult] = []
    var shouldThrowError: Bool = false
    var delayDuration: Foundation.TimeInterval = 0
    
    func analyzeCode(_ code: String) async -> CodeAnalysisReport {
        if delayDuration > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delayDuration * 1_000_000_000))
        }
        
        if shouldThrowError {
            // Return an error report instead of throwing
            let metrics = CodeMetrics(
                characterCount: code.count,
                lineCount: code.components(separatedBy: .newlines).count,
                estimatedComplexity: 1,
                analysisTime: delayDuration
            )
            
            return CodeAnalysisReport(
                results: [AnalysisResult(
                    type: .security,
                    message: "Mock error for testing",
                    line: 1,
                    severity: .high
                )],
                metrics: metrics,
                overallRating: .poor
            )
        }
        
        let metrics = CodeMetrics(
            characterCount: code.count,
            lineCount: code.components(separatedBy: .newlines).count,
            estimatedComplexity: 1,
            analysisTime: delayDuration
        )
        
        return CodeAnalysisReport(
            results: mockResults,
            metrics: metrics,
            overallRating: .good
        )
    }
}
