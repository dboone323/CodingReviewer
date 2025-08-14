import Foundation
import CryptoKit

/// Manages caching of analysis results to improve performance for unchanged files
final class AnalysisCache {
    static let shared = AnalysisCache()

    private let logger = AppLogger.shared
    private var cache: [String: CachedAnalysisResult] = [:]
    private let maxCacheSize = 100
    private let cacheExpirationTime: TimeInterval = 3600 // 1 hour

    private init() {}

    /// Get cached analysis result if available and not expired
    /// <#Description#>
    /// - Returns: <#description#>
    func getCachedResult(for code: String, analyzerType: String) -> [AnalysisResult]? {
        let cacheKey = generateCacheKey(for: code, analyzerType: analyzerType)

        guard let cachedResult = cache[cacheKey] else {
            logger.debug("Cache miss for \(analyzerType) analysis")
            return nil
        }

        // Check if cache has expired
        if Date().timeIntervalSince(cachedResult.timestamp) > cacheExpirationTime {
            cache.removeValue(forKey: cacheKey)
            logger.debug("Cache expired for \(analyzerType) analysis")
            return nil
        }

        logger.debug("Cache hit for \(analyzerType) analysis")
        return cachedResult.results
    }

    /// Cache analysis result
    /// <#Description#>
    /// - Returns: <#description#>
    func cacheResult(_ results: [AnalysisResult], for code: String, analyzerType: String) {
        let cacheKey = generateCacheKey(for: code, analyzerType: analyzerType)

        let cachedResult = CachedAnalysisResult(
            results: results,
            timestamp: Date(),
            analyzerType: analyzerType
        )

        cache[cacheKey] = cachedResult

        // Clean up old entries if cache is too large
        if cache.count > maxCacheSize {
            cleanupOldEntries()
        }

        logger.debug("Cached \(results.count) results for \(analyzerType) analysis")
    }

    /// Generate a cache key based on code content and analyzer type
    private func generateCacheKey(for code: String, analyzerType: String) -> String {
        let data = Data("\(code)\(analyzerType)".utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Clean up old cache entries
    private func cleanupOldEntries() {
        let sortedEntries = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        let entriesToRemove = sortedEntries.prefix(cache.count - maxCacheSize + 10)

        for (key, _) in entriesToRemove {
            cache.removeValue(forKey: key)
        }

        logger.debug("Cleaned up \(entriesToRemove.count) old cache entries")
    }

    /// Clear all cached results
    /// <#Description#>
    /// - Returns: <#description#>
    func clearCache() {
        cache.removeAll()
        logger.log("Analysis cache cleared", level: .info, category: .performance)
    }

    /// Get cache statistics
    /// <#Description#>
    /// - Returns: <#description#>
    func getCacheStats() -> CacheStatistics {
        let expiredCount = cache.values.count(where: {
            Date().timeIntervalSince($0.timestamp) > cacheExpirationTime
        })

        return CacheStatistics(
            totalEntries: cache.count,
            expiredEntries: expiredCount,
            maxSize: maxCacheSize,
            expirationTime: cacheExpirationTime
        )
    }
}

/// Represents a cached analysis result
private struct CachedAnalysisResult {
    let results: [AnalysisResult]
    let timestamp: Date
    let analyzerType: String
}

/// Statistics about the analysis cache
struct CacheStatistics {
    let totalEntries: Int
    let expiredEntries: Int
    let maxSize: Int
    let expirationTime: TimeInterval

    var hitRate: Double {
        guard totalEntries > 0 else { return 0.0 }
        return Double(totalEntries - expiredEntries) / Double(totalEntries)
    }

    var description: String {
        """
        Cache Statistics:
        - Total entries: \(totalEntries)
        - Expired entries: \(expiredEntries)
        - Active entries: \(totalEntries - expiredEntries)
        - Hit rate: \(String(format: "%.1f%%", hitRate * 100))
        - Max size: \(maxSize)
        - Expiration time: \(Int(expirationTime))s
        """
    }
}

/// Extension to integrate caching with existing analyzers
extension CodeAnalyzer {
    /// Analyzes and processes data with comprehensive validation
    /// <#Description#>
    /// - Returns: <#description#>
    func analyzeWithCaching(_ code: String) async -> [AnalysisResult] {
        let analyzerType = String(describing: type(of: self))

        // Try to get cached result first
        if let cachedResults = AnalysisCache.shared.getCachedResult(for: code, analyzerType: analyzerType) {
            return cachedResults
        }

        // Run analysis and cache result
        let results = await analyze(code)
        AnalysisCache.shared.cacheResult(results, for: code, analyzerType: analyzerType)

        return results
    }
}
