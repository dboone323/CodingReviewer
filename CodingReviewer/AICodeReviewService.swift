//
//  AICodeReviewService.swift
//  CodingReviewer
//
//  Created by AI Assistant on 7/17/25.
//

import Foundation
import CryptoKit
import Combine

// MARK: - AI Service Protocol

protocol AICodeReviewService {
    func analyzeWithAI(_ code: String, language: CodeLanguage) async throws -> AIAnalysisResult
    func generateFixes(for issues: [AnalysisResult]) async throws -> [CodeFix]
    func generateDocumentation(for code: String) async throws -> String
    func explainIssue(_ issue: AnalysisResult) async throws -> String
}

// MARK: - AI Models

struct AIAnalysisResult {
    let suggestions: [AISuggestion]
    let fixes: [CodeFix]
    let documentation: String
    let complexity: ComplexityScore
    let maintainability: MaintainabilityScore
    let explanation: String
}

struct AISuggestion {
    let id: UUID
    let title: String
    let description: String
    let severity: AnalysisResult.Severity
    let category: AICategory
    let confidence: Double
    let applicableRange: NSRange?
    let suggestedFix: String?
}

struct CodeFix {
    let id: UUID
    let title: String
    let description: String
    let originalCode: String
    let fixedCode: String
    let range: NSRange
    let category: FixCategory
    let confidence: Double
}

struct ComplexityScore {
    let cyclomatic: Int
    let cognitive: Int
    let maintainability: Double
    let readability: Double
}

struct MaintainabilityScore {
    let index: Double
    let testability: Double
    let modularity: Double
    let documentation: Double
}

enum AICategory: String, CaseIterable {
    case codeQuality = "Code Quality"
    case performance = "Performance"
    case security = "Security"
    case maintainability = "Maintainability"
    case bestPractices = "Best Practices"
    case documentation = "Documentation"
    case refactoring = "Refactoring"
}

enum FixCategory: String, CaseIterable {
    case syntax = "Syntax"
    case logic = "Logic"
    case performance = "Performance"
    case security = "Security"
    case style = "Style"
    case refactor = "Refactor"
}

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
    case json = "json"
    case xml = "xml"
    case yaml = "yaml"
    case markdown = "markdown"
    
    var fileExtensions: [String] {
        switch self {
        case .swift: return ["swift"]
        case .python: return ["py", "pyw", "python"]
        case .javascript: return ["js", "jsx"]
        case .typescript: return ["ts", "tsx"]
        case .java: return ["java"]
        case .cpp: return ["cpp", "cc", "cxx", "c++", "h", "hpp"]
        case .go: return ["go"]
        case .rust: return ["rs"]
        case .html: return ["html", "htm"]
        case .css: return ["css", "scss", "sass"]
        case .json: return ["json"]
        case .xml: return ["xml"]
        case .yaml: return ["yaml", "yml"]
        case .markdown: return ["md", "markdown"]
        }
    }
}

// MARK: - OpenAI Service Implementation

@MainActor
final class OpenAICodeReviewService: AICodeReviewService, ObservableObject {
    
    // MARK: - Properties
    
    @Published var isProcessing = false
    @Published var usageStats = APIUsageStats()
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    private let model = "gpt-4"
    private let maxTokens = 2000
    private let temperature = 0.3
    
    private let logger = AppLogger.shared
    private let session: URLSession
    
    // MARK: - Initialization
    
    init() throws {
        // Try to get API key from secure storage or environment
        if let key = Self.getAPIKey() {
            self.apiKey = key
        } else {
            throw AIServiceError.missingAPIKey
        }
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
        
        logger.log("OpenAI Code Review Service initialized", level: .info, category: .ai)
    }
    
    // MARK: - AI Service Protocol Implementation
    
    func analyzeWithAI(_ code: String, language: CodeLanguage) async throws -> AIAnalysisResult {
        let startTime = logger.startMeasurement(for: "AI Analysis")
        isProcessing = true
        
        defer {
            isProcessing = false
            logger.endMeasurement(for: "AI Analysis", startTime: startTime)
        }
        
        let prompt = buildAnalysisPrompt(code: code, language: language)
        let response = try await makeOpenAIRequest(prompt: prompt)
        let result = try parseAnalysisResponse(response, for: code)
        
        // Update usage stats
        usageStats.totalRequests += 1
        usageStats.totalTokensUsed += response.usage.totalTokens
        usageStats.lastRequestDate = Date()
        
        logger.log("AI analysis completed for \(language.displayName) code", 
                  level: .info, category: .ai)
        
        return result
    }
    
