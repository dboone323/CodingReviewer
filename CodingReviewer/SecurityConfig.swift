import Foundation

struct SecurityConfig {
    static let minPasswordLength = 12
    static let sessionTimeout: TimeInterval = 3600 // 1 hour
    static let maxFailedAttempts = 3
    static let requiredHTTPS = true
    static let logSecurityEvents = true

    // Secure defaults
    static let allowedAPIEndpoints = [
        "https:// api.openai.com",
        "https:// api.anthropic.com",
        "https:// api.github.com"
    ]

    static func validateEndpoint(_ endpoint: String) -> Bool {
        guard SecurityManager.shared.validateSecureURL(endpoint) else {
            return false
        }

        return allowedAPIEndpoints.contains { endpoint.hasPrefix($0) }
    }
}
