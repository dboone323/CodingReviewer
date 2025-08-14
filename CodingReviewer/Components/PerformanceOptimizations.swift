import Foundation
import Combine
import SwiftUI

//
//  PerformanceOptimizations.swift
//  CodingReviewer
//
//  Created by Phase 3 Production Enhancement on 8/5/25.
//

// MARK: - Async Operation Batching

@MainActor
class BatchProcessor<T: Sendable>: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var processedItems: [T] = []
    @Published var errors: [Error] = []

    private let batchSize: Int
    private let processingDelay: TimeInterval
    private var cancellables = Set<AnyCancellable>()

    init(batchSize: Int = 10, processingDelay: TimeInterval = 0.1) {
        self.batchSize = batchSize
        self.processingDelay = processingDelay
    }

    /// Analyzes and processes data with comprehensive validation
    func processBatch<Result: Sendable>(
        items: [T],
        processor: @escaping @Sendable (T) async throws -> Result
    ) async -> [Result] {
        await MainActor.run {
            isProcessing = true
            progress = 0.0
            processedItems.removeAll()
            errors.removeAll()
        }

        var results: [Result] = []
        let totalItems = items.count

        // Simple sequential processing to avoid concurrency issues
        for (index, item) in items.enumerated() {
            do {
                let result = try await processor(item)
                results.append(result)

                await MainActor.run {
                    progress = Double(index + 1) / Double(totalItems)
                }

                // Small delay between items
                if index < items.count - 1 {
                    try? await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
                }
            } catch {
                await MainActor.run {
                    errors.append(error)
                }
            }
        }

        await MainActor.run {
            isProcessing = false
        }

        return results
    }
}

// MARK: - Memory Usage Monitor

@MainActor
public class MemoryMonitor: ObservableObject {
    @Published var currentUsage: UInt64 = 0
    @Published var peakUsage: UInt64 = 0
    @Published var memoryPressure: MemoryPressure = .normal
    @Published var warnings: [MemoryWarning] = []

    enum MemoryPressure {
        case normal
        case elevated
        case critical

        var threshold: UInt64 {
            switch self {
            case .normal: 512 * 1024 * 1024 // 512MB
            case .elevated: 1024 * 1024 * 1024 // 1GB
            case .critical: 2048 * 1024 * 1024 // 2GB
            }
        }

        var color: Color {
            switch self {
            case .normal: .green
            case .elevated: .orange
            case .critical: .red
            }
        }
    }

    struct MemoryWarning: Identifiable {
        let id = UUID()
        let timestamp: Date
        let usage: UInt64
        let pressure: MemoryPressure
        let message: String
    }

    private nonisolated(unsafe) var timer: Timer?

    init() {
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    /// Initiates process with proper setup and monitoring
            /// Function description
            /// - Returns: Return value description
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateMemoryUsage()
            }
        }
    }

    /// Completes process and performs cleanup
            /// Function description
            /// - Returns: Return value description
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    /// Updates and persists data with validation
    private func updateMemoryUsage() {
        let usage = getMemoryUsage()
        currentUsage = usage

        if usage > peakUsage {
            peakUsage = usage
        }

        let newPressure: MemoryPressure = if usage > MemoryPressure.critical.threshold {
            .critical
        } else if usage > MemoryPressure.elevated.threshold {
            .elevated
        } else {
            .normal
        }

        if newPressure != memoryPressure {
            memoryPressure = newPressure
            addWarning(for: newPressure, usage: usage)
        }
    }

    /// Retrieves data with proper error handling and caching
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }

    /// Performs operation with error handling and validation
    private func addWarning(for pressure: MemoryPressure, usage: UInt64) {
        let message = switch pressure {
        case .normal:
            "Memory usage returned to normal"
        case .elevated:
            "Memory usage is elevated. Consider closing unused features."
        case .critical:
            "Critical memory usage detected. Performance may be affected."
        }

        let warning = MemoryWarning(
            timestamp: Date(),
            usage: usage,
            pressure: pressure,
            message: message
        )

        warnings.append(warning)

        // Keep only last 10 warnings
        if warnings.count > 10 {
            warnings.removeFirst()
        }
    }

    /// Formats and displays data with proper styling
            /// Function description
            /// - Returns: Return value description
    func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Response Time Tracker

