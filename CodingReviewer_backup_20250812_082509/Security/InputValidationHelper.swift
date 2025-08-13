//
// InputValidationHelper.swift
// CodingReviewer
//
// Additional input validation and security helpers

import Foundation

/// Enhanced input validation and security utilities
struct InputValidationHelper {
    
    /// Validates email addresses with security considerations
    static func validateEmail(_ email: String) -> Bool {
        guard email.count <= 254 else { return false } // RFC 5321 limit
        
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validates URLs for security (prevents javascript:, data:, etc.)
    static func validateSecureURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        
        let allowedSchemes = ["https", "http"]
        guard let scheme = url.scheme?.lowercased(),
              allowedSchemes.contains(scheme) else { return false }
        
        // Prevent dangerous schemes
        let dangerousSchemes = ["javascript", "data", "file", "ftp"]
        return !dangerousSchemes.contains(scheme)
    }
    
    /// Sanitizes HTML input to prevent XSS
    static func sanitizeHTML(_ input: String) -> String {
        var sanitized = input
        
        // Remove script tags
        sanitized = sanitized.replacingOccurrences(
            of: "<script[^>]*>.*?</script>",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // Remove dangerous attributes
        let dangerousPatterns = [
            "on\\w+\\s*=", // onclick, onload, etc.
            "javascript:",
            "vbscript:",
            "data:"
        ]
        
        for pattern in dangerousPatterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        return sanitized
    }
    
    /// Validates file paths to prevent directory traversal
    static func validateFilePath(_ path: String) -> Bool {
        // Normalize path
        let normalizedPath = (path as NSString).standardizingPath
        
        // Check for directory traversal attempts
        let dangerousPatterns = ["../", "..\\", "%2e%2e", "%252e%252e"]
        
        for pattern in dangerousPatterns {
            if normalizedPath.lowercased().contains(pattern) {
                return false
            }
        }
        
        return true
    }
    
    /// Generates cryptographically secure random strings
    static func generateSecureRandomString(length: Int) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        var result = ""
        
        for _ in 0..<length {
            let randomIndex = Int.random(in: 0..<characters.count)
            let character = characters[characters.index(characters.startIndex, offsetBy: randomIndex)]
            result.append(character)
        }
        
        return result
    }
    
    /// Validates password strength
    static func validatePasswordStrength(_ password: String) -> PasswordStrength {
        var score = 0
        var feedback: [String] = []
        
        // Length check
        if password.count >= 8 {
            score += 1
        } else {
            feedback.append("Password should be at least 8 characters long")
        }
        
        // Uppercase check
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil {
            score += 1
        } else {
            feedback.append("Password should contain uppercase letters")
        }
        
        // Lowercase check
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil {
            score += 1
        } else {
            feedback.append("Password should contain lowercase letters")
        }
        
        // Number check
        if password.rangeOfCharacter(from: .decimalDigits) != nil {
            score += 1
        } else {
            feedback.append("Password should contain numbers")
        }
        
        // Special character check
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        if password.rangeOfCharacter(from: specialCharacters) != nil {
            score += 1
        } else {
            feedback.append("Password should contain special characters")
        }
        
        let strength: PasswordStrength.Level
        switch score {
        case 0...1: strength = .weak
        case 2...3: strength = .medium
        case 4...5: strength = .strong
        default: strength = .weak
        }
        
        return PasswordStrength(level: strength, score: score, feedback: feedback)
    }
}

/// Password strength evaluation result
struct PasswordStrength {
    enum Level: String {
        case weak = "Weak"
        case medium = "Medium"
        case strong = "Strong"
    }
    
    let level: Level
    let score: Int
    let feedback: [String]
}
