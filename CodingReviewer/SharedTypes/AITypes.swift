import Foundation

// MARK: - AI Service Types  
// Pure AI-related data models - NO SwiftUI imports, NO Codable

public struct AISuggestion: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let description: String
    public let confidence: Double
    public let implementation: String
    
    public init(id: UUID = UUID(), title: String, description: String, confidence: Double, implementation: String) {
        self.id = id
        self.title = title
        self.description = description
        self.confidence = confidence
        self.implementation = implementation
    }
}

public struct AIAnalysisRequest: Sendable {
    public let content: String
    public let fileType: String
    public let analysisType: String
    
    public init(content: String, fileType: String, analysisType: String) {
        self.content = content
        self.fileType = fileType
        self.analysisType = analysisType
    }
}

public struct AIAnalysisResponse: Sendable {
    public let suggestions: [AISuggestion]
    public let complexityScore: Double
    public let maintainabilityScore: Double
    public let confidence: Double
    
    public init(suggestions: [AISuggestion], complexityScore: Double, maintainabilityScore: Double, confidence: Double) {
        self.suggestions = suggestions
        self.complexityScore = complexityScore
        self.maintainabilityScore = maintainabilityScore
        self.confidence = confidence
    }
}

public struct ComplexityScore: Sendable {
    public let value: Double
    public let breakdown: [String: Double]
    public let recommendations: [String]
    
    public init(value: Double, breakdown: [String: Double], recommendations: [String]) {
        self.value = value
        self.breakdown = breakdown
        self.recommendations = recommendations
    }
    
    public enum Rating: String, Sendable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case veryHigh = "Very High"
    }
}

public struct MaintainabilityScore: Sendable {
    public let value: Double
    public let factors: [String: Double]
    public let improvements: [String]
    
    public init(value: Double, factors: [String: Double], improvements: [String]) {
        self.value = value
        self.factors = factors
        self.improvements = improvements
    }
    
    public enum Rating: String, Sendable, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
    }
}

public enum AIServiceError: Error, Sendable {
    case invalidRequest
    case invalidAPIKey
    case invalidResponse
    case networkError(String)
    case parseError(String)
    case serviceUnavailable
    case rateLimitExceeded
    case unknown(String)
    
    public var localizedDescription: String {
        switch self {
        case .invalidRequest:
            return "Invalid request parameters"
        case .invalidAPIKey:
            return "Invalid API key provided"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .networkError(let message):
            return "Network error: \(message)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .serviceUnavailable:
            return "AI service is currently unavailable"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
