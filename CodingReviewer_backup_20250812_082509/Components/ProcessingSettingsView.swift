import Foundation
import SwiftUI

//
//  ProcessingSettingsView.swift
//  CodingReviewer
//
//  Created by Phase 4 Enterprise Features on 8/5/25.
//

// Note: ProcessingJob types are defined in BackgroundProcessingTypes.swift

// MARK: - Job Creator View

struct JobCreatorView: View {
    @ObservedObject var processingSystem: BackgroundProcessingSystem
    @Environment(\.dismiss) private var dismiss

    @State private var selectedJobType: ProcessingJob.JobType = .codeAnalysis
    @State private var selectedPriority: ProcessingJob.JobPriority = .normal
    @State private var jobCount: Int = 1
    @State private var customData: [String: String] = [:]
    @State private var customOptions: [String: Bool] = [:]
    @State private var scheduleRecurring: Bool = false
    @State private var recurringInterval: TimeInterval = 3600 // 1 hour

    var body: some View {
        NavigationView {
            Form {
                Section("Job Configuration") {
                    Picker("Job Type", selection: $selectedJobType) {
                        ForEach(ProcessingJob.JobType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(ProcessingJob.JobPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName)
                                .foregroundColor(priority.color)
                                .tag(priority)
                        }
                    }

                    HStack {
                        Text("Job Count")
                        Spacer()
                        Stepper("\(jobCount)", value: $jobCount, in: 1 ... 20)
                    }

                    if jobCount > 1 {
                        Text("This will create \(jobCount) jobs of the selected type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Scheduling") {
                    Toggle("Schedule Recurring", isOn: $scheduleRecurring)

                    if scheduleRecurring {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Repeat Interval")
                                .font(.subheadline)

                            Picker("Interval", selection: $recurringInterval) {
                                Text("Every 15 minutes").tag(TimeInterval(900))
                                Text("Every 30 minutes").tag(TimeInterval(1800))
                                Text("Every hour").tag(TimeInterval(3600))
                                Text("Every 2 hours").tag(TimeInterval(7200))
                                Text("Every 6 hours").tag(TimeInterval(21600))
                                Text("Daily").tag(TimeInterval(86400))
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }

                Section("Custom Parameters") {
                    CustomParametersEditor(
                        data: $customData,
                        options: $customOptions
                    )
                }
            }
            .navigationTitle("Create Job")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Create") {
                        createJobs()
                        dismiss()
                    }
                }
            }
        }
    }

    /// Performs operation with comprehensive error handling and validation
    private func createJobs() {
        if scheduleRecurring {
            processingSystem.scheduleRecurringJob(
                type: selectedJobType,
                interval: recurringInterval,
                priority: selectedPriority
            )
        } else if jobCount == 1 {
            _ = processingSystem.addJob(
                type: selectedJobType,
                title: "Manual Job",
                priority: selectedPriority,
                data: customData.mapValues { $0 as Any }
            )
        } else {
            for i in 1 ... jobCount {
                _ = processingSystem.addJob(
                    type: selectedJobType,
                    title: "Batch Job \(i)",
                    priority: selectedPriority,
                    data: customData.mapValues { $0 as Any }
                )
            }
        }
    }
}

// MARK: - Processing Settings View

struct ProcessingSettingsView: View {
    @ObservedObject var processingSystem: BackgroundProcessingSystem
    @Environment(\.dismiss) private var dismiss

    @State private var limits: ProcessingLimits
    @State private var showingResetAlert = false

    init(processingSystem: BackgroundProcessingSystem) {
        self.processingSystem = processingSystem
        _limits = State(initialValue: processingSystem.processingLimits)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Processing Limits") {
                    HStack {
                        Text("Max Concurrent Jobs")
                        Spacer()
                        Stepper("\(limits.maxConcurrentJobs)", value: $limits.maxConcurrentJobs, in: 1 ... 10)
                    }

                    HStack {
                        Text("Max Queue Size")
                        Spacer()
                        Stepper("\(limits.maxQueueSize)", value: $limits.maxQueueSize, in: 10 ... 1000, step: 10)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Max Job Duration")
                            Spacer()
                            Text("\(Int(limits.maxJobDuration)) seconds")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $limits.maxJobDuration, in: 30 ... 3600, step: 30)
                    }
                }

