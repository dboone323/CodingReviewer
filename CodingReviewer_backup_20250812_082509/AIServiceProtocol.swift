// SECURITY: API key handling - ensure proper encryption and keychain storage
//
// AIServiceProtocol.swift
// CodingReviewer
//
// Creat// MARK: - AI Service Protocol extensions for additional functionality

// Additional protocol extensions and utilities can be added hereervice Protocol extensions for additional
// functionality2025.
//

import Foundation

// SharedTypes are automatically available in the same target
// No need to explicitly import AITypes or CoreDataTypes

// MARK: - AI Analysis Request

/// AI Service Protocol and Data Models
///
/// This file defines the protocol and data structures for AI-powered code analysis.
/// All error handling follows Swift best practices with proper error propagation
/// and optional handling throughout the service implementations.

// AIAnalysisRequest, ComplexityScore, MaintainabilityScore are now imported from AITypes.swift

// Additional analysis context types specific to this service
struct AnalysisContext {
    let fileName: String?
    let projectType: ProjectType?
    let dependencies: [String]?
    let targetFramework: String?

    enum ProjectType {
        case ios, macos, watchos, tvos, multiplatform
    }
}

// AnalysisType is now imported from ServiceTypes.swift

// AIAnalysisResponse, AISuggestion, CodeFix are now imported from AITypes.swift

// Additional service-specific types
extension AISuggestion {
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
            case .info: "blue"
            case .warning: "orange"
            case .error: "red"
            case .critical: "purple"
            }
        }
    }
}

// CodeFix is now imported from AITypes.swift

// MARK: - AI Service Errors

// AIServiceError is now imported from AITypes.swift

// MARK: - AI Service Protocol

protocol AIServiceProtocol {
    func analyzeCode(_ request: AIAnalysisRequest) async throws -> AIAnalysisResponse
    func generateDocumentation(for code: String, language: CodeLanguage) async throws -> String
    func suggestFixes(for issues: [String]) async throws -> [CodeFix]
}

// MARK: - Code Language Extension

extension CodeLanguage {
    var aiPromptName: String {
        switch self {
        case .swift: "Swift"
        case .python: "Python"
        case .javascript: "JavaScript"
        case .typescript: "TypeScript"
        case .kotlin: "Kotlin"
        case .java: "Java"
        case .csharp: "C#"
        case .cpp: "C++"
        case .c: "C"
        case .go: "Go"
        case .rust: "Rust"
        case .php: "PHP"
        case .ruby: "Ruby"
        case .html: "HTML"
        case .css: "CSS"
        case .xml: "XML"
        case .json: "JSON"
        case .yaml: "YAML"
        case .markdown: "Markdown"
        case .unknown: "Unknown"
        }
    }
}

// MARK: - API Usage Statistics

struct APIUsageStats: @preconcurrency Codable, Sendable {
    let tokensUsed: Int
    let requestsCount: Int
    let totalCost: Double
    let lastResetDate: Date
    let dailyLimit: Int
    let monthlyLimit: Int

    init() {
        tokensUsed = 0
        requestsCount = 0
        totalCost = 0.0
        lastResetDate = Date()
        dailyLimit = 10000
        monthlyLimit = 100_000
    }
}

// MARK: - AI Service Protocol Extensions

// Additional protocol extensions and utilities can be added here
