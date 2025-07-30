// SECURITY: API key handling - ensure proper encryption and keychain storage
//
//  AIServiceProtocol.swift
//  CodingReviewer
//
//  Created on July 17, 2025.
//

import Foundation

// Import our centralized shared types
// This provides access to CodeLanguage and other shared enums

// MARK: - AI Analysis Request

// TODO: Review error handling in this file - Consider wrapping force unwraps and try statements in proper error handling

struct AIAnalysisRequest {
    let code: String
    let language: CodeLanguage
    let analysisType: AnalysisType
    let context: AnalysisContext?

    enum AnalysisType {
        case quality
        case security
        case performance
        case documentation
        case refactoring
        case comprehensive
    }

    struct AnalysisContext {
        let fileName: String?
        let projectType: ProjectType?
        let dependencies: [String]?
        let targetFramework: String?

        enum ProjectType {
            case ios, macos, watchos, tvos, multiplatform
        }
    }
}

// MARK: - AI Analysis Response

struct ComplexityScore {
    let score: Double // 0.0 to 1.0
    let description: String
    let cyclomaticComplexity: Double

    enum Rating: String, CaseIterable {
        case excellent = "excellent"
        case good = "good"
        case fair = "fair"
        case poor = "poor"
        case critical = "critical"
    }
}

struct MaintainabilityScore {
    let score: Double // 0.0 to 1.0
    let description: String

    enum Rating: String, CaseIterable {
        case excellent = "excellent"
        case good = "good"
        case fair = "fair"
        case poor = "poor"
        case critical = "critical"
    }
}

struct AIAnalysisResponse {
    let suggestions: [AISuggestion]
    let fixes: [CodeFix]
    let documentation: String?
    let complexity: ComplexityScore?
    let maintainability: MaintainabilityScore?
    let executionTime: TimeInterval
}

struct AISuggestion {
    let id: UUID
    let type: SuggestionType
    let title: String
    let description: String
    let severity: Severity
    let lineNumber: Int?
    let columnNumber: Int?
    let confidence: Double // 0.0 to 1.0

    enum SuggestionType: String, CaseIterable {
        case codeQuality = "Code Quality"
        case security = "Security"
        case performance = "Performance"
        case bestPractice = "Best Practice"
        case refactoring = "Refactoring"
        case documentation = "Documentation"
    }

    enum Severity: String, CaseIterable {
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
        case critical = "Critical"

        var color: String {
            switch self {
            case .info: return "blue"
            case .warning: return "orange"
            case .error: return "red"
            case .critical: return "purple"
            }
        }
    }
}

struct CodeFix {
    let id: UUID
    let suggestionId: UUID
    let title: String
    let description: String
    let originalCode: String
    let fixedCode: String
    let explanation: String
    let confidence: Double
    let isAutoApplicable: Bool
}

// MARK: - AI Service Errors

enum AIServiceError: LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case rateLimitExceeded
    case tokenLimitExceeded
    case invalidResponse
    case serviceUnavailable
    case insufficientCredits

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenAI API key in settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .tokenLimitExceeded:
            return "Token limit exceeded. Please try with shorter code."
        case .invalidResponse:
            return "Received invalid response from AI service."
        case .serviceUnavailable:
            return "AI service is currently unavailable. Please try again later."
        case .insufficientCredits:
            return "Insufficient API credits. Please check your OpenAI account."
        }
    }
}

// MARK: - Code Language Extension

extension CodeLanguage {
    var aiPromptName: String {
        switch self {
        case .swift: return "Swift"
        case .python: return "Python"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .kotlin: return "Kotlin"
        case .java: return "Java"
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
}

// MARK: - API Usage Statistics

struct APIUsageStats: Codable {
    let tokensUsed: Int
    let requestsCount: Int
    let totalCost: Double
    let lastResetDate: Date
    let dailyLimit: Int
    let monthlyLimit: Int

    init() {
        self.tokensUsed = 0
        self.requestsCount = 0
        self.totalCost = 0.0
        self.lastResetDate = Date()
        self.dailyLimit = 10000
        self.monthlyLimit = 100000
    }
}

// MARK: - AI Service Protocol

@MainActor
protocol AIServiceProtocol {
    func analyzeCode(_ request: AIAnalysisRequest) async throws -> AIAnalysisResponse
    func explainCode(_ code: String, language: String) async throws -> String
    func generateDocumentation(_ code: String, language: String) async throws -> String
    func suggestRefactoring(_ code: String, language: String) async throws -> [AISuggestion]
    func generateFix(for issue: String) async throws -> String
}
