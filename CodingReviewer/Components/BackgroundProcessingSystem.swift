//
//  BackgroundProcessingSystem.swift
//  CodingReviewer
//
//  Created by Phase 4 Enterprise Features on 8/5/25.
//  Refactored for better code organization - extracted types to separate files
//

import SwiftUI
import Foundation
import Combine

// Note: Background processing types are now defined in BackgroundProcessingTypes.swift

// MARK: - Background Processing Queue System

@MainActor
class BackgroundProcessingSystem: ObservableObject {
    @Published var activeJobs: [ProcessingJob] = []
    @Published var completedJobs: [ProcessingJob] = []
    @Published var failedJobs: [ProcessingJob] = []
    @Published var systemLoad: SystemLoad = SystemLoad()
    @Published var processingLimits = ProcessingLimits.default
    @Published var isProcessingEnabled = true
    
    private let jobQueue = DispatchQueue(label: "com.codingreviewer.background", qos: .utility, attributes: .concurrent)
    // Use a non-isolated semaphore that can be accessed from background queues
    private let semaphore: DispatchSemaphore
    private var jobTimer: Timer?
    private var systemMonitorTimer: Timer?
    private let maxJobHistory = 1000
    private let systemStartTime = Date()
    
    // Initialize semaphore in init
    init() {
        self.semaphore = DispatchSemaphore(value: 5) // Default value
        
        // Defer async setup to avoid MainActor issues in init
        Task { @MainActor in
            self.setupSystemMonitoring()
            self.loadJobHistory()
        }
    }
    
    // MARK: - Job Management
    
    func addJob(
        type: ProcessingJob.JobType,
        title: String,
        priority: ProcessingJob.JobPriority = .normal,
        data: [String: Any] = [:]
    ) -> ProcessingJob {
        let job = ProcessingJob(
            name: title,
            type: type,
            status: .queued,
            priority: priority,
            progress: 0.0,
            startTime: Date(),
            result: nil,
            endTime: nil,
            duration: nil
        )
        
        activeJobs.append(job)
        updateSystemLoad()
        processNextJob()
        
        return job
    }
    
    func cancelJob(id: UUID) {
        if let index = activeJobs.firstIndex(where: { $0.id == id }) {
            var job = activeJobs[index]
            job.status = .cancelled
            job.endTime = Date()
            
            activeJobs.remove(at: index)
            failedJobs.append(job)
            
            updateSystemLoad()
        }
    }
    
    func pauseAllJobs() {
        isProcessingEnabled = false
        for index in activeJobs.indices {
            if activeJobs[index].status == .running {
                activeJobs[index].status = .paused
            }
        }
        updateSystemLoad()
    }
    
    func resumeAllJobs() {
        isProcessingEnabled = true
        for index in activeJobs.indices {
            if activeJobs[index].status == .paused {
                activeJobs[index].status = .queued
            }
        }
        updateSystemLoad()
        processNextJob()
    }
    
    func retryFailedJob(id: UUID) {
        if let index = failedJobs.firstIndex(where: { $0.id == id }) {
            var job = failedJobs[index]
            job.status = .queued
            job.progress = 0.0
            job.startTime = Date()
            job.endTime = nil
            job.errorMessage = nil
            
            failedJobs.remove(at: index)
            activeJobs.append(job)
            
            updateSystemLoad()
            processNextJob()
        }
    }
    
    func addBatchJobs(count: Int, type: ProcessingJob.JobType) {
        for i in 1...count {
            _ = addJob(
                type: type,
                title: "\(type.rawValue) Job \(i)",
                priority: .normal,
                data: ["batchIndex": i]
            )
        }
    }
    
    func toggleProcessing() {
        if isProcessingEnabled {
            pauseAllJobs()
        } else {
            resumeAllJobs()
        }
    }
    
    func pauseJob(id: UUID) {
        if let index = activeJobs.firstIndex(where: { $0.id == id && $0.status == .running }) {
            activeJobs[index].status = .paused
            updateSystemLoad()
        }
    }
    
    func resumeJob(id: UUID) {
        if let index = activeJobs.firstIndex(where: { $0.id == id && $0.status == .paused }) {
            activeJobs[index].status = .queued
            updateSystemLoad()
            processNextJob()
        }
    }
    