    func generateFixes(for issues: [AnalysisResult]) async throws -> [CodeFix] {
        let startTime = logger.startMeasurement(for: "AI Fix Generation")
        isProcessing = true
        
        defer {
            isProcessing = false
            logger.endMeasurement(for: "AI Fix Generation", startTime: startTime)
        }
        
        let prompt = buildFixPrompt(for: issues)
        let response = try await makeOpenAIRequest(prompt: prompt)
        let fixes = try parseFixResponse(response, for: issues)
        
        usageStats.totalRequests += 1
        usageStats.totalTokensUsed += response.usage.totalTokens
        
        logger.log("Generated \(fixes.count) AI fixes", level: .info, category: .ai)
        
        return fixes
    }
    
    func generateDocumentation(for code: String) async throws -> String {
        let prompt = buildDocumentationPrompt(for: code)
        let response = try await makeOpenAIRequest(prompt: prompt)
        
        usageStats.totalRequests += 1
        usageStats.totalTokensUsed += response.usage.totalTokens
        
        return response.choices.first?.message.content ?? ""
    }
    
    func explainIssue(_ issue: AnalysisResult) async throws -> String {
        let prompt = buildExplanationPrompt(for: issue)
        let response = try await makeOpenAIRequest(prompt: prompt)
        
        usageStats.totalRequests += 1
        usageStats.totalTokensUsed += response.usage.totalTokens
        
        return response.choices.first?.message.content ?? ""
    }
}

// MARK: - Private Implementation

private extension OpenAICodeReviewService {
    
    func buildAnalysisPrompt(code: String, language: CodeLanguage) -> String {
        return """
        You are an expert code reviewer specializing in \(language.displayName). 
        Analyze the following code and provide detailed feedback in JSON format.
        
        Code to analyze:
        ```\(language.rawValue)
        \(code)
        ```
        
        Please provide analysis in this JSON structure:
        {
            "suggestions": [
                {
                    "title": "Brief title",
                    "description": "Detailed description",
                    "severity": "low|medium|high|critical",
                    "category": "codeQuality|performance|security|maintainability|bestPractices|documentation|refactoring",
                    "confidence": 0.95,
                    "suggestedFix": "Fixed code snippet"
                }
            ],
            "complexity": {
                "cyclomatic": 5,
                "cognitive": 3,
                "maintainability": 0.85,
                "readability": 0.90
            },
            "maintainability": {
                "index": 0.85,
                "testability": 0.80,
                "modularity": 0.75,
                "documentation": 0.60
            },
            "explanation": "Overall assessment of the code quality and recommendations"
        }
        
        Focus on:
        - Code quality and best practices
        - Performance optimizations
        - Security vulnerabilities
        - Maintainability improvements
        - Documentation suggestions
        """
    }
    
    func buildFixPrompt(for issues: [AnalysisResult]) -> String {
        let issueDescriptions = issues.map { issue in
            "- \(issue.message) (Severity: \(issue.severity), Type: \(issue.type))"
        }.joined(separator: "\n")
        
        return """
        Generate specific code fixes for the following issues:
        
        \(issueDescriptions)
        
        Provide fixes in JSON format:
        {
            "fixes": [
                {
                    "title": "Fix title",
                    "description": "What this fix does",
                    "originalCode": "code before fix",
                    "fixedCode": "code after fix",
                    "category": "syntax|logic|performance|security|style|refactor",
                    "confidence": 0.95
                }
            ]
        }
        """
    }
    
    func buildDocumentationPrompt(for code: String) -> String {
        return """
        Generate comprehensive documentation for this code:
        
        ```
        \(code)
        ```
        
        Include:
        - Purpose and functionality
        - Parameters and return values
        - Usage examples
        - Implementation notes
        - Potential improvements
        """
    }
    
    func buildExplanationPrompt(for issue: AnalysisResult) -> String {
        return """
        Explain this code issue in detail:
        
        Issue: \(issue.message)
        Type: \(issue.type)
        Severity: \(issue.severity)
        
        Provide:
        - Why this is an issue
        - Potential consequences
        - How to fix it
        - Best practices to prevent it
        """
    }
    
    func makeOpenAIRequest(prompt: String) async throws -> OpenAIResponse {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OpenAIRequest(
            model: model,
            messages: [
                OpenAIMessage(role: "system", content: "You are an expert code reviewer."),
                OpenAIMessage(role: "user", content: prompt)
            ],
            maxTokens: maxTokens,
            temperature: temperature
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIServiceError.apiError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(OpenAIResponse.self, from: data)
    }
    
    func parseAnalysisResponse(_ response: OpenAIResponse, for code: String) throws -> AIAnalysisResult {
        guard let content = response.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }
        
        // Parse JSON response
        guard let jsonData = content.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw AIServiceError.parsingError
        }
        
        // Extract suggestions
        let suggestions = try parseSuggestions(from: json["suggestions"] as? [[String: Any]] ?? [])
        
