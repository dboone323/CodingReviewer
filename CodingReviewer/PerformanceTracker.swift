import Foundation

class PerformanceTracker {
    static let shared = PerformanceTracker()
    
    private var startTimes: [String: CFTimeInterval] = [:]
    private var performanceMetrics: [PerformanceMetric] = []
    
    private init() {}
    
    func startTracking(_ operation: String) {
        startTimes[operation] = CFAbsoluteTimeGetCurrent()
        AppLogger.shared.log("Performance tracking started: \(operation)")
    }
    
    func endTracking(_ operation: String) -> TimeInterval? {
        guard let startTime = startTimes[operation] else {
            AppLogger.shared.logWarning("No start time found for operation: \(operation)")
            return nil
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        let metric = PerformanceMetric(
            operation: operation,
            duration: duration,
            timestamp: Date(),
            memoryUsage: getCurrentMemoryUsage()
        )
        
        performanceMetrics.append(metric)
        startTimes.removeValue(forKey: operation)
        
        AppLogger.shared.log("Performance tracking completed: \(operation) - \(String(format: "%.3f", duration))s")
        
        // Log warning for slow operations
        if duration > 1.0 {
            AppLogger.shared.logWarning("Slow operation detected: \(operation) took \(String(format: "%.3f", duration))s")
        }
        
        return duration
    }
    
    func getMetrics(for operation: String? = nil) -> [PerformanceMetric] {
        if let operation = operation {
            return performanceMetrics.filter { $0.operation == operation }
        }
        return performanceMetrics
    }
    
    func getAverageTime(for operation: String) -> TimeInterval? {
        let metrics = getMetrics(for: operation)
        guard !metrics.isEmpty else { return nil }
        
        let totalTime = metrics.reduce(0) { $0 + $1.duration }
        return totalTime / Double(metrics.count)
    }
    
    func getSlowestOperations(limit: Int = 10) -> [PerformanceMetric] {
        return performanceMetrics
            .sorted { $0.duration > $1.duration }
            .prefix(limit)
            .map { $0 }
    }
    
    func clearMetrics() {
        performanceMetrics.removeAll()
        startTimes.removeAll()
        AppLogger.shared.log("Performance metrics cleared")
    }
    
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
    
    func generateReport() -> String {
        var report = "# Performance Report\n\n"
        report += "Generated: \(Date())\n\n"
        
        // Summary statistics
        report += "## Summary\n"
        report += "Total operations tracked: \(performanceMetrics.count)\n"
        
        if !performanceMetrics.isEmpty {
            let totalTime = performanceMetrics.reduce(0) { $0 + $1.duration }
            let averageTime = totalTime / Double(performanceMetrics.count)
            report += "Average operation time: \(String(format: "%.3f", averageTime))s\n"
            
            let slowestMetric = performanceMetrics.max { $0.duration < $1.duration }
            if let slowest = slowestMetric {
                report += "Slowest operation: \(slowest.operation) (\(String(format: "%.3f", slowest.duration))s)\n"
            }
        }
        
        // Top slow operations
        report += "\n## Slowest Operations\n"
        let slowest = getSlowestOperations(limit: 5)
        for metric in slowest {
            report += "- \(metric.operation): \(String(format: "%.3f", metric.duration))s\n"
        }
        
        return report
    }
}

struct PerformanceMetric {
    let operation: String
    let duration: TimeInterval
    let timestamp: Date
    let memoryUsage: UInt64
    
    var formattedDuration: String {
        return String(format: "%.3f", duration)
    }
    
    var formattedMemoryUsage: String {
        let mb = Double(memoryUsage) / 1024.0 / 1024.0
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - Performance Measurement Extensions

extension NSObject {
    func measurePerformance<T>(of operation: String, block: () throws -> T) rethrows -> T {
        PerformanceTracker.shared.startTracking(operation)
        defer { PerformanceTracker.shared.endTracking(operation) }
        return try block()
    }
    
    func measureAsyncPerformance<T>(of operation: String, block: () async throws -> T) async rethrows -> T {
        PerformanceTracker.shared.startTracking(operation)
        defer { PerformanceTracker.shared.endTracking(operation) }
        return try await block()
    }
}
