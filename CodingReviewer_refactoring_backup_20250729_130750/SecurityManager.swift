import Foundation
import Security

class SecurityManager {
    static let shared = SecurityManager()
    
    private init() {}
    
    // Secure API key storage in Keychain
    func storeAPIKey(_ key: String, for service: String) -> Bool {
        let data = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            AppLogger.shared.logSecurity("API key stored securely for service: \(service)")
            return true
        } else {
            AppLogger.shared.logError("Failed to store API key for service: \(service)")
            return false
        }
    }
    
    func retrieveAPIKey(for service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let key = String(data: data, encoding: .utf8) {
            AppLogger.shared.log("API key retrieved securely for service: \(service)")
            return key
        } else {
            AppLogger.shared.logError("Failed to retrieve API key for service: \(service)")
            return nil
        }
    }
    
    // Validate URLs for HTTPS
    func validateSecureURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              url.scheme?.lowercased() == "https" else {
            AppLogger.shared.logSecurity("Insecure URL detected: \(urlString)")
            return false
        }
        return true
    }
    
    // Sanitize input strings
    func sanitizeInput(_ input: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces).union(.punctuationCharacters)
        return String(input.unicodeScalars.filter { allowedCharacters.contains($0) })
    }
}
