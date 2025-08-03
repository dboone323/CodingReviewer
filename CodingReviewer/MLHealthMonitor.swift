//
// MLHealthMonitor.swift
// CodingReviewer
//
// Swift 6 Compatible ML Health Monitoring System
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class MLHealthMonitor: ObservableObject {
    @Published var healthStatus: HealthStatus = .unknown
    @Published var lastCheck: Date?
    @Published var healthScore: Double = 0.0
    @Published var activeMonitors: Int = 0
    @Published var systemLoad: Double = 0.0

    private var cancellables = Set<AnyCancellable>()
    private let checkInterval: TimeInterval = 300 // 5 minutes

    enum HealthStatus {
        case healthy
        case warning
        case critical
        case unknown

        var color: Color {
            switch self {
            case .healthy: return .green
            case .warning: return .yellow
            case .critical: return .red
            case .unknown: return .gray
            }
        }

        var icon: String {
            switch self {
            case .healthy: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.circle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }

        var description: String {
            switch self {
            case .healthy: return "All systems operational"
            case .warning: return "Minor issues detected"
            case .critical: return "Critical issues require attention"
            case .unknown: return "Status unknown"
            }
        }
    }

    init() {
        startHealthMonitoring()
    }

    private func startHealthMonitoring() {
        Timer.publish(every: checkInterval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task {
                    await self.performHealthCheck()
                }
            }
            .store(in: &cancellables)

        // Initial health check
        Task {
            await performHealthCheck()
        }
    }

    func performHealthCheck() async {
        let startTime = Date()

        // Check ML data availability
        let dataHealth = await checkMLDataHealth()

        // Check script execution health
        let scriptHealth = await checkScriptHealth()

        // Check system resources
        let resourceHealth = await checkResourceHealth()

        // Calculate overall health score
        let overallScore = (dataHealth + scriptHealth + resourceHealth) / 3.0

        // Update UI on main actor
        healthScore = overallScore
        lastCheck = Date()
        activeMonitors = 3
        systemLoad = await getCurrentSystemLoad()

        // Determine health status
        healthStatus = determineHealthStatus(score: overallScore)

        AppLogger.shared.log("ML Health Check completed: \(Int(overallScore * 100))% healthy", level: .info, category: .ai)
    }

    private func checkMLDataHealth() async -> Double {
        let mlDataPath = "/Users/danielstevens/Desktop/CodingReviewer/.ml_automation/data"

        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: mlDataPath)
            let today = DateFormatter.filenameDateFormatter.string(from: Date())
            let todayFiles = files.filter { $0.contains(today) }

            return todayFiles.isEmpty ? 0.3 : 1.0
        } catch {
            return 0.0
        }
    }

    private func checkScriptHealth() async -> Double {
        // Check if main ML scripts are executable and recent
        let scripts = [
            "ml_pattern_recognition_fixed.sh",
            "predictive_analytics.sh",
            "cross_project_learning.sh"
        ]

        var healthyScripts = 0
        for script in scripts {
            let scriptPath = "/Users/danielstevens/Desktop/CodingReviewer/\(script)"
            if FileManager.default.isExecutableFile(atPath: scriptPath) {
                healthyScripts += 1
            }
        }

        return Double(healthyScripts) / Double(scripts.count)
    }

    private func checkResourceHealth() async -> Double {
        let memoryInfo = getMemoryInfo()
        let cpuUsage = getCPUUsage()

        // Consider healthy if memory usage < 80% and CPU < 90%
        let memoryHealth = memoryInfo.available > 0.2 ? 1.0 : 0.5
        let cpuHealth = cpuUsage < 0.9 ? 1.0 : 0.5

        return (memoryHealth + cpuHealth) / 2.0
    }

    private func getCurrentSystemLoad() async -> Double {
        // Simple system load estimation
        let memoryInfo = getMemoryInfo()
        let cpuUsage = getCPUUsage()

        return (memoryInfo.used + cpuUsage) / 2.0
    }

    private func determineHealthStatus(score: Double) -> HealthStatus {
        switch score {
        case 0.8...1.0: return .healthy
        case 0.5...0.8: return .warning
        case 0.0...0.5: return .critical
        default: return .unknown
        }
    }

    // MARK: - System Info Helpers

    private func getMemoryInfo() -> (used: Double, available: Double) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let totalMemory = Double(info.resident_size)
            let maxMemory = 8_000_000_000.0 // 8GB assumption
            let used = totalMemory / maxMemory
            return (used: used, available: 1.0 - used)
        }

        return (used: 0.5, available: 0.5)
    }

    private func getCPUUsage() -> Double {
        // Simplified CPU usage estimation
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let totalTicks = info.cpu_ticks.0 + info.cpu_ticks.1 + info.cpu_ticks.2 + info.cpu_ticks.3
            let idleTicks = info.cpu_ticks.2
            return totalTicks > 0 ? Double(totalTicks - idleTicks) / Double(totalTicks) : 0.5
        }

        return 0.5
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}
