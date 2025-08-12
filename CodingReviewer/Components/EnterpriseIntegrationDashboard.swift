//
//  EnterpriseIntegrationDashboard.swift
//  CodingReviewer
//
//  Created by Phase 4 Enterprise Features on 8/5/25.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

// MARK: - Simple MetricCard Component
struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Enterprise Integration Dashboard

struct EnterpriseIntegrationDashboard: View {
    @StateObject private var dataExporter = EnterpriseDataExporter()
    @StateObject private var collaborationManager = TeamCollaborationManager()
    @StateObject private var usageTracker = UsageTracker()
    @State private var selectedTab: IntegrationTab = .export
    
    enum IntegrationTab: String, CaseIterable {
        case export = "Export"
        case collaboration = "Collaboration"
        case team = "Team"
        case notifications = "Notifications"
        
        var icon: String {
            switch self {
            case .export: return "square.and.arrow.up"
            case .collaboration: return "person.2"
            case .team: return "person.3"
            case .notifications: return "bell"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Integration Tab", selection: $selectedTab) {
                    ForEach(IntegrationTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    DataExportTab(dataExporter: dataExporter, usageTracker: usageTracker)
                        .tag(IntegrationTab.export)
                    
                    CollaborationTab(collaborationManager: collaborationManager)
                        .tag(IntegrationTab.collaboration)
                    
                    TeamManagementTab(collaborationManager: collaborationManager)
                        .tag(IntegrationTab.team)
                    
                    NotificationsTab(collaborationManager: collaborationManager)
                        .tag(IntegrationTab.notifications)
                }
                .tabViewStyle(.automatic)
            }
            .navigationTitle("Enterprise Integration")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Connect to Team") {
                            Task {
                                await collaborationManager.connect()
                            }
                        }
                        .disabled(collaborationManager.isConnected)
                        
                        Button("Disconnect") {
                            collaborationManager.disconnect()
                        }
                        .disabled(!collaborationManager.isConnected)
                        
                        Divider()
                        
                        Button("Export All Data") {
                            if let template = dataExporter.availableExports.first {
                                Task {
                                    try? await dataExporter.exportData(template: template)
                                }
                            }
                        }
                        