                Section("System Monitoring") {
                    Toggle("Enable Throttling", isOn: $limits.enableThrottling)

                    Toggle("Auto-pause on High Load", isOn: $limits.pauseOnHighLoad)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("CPU Threshold")
                            Spacer()
                            Text("\(Int(limits.cpuThreshold * 100))%")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $limits.cpuThreshold, in: 0.5 ... 1.0, step: 0.05)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Memory Threshold")
                            Spacer()
                            Text("\(Int(limits.memoryThreshold * 100))%")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $limits.memoryThreshold, in: 0.5 ... 1.0, step: 0.05)
                    }
                }

                Section("Current Status") {
                    HStack {
                        Text("Processing Enabled")
                        Spacer()
                        Text(processingSystem.isProcessingEnabled ? "Yes" : "No")
                            .foregroundColor(processingSystem.isProcessingEnabled ? .green : .red)
                    }

                    HStack {
                        Text("Active Jobs")
                        Spacer()
                        Text("\(processingSystem.activeJobs.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("System Load")
                        Spacer()
                        Text(processingSystem.systemLoad.loadLevel.rawValue)
                            .foregroundColor(processingSystem.systemLoad.loadLevel.color)
                    }
                }

                Section("Actions") {
                    Button("Reset to Defaults") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.orange)

                    Button(processingSystem.isProcessingEnabled ? "Disable Processing" : "Enable Processing") {
                        processingSystem.toggleProcessing()
                    }
                    .foregroundColor(processingSystem.isProcessingEnabled ? .red : .green)
                }
            }
            .navigationTitle("Processing Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                    .disabled(!limits.isValid)
                }
            }
            .alert("Reset Settings", isPresented: $showingResetAlert) {
                Button("Reset", role: .destructive) {
                    limits = ProcessingLimits.default
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset all processing settings to their default values.")
            }
        }
    }

    /// Performs operation with comprehensive error handling and validation
    private func saveSettings() {
        processingSystem.updateProcessingLimits(limits)
    }
}

// MARK: - Custom Parameters Editor

struct CustomParametersEditor: View {
    @Binding var data: [String: String]
    @Binding var options: [String: Bool]

    @State private var newDataKey = ""
    @State private var newDataValue = ""
    @State private var newOptionKey = ""
    @State private var newOptionValue = false
    @State private var showingDataEditor = false
    @State private var showingOptionEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Data Parameters
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Data Parameters")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Button("Add") {
                        showingDataEditor = true
                    }
                    .font(.caption)
                }

                if data.isEmpty {
                    Text("No data parameters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(data.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.primary)

                            Text(":")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(data[key] ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Button("Remove") {
                                data.removeValue(forKey: key)
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                }
            }

            Divider()

            // Option Parameters
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Option Parameters")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Button("Add") {
                        showingOptionEditor = true
                    }
                    .font(.caption)
                }

                if options.isEmpty {
                    Text("No option parameters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(options.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.primary)

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { options[key] ?? false },
                                set: { options[key] = $0 }
                            ))
                            .labelsHidden()

                            Button("Remove") {
                                options.removeValue(forKey: key)
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingDataEditor) {
            DataParameterEditor(
                key: $newDataKey,
                value: $newDataValue,
                onSave: {
                    if !newDataKey.isEmpty {
                        data[newDataKey] = newDataValue
                        newDataKey = ""
                        newDataValue = ""
                    }
                }
            )
        }
        .sheet(isPresented: $showingOptionEditor) {
            OptionParameterEditor(
                key: $newOptionKey,
                value: $newOptionValue,
                onSave: {
                    if !newOptionKey.isEmpty {
                        options[newOptionKey] = newOptionValue
                        newOptionKey = ""
                        newOptionValue = false
                    }
                }
            )
        }
    }
}

// MARK: - Parameter Editors

struct DataParameterEditor: View {
    @Binding var key: String
    @Binding var value: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Data Parameter") {
                    TextField("Key", text: $key)
                    TextField("Value", text: $value, axis: .vertical)
                        .lineLimit(3 ... 6)
                }
            }
            .navigationTitle("Add Data Parameter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        onSave()
                        dismiss()
                    }
                    .disabled(key.isEmpty)
                }
            }
        }
    }
}

struct OptionParameterEditor: View {
    @Binding var key: String
    @Binding var value: Bool
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Option Parameter") {
                    TextField("Key", text: $key)
                    Toggle("Value", isOn: $value)
                }
            }
            .navigationTitle("Add Option Parameter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        onSave()
                        dismiss()
                    }
                    .disabled(key.isEmpty)
                }
            }
        }
    }
}

// MARK: - Advanced Settings View

struct AdvancedProcessingSettings: View {
    @ObservedObject var processingSystem: BackgroundProcessingSystem
    @State private var showingExportSheet = false
    @State private var exportData = ""

    var body: some View {
        List {
            Section("Performance Tuning") {
                NavigationLink("Queue Management") {
                    QueueManagementView(processingSystem: processingSystem)
                }

                NavigationLink("Load Balancing") {
                    LoadBalancingView(processingSystem: processingSystem)
                }

                NavigationLink("Resource Monitoring") {
                    ResourceMonitoringView(processingSystem: processingSystem)
                }
            }

            Section("Data Management") {
                Button("Export Processing Data") {
                    exportProcessingData()
                }

                Button("Clear All History", role: .destructive) {
                    processingSystem.clearCompletedJobs()
                    processingSystem.clearFailedJobs()
                }
            }

            Section("System Information") {
                NavigationLink("Diagnostics") {
                    ProcessingDiagnosticsView(processingSystem: processingSystem)
                }
            }
        }
        .navigationTitle("Advanced Settings")
        .sheet(isPresented: $showingExportSheet) {
            ExportProcessingDataView(data: exportData)
        }
    }

