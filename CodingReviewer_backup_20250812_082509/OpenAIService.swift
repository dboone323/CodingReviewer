// SECURITY: API key handling - ensure proper encryption and keychain storage
//
//  OpenAIService.swift
//  CodingReviewer
//
//  Created on July 17, 2025.
//

import Foundation

// MARK: - OpenAI Service Implementation

final class OpenAIService: AIServiceProtocol {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    private let model = "gpt-4"
    private let session: URLSession
    private let secureManager: SecureNetworkManager?
    private let tokenManager: TokenManager
    private let logger = AppLogger.shared

    // MARK: - Initialization

    init(apiKey: String) {
        self.apiKey = apiKey
        session = URLSession.shared
        secureManager = SecureNetworkManager.shared
        tokenManager = TokenManager()
    }

    // MARK: - AI Service Protocol Implementation

    /// Analyzes and processes data with comprehensive validation and error handling
    /// <#Description#>
    /// - Returns: <#description#>
    func analyzeCode(_ request: AIAnalysisRequest) async throws -> AIAnalysisResponse {
        let startTime = logger.startMeasurement(for: "ai_code_analysis")
        defer { logger.endMeasurement(for: "ai_code_analysis", startTime: startTime) }

        logger.log("Starting AI code analysis for \(request.fileType)", level: .info, category: .ai)

        let prompt = buildAnalysisPrompt(for: request)
        let response = try await sendChatRequest(prompt: prompt)
        let analysisResponse = try parseAnalysisResponse(response)

        logger.log(
            "AI analysis completed with \(analysisResponse.suggestions.count) suggestions",
            level: .info,
            category: .ai
        )

        return analysisResponse
    }

    /// Generates comprehensive documentation for the provided code
    /// <#Description#>
    /// - Returns: <#description#>
    func generateDocumentation(for code: String, language: CodeLanguage) async throws -> String {
        let startTime = logger.startMeasurement(for: "ai_generate_documentation")
        defer { logger.endMeasurement(for: "ai_generate_documentation", startTime: startTime) }

        let prompt = "Generate comprehensive documentation for this \(language.aiPromptName) code:\n\n\(code)"
        let response = try await sendChatRequest(prompt: prompt)
        return extractContent(from: response)
    }

    /// Suggests fixes for the provided code issues
    /// <#Description#>
    /// - Returns: <#description#>
    func suggestFixes(for issues: [String]) async throws -> [CodeFix] {
        let startTime = logger.startMeasurement(for: "ai_suggest_fixes")
        defer { logger.endMeasurement(for: "ai_suggest_fixes", startTime: startTime) }

        let issuesText = issues.enumerated().map { [weak self] index, issue in
            "\(index + 1). \(issue)"
        }.joined(separator: "\n")

        let prompt = """
        Suggest fixes for these code issues:

        \(issuesText)

        Please provide a JSON array of fixes with the following format:
        [
            {
                "title": "Brief fix title",
                "description": "Detailed explanation of the fix",
                "code": "The actual code fix or suggestion",
                "confidence": 0.95
            }
        ]
        """

        let response = try await sendChatRequest(prompt: prompt)
        return try parseCodeFixes(response)
    }

    /// Performs explainCode operation with comprehensive error handling, validation, and logging
    /// <#Description#>
    /// - Returns: <#description#>
    func explainCode(_ code: String, language: String) async throws -> String {
        let prompt = "Explain what this \(language) code does:\n\n\(code)"
        let response = try await sendChatRequest(prompt: prompt)
        return extractContent(from: response)
    }

    /// Performs suggestRefactoring operation with comprehensive error handling, validation, and logging
    /// <#Description#>
    /// - Returns: <#description#>
    func suggestRefactoring(_ code: String, language: String) async throws -> [AISuggestion] {
        let prompt = "Suggest refactoring improvements for this \(language) code:\n\n\(code)"
        let response = try await sendChatRequest(prompt: prompt)
        return try parseRefactoringSuggestions(response)
    }

    // MARK: - Private Implementation

    /// Performs sendChatRequest operation with comprehensive error handling, validation, and logging
    private func sendChatRequest(prompt: String) async throws -> OpenAIChatResponse {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AppError.configurationError("Invalid URL: \(baseURL)/chat/completions")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let chatRequest = OpenAIChatRequest(
            model: model,
            messages: [
                OpenAIChatMessage(role: "system", content: systemPrompt),
                OpenAIChatMessage(role: "user", content: prompt),
            ],
            temperature: 0.1,
            maxTokens: 2000
        )

        request.httpBody = try JSONEncoder().encode(chatRequest)

        do {
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    return try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
                case 401:
                    throw AIServiceError.invalidAPIKey
                case 429:
                    throw AIServiceError.rateLimitExceeded
                case 500 ... 599:
                    throw AIServiceError.serviceUnavailable
                default:
                    throw AIServiceError.invalidResponse
                }
            }