    func scheduleRecurringJob(type: ProcessingJob.JobType, interval: TimeInterval, priority: ProcessingJob.JobPriority) {
        // For now, just add a single job - in a real implementation this would schedule recurring jobs
        _ = addJob(
            type: type,
            title: "Scheduled \(type.rawValue) Job",
            priority: priority,
            data: ["recurring": true, "interval": interval]
        )
    }
    
    func updateProcessingLimits(_ newLimits: ProcessingLimits) {
        DispatchQueue.main.async {
            self.processingLimits = newLimits
            self.updateSystemLoad()
        }
    }
    
    func clearCompletedJobs() {
        DispatchQueue.main.async {
            self.completedJobs.removeAll()
        }
    }
    
    func clearFailedJobs() {
        DispatchQueue.main.async {
            self.failedJobs.removeAll()
        }
    }
    
    func getProcessingStats() -> ProcessingStats {
        let totalProcessed = completedJobs.count + failedJobs.count
        let successCount = completedJobs.count
        let successRate = totalProcessed > 0 ? Double(successCount) / Double(totalProcessed) : 0.0
        let avgProcessingTime = completedJobs.isEmpty ? 0.0 : 
            completedJobs.reduce(0.0) { sum, job in
                sum + (job.duration ?? 0.0)
            } / Double(completedJobs.count)
        
        return ProcessingStats(
            totalJobs: totalProcessed,
            completedJobs: successCount,
            failedJobs: failedJobs.count,
            averageProcessingTime: avgProcessingTime,
            systemLoad: systemLoad,
            totalJobsProcessed: totalProcessed,
            successRate: successRate,
            currentLoad: systemLoad.loadLevel,
            activeJobs: activeJobs.count,
            queueLength: systemLoad.queueLength
        )
    }
    
    // MARK: - Job Processing
    
    private func processNextJob() {
        guard isProcessingEnabled else { return }
        
        let currentRunningJobs = activeJobs.filter { $0.status == .running }.count
        guard currentRunningJobs < processingLimits.maxConcurrentJobs else { return }
        
        let nextJob = activeJobs
            .filter { $0.status == .queued }
            .sorted { $0.priority > $1.priority }
            .first
        
        guard let job = nextJob,
              let jobIndex = activeJobs.firstIndex(where: { $0.id == job.id }) else { return }
        
        executeJob(at: jobIndex)
    }
    
    private func executeJob(at index: Int) {
        guard index < activeJobs.count else { return }

        activeJobs[index].status = .running
        activeJobs[index].startTime = Date()
        updateSystemLoad()

        let jobId = activeJobs[index].id
        let jobType = activeJobs[index].type
        let duration = jobType.estimatedDuration // Capture before async context

        jobQueue.async { [weak self] in
            self?.semaphore.wait()

            // Simulate job execution with progress updates
            let steps = 20
            let stepDuration = duration / Double(steps)

            for step in 1...steps {
                Thread.sleep(forTimeInterval: stepDuration)

                Task { @MainActor [weak self] in
                    guard let self = self,
                          let jobIndex = self.activeJobs.firstIndex(where: { $0.id == jobId }),
                          self.activeJobs[jobIndex].status == .running else {
                        return
                    }

                    let progress = Double(step) / Double(steps)
                    self.activeJobs[jobIndex].progress = progress
                    self.updateSystemLoad()
                }

                // Check for cancellation
                if Task.isCancelled { break }
            }

            // Job completion
            Task { @MainActor [weak self] in
                self?.completeJob(jobId: jobId, success: !Task.isCancelled)
            }

            self?.semaphore.signal()
        }
    }
    
    private func completeJob(jobId: UUID, success: Bool) {
        guard let jobIndex = activeJobs.firstIndex(where: { $0.id == jobId }) else { return }
        
        var job = activeJobs[jobIndex]
        job.endTime = Date()
        job.progress = success ? 1.0 : job.progress
        job.status = success ? .completed : .failed
        
        // Calculate duration
        if let endTime = job.endTime {
            job.duration = endTime.timeIntervalSince(job.startTime)
        }
        
        if !success {
            job.errorMessage = "Job processing failed"
        }
        
        activeJobs.remove(at: jobIndex)
        
        if success {
            completedJobs.append(job)
        } else {
            failedJobs.append(job)
        }
        
        // Cleanup old history
        maintainJobHistory()
        updateSystemLoad()
        
        // Process next job in queue
        processNextJob()
    }
    
