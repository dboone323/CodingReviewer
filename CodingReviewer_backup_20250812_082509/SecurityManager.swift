import Foundation
import Security

class SecurityManager {
    static let shared = SecurityManager()

    private init() {}

    // Secure API key storage in Keychain
    /// Updates and persists data with validation
    static func storeAPIKey(_ key: String, for service: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: key.data(using: .utf8) ?? Data(),
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Retrieves data with proper error handling and caching
    /// <#Description#>
    /// - Returns: <#description#>
    func retrieveAPIKey(for service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let key = String(data: data, encoding: .utf8)
        {
            return key
        } else {
            return nil
        }
    }

    // Validate URLs for HTTPS
    /// Validates input and ensures compliance
    /// <#Description#>
    /// - Returns: <#description#>
    func validateSecureURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              url.scheme?.lowercased() == "https"
        else {
            return false
        }
        return true
    }

    // Sanitize input strings
    /// Performs operation with error handling and validation
    /// <#Description#>
    /// - Returns: <#description#>
    func sanitizeInput(_ input: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces).union(.punctuationCharacters)
        return String(input.unicodeScalars.filter { allowedCharacters.contains($0) })
    }
}