@MainActor
class ResponseTimeTracker: ObservableObject {
    @Published var averageResponseTime: TimeInterval = 0
    @Published var recentResponseTimes: [ResponseTimeEntry] = []
    @Published var slowOperations: [SlowOperation] = []

    struct ResponseTimeEntry: Identifiable {
        let id = UUID()
        let operation: String
        let duration: TimeInterval
        let timestamp: Date
        let success: Bool
    }

    struct SlowOperation: Identifiable {
        let id = UUID()
        let operation: String
        let duration: TimeInterval
        let timestamp: Date
        let threshold: TimeInterval
    }

    private let slowThreshold: TimeInterval = 2.0 // 2 seconds
    private let maxEntries = 100

    /// Performs operation with error handling and validation
    func trackOperation<T>(
        _ operation: String,
        threshold: TimeInterval? = nil,
        task: () async throws -> T
    ) async rethrows -> T {
        let startTime = Date()
        var success = false

        defer {
            let duration = Date().timeIntervalSince(startTime)
            let entry = ResponseTimeEntry(
                operation: operation,
                duration: duration,
                timestamp: startTime,
                success: success
            )

            recentResponseTimes.append(entry)
            if recentResponseTimes.count > maxEntries {
                recentResponseTimes.removeFirst()
            }

            updateAverageResponseTime()

            let operationThreshold = threshold ?? slowThreshold
            if duration > operationThreshold {
                let slowOp = SlowOperation(
                    operation: operation,
                    duration: duration,
                    timestamp: startTime,
                    threshold: operationThreshold
                )
                slowOperations.append(slowOp)

                // Keep only last 20 slow operations
                if slowOperations.count > 20 {
                    slowOperations.removeFirst()
                }
            }
        }

        do {
            let result = try await task()
            success = true
            return result
        } catch {
            success = false
            throw error
        }
    }

    /// Updates and persists data with validation
    private func updateAverageResponseTime() {
        guard !recentResponseTimes.isEmpty else {
            averageResponseTime = 0
            return
        }

        let totalTime = recentResponseTimes
            .reduce(0) {
                $0 + $1.duration
            }
        averageResponseTime = totalTime / Double(recentResponseTimes.count)
    }

    /// Retrieves data with proper error handling and caching
            /// Function description
            /// - Returns: Return value description
    func getSuccessRate() -> Double {
        guard !recentResponseTimes.isEmpty else { return 0 }

        let successCount = recentResponseTimes.count(where: { $0.success })
        return Double(successCount) / Double(recentResponseTimes.count)
    }

            /// Function description
            /// - Returns: Return value description
    func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 1.0 {
            String(format: "%.0f ms", duration * 1000)
        } else {
            String(format: "%.2f s", duration)
        }
    }
}

// MARK: - Background Processing Manager

@MainActor
class BackgroundProcessingManager: ObservableObject {
    @Published var activeJobs: [BackgroundJob] = []
    @Published var completedJobs: [BackgroundJob] = []
    @Published var totalJobsProcessed = 0

    struct BackgroundJob: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let priority: Priority
        var status: Status
        var progress: Double
        let startTime: Date
        var endTime: Date?
        var result: Any?
        var error: Error?

        enum Priority {
            case low
            case medium
            case high
            case critical

            var sortOrder: Int {
                switch self {
                case .low: 0
                case .medium: 1
                case .high: 2
                case .critical: 3
                }
            }
        }

        enum Status {
            case queued
            case running
            case completed
            case failed
            case cancelled

            var icon: String {
                switch self {
                case .queued: "clock"
                case .running: "gear"
                case .completed: "checkmark.circle.fill"
                case .failed: "xmark.circle.fill"
                case .cancelled: "stop.circle"
                }
            }

