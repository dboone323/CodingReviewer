//
//  EnterpriseIntegration.swift
//  CodingReviewer
//
//  Created by Phase 4 Enterprise Features on 8/5/25.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers
import Combine

// MARK: - Enterprise Data Export System

@MainActor
class EnterpriseDataExporter: ObservableObject {
    @Published var availableExports: [ExportTemplate] = []
    @Published var exportHistory: [ExportRecord] = []
    @Published var isExporting = false
    @Published var exportProgress: Double = 0
    @Published var lastExportError: String?
    
    struct ExportTemplate: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let format: ExportFormat
        let dataTypes: [DataType]
        let customFields: [String]
        let isDefault: Bool
        let createdAt: Date
    }
    
    struct ExportRecord: Identifiable {
        let id = UUID()
        let templateName: String
        let format: ExportFormat
        let dataTypes: [DataType]
        let exportedAt: Date
        let fileSize: Int64
        let recordCount: Int
        let duration: TimeInterval
        let success: Bool
        let errorMessage: String?
        let filePath: String?
        
        var formattedFileSize: String {
            ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        }
        
        var formattedDuration: String {
            String(format: "%.2fs", duration)
        }
    }
    
    struct ExportConfiguration {
        var includeMetadata: Bool = true
        var compressOutput: Bool = false
        var dateRange: DateRange = .all
        var maxRecords: Int? = nil
        var customFilters: [String: Any] = [:]
        
        enum DateRange {
            case all
            case lastDay
            case lastWeek
            case lastMonth
            case custom(from: Date, to: Date)
            
            var displayName: String {
                switch self {
                case .all: return "All Time"
                case .lastDay: return "Last 24 Hours"
                case .lastWeek: return "Last Week"
                case .lastMonth: return "Last Month"
                case .custom(let from, let to): return "Custom (\(from.formatted(date: .abbreviated, time: .omitted)) - \(to.formatted(date: .abbreviated, time: .omitted)))"
                }
            }
        }
    }
    
    init() {
        loadTemplates()
        loadExportHistory()
        createDefaultTemplates()
    }
    
    // MARK: - Template Management
    
    /// Creates and configures components with proper initialization
    func createTemplate(
        name: String,
        description: String,
        format: ExportFormat,
        dataTypes: [DataType],
        customFields: [String] = []
    ) -> ExportTemplate {
        let template = ExportTemplate(
            name: name,
            description: description,
            format: format,
            dataTypes: dataTypes,
            customFields: customFields,
            isDefault: false,
            createdAt: Date()
        )
        
        availableExports.append(template)
        saveTemplates()
        return template
    }
    
    /// Removes data and performs cleanup safely
    func deleteTemplate(id: UUID) {
        availableExports.removeAll { $0.id == id && !$0.isDefault }
        saveTemplates()
    }
    
    /// Creates and configures components with proper initialization
    private func createDefaultTemplates() {
        if availableExports.isEmpty {
            let defaultTemplates = [
                ExportTemplate(
                    name: "Complete Analytics Report",
                    description: "Comprehensive report including all analytics data",
                    format: .json,
                    dataTypes: [.codeAnalysis, .usageAnalytics, .performanceMetrics, .insights],
                    customFields: [],
                    isDefault: true,
                    createdAt: Date()
                ),
                ExportTemplate(
                    name: "Performance Dashboard",
                    description: "Performance metrics and system monitoring data",
                    format: .csv,
                    dataTypes: [.performanceMetrics, .processingJobs, .systemConfiguration],
                    customFields: [],
                    isDefault: true,
                    createdAt: Date()
                ),
                ExportTemplate(
                    name: "Code Analysis Summary",
                    description: "Detailed code analysis results and insights",
                    format: .pdf,
                    dataTypes: [.codeAnalysis, .insights],
                    customFields: ["summary", "recommendations"],
                    isDefault: true,
                    createdAt: Date()
                ),
                ExportTemplate(
                    name: "Error and Activity Log",
                    description: "System logs and user activity tracking",
                    format: .html,
                    dataTypes: [.errorLogs, .userActivity],
                    customFields: [],
                    isDefault: true,
                    createdAt: Date()
                )
            ]
            
            availableExports = defaultTemplates
            saveTemplates()
        }
    }
    
    // MARK: - Export Operations
    
    /// Performs operation with error handling and validation
    func exportData(
        template: ExportTemplate,
        configuration: ExportConfiguration = ExportConfiguration()
    ) async throws -> ExportRecord {
        isExporting = true
        exportProgress = 0
        lastExportError = nil
        
        let startTime = Date()
        
        do {
            // Simulate data collection and export process
            let data = try await collectData(for: template, configuration: configuration)
            exportProgress = 0.3
            
            let formattedData = try formatData(data, format: template.format, configuration: configuration)
            exportProgress = 0.6
            
            let (filePath, fileSize) = try await saveExportedData(formattedData, template: template)
            exportProgress = 0.8
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            let record = ExportRecord(
                templateName: template.name,
                format: template.format,
                dataTypes: template.dataTypes,
                exportedAt: endTime,
                fileSize: fileSize,
                recordCount: data.count,
                duration: duration,
                success: true,
                errorMessage: nil,
                filePath: filePath
            )
            
            exportHistory.insert(record, at: 0)
            saveExportHistory()
            
            exportProgress = 1.0
            isExporting = false
            
            return record
            
        } catch {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            let record = ExportRecord(
                templateName: template.name,
                format: template.format,
                dataTypes: template.dataTypes,
                exportedAt: endTime,
                fileSize: 0,
                recordCount: 0,
                duration: duration,
                success: false,
                errorMessage: error.localizedDescription,
                filePath: nil
            )
            
            exportHistory.insert(record, at: 0)
            saveExportHistory()
            
            lastExportError = error.localizedDescription
            isExporting = false
            exportProgress = 0
            
            throw error
        }
    }
    
    /// Performs operation with error handling and validation
    private func collectData(
        for template: ExportTemplate,
        configuration: ExportConfiguration
    ) async throws -> [[String: Any]] {
        var allData: [[String: Any]] = []
        
        // Simulate data collection with progress updates
        for (index, dataType) in template.dataTypes.enumerated() {
            let data = try await collectDataForType(dataType, configuration: configuration)
            allData.append(contentsOf: data)
            exportProgress = 0.1 + (0.2 * Double(index + 1) / Double(template.dataTypes.count))
        }
        
        return allData
    }
    
    /// Performs operation with error handling and validation
    private func collectDataForType(
        _ dataType: DataType,
        configuration: ExportConfiguration
    ) async throws -> [[String: Any]] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Generate mock data based on type
        switch dataType {
        case .codeAnalysis:
            return generateMockCodeAnalysisData()
        case .usageAnalytics:
            return generateMockUsageAnalyticsData()
        case .performanceMetrics:
            return generateMockPerformanceData()
        case .errorLogs:
            return generateMockErrorLogData()
        case .userActivity:
            return generateMockUserActivityData()
        case .systemConfiguration:
            return generateMockConfigurationData()
        case .processingJobs:
            return generateMockProcessingJobData()
        case .insights:
            return generateMockInsightData()
        }
    }
    
    /// Formats and displays data with proper styling
    private func formatData(
        _ data: [[String: Any]],
        format: ExportFormat,
        configuration: ExportConfiguration
    ) throws -> Data {
        switch format {
        case .json:
            return try formatAsJSON(data, configuration: configuration)
        case .csv:
            return try formatAsCSV(data, configuration: configuration)
        case .xml:
            return try formatAsXML(data, configuration: configuration)
        case .pdf:
            return try formatAsPDF(data, configuration: configuration)
        case .html:
            return try formatAsHTML(data, configuration: configuration)
        case .markdown:
            return try formatAsMarkdown(data, configuration: configuration)
        }
    }
    
    /// Updates and persists data with validation
    private func saveExportedData(_ data: Data, template: ExportTemplate) async throws -> (String, Int64) {
        let fileName = "\(template.name.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).\(template.format.fileExtension)"
        
        // Cross-platform document directory handling
        let documentsPath: URL
        #if os(macOS)
        if let userDocumentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            documentsPath = userDocumentsPath
        } else {
            documentsPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents")
        }
        #else
        documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        #endif
        
        let filePath = documentsPath.appendingPathComponent(fileName)
        
        try data.write(to: filePath)
        
        let fileSize = Int64(data.count)
        return (filePath.path, fileSize)
    }
    
    // MARK: - Data Formatting Methods
    
    /// Formats and displays data with proper styling
    private func formatAsJSON(_ data: [[String: Any]], configuration: ExportConfiguration) throws -> Data {
        var output: [String: Any] = [:]
        
        if configuration.includeMetadata {
            output["metadata"] = [
                "exportedAt": ISO8601DateFormatter().string(from: Date()),
                "recordCount": data.count,
                "version": "1.0"
            ]
        }
        
        output["data"] = data
        
        return try JSONSerialization.data(withJSONObject: output, options: .prettyPrinted)
    }
    
    /// Formats and displays data with proper styling
    private func formatAsCSV(_ data: [[String: Any]], configuration: ExportConfiguration) throws -> Data {
        guard !data.isEmpty else { return Data() }
        
        let headers = Array(data.first!.keys).sorted()
        var csvContent = headers.joined(separator: ",") + "\n"
        
        for record in data {
            let values = headers.map { key in
                let value = record[key] ?? ""
                return "\"\(value)\""
            }
            csvContent += values.joined(separator: ",") + "\n"
        }
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func formatAsXML(_ data: [[String: Any]], configuration: ExportConfiguration) throws -> Data {
        var xmlContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<export>\n"
        
        if configuration.includeMetadata {
            xmlContent += "<metadata>\n"
            xmlContent += "<exportedAt>\(ISO8601DateFormatter().string(from: Date()))</exportedAt>\n"
            xmlContent += "<recordCount>\(data.count)</recordCount>\n"
            xmlContent += "</metadata>\n"
        }
        
        xmlContent += "<data>\n"
        for record in data {
            xmlContent += "<record>\n"
            for (key, value) in record {
                xmlContent += "<\(key)>\(value)</\(key)>\n"
            }
            xmlContent += "</record>\n"
        }
        xmlContent += "</data>\n</export>"
        
        return xmlContent.data(using: .utf8) ?? Data()
    }
    
    private func formatAsPDF(_ data: [[String: Any]], configuration: ExportConfiguration) throws -> Data {
        // In a real implementation, you would use PDFKit or similar
        let content = "PDF Export - \(data.count) records exported at \(Date())"
        return content.data(using: .utf8) ?? Data()
    }
    
    private func formatAsHTML(_ data: [[String: Any]], configuration: ExportConfiguration) throws -> Data {
        var htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Export Report</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                table { border-collapse: collapse; width: 100%; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                th { background-color: #f2f2f2; }
            </style>
        </head>
        <body>
            <h1>Export Report</h1>
            <p>Exported at: \(Date())</p>
            <p>Records: \(data.count)</p>
            <table>
        """
        
        if let firstRecord = data.first {
            let headers = Array(firstRecord.keys).sorted()
            htmlContent += "<tr>"
            for header in headers {
                htmlContent += "<th>\(header)</th>"
            }
            htmlContent += "</tr>"
            
            for record in data {
                htmlContent += "<tr>"
                for header in headers {
                    htmlContent += "<td>\(record[header] ?? "")</td>"
                }
                htmlContent += "</tr>"
            }
        }
        
        htmlContent += """
            </table>
        </body>
        </html>
        """
        
        return htmlContent.data(using: .utf8) ?? Data()
    }
    
    private func formatAsMarkdown(_ data: [[String: Any]], configuration: ExportConfiguration) throws -> Data {
        var mdContent = "# Export Report\n\n"
        mdContent += "**Exported at:** \(Date())\n"
        mdContent += "**Records:** \(data.count)\n\n"
        
        if let firstRecord = data.first {
            let headers = Array(firstRecord.keys).sorted()
            
            // Table headers
            mdContent += "| " + headers.joined(separator: " | ") + " |\n"
            mdContent += "|" + headers.map { _ in "---" }.joined(separator: "|") + "|\n"
            
            // Table rows
            for record in data {
                let values = headers.map { key in "\(record[key] ?? "")" }
                mdContent += "| " + values.joined(separator: " | ") + " |\n"
            }
        }
        
        return mdContent.data(using: .utf8) ?? Data()
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockCodeAnalysisData() -> [[String: Any]] {
        (1...Int.random(in: 10...50)).map { i in
            [
                "id": i,
                "file": "file_\(i).swift",
                "issues": Int.random(in: 0...10),
                "suggestions": Int.random(in: 5...20),
                "complexity": Double.random(in: 1.0...10.0),
                "timestamp": Date().addingTimeInterval(-Double.random(in: 0...86400))
            ]
        }
    }
    
    private func generateMockUsageAnalyticsData() -> [[String: Any]] {
        (1...Int.random(in: 20...100)).map { i in
            [
                "id": i,
                "action": ["analysis", "upload", "insight"].randomElement()!,
                "duration": Double.random(in: 1.0...60.0),
                "success": Bool.random(),
                "timestamp": Date().addingTimeInterval(-Double.random(in: 0...604800))
            ]
        }
    }
    
    private func generateMockPerformanceData() -> [[String: Any]] {
        (1...Int.random(in: 50...200)).map { i in
            [
                "id": i,
                "cpu_usage": Double.random(in: 0.1...0.9),
                "memory_usage": Double.random(in: 0.2...0.8),
                "response_time": Double.random(in: 0.1...5.0),
                "timestamp": Date().addingTimeInterval(-Double.random(in: 0...86400))
            ]
        }
    }
    
    private func generateMockErrorLogData() -> [[String: Any]] {
        (1...Int.random(in: 5...30)).map { i in
            [
                "id": i,
                "level": ["error", "warning", "info"].randomElement()!,
                "message": "Mock error message \(i)",
                "component": ["analyzer", "uploader", "processor"].randomElement()!,
                "timestamp": Date().addingTimeInterval(-Double.random(in: 0...604800))
            ]
        }
    }
    
    private func generateMockUserActivityData() -> [[String: Any]] {
        (1...Int.random(in: 30...150)).map { i in
            [
                "id": i,
                "user": "user_\(Int.random(in: 1...10))",
                "action": ["login", "logout", "analysis", "upload", "export"].randomElement()!,
                "details": "Action details \(i)",
                "timestamp": Date().addingTimeInterval(-Double.random(in: 0...2592000))
            ]
        }
    }
    
    private func generateMockConfigurationData() -> [[String: Any]] {
        [
            [
                "setting": "max_concurrent_jobs",
                "value": 3,
                "category": "processing",
                "updated_at": Date().addingTimeInterval(-86400)
            ],
            [
                "setting": "enable_analytics",
                "value": true,
                "category": "features",
                "updated_at": Date().addingTimeInterval(-172800)
            ],
            [
                "setting": "export_format",
                "value": "json",
                "category": "export",
                "updated_at": Date().addingTimeInterval(-259200)
            ]
        ]
    }
    
    private func generateMockProcessingJobData() -> [[String: Any]] {
        (1...Int.random(in: 20...80)).map { i in
            [
                "id": i,
                "type": ["code_analysis", "pattern_detection", "batch_analysis"].randomElement()!,
                "status": ["completed", "failed", "running"].randomElement()!,
                "duration": Double.random(in: 1.0...300.0),
                "timestamp": Date().addingTimeInterval(-Double.random(in: 0...604800))
            ]
        }
    }
    
    private func generateMockInsightData() -> [[String: Any]] {
        (1...Int.random(in: 10...40)).map { i in
            [
                "id": i,
                "type": "optimization",
                "confidence": Double.random(in: 0.5...1.0),
                "recommendation": "Mock recommendation \(i)",
                "impact": ["low", "medium", "high"].randomElement()!,
                "timestamp": Date().addingTimeInterval(-Double.random(in: 0...259200))
            ]
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveTemplates() {
        // Simplified persistence - just store count
        UserDefaults.standard.set(availableExports.count, forKey: "ExportTemplatesCount")
    }
    
    private func loadTemplates() {
        // Templates will be initialized by default
        if availableExports.isEmpty {
            initializeDefaultTemplates()
        }
    }
    
    private func initializeDefaultTemplates() {
        availableExports = [
            ExportTemplate(
                name: "Standard Analysis Report",
                description: "Complete analysis results with recommendations",
                format: .json,
                dataTypes: [.codeAnalysis, .insights],
                customFields: [],
                isDefault: true,
                createdAt: Date()
            ),
            ExportTemplate(
                name: "Executive Summary",
                description: "High-level summary for stakeholders",
                format: .pdf,
                dataTypes: [.performanceMetrics, .usageAnalytics],
                customFields: [],
                isDefault: true,
                createdAt: Date()
            )
        ]
    }
    
    private func saveExportHistory() {
        // Simplified persistence - just store count
        UserDefaults.standard.set(exportHistory.count, forKey: "ExportHistoryCount")
    }
    
    private func loadExportHistory() {
        // History will be populated by actual exports
        exportHistory = []
    }
    
    func clearExportHistory() {
        exportHistory.removeAll()
        saveExportHistory()
    }
}

// MARK: - Team Collaboration System

@MainActor
class TeamCollaborationManager: ObservableObject {
    @Published var teamMembers: [TeamMember] = []
    @Published var collaborationProjects: [CollaborationProject] = []
    @Published var notifications: [CollaborationNotification] = []
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case error(String)
        
        var displayName: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting..."
            case .connected: return "Connected"
            case .error(let message): return "Error: \(message)"
            }
        }
        
        var color: Color {
            switch self {
            case .disconnected: return .gray
            case .connecting: return .yellow
            case .connected: return .green
            case .error: return .red
            }
        }
    }
    
    struct TeamMember: Identifiable {
        let id = UUID()
        let name: String
        let email: String
        let role: Role
        let permissions: [Permission]
        let avatar: String?
        let isOnline: Bool
        let lastSeen: Date
        let joinedAt: Date
        
        enum Role: String, Codable, CaseIterable {
            case admin = "Admin"
            case developer = "Developer"
            case reviewer = "Reviewer"
            case viewer = "Viewer"
            
            var permissions: [Permission] {
                switch self {
                case .admin:
                    return Permission.allCases
                case .developer:
                    return [.viewProjects, .createAnalysis, .exportData, .manageOwnProjects]
                case .reviewer:
                    return [.viewProjects, .createAnalysis, .viewReports]
                case .viewer:
                    return [.viewProjects, .viewReports]
                }
            }
            
            var color: Color {
                switch self {
                case .admin: return .red
                case .developer: return .blue
                case .reviewer: return .orange
                case .viewer: return .gray
                }
            }
        }
        
        enum Permission: String, Codable, CaseIterable {
            case viewProjects = "View Projects"
            case createAnalysis = "Create Analysis"
            case exportData = "Export Data"
            case manageProjects = "Manage Projects"
            case manageOwnProjects = "Manage Own Projects"
            case manageTeam = "Manage Team"
            case viewReports = "View Reports"
            case systemSettings = "System Settings"
        }
    }
    
    struct CollaborationProject: Identifiable {
        let id = UUID()
        var name: String
        var description: String
        let owner: String
        var members: [String] // Member IDs
        var sharedAnalyses: [SharedAnalysis]
        var discussions: [Discussion]
        let createdAt: Date
        var updatedAt: Date
        var isPublic: Bool
        var tags: [String]
        
        struct SharedAnalysis: Identifiable {
            let id = UUID()
            let title: String
            let description: String
            let authorId: String
            let results: String // JSON string of analysis results
            let createdAt: Date
            var comments: [Comment]
            var likes: Int
            var isPublic: Bool
            
            struct Comment: Identifiable {
                let id = UUID()
                let authorId: String
                let content: String
                let createdAt: Date
                var replies: [Comment]
                var likes: Int
            }
        }
        
        struct Discussion: Identifiable {
            let id = UUID()
            let title: String
            let content: String
            let authorId: String
            let createdAt: Date
            var replies: [DiscussionReply]
            var isResolved: Bool
            var tags: [String]
            
            struct DiscussionReply: Identifiable {
                let id = UUID()
                let authorId: String
                let content: String
                let createdAt: Date
                var likes: Int
            }
        }
    }
    
    struct CollaborationNotification: Identifiable {
        let id = UUID()
        let type: NotificationType
        let title: String
        let message: String
        let fromUserId: String?
        let projectId: UUID?
        let createdAt: Date
        var isRead: Bool
        var actionRequired: Bool
        
        enum NotificationType: String, Codable {
            case projectInvite = "Project Invite"
            case analysisShared = "Analysis Shared"
            case commentAdded = "Comment Added"
            case discussionStarted = "Discussion Started"
            case mentionReceived = "Mention Received"
            case projectUpdated = "Project Updated"
            case systemAlert = "System Alert"
            
            var icon: String {
                switch self {
                case .projectInvite: return "person.badge.plus"
                case .analysisShared: return "square.and.arrow.up"
                case .commentAdded: return "bubble.left"
                case .discussionStarted: return "message"
                case .mentionReceived: return "at.badge.plus"
                case .projectUpdated: return "folder.badge.gearshape"
                case .systemAlert: return "bell.badge"
                }
            }
            
            var color: Color {
                switch self {
                case .projectInvite: return .blue
                case .analysisShared: return .green
                case .commentAdded: return .orange
                case .discussionStarted: return .purple
                case .mentionReceived: return .pink
                case .projectUpdated: return .cyan
                case .systemAlert: return .red
                }
            }
        }
    }
    
    init() {
        loadTeamData()
        createMockData()
    }
    
    // MARK: - Connection Management
    
    func connect() async {
        connectionStatus = .connecting
        
        // Simulate connection process
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        if Bool.random() {
            connectionStatus = .connected
            isConnected = true
            await syncData()
        } else {
            connectionStatus = .error("Failed to connect to collaboration server")
            isConnected = false
        }
    }
    
    func disconnect() {
        connectionStatus = .disconnected
        isConnected = false
    }
    
    private func syncData() async {
        // Simulate data synchronization
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Update online status for team members
        for i in teamMembers.indices {
            teamMembers[i] = TeamMember(
                name: teamMembers[i].name,
                email: teamMembers[i].email,
                role: teamMembers[i].role,
                permissions: teamMembers[i].permissions,
                avatar: teamMembers[i].avatar,
                isOnline: Bool.random(),
                lastSeen: teamMembers[i].isOnline ? Date() : Date().addingTimeInterval(-Double.random(in: 0...86400)),
                joinedAt: teamMembers[i].joinedAt
            )
        }
    }
    
    // MARK: - Team Management
    
    func inviteTeamMember(email: String, role: TeamMember.Role) -> TeamMember {
        let member = TeamMember(
            name: email.components(separatedBy: "@").first ?? "User",
            email: email,
            role: role,
            permissions: role.permissions,
            avatar: nil,
            isOnline: false,
            lastSeen: Date(),
            joinedAt: Date()
        )
        
        teamMembers.append(member)
        
        // Create notification for invitation
        let notification = CollaborationNotification(
            type: .projectInvite,
            title: "Team Invitation Sent",
            message: "Invitation sent to \(email) as \(role.rawValue)",
            fromUserId: nil,
            projectId: nil,
            createdAt: Date(),
            isRead: false,
            actionRequired: false
        )
        
        notifications.insert(notification, at: 0)
        saveTeamData()
        
        return member
    }
    
    func removeTeamMember(id: UUID) {
        teamMembers.removeAll { $0.id == id }
        saveTeamData()
    }
    
    func updateMemberRole(id: UUID, newRole: TeamMember.Role) {
        if let index = teamMembers.firstIndex(where: { $0.id == id }) {
            let member = teamMembers[index]
            teamMembers[index] = TeamMember(
                name: member.name,
                email: member.email,
                role: newRole,
                permissions: newRole.permissions,
                avatar: member.avatar,
                isOnline: member.isOnline,
                lastSeen: member.lastSeen,
                joinedAt: member.joinedAt
            )
            saveTeamData()
        }
    }
    
    // MARK: - Project Management
    
    func createProject(
        name: String,
        description: String,
        isPublic: Bool = false,
        tags: [String] = []
    ) -> CollaborationProject {
        let project = CollaborationProject(
            name: name,
            description: description,
            owner: "current_user", // In real implementation, use actual user ID
            members: ["current_user"],
            sharedAnalyses: [],
            discussions: [],
            createdAt: Date(),
            updatedAt: Date(),
            isPublic: isPublic,
            tags: tags
        )
        
        collaborationProjects.append(project)
        saveTeamData()
        
        return project
    }
    
    func shareAnalysis(
        projectId: UUID,
        title: String,
        description: String,
        results: String
    ) {
        if let index = collaborationProjects.firstIndex(where: { $0.id == projectId }) {
            let analysis = CollaborationProject.SharedAnalysis(
                title: title,
                description: description,
                authorId: "current_user",
                results: results,
                createdAt: Date(),
                comments: [],
                likes: 0,
                isPublic: collaborationProjects[index].isPublic
            )
            
            collaborationProjects[index].sharedAnalyses.append(analysis)
            collaborationProjects[index].updatedAt = Date()
            
            // Create notification for team members
            let notification = CollaborationNotification(
                type: .analysisShared,
                title: "Analysis Shared",
                message: "New analysis '\(title)' shared in \(collaborationProjects[index].name)",
                fromUserId: "current_user",
                projectId: projectId,
                createdAt: Date(),
                isRead: false,
                actionRequired: false
            )
            
            notifications.insert(notification, at: 0)
            saveTeamData()
        }
    }
    
    func addComment(to analysisId: UUID, in projectId: UUID, content: String) {
        if let projectIndex = collaborationProjects.firstIndex(where: { $0.id == projectId }),
           let analysisIndex = collaborationProjects[projectIndex].sharedAnalyses.firstIndex(where: { $0.id == analysisId }) {
            
            let comment = CollaborationProject.SharedAnalysis.Comment(
                authorId: "current_user",
                content: content,
                createdAt: Date(),
                replies: [],
                likes: 0
            )
            
            collaborationProjects[projectIndex].sharedAnalyses[analysisIndex].comments.append(comment)
            collaborationProjects[projectIndex].updatedAt = Date()
            
            // Create notification
            let notification = CollaborationNotification(
                type: .commentAdded,
                title: "New Comment",
                message: "Comment added to analysis in \(collaborationProjects[projectIndex].name)",
                fromUserId: "current_user",
                projectId: projectId,
                createdAt: Date(),
                isRead: false,
                actionRequired: false
            )
            
            notifications.insert(notification, at: 0)
            saveTeamData()
        }
    }
    
    func startDiscussion(in projectId: UUID, title: String, content: String, tags: [String] = []) {
        if let index = collaborationProjects.firstIndex(where: { $0.id == projectId }) {
            let discussion = CollaborationProject.Discussion(
                title: title,
                content: content,
                authorId: "current_user",
                createdAt: Date(),
                replies: [],
                isResolved: false,
                tags: tags
            )
            
            collaborationProjects[index].discussions.append(discussion)
            collaborationProjects[index].updatedAt = Date()
            
            // Create notification
            let notification = CollaborationNotification(
                type: .discussionStarted,
                title: "Discussion Started",
                message: "New discussion '\(title)' in \(collaborationProjects[index].name)",
                fromUserId: "current_user",
                projectId: projectId,
                createdAt: Date(),
                isRead: false,
                actionRequired: false
            )
            
            notifications.insert(notification, at: 0)
            saveTeamData()
        }
    }
    
    // MARK: - Notification Management
    
    func markNotificationAsRead(id: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index] = CollaborationNotification(
                type: notifications[index].type,
                title: notifications[index].title,
                message: notifications[index].message,
                fromUserId: notifications[index].fromUserId,
                projectId: notifications[index].projectId,
                createdAt: notifications[index].createdAt,
                isRead: true,
                actionRequired: notifications[index].actionRequired
            )
            saveTeamData()
        }
    }
    
    func clearAllNotifications() {
        notifications.removeAll()
        saveTeamData()
    }
    
    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    // MARK: - Data Persistence
    
    private func saveTeamData() {
        // Simplified persistence - just store basic counts and statistics
        let basicData: [String: Any] = [
            "memberCount": teamMembers.count,
            "projectCount": collaborationProjects.count,
            "notificationCount": notifications.count,
            "lastSaved": Date().timeIntervalSince1970
        ]
        
        UserDefaults.standard.set(basicData, forKey: "teamCollaboration")
    }
    
    private func loadTeamData() {
        if UserDefaults.standard.dictionary(forKey: "teamCollaboration") != nil {
            // Initialize with sample data for demonstration
            initializeSampleData()
        } else {
            initializeSampleData()
        }
    }
    
    private func initializeSampleData() {
        if teamMembers.isEmpty {
            teamMembers = [
                TeamMember(
                    name: "Alice Johnson",
                    email: "alice@company.com",
                    role: .admin,
                    permissions: TeamMember.Role.admin.permissions,
                    avatar: nil,
                    isOnline: true,
                    lastSeen: Date(),
                    joinedAt: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
                ),
                TeamMember(
                    name: "Bob Smith",
                    email: "bob@company.com",
                    role: .developer,
                    permissions: TeamMember.Role.developer.permissions,
                    avatar: nil,
                    isOnline: false,
                    lastSeen: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                    joinedAt: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
                ),
                TeamMember(
                    name: "Carol Wilson",
                    email: "carol@company.com",
                    role: .reviewer,
                    permissions: TeamMember.Role.reviewer.permissions,
                    avatar: nil,
                    isOnline: true,
                    lastSeen: Date(),
                    joinedAt: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                )
            ]
        }
    }
    
    private func createMockData() {
        if teamMembers.isEmpty {
            teamMembers = [
                TeamMember(
                    name: "Alice Johnson",
                    email: "alice@company.com",
                    role: .admin,
                    permissions: TeamMember.Role.admin.permissions,
                    avatar: nil,
                    isOnline: true,
                    lastSeen: Date(),
                    joinedAt: Date().addingTimeInterval(-2592000)
                ),
                TeamMember(
                    name: "Bob Smith",
                    email: "bob@company.com",
                    role: .developer,
                    permissions: TeamMember.Role.developer.permissions,
                    avatar: nil,
                    isOnline: false,
                    lastSeen: Date().addingTimeInterval(-3600),
                    joinedAt: Date().addingTimeInterval(-1728000)
                ),
                TeamMember(
                    name: "Carol Williams",
                    email: "carol@company.com",
                    role: .reviewer,
                    permissions: TeamMember.Role.reviewer.permissions,
                    avatar: nil,
                    isOnline: true,
                    lastSeen: Date(),
                    joinedAt: Date().addingTimeInterval(-864000)
                )
            ]
        }
        
        if collaborationProjects.isEmpty {
            let project = CollaborationProject(
                name: "Mobile App Analysis",
                description: "Collaborative analysis of mobile application code quality",
                owner: "current_user",
                members: ["current_user"],
                sharedAnalyses: [],
                discussions: [],
                createdAt: Date(),
                updatedAt: Date(),
                isPublic: false,
                tags: ["mobile", "swift", "quality"]
            )
            collaborationProjects.append(project)
        }
        
        saveTeamData()
    }
}

// MARK: - Supporting Data Models

// Simplified data models for enterprise integration