    private func maintainJobHistory() {
        if completedJobs.count > maxJobHistory {
            completedJobs.removeFirst(completedJobs.count - maxJobHistory)
        }
        
        if failedJobs.count > maxJobHistory {
            failedJobs.removeFirst(failedJobs.count - maxJobHistory)
        }
    }
    
    // MARK: - System Monitoring
    
    private func setupSystemMonitoring() {
        systemMonitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateSystemLoad()
            }
        }
    }
    
    private func updateSystemLoad() {
        let runningJobs = activeJobs.filter { $0.status == .running }
        let queuedJobs = activeJobs.filter { $0.status == .queued }
        
        systemLoad.activeJobs = runningJobs.count
        systemLoad.queuedJobs = queuedJobs.count
        systemLoad.currentConcurrentJobs = runningJobs.count
        systemLoad.queueLength = queuedJobs.count
        systemLoad.lastUpdated = Date()
        
        // Calculate average job duration
        if !completedJobs.isEmpty {
            let durations = completedJobs.compactMap { $0.duration }
            if !durations.isEmpty {
                systemLoad.averageJobDuration = durations.reduce(0, +) / Double(durations.count)
            }
        }
        
        // Simulate system metrics (in a real implementation, these would be actual system readings)
        let cpuUsage = min(0.1 + Double(runningJobs.count) * 0.15, 0.95)
        let memoryUsage = min(0.2 + Double(activeJobs.count) * 0.05, 0.90)
        let diskUsage = 0.3
        let networkActivity = runningJobs.isEmpty ? 0.0 : 0.4
        let isOverloaded = cpuUsage > 0.8 || memoryUsage > 0.8
        
        // Create updated SystemLoad with calculated values
        systemLoad = SystemLoad(
            cpu: cpuUsage,
            memory: memoryUsage,
            disk: diskUsage,
            queueLength: systemLoad.queueLength,
            currentConcurrentJobs: systemLoad.currentConcurrentJobs,
            lastUpdated: systemLoad.lastUpdated,
            averageJobDuration: systemLoad.averageJobDuration,
            activeJobs: systemLoad.activeJobs,
            queuedJobs: systemLoad.queuedJobs,
            diskUsage: diskUsage,
            networkActivity: networkActivity,
            isOverloaded: isOverloaded
        )
        
        // Auto-pause if system is overloaded
        if processingLimits.pauseOnHighLoad && systemLoad.isOverloaded {
            pauseAllJobs()
        }
    }
    
    // MARK: - System Status and Statistics
    
    func getSystemStatus() -> SystemStatus {
        let totalJobs = activeJobs.count + completedJobs.count + failedJobs.count
        let successRate = totalJobs > 0 ? Double(completedJobs.count) / Double(totalJobs) : 1.0
        let uptime = Date().timeIntervalSince(systemStartTime)
        let _ = systemLoad.averageJobDuration // Acknowledge usage
        let isHealthy = !systemLoad.isOverloaded && successRate > 0.8
        let statusText = isHealthy ? "Healthy" : "Needs Attention"
        
        return SystemStatus(
            isHealthy: isHealthy,
            uptime: uptime,
            systemLoad: systemLoad,
            activeUsers: 1,  // Placeholder
            errorRate: 1.0 - successRate,
            activeJobsCount: activeJobs.count,
            status: statusText,
            successRate: successRate,
            healthScore: isHealthy ? 0.9 : 0.5,
            totalJobsProcessed: totalJobs,
            isProcessingEnabled: isProcessingEnabled
        )
    }
    
    // MARK: - Data Persistence
    
    private func loadJobHistory() {
        // In a real implementation, this would load from persistent storage
        // For now, we'll start with empty history
    }
    
    private func saveJobHistory() {
        // In a real implementation, this would save to persistent storage
    }
    
    // MARK: - Configuration
    
    @MainActor
    func cleanup() {
        systemMonitorTimer?.invalidate()
        systemMonitorTimer = nil
        jobTimer?.invalidate()
        jobTimer = nil
    }
    
    // MARK: - Cleanup
    
    deinit {
        // For Swift 6 concurrency, we need to be careful with timer cleanup
        // Since timers are typically created on main thread, we should invalidate them there
        // But we can't access non-Sendable properties from deinit
        // The system will handle cleanup automatically when the object is deallocated
    }
}