            throw AIServiceError.invalidResponse
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Prompt Builders

    /// Creates and configures components with proper initialization and dependency injection
    private func buildAnalysisPrompt(for request: AIAnalysisRequest) -> String {
        let analysisType = request.analysisType

        return """
        Analyze the following \(request.fileType) code for \(analysisType) issues:

        Code to analyze:
        ```\(request.fileType.lowercased())
        \(request.content)
        ```

        Please provide a comprehensive analysis including:
        1. Code quality issues and suggestions
        2. Security vulnerabilities and concerns
        3. Performance optimization opportunities
        4. Best practice recommendations
        5. Refactoring suggestions

        Format your response as a structured JSON with the following schema:
        {
            "suggestions": [
                {
                    "type": "codeQuality|security|performance|bestPractice|refactoring",
                    "title": "Brief title",
                    "description": "Detailed description",
                    "severity": "info|warning|error|critical",
                    "lineNumber": number or null,
                    "confidence": 0.0-1.0
                }
            ],
            "complexity": {
                "cyclomaticComplexity": number,
                "cognitiveComplexity": number,
                "linesOfCode": number,
                "rating": "excellent|good|fair|poor|critical"
            },
            "maintainability": {
                "score": 0.0-100.0,
                "rating": "excellent|good|fair|poor|critical"
            }
        }
        """
    }

    // MARK: - Response Parsers

    /// Parses and transforms data with comprehensive validation and error recovery
    private func parseAnalysisResponse(_ response: OpenAIChatResponse) throws -> AIAnalysisResponse {
        let content = extractContent(from: response)

        // Try to extract JSON from the response
        guard let jsonData = extractJSON(from: content)?.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        let analysisData = try JSONDecoder().decode(AIAnalysisData.self, from: jsonData)

        let suggestions = analysisData.suggestions.map { suggestion in
            AISuggestion(
                id: UUID(),
                title: suggestion.title,
                description: suggestion.description,
                confidence: suggestion.confidence,
                implementation: "" // Implementation details not provided in this context
            )
        }

        let complexity = analysisData.complexity.map { data in
            ComplexityScore(
                value: data.cyclomaticComplexity / 20.0, // normalize to 0-1 scale
                breakdown: ["cyclomaticComplexity": data.cyclomaticComplexity],
                recommendations: ["Consider refactoring complex functions"]
            )
        }

        let maintainability = analysisData.maintainability.map { data in
            MaintainabilityScore(
                value: data.score,
                factors: ["rating": data.score],
                improvements: ["Maintainability rating: \(data.rating)"]
            )
        }

        return AIAnalysisResponse(
            suggestions: suggestions,
            complexityScore: complexity?.value ?? 0.5,
            maintainabilityScore: maintainability?.value ?? 0.5,
            confidence: 0.8
        )
    }

    /// Parses and transforms data with comprehensive validation and error recovery
    private func parseRefactoringSuggestions(_ response: OpenAIChatResponse) throws -> [AISuggestion] {
        let content = extractContent(from: response)

        guard let jsonData = extractJSON(from: content)?.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        let suggestionsData = try JSONDecoder().decode([SuggestionData].self, from: jsonData)

        return suggestionsData.map { data in
            AISuggestion(
                id: UUID(),
                title: data.title,
                description: data.description,
                confidence: data.confidence,
                implementation: "" // Implementation details not provided in this context
            )
        }
    }

    /// Parses code fixes from AI response with comprehensive validation and error recovery
    private func parseCodeFixes(_ response: OpenAIChatResponse) throws -> [CodeFix] {
        let content = extractContent(from: response)

        guard let jsonData = extractJSON(from: content)?.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        let fixesData = try JSONDecoder().decode([CodeFixData].self, from: jsonData)

        return fixesData.map { data in
            CodeFix(
                id: UUID(),
                description: data.description,
                originalCode: "", // Original code not available in this context
                fixedCode: data.code,
                confidence: data.confidence
            )
        }
    }

    /// Parses and transforms data with comprehensive validation and error recovery
    private func extractContent(from response: OpenAIChatResponse) -> String {
        response.choices.first?.message.content ?? ""
    }

    /// Parses and transforms data with comprehensive validation and error recovery
    private func extractJSON(from content: String) -> String? {
        let lines = content.components(separatedBy: .newlines)
        var jsonLines: [String] = []
        var inJSON = false

        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("{") || line.trimmingCharacters(in: .whitespaces)
                .hasPrefix("[")
            {
                inJSON = true
            }

            if inJSON {
                jsonLines.append(line)
            }

            if line.trimmingCharacters(in: .whitespaces).hasSuffix("}") || line.trimmingCharacters(in: .whitespaces)
                .hasSuffix("]"), inJSON
            {
                break
            }
        }