                        Button("Sync Team Data") {
                            // Sync functionality
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

// MARK: - Data Export Tab

struct DataExportTab: View {
    @ObservedObject var dataExporter: EnterpriseDataExporter
    @ObservedObject var usageTracker: UsageTracker
    @State private var showingTemplateCreator = false
    @State private var showingExportConfiguration = false
    @State private var selectedTemplate: EnterpriseDataExporter.ExportTemplate?
    @State private var exportConfiguration = EnterpriseDataExporter.ExportConfiguration()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Export Status
                if dataExporter.isExporting {
                    VStack(spacing: 12) {
                        Text("Exporting Data...")
                            .font(.headline)
                        
                        ProgressView(value: dataExporter.exportProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("\(Int(dataExporter.exportProgress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Quick Export Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Export")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(dataExporter.availableExports.filter { $0.isDefault }) { template in
                            QuickExportCard(
                                template: template,
                                onExport: {
                                    Task {
                                        usageTracker.trackActivity(
                                            action: .aiInsight,
                                            details: "Quick export: \(template.name)"
                                        )
                                        do {
                                            _ = try await dataExporter.exportData(template: template)
                                        } catch {
                                            AppLogger.shared.log("Export failed: \(error)", level: .error, category: .general)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Export Templates
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Export Templates")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Create Template") {
                            showingTemplateCreator = true
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(dataExporter.availableExports) { template in
                            ExportTemplateRow(
                                template: template,
                                onExport: {
                                    selectedTemplate = template
                                    showingExportConfiguration = true
                                },
                                onDelete: template.isDefault ? nil : {
                                    dataExporter.deleteTemplate(id: template.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Export History
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Exports")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Clear History") {
                            dataExporter.clearExportHistory()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    
                    if dataExporter.exportHistory.isEmpty {
                        Text("No export history")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(dataExporter.exportHistory.prefix(10))) { record in
                                ExportHistoryRow(record: record)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTemplateCreator) {
            ExportTemplateCreator(dataExporter: dataExporter)
        }
        .sheet(isPresented: $showingExportConfiguration) {
            if let template = selectedTemplate {
                ExportConfigurationView(
                    template: template,
                    configuration: $exportConfiguration,
                    onExport: { config in
                        Task {
                            usageTracker.trackActivity(
                                action: .aiInsight,
                                details: "Custom export: \(template.name)"
                            )
                            do {
                                _ = try await dataExporter.exportData(template: template, configuration: config)
                            } catch {
                                AppLogger.shared.log("Export failed: \(error)", level: .error, category: .general)
                            }
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Collaboration Tab

struct CollaborationTab: View {
    @ObservedObject var collaborationManager: TeamCollaborationManager
    @State private var showingProjectCreator = false
    @State private var showingAnalysisSharing = false
    @State private var selectedProject: TeamCollaborationManager.CollaborationProject?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Connection Status
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundColor(collaborationManager.connectionStatus.color)
                        .font(.caption)
                    
                    Text(collaborationManager.connectionStatus.displayName)
                        .font(.subheadline)
                        .foregroundColor(collaborationManager.connectionStatus.color)
                    
                    Spacer()
                    
                    if !collaborationManager.isConnected {
                        Button("Connect") {
                            Task {
                                await collaborationManager.connect()
                            }
                        }
                        .font(.caption)
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Quick Actions
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ActionCard(
                        title: "New Project",
                        icon: "folder.badge.plus",
                        color: .blue,
                        action: { showingProjectCreator = true }
                    )
                    
                    ActionCard(
                        title: "Share Analysis",
                        icon: "square.and.arrow.up",
                        color: .green,
                        action: { showingAnalysisSharing = true }
                    )
                }
                .padding(.horizontal)
                
                // Recent Projects
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Projects")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if collaborationManager.collaborationProjects.isEmpty {
                        Text("No projects yet")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(collaborationManager.collaborationProjects) { project in
                                ProjectRow(
                                    project: project,
                                    onSelect: { selectedProject = project }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(Array(collaborationManager.notifications.prefix(5))) { notification in
                            ActivityRow(notification: notification)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showingProjectCreator) {
            ProjectCreatorView(collaborationManager: collaborationManager)
        }
        .sheet(isPresented: $showingAnalysisSharing) {
            AnalysisSharingView(collaborationManager: collaborationManager)
        }
        .sheet(item: $selectedProject) { project in
            ProjectDetailView(project: project, collaborationManager: collaborationManager)
        }
    }
}

// MARK: - Team Management Tab

struct TeamManagementTab: View {
    @ObservedObject var collaborationManager: TeamCollaborationManager
    @State private var showingMemberInvite = false
    @State private var newMemberEmail = ""
    @State private var newMemberRole: TeamCollaborationManager.TeamMember.Role = .developer
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Team Overview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Team Overview")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Invite Member") {
                            showingMemberInvite = true
                        }
                        .font(.caption)
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        MetricCard(
                            title: "Total Members",
                            value: "\(collaborationManager.teamMembers.count)",
                            color: .blue
                        )
                        
                        MetricCard(
                            title: "Online Now",
                            value: "\(collaborationManager.teamMembers.filter { $0.isOnline }.count)",
                            color: .green
                        )
                    }
                }
                .padding(.horizontal)
                
                // Team Members
                VStack(alignment: .leading, spacing: 12) {
                    Text("Team Members")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(collaborationManager.teamMembers) { member in
                            TeamMemberRow(
                                member: member,
                                onRoleChange: { newRole in
                                    collaborationManager.updateMemberRole(id: member.id, newRole: newRole)
                                },
                                onRemove: {
                                    collaborationManager.removeTeamMember(id: member.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Role Distribution
                VStack(alignment: .leading, spacing: 12) {
                    Text("Role Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    let roleDistribution = Dictionary(grouping: collaborationManager.teamMembers, by: { $0.role })
                    
                    VStack(spacing: 8) {
                        ForEach(TeamCollaborationManager.TeamMember.Role.allCases, id: \.self) { role in
                            let count = roleDistribution[role]?.count ?? 0
                            
                            HStack {
                                Text(role.rawValue)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(count)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Rectangle()
                                    .fill(role.color)
                                    .frame(width: CGFloat(count * 20), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showingMemberInvite) {
            NavigationView {
                Form {
                    Section("Member Details") {
                        TextField("Email Address", text: $newMemberEmail)
                            .textContentType(.emailAddress)
                        
                        Picker("Role", selection: $newMemberRole) {
                            ForEach(TeamCollaborationManager.TeamMember.Role.allCases, id: \.self) { role in
                                Text(role.rawValue)
                                    .foregroundColor(role.color)
                                    .tag(role)
                            }
                        }
                    }
                    
                    Section("Permissions") {
                        ForEach(newMemberRole.permissions, id: \.self) { permission in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(permission.rawValue)
                            }
                        }
                    }
                }
                .navigationTitle("Invite Team Member")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingMemberInvite = false
                            newMemberEmail = ""
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button("Invite") {
                            _ = collaborationManager.inviteTeamMember(email: newMemberEmail, role: newMemberRole)
                            showingMemberInvite = false
                            newMemberEmail = ""
                        }
                        .disabled(newMemberEmail.isEmpty)
                    }
                }
            }
        }
    }
}

// MARK: - Notifications Tab

struct NotificationsTab: View {
    @ObservedObject var collaborationManager: TeamCollaborationManager
    @State private var selectedFilter: NotificationFilter = .all
    
    enum NotificationFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case actionRequired = "Action Required"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Controls
            HStack {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(NotificationFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
                
                Menu {
                    Button("Mark All as Read") {
                        for notification in collaborationManager.notifications where !notification.isRead {
                            collaborationManager.markNotificationAsRead(id: notification.id)
                        }
                    }
                    
                    Button("Clear All", role: .destructive) {
                        collaborationManager.clearAllNotifications()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .padding()
            
            // Notifications List
            if filteredNotifications().isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No Notifications")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("You're all caught up!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredNotifications()) { notification in
                        NotificationRow(
                            notification: notification,
                            onMarkAsRead: {
                                collaborationManager.markNotificationAsRead(id: notification.id)
                            }
                        )
                    }
                }
            }
        }
    }
    
    /// Performs operation with error handling and validation
    private func filteredNotifications() -> [TeamCollaborationManager.CollaborationNotification] {
        switch selectedFilter {
        case .all:
            return collaborationManager.notifications
        case .unread:
            return collaborationManager.notifications.filter { !$0.isRead }
        case .actionRequired:
            return collaborationManager.notifications.filter { $0.actionRequired }
        }
    }
}

// MARK: - Supporting Views

struct QuickExportCard: View {
    let template: EnterpriseDataExporter.ExportTemplate
    let onExport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: template.format.icon)
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Spacer()
                
                Text(template.format.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            Text(template.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text(template.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Button("Export") {
                onExport()
            }
            .font(.caption)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 6))
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ExportTemplateRow: View {
    let template: EnterpriseDataExporter.ExportTemplate
    let onExport: () -> Void
    let onDelete: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: template.format.icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(template.format.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Text("\(template.dataTypes.count) data types")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if template.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            Menu {
                Button("Export") {
                    onExport()
                }
                
                if let onDelete = onDelete {
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .padding(.vertical, 4)
    }
}

struct ExportHistoryRow: View {
    let record: EnterpriseDataExporter.ExportRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(record.success ? .green : .red)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.templateName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(record.format.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(record.formattedFileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(record.recordCount) records")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(record.exportedAt, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(record.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProjectRow: View {
    let project: TeamCollaborationManager.CollaborationProject
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: project.isPublic ? "globe" : "lock")
                    .foregroundColor(project.isPublic ? .green : .gray)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(project.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text("\(project.members.count) members")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(project.sharedAnalyses.count) analyses")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("Updated \(project.updatedAt, format: .relative(presentation: .named))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityRow: View {
    let notification: TeamCollaborationManager.CollaborationNotification
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type.icon)
                .foregroundColor(notification.type.color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(notification.createdAt, format: .relative(presentation: .numeric))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TeamMemberRow: View {
    let member: TeamCollaborationManager.TeamMember
    let onRoleChange: (TeamCollaborationManager.TeamMember.Role) -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(member.isOnline ? .green : .gray)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text(member.role.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(member.role.color.opacity(0.2))
                        .foregroundColor(member.role.color)
                        .cornerRadius(4)
                    
                    if member.isOnline {
                        Text("Online")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text("Last seen \(member.lastSeen, format: .relative(presentation: .named))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Menu {
                ForEach(TeamCollaborationManager.TeamMember.Role.allCases, id: \.self) { role in
                    Button(role.rawValue) {
                        onRoleChange(role)
                    }
                    .disabled(role == member.role)
                }
                
                Divider()
                
                Button("Remove", role: .destructive) {
                    onRemove()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .padding(.vertical, 4)
    }
}

struct NotificationRow: View {
    let notification: TeamCollaborationManager.CollaborationNotification
    let onMarkAsRead: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type.icon)
                .foregroundColor(notification.type.color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !notification.isRead {
                        Circle()
                            .fill(.blue)
                            .frame(width: 6, height: 6)
                    }
                    
                    Spacer()
                }
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                Text(notification.createdAt, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !notification.isRead {
                Button("Mark Read") {
                    onMarkAsRead()
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: 6))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Placeholder Views

struct ExportTemplateCreator: View {
    @ObservedObject var dataExporter: EnterpriseDataExporter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Export Template Creator")
                .navigationTitle("New Template")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Create") { dismiss() }
                    }
                }
        }
    }
}

struct ExportConfigurationView: View {
    let template: EnterpriseDataExporter.ExportTemplate
    @Binding var configuration: EnterpriseDataExporter.ExportConfiguration
    let onExport: (EnterpriseDataExporter.ExportConfiguration) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Export Configuration")
                .navigationTitle("Configure Export")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Export") {
                            onExport(configuration)
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct ProjectCreatorView: View {
    @ObservedObject var collaborationManager: TeamCollaborationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Project Creator")
                .navigationTitle("New Project")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Create") { dismiss() }
                    }
                }
        }
    }
}

struct AnalysisSharingView: View {
    @ObservedObject var collaborationManager: TeamCollaborationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Analysis Sharing")
                .navigationTitle("Share Analysis")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Share") { dismiss() }
                    }
                }
        }
    }
}

struct ProjectDetailView: View {
    let project: TeamCollaborationManager.CollaborationProject
    @ObservedObject var collaborationManager: TeamCollaborationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Project Details")
                Text(project.name)
                    .font(.headline)
                Text(project.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Project")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EnterpriseIntegrationDashboard()
}