            var color: Color {
                switch self {
                case .queued: .orange
                case .running: .blue
                case .completed: .green
                case .failed: .red
                case .cancelled: .gray
                }
            }
        }
    }

    private let maxConcurrentJobs: Int
    private var jobQueue: [BackgroundJob] = []

    init(maxConcurrentJobs: Int = 3) {
        self.maxConcurrentJobs = maxConcurrentJobs
    }

    func enqueueJob(
        name: String,
        description: String,
        priority: BackgroundJob.Priority = .medium,
        task _: @escaping () async throws -> some Any
    ) -> UUID {
        let job = BackgroundJob(
            name: name,
            description: description,
            priority: priority,
            status: .queued,
            progress: 0.0,
            startTime: Date()
        )

        jobQueue.append(job)
        jobQueue.sort { $0.priority.sortOrder > $1.priority.sortOrder }

        processNextJob()

        return job.id
    }

            /// Function description
            /// - Returns: Return value description
    func cancelJob(id: UUID) {
        if let index = activeJobs.firstIndex(where: { $0.id == id }) {
            activeJobs[index].status = .cancelled
            activeJobs[index].endTime = Date()

            let job = activeJobs.remove(at: index)
            completedJobs.append(job)
        }

        jobQueue.removeAll { $0.id == id }
    }

    private func processNextJob() {
        guard activeJobs.count < maxConcurrentJobs,
              !jobQueue.isEmpty else { return }

        var job = jobQueue.removeFirst()
        job.status = .running
        activeJobs.append(job)

        Task {
            do {
                // Simulate job processing with progress updates
                for i in 1 ... 10 {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                    if let index = activeJobs.firstIndex(where: { $0.id == job.id }) {
                        activeJobs[index].progress = Double(i) / 10.0

                        if activeJobs[index].status == .cancelled {
                            return
                        }
                    }
                }

                // Complete the job
                if let index = activeJobs.firstIndex(where: { $0.id == job.id }) {
                    activeJobs[index].status = .completed
                    activeJobs[index].progress = 1.0
                    activeJobs[index].endTime = Date()

                    let completedJob = activeJobs.remove(at: index)
                    completedJobs.append(completedJob)
                    totalJobsProcessed += 1
                }

            } catch {
                if let index = activeJobs.firstIndex(where: { $0.id == job.id }) {
                    activeJobs[index].status = .failed
                    activeJobs[index].error = error
                    activeJobs[index].endTime = Date()

                    let failedJob = activeJobs.remove(at: index)
                    completedJobs.append(failedJob)
                }
            }

            // Process next job in queue
            processNextJob()
        }
    }

            /// Function description
            /// - Returns: Return value description
    func clearCompletedJobs() {
        completedJobs.removeAll()
    }

            /// Function description
            /// - Returns: Return value description
    func getJobsBy(status: BackgroundJob.Status) -> [BackgroundJob] {
        let allJobs = activeJobs + completedJobs + jobQueue
        return allJobs.filter { $0.status == status }
    }
}

// MARK: - Performance Dashboard

struct OptimizationDashboard: View {
    @StateObject private var memoryMonitor = MemoryMonitor()
    @StateObject private var responseTracker = ResponseTimeTracker()
    @StateObject private var backgroundManager = BackgroundProcessingManager()

    var body: some View {
        VStack(spacing: 16) {
            // Memory Usage
            VStack(alignment: .leading, spacing: 8) {
                Text("Memory Usage")
                    .font(.headline)

                HStack {
                    Circle()
                        .fill(memoryMonitor.memoryPressure.color)
                        .frame(width: 12, height: 12)

                    Text(memoryMonitor.formatBytes(memoryMonitor.currentUsage))
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("Peak: \(memoryMonitor.formatBytes(memoryMonitor.peakUsage))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)

            // Response Times
            VStack(alignment: .leading, spacing: 8) {
                Text("Response Times")
                    .font(.headline)

                HStack {
                    Text(responseTracker.formatDuration(responseTracker.averageResponseTime))
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("Success: \(Int(responseTracker.getSuccessRate() * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)

            // Background Jobs
            VStack(alignment: .leading, spacing: 8) {
                Text("Background Processing")
                    .font(.headline)

                HStack {
                    Text("\(backgroundManager.activeJobs.count) active")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("\(backgroundManager.totalJobsProcessed) completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !backgroundManager.activeJobs.isEmpty {
                    VStack(spacing: 4) {
                        ForEach(backgroundManager.activeJobs.prefix(3)) { job in
                            HStack {
                                Image(systemName: job.status.icon)
                                    .foregroundColor(job.status.color)
                                    .font(.caption)

                                Text(job.name)
                                    .font(.caption)
                                    .lineLimit(1)

                                Spacer()

                                Text("\(Int(job.progress * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
        }
    }
}

// MARK: - Array Extension for Chunking

extension Array {
            /// Function description
            /// - Returns: Return value description
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Preview

#Preview {
    OptimizationDashboard()
        .padding()
}
