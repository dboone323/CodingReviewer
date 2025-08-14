import Foundation

// MARK: - Shared Application Error

enum AppError: LocalizedError {
    case invalidInput(String)
    case fileNotFound(String)
    case networkError(String)
    case parsingError(String)
    case apiError(String)
    case configurationError(String)
    case unauthorized
    case invalidCredentials
    case operationFailed(String)
    case invalidConfiguration(String)
    case unknown

    nonisolated var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            "Invalid input: \(message)"
        case .fileNotFound(let filename):
            "File not found: \(filename)"
        case .networkError(let message):
            "Network error: \(message)"
        case .parsingError(let message):
            "Parsing error: \(message)"
        case .apiError(let message):
            "API error: \(message)"
        case .configurationError(let message):
            "Configuration error: \(message)"
        case .unauthorized:
            "Unauthorized access"
        case .invalidCredentials:
            "Invalid credentials"
        case .operationFailed(let message):
            "Operation failed: \(message)"
        case .invalidConfiguration(let message):
            "Invalid configuration: \(message)"
        case .unknown:
            "An unknown error occurred"
        }
    }
}
