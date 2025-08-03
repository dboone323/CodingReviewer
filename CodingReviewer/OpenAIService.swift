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
    private let tokenManager: TokenManager
    private let logger = AppLogger.shared

    // MARK: - Initialization

    init(apiKey: String) {
        self.apiKey = apiKey
        self.session = URLSession.shared
        self.tokenManager = TokenManager()
    }

    // MARK: - AI Service Protocol Implementation

    func analyzeCode(_ request: AIAnalysisRequest) async throws -> AIAnalysisResponse {
        let startTime = logger.startMeasurement(for: "ai_code_analysis")
        defer { logger.endMeasurement(for: "ai_code_analysis", startTime: startTime) }

        logger.log("Starting AI code analysis for \(request.language.aiPromptName)", level: .info, category: .ai)

        let prompt = buildAnalysisPrompt(for: request)
        let response = try await sendChatRequest(prompt: prompt)
        let analysisResponse = try parseAnalysisResponse(response)

        logger.log("AI analysis completed with \(analysisResponse.suggestions.count) suggestions", level: .info, category: .ai)

        return analysisResponse
    }

    func generateFix(for issue: String) async throws -> String {
        let startTime = logger.startMeasurement(for: "ai_generate_fix")
        defer { logger.endMeasurement(for: "ai_generate_fix", startTime: startTime) }

        let prompt = "Fix this code issue: \(issue)"
        let response = try await sendChatRequest(prompt: prompt)
        return extractContent(from: response)
    }

    func generateDocumentation(_ code: String, language: String) async throws -> String {
        let prompt = "Generate comprehensive documentation for this \(language) code:\n\n\(code)"
        let response = try await sendChatRequest(prompt: prompt)
        return extractContent(from: response)
    }

    func explainCode(_ code: String, language: String) async throws -> String {
        let prompt = "Explain what this \(language) code does:\n\n\(code)"
        let response = try await sendChatRequest(prompt: prompt)
        return extractContent(from: response)
    }

    func suggestRefactoring(_ code: String, language: String) async throws -> [AISuggestion] {
        let prompt = "Suggest refactoring improvements for this \(language) code:\n\n\(code)"
        let response = try await sendChatRequest(prompt: prompt)
        return try parseRefactoringSuggestions(response)
    }

    // MARK: - Private Implementation

    private func sendChatRequest(prompt: String) async throws -> OpenAIChatResponse {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url);
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let chatRequest = OpenAIChatRequest(
            model: model,
            messages: [
                OpenAIChatMessage(role: "system", content: systemPrompt),
                OpenAIChatMessage(role: "user", content: prompt)
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
                case 500...599:
                    throw AIServiceError.serviceUnavailable
                default:
                    throw AIServiceError.invalidResponse
                }
            }

            throw AIServiceError.invalidResponse
        } catch let error as AIServiceError {
            throw error
        } catch {
            throw AIServiceError.networkError(error)
        }
    }

    // MARK: - Prompt Builders

    private func buildAnalysisPrompt(for request: AIAnalysisRequest) -> String {
        let analysisType = request.analysisType
        var contextInfo = ""

        if let context = request.context {
            contextInfo += "Context Information:\n"
            if let fileName = context.fileName {
                contextInfo += "- File: \(fileName)\n"
            }
            if let projectType = context.projectType {
                contextInfo += "- Project Type: \(projectType)\n"
            }
            contextInfo += "\n"
        }

        return """
        Analyze the following \(request.language.aiPromptName) code for \(analysisType) issues:

        \(contextInfo)

        Code to analyze:
        ```\(request.language.aiPromptName.lowercased())
        \(request.code)
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
                type: mapSuggestionType(suggestion.type),
                title: suggestion.title,
                description: suggestion.description,
                severity: mapSeverity(suggestion.severity),
                lineNumber: suggestion.lineNumber,
                columnNumber: nil,
                confidence: suggestion.confidence
            )
        }

        let complexity = analysisData.complexity.map { data in
            ComplexityScore(
                score: data.cyclomaticComplexity / 20.0, // normalize to 0-1 scale
                description: "Complexity rating: \(data.rating)",
                cyclomaticComplexity: data.cyclomaticComplexity
            )
        }

        let maintainability = analysisData.maintainability.map { data in
            MaintainabilityScore(
                score: data.score,
                description: "Maintainability rating: \(data.rating)"
            )
        }

        return AIAnalysisResponse(
            suggestions: suggestions,
            fixes: [],
            documentation: nil,
            complexity: complexity,
            maintainability: maintainability,
            executionTime: 0
        )
    }

    private func parseRefactoringSuggestions(_ response: OpenAIChatResponse) throws -> [AISuggestion] {
        let content = extractContent(from: response)

        guard let jsonData = extractJSON(from: content)?.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        let suggestionsData = try JSONDecoder().decode([SuggestionData].self, from: jsonData)

        return suggestionsData.map { data in
            AISuggestion(
                id: UUID(),
                type: mapSuggestionType(data.type),
                title: data.title,
                description: data.description,
                severity: mapSeverity(data.severity),
                lineNumber: nil,
                columnNumber: nil,
                confidence: data.confidence
            )
        }
    }

    private func extractContent(from response: OpenAIChatResponse) -> String {
        return response.choices.first?.message.content ?? ""
    }

    private func extractJSON(from content: String) -> String? {
        let lines = content.components(separatedBy: .newlines)
        var jsonLines: [String] = [];
        var inJSON = false;

        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("{") || line.trimmingCharacters(in: .whitespaces).hasPrefix("[") {
                inJSON = true
            }

            if inJSON {
                jsonLines.append(line)
            }

            if (line.trimmingCharacters(in: .whitespaces).hasSuffix("}") || line.trimmingCharacters(in: .whitespaces).hasSuffix("]")) && inJSON {
                break
            }
        }

        return jsonLines.isEmpty ? nil : jsonLines.joined(separator: "\n")
    }

    // MARK: - Utility Methods

    private func mapSuggestionType(_ type: String) -> AISuggestion.SuggestionType {
        switch type.lowercased() {
        case "codequality": return .codeQuality
        case "security": return .security
        case "performance": return .performance
        case "bestpractice": return .bestPractice
        case "refactoring": return .refactoring
        case "documentation": return .documentation
        default: return .codeQuality
        }
    }

    private func mapSeverity(_ severity: String) -> AISuggestion.Severity {
        switch severity.lowercased() {
        case "info": return .info
        case "warning": return .warning
        case "error": return .error
        case "critical": return .critical
        default: return .info
        }
    }

    private func mapComplexityRating(_ rating: String) -> ComplexityScore.Rating {
        switch rating.lowercased() {
        case "excellent": return .excellent
        case "good": return .good
        case "fair": return .fair
        case "poor": return .poor
        case "critical": return .critical
        default: return .fair
        }
    }

    private func mapMaintainabilityRating(_ rating: String) -> MaintainabilityScore.Rating {
        switch rating.lowercased() {
        case "excellent": return .excellent
        case "good": return .good
        case "fair": return .fair
        case "poor": return .poor
        case "critical": return .critical
        default: return .fair
        }
    }

    private var systemPrompt: String {
        return """
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
    private var tokenUsage: [Date: Int] = [:];
    private let maxTokensPerMinute = 1000

    func canUseTokens(_ count: Int) -> Bool {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)

        // Clean old entries
        tokenUsage = tokenUsage.filter { $0.key > oneMinuteAgo }

        let currentUsage = tokenUsage.values.reduce(0, +)
        return currentUsage + count <= maxTokensPerMinute
    }

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

