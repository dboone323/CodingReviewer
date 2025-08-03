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
            return "Invalid input: \(message)"
        case .fileNotFound(let filename):
            return "File not found: \(filename)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .unauthorized:
            return "Unauthorized access"
        case .invalidCredentials:
            return "Invalid credentials"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