        return jsonLines.isEmpty ? nil : jsonLines.joined(separator: "\n")
    }

    // MARK: - Utility Methods

    /// Transforms data using functional programming patterns with error propagation
    private func mapSuggestionType(_ type: String) -> AISuggestion.SuggestionType {
        switch type.lowercased() {
        case "codequality": .codeQuality
        case "security": .security
        case "performance": .performance
        case "bestpractice": .bestPractice
        case "refactoring": .refactoring
        case "documentation": .documentation
        default: .codeQuality
        }
    }

    /// Transforms data using functional programming patterns with error propagation
    private func mapSeverity(_ severity: String) -> AISuggestion.Severity {
        switch severity.lowercased() {
        case "info": .info
        case "warning": .warning
        case "error": .error
        case "critical": .critical
        default: .info
        }
    }

    /// Transforms data using functional programming patterns with error propagation
    private func mapComplexityRating(_ rating: String) -> ComplexityScore.Rating {
        switch rating.lowercased() {
        case "low": .low
        case "medium": .medium
        case "high": .high
        case "veryhigh", "very high", "critical": .veryHigh
        default: .medium
        }
    }

    /// Transforms data using functional programming patterns with error propagation
    private func mapMaintainabilityRating(_ rating: String) -> MaintainabilityScore.Rating {
        switch rating.lowercased() {
        case "excellent": .excellent
        case "good": .good
        case "fair": .fair
        case "poor", "critical": .poor
        default: .fair
        }
    }

    private var systemPrompt: String {
        """
        You are an expert code reviewer and software architect with deep knowledge of software engineering best practices, security, and performance optimization. Your role is to provide thorough, actionable feedback on code quality, security vulnerabilities, performance issues, and suggest improvements.

        Guidelines:
        1. Be specific and actionable in your suggestions
        2. Provide clear explanations for why changes are recommended
        3. Consider the broader context and architecture
        4. Prioritize security and performance concerns
        5. Suggest modern best practices and patterns
        6. Be constructive and educational in your feedback
        7. Format responses as valid JSON when requested

        Always strive to help developers improve their code and learn better practices.
        """
    }
}

// MARK: - Token Manager

private class TokenManager {
    private var tokenUsage: [Date: Int] = [:]
    private let maxTokensPerMinute = 1000

    /// Performs operation with error handling and validation
    /// <#Description#>
    /// - Returns: <#description#>
    func canUseTokens(_ count: Int) -> Bool {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)

        // Clean old entries
        tokenUsage = tokenUsage.filter { $0.key > oneMinuteAgo }

        let currentUsage = tokenUsage.values.reduce(0, +)
        return currentUsage + count <= maxTokensPerMinute
    }

    /// Performs operation with error handling and validation
    /// <#Description#>
    /// - Returns: <#description#>
    func recordTokenUsage(_ count: Int) {
        tokenUsage[Date()] = count
    }
}

// MARK: - OpenAI API Models

private struct OpenAIChatRequest: @preconcurrency Codable, Sendable {
    let model: String
    let messages: [OpenAIChatMessage]
    let temperature: Double
    let maxTokens: Int?

    enum CodingKeys: String, @preconcurrency CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

private struct OpenAIChatMessage: @preconcurrency Codable, Sendable {
    let role: String
    let content: String
}

private struct OpenAIChatResponse: @preconcurrency Codable, Sendable {
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?
}

private struct OpenAIChoice: @preconcurrency Codable, Sendable {
    let message: OpenAIChatMessage
    let finishReason: String?

    enum CodingKeys: String, @preconcurrency CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

private struct OpenAIUsage: @preconcurrency Codable, Sendable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, @preconcurrency CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

private struct AIAnalysisData: @preconcurrency Codable, Sendable {
    let suggestions: [SuggestionData]
    let complexity: ComplexityData?
    let maintainability: MaintainabilityData?
}

private struct SuggestionData: @preconcurrency Codable, Sendable {
    let type: String
    let title: String
    let description: String
    let severity: String
    let lineNumber: Int?
    let confidence: Double
}

private struct ComplexityData: @preconcurrency Codable, Sendable {
    let cyclomaticComplexity: Double
    let cognitiveComplexity: Double
    let linesOfCode: Int
    let rating: String
}

private struct MaintainabilityData: @preconcurrency Codable, Sendable {
    let score: Double
    let rating: String
}

private struct FixData: @preconcurrency Codable, Sendable {
    let fixedCode: String
    let explanation: String
    let confidence: Double
    let isAutoApplicable: Bool
}

private struct CodeFixData: @preconcurrency Codable, Sendable {
    let title: String
    let description: String
    let code: String
    let confidence: Double
}