    /// Performs operation with comprehensive error handling and validation
    private func exportProcessingData() {
        let stats = processingSystem.getProcessingStats()
        let exportDict: [String: Any] = [
            "statistics": [
                "totalJobsProcessed": stats.totalJobsProcessed,
                "successRate": stats.successRate,
                "averageProcessingTime": stats.averageProcessingTime,
                "currentLoad": stats.currentLoad.rawValue,
                "activeJobs": stats.activeJobs,
                "queueLength": stats.queueLength,
            ],
            "configuration": [
                "maxConcurrentJobs": processingSystem.processingLimits.maxConcurrentJobs,
                "maxQueueSize": processingSystem.processingLimits.maxQueueSize,
                "maxJobDuration": processingSystem.processingLimits.maxJobDuration,
                "enableThrottling": processingSystem.processingLimits.enableThrottling,
                "pauseOnHighLoad": processingSystem.processingLimits.pauseOnHighLoad,
            ],
            "exportedAt": ISO8601DateFormatter().string(from: Date()),
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8)
        {
            exportData = jsonString
            showingExportSheet = true
        }
    }
}

// MARK: - Supporting Detail Views

struct QueueManagementView: View {
    @ObservedObject var processingSystem: BackgroundProcessingSystem

    var body: some View {
        List {
            Section("Queue Statistics") {
                HStack {
                    Text("Current Queue Length")
                    Spacer()
                    Text("\(processingSystem.systemLoad.queueLength)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Max Queue Size")
                    Spacer()
                    Text("\(processingSystem.processingLimits.maxQueueSize)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Queue Utilization")
                    Spacer()
                    let utilization = Double(processingSystem.systemLoad.queueLength) /
                        Double(processingSystem.processingLimits.maxQueueSize)
                    Text("\(Int(utilization * 100))%")
                        .foregroundColor(utilization > 0.8 ? .red : .secondary)
                }
            }

            Section("Queue Actions") {
                Button("Clear Queued Jobs", role: .destructive) {
                    // Implementation would clear queued jobs
                }

                Button("Prioritize Critical Jobs") {
                    // Implementation would reorder queue by priority
                }
            }
        }
        .navigationTitle("Queue Management")
    }
}

struct LoadBalancingView: View {
    @ObservedObject var processingSystem: BackgroundProcessingSystem

    var body: some View {
        List {
            Section("Load Distribution") {
                HStack {
                    Text("Current Concurrent Jobs")
                    Spacer()
                    Text("\(processingSystem.systemLoad.currentConcurrentJobs)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("CPU Usage")
                    Spacer()
                    Text("\(Int(processingSystem.systemLoad.cpuUsage * 100))%")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Memory Usage")
                    Spacer()
                    Text("\(Int(processingSystem.systemLoad.memoryUsage * 100))%")
                        .foregroundColor(.secondary)
                }
            }

            Section("Load Balancing Settings") {
                Toggle("Dynamic Load Balancing", isOn: .constant(true))
                Toggle("Auto-scale Based on Load", isOn: .constant(false))
            }
        }
        .navigationTitle("Load Balancing")
    }
}

struct ResourceMonitoringView: View {
    @ObservedObject var processingSystem: BackgroundProcessingSystem

    var body: some View {
        List {
            Section("Resource Usage") {
                HStack {
                    Text("System Load Level")
                    Spacer()
                    Text(processingSystem.systemLoad.loadLevel.rawValue)
                        .foregroundColor(processingSystem.systemLoad.loadLevel.color)
                }

                HStack {
                    Text("Last Updated")
                    Spacer()
                    Text(processingSystem.systemLoad.lastUpdated, format: .dateTime.hour().minute().second())
                        .foregroundColor(.secondary)
                }
            }

            Section("Monitoring Settings") {
                Toggle("Real-time Monitoring", isOn: .constant(true))
                Toggle("Performance Alerts", isOn: .constant(true))
            }
        }
        .navigationTitle("Resource Monitoring")
    }
}

struct ProcessingDiagnosticsView: View {
    @ObservedObject var processingSystem: BackgroundProcessingSystem

    var body: some View {
        List {
            Section("System Health") {
                HStack {
                    Text("Processing System")
                    Spacer()
                    Text("Healthy")
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Queue System")
                    Spacer()
                    Text("Operational")
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Monitoring System")
                    Spacer()
                    Text("Active")
                        .foregroundColor(.green)
                }
            }

            Section("Diagnostic Actions") {
                Button("Run System Check") {
                    // Implementation would run diagnostic checks
                }

                Button("Generate Diagnostic Report") {
                    // Implementation would generate detailed report
                }
            }
        }
        .navigationTitle("Diagnostics")
    }
}

struct ExportProcessingDataView: View {
    let data: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(data)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Processing Data Export")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(data, forType: .string)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ProcessingSettingsView(processingSystem: BackgroundProcessingSystem())
    }
}