        // Extract complexity
        let complexity = try parseComplexity(from: json["complexity"] as? [String: Any] ?? [:])
        
        // Extract maintainability
        let maintainability = try parseMaintainability(from: json["maintainability"] as? [String: Any] ?? [:])
        
        let explanation = json["explanation"] as? String ?? ""
        
        return AIAnalysisResult(
            suggestions: suggestions,
            fixes: [], // Will be generated separately
            documentation: "",
            complexity: complexity,
            maintainability: maintainability,
            explanation: explanation
        )
    }
    
    func parseFixResponse(_ response: OpenAIResponse, for issues: [AnalysisResult]) throws -> [CodeFix] {
        guard let content = response.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }
        
        guard let jsonData = content.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let fixesArray = json["fixes"] as? [[String: Any]] else {
            throw AIServiceError.parsingError
        }
        
        return try fixesArray.map { fixDict in
            guard let title = fixDict["title"] as? String,
                  let description = fixDict["description"] as? String,
                  let originalCode = fixDict["originalCode"] as? String,
                  let fixedCode = fixDict["fixedCode"] as? String,
                  let categoryString = fixDict["category"] as? String,
                  let category = FixCategory(rawValue: categoryString),
                  let confidence = fixDict["confidence"] as? Double else {
                throw AIServiceError.parsingError
            }
            
            return CodeFix(
                id: UUID(),
                title: title,
                description: description,
                originalCode: originalCode,
                fixedCode: fixedCode,
                range: NSRange(location: 0, length: originalCode.count),
                category: category,
                confidence: confidence
            )
        }
    }
    
    func parseSuggestions(from array: [[String: Any]]) throws -> [AISuggestion] {
        return try array.map { dict in
            guard let title = dict["title"] as? String,
                  let description = dict["description"] as? String,
                  let severityString = dict["severity"] as? String,
                  let categoryString = dict["category"] as? String,
                  let confidence = dict["confidence"] as? Double else {
                throw AIServiceError.parsingError
            }
            
            let severity: AnalysisResult.Severity = {
                switch severityString.lowercased() {
                case "low": return .low
                case "medium": return .medium
                case "high": return .high
                case "critical": return .critical
                default: return .medium
                }
            }()
            let category = AICategory(rawValue: categoryString) ?? .codeQuality
            let suggestedFix = dict["suggestedFix"] as? String
            
            return AISuggestion(
                id: UUID(),
                title: title,
                description: description,
                severity: severity,
                category: category,
                confidence: confidence,
                applicableRange: nil,
                suggestedFix: suggestedFix
            )
        }
    }
    
    func parseComplexity(from dict: [String: Any]) throws -> ComplexityScore {
        let cyclomatic = dict["cyclomatic"] as? Int ?? 0
        let cognitive = dict["cognitive"] as? Int ?? 0
        let maintainability = dict["maintainability"] as? Double ?? 0.0
        let readability = dict["readability"] as? Double ?? 0.0
        
        return ComplexityScore(
            cyclomatic: cyclomatic,
            cognitive: cognitive,
            maintainability: maintainability,
            readability: readability
        )
    }
    
    func parseMaintainability(from dict: [String: Any]) throws -> MaintainabilityScore {
        let index = dict["index"] as? Double ?? 0.0
        let testability = dict["testability"] as? Double ?? 0.0
        let modularity = dict["modularity"] as? Double ?? 0.0
        let documentation = dict["documentation"] as? Double ?? 0.0
        
        return MaintainabilityScore(
            index: index,
            testability: testability,
            modularity: modularity,
            documentation: documentation
        )
    }
    
    static func getAPIKey() -> String? {
        // First try environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return envKey
        }
        
        // Then try Keychain (in a real app)
        // For now, return nil to require manual setup
        return nil
    }
}

// MARK: - OpenAI API Models

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

struct OpenAIUsage: Codable {
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case totalTokens = "total_tokens"
    }
}

// MARK: - Usage Statistics

struct APIUsageStats {
    var totalRequests: Int = 0
    var totalTokensUsed: Int = 0
    var lastRequestDate: Date?
    var estimatedCost: Double {
        // Rough estimate based on GPT-4 pricing
        return Double(totalTokensUsed) * 0.00003 // $0.03 per 1K tokens
    }
}

// MARK: - Error Types

enum AIServiceError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(Int)
    case parsingError
    case rateLimitExceeded
    case insufficientCredits
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not found. Please set OPENAI_API_KEY environment variable."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .apiError(let code):
            return "OpenAI API error: \(code)"
        case .parsingError:
            return "Failed to parse AI response"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .insufficientCredits:
            return "Insufficient API credits"
        }
    }
}
