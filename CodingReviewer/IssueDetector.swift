import Foundation
import SwiftUI
import Combine

class IssueDetector: ObservableObject {
    @Published var detectedIssues: [DetectedIssue] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var autoFixes: [AutoFix] = []
    
    // Shared instance
    static let shared = IssueDetector()
    
    func scanFiles(_ files: [CodeFile]) async {
        await MainActor.run {
            isScanning = true
            scanProgress = 0.0
            detectedIssues.removeAll()
        }
        
        let totalFiles = files.count
        for (index, file) in files.enumerated() {
            let issues = await scanFile(file)
            await MainActor.run {
                detectedIssues.append(contentsOf: issues)
                scanProgress = Double(index + 1) / Double(totalFiles)
            }
        }
        
        await MainActor.run {
            isScanning = false
            // Generate auto-fixes for detected issues
            autoFixes = generateAutoFixes(for: detectedIssues)
        }
    }
    
    private func scanFile(_ file: CodeFile) async -> [DetectedIssue] {
        let lines = file.content.components(separatedBy: .newlines)
        var issues: [DetectedIssue] = []
        
        for (lineNumber, line) in lines.enumerated() {
            let lineIndex = lineNumber + 1 // 1-based line numbers
            
            // Detect various types of issues
            issues.append(contentsOf: detectSecurityIssues(line: line, lineNumber: lineIndex, file: file))
            issues.append(contentsOf: detectPerformanceIssues(line: line, lineNumber: lineIndex, file: file))
            issues.append(contentsOf: detectQualityIssues(line: line, lineNumber: lineIndex, file: file))
        }
        
        return issues
    }
    
    private func detectSecurityIssues(line: String, lineNumber: Int, file: CodeFile) -> [DetectedIssue] {
        var issues: [DetectedIssue] = []
        
        // SQL Injection patterns
        if line.localizedCaseInsensitiveContains("SELECT * FROM") && !line.contains("prepared") {
            issues.append(DetectedIssue(
                id: UUID(),
                type: .security,
                severity: .high,
                title: "Potential SQL Injection",
                description: "Direct SQL query without prepared statements",
                line: lineNumber,
                column: 0,
                file: file.name,
                suggestion: "Use prepared statements or parameterized queries"
            ))
        }
        
        // Hardcoded credentials
        if line.contains("password =") || line.contains("api_key =") {
            issues.append(DetectedIssue(
                id: UUID(),
                type: .security,
                severity: .critical,
                title: "Hardcoded Credentials",
                description: "Credentials should not be hardcoded",
                line: lineNumber,
                column: 0,
                file: file.name,
                suggestion: "Use environment variables or secure storage"
            ))
        }
        
        // Insecure HTTP
        if line.contains("https://") && !line.contains("localhost") {
            issues.append(DetectedIssue(
                id: UUID(),
                type: .security,
                severity: .medium,
                title: "Insecure HTTP",
                description: "Use HTTPS for secure communication",
                line: lineNumber,
                column: 0,
                file: file.name,
                suggestion: "Replace https:// with https://"
            ))
        }
        
        return issues
    }
    
    private func detectPerformanceIssues(line: String, lineNumber: Int, file: CodeFile) -> [DetectedIssue] {
        var issues: [DetectedIssue] = []
        
        // N+1 query pattern
        if line.contains("for") && line.contains(".query(") {
            issues.append(DetectedIssue(
                id: UUID(),
                type: .performance,
                severity: .medium,
                title: "Potential N+1 Query",
                description: "Database query inside loop may cause performance issues",
                line: lineNumber,
                column: 0,
                file: file.name,
                suggestion: "Consider using batch queries or eager loading"
            ))
        }
        
        // Large file operations
        if line.contains("readFile") || line.contains("writeFile") {
            if line.contains("sync") {
                issues.append(DetectedIssue(
                    id: UUID(),
                    type: .performance,
                    severity: .medium,
                    title: "Synchronous File Operation",
                    description: "Synchronous file operations can block the main thread",
                    line: lineNumber,
                    column: 0,
                    file: file.name,
                    suggestion: "Use asynchronous file operations"
                ))
            }
        }
        
        return issues
    }
    
    private func detectQualityIssues(line: String, lineNumber: Int, file: CodeFile) -> [DetectedIssue] {
        var issues: [DetectedIssue] = []
        
        // Long lines
        if line.count > 120 {
            issues.append(DetectedIssue(
                id: UUID(),
                type: .codeQuality,
                severity: .low,
                title: "Long Line",
                description: "Line exceeds recommended length of 120 characters",
                line: lineNumber,
                column: 0,
                file: file.name,
                suggestion: "Break long lines into multiple lines"
            ))
        }
        
        // TODO comments
        if line.localizedCaseInsensitiveContains("TODO") {
            issues.append(DetectedIssue(
                id: UUID(),
                type: .codeQuality,
                severity: .info,
                title: "TODO Comment",
                description: "Unresolved TODO comment",
                line: lineNumber,
                column: 0,
                file: file.name,
                suggestion: "Address TODO or create a proper issue"
            ))
        }
        
        return issues
    }
    
    func generateAutoFixes(for issues: [DetectedIssue]) -> [AutoFix] {
        return issues.compactMap { issue in
            switch issue.type {
            case .security:
                return generateSecurityFix(for: issue)
            case .performance:
                return generatePerformanceFix(for: issue)
            case .codeQuality:
                return generateQualityFix(for: issue)
            default:
                return nil
            }
        }
    }
    
    private func generateSecurityFix(for issue: DetectedIssue) -> AutoFix? {
        switch issue.title {
        case "Insecure HTTP":
            return AutoFix(
                id: UUID(),
                issueId: issue.id,
                title: "Replace HTTP with HTTPS",
                description: "Automatically replace https:// with https://",
                confidence: 0.9
            )
        default:
            return nil
        }
    }
    
    private func generatePerformanceFix(for issue: DetectedIssue) -> AutoFix? {
        // Implementation for performance fixes
        return nil
    }
    
    private func generateQualityFix(for issue: DetectedIssue) -> AutoFix? {
        // Implementation for quality fixes
        return nil
    }
}

// MARK: - Data Models

struct DetectedIssue: Identifiable, Codable {
    let id: UUID
    let type: IssueType
    let severity: IssueSeverity
    let title: String
    let description: String
    let line: Int
    let column: Int
    let file: String
    let suggestion: String
    
    enum IssueType: String, Codable, CaseIterable {
        case security = "Security"
        case performance = "Performance"  
        case codeQuality = "Code Quality"
        case syntax = "Syntax"
        case style = "Style"
        case documentation = "Documentation"
    }
    
    enum IssueSeverity: String, Codable, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case info = "Info"
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .medium: return .yellow
            case .low: return .blue
            case .info: return .gray
            }
        }
    }
}

struct AutoFix: Identifiable, Codable {
    let id: UUID
    let issueId: UUID
    let title: String
    let description: String
    let confidence: Double // 0.0 to 1.0
}

// MARK: - Views

struct SmartEnhancementView: View {
    @StateObject private var issueDetector = IssueDetector.shared
    @EnvironmentObject private var fileManager: FileManagerService
    @State private var selectedType: DetectedIssue.IssueType?
    
    var filteredIssues: [DetectedIssue] {
        if let selectedType = selectedType {
            return issueDetector.detectedIssues.filter { $0.type == selectedType }
        }
        return issueDetector.detectedIssues
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if issueDetector.isScanning {
                    VStack {
                        ProgressView(value: issueDetector.scanProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        Text("Scanning files... \(Int(issueDetector.scanProgress * 100))%")
                            .font(.caption)
                            .padding(.top, 4)
                    }
                    .padding()
                }
                
                // Issue type filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button("All") {
                            selectedType = nil
                        }
                        .buttonStyle(.bordered)
                        .background(selectedType == nil ? Color.accentColor : Color.clear)
                        
                        ForEach(DetectedIssue.IssueType.allCases, id: \.self) { type in
                            Button(type.rawValue) {
                                selectedType = type
                            }
                            .buttonStyle(.bordered)
                            .background(selectedType == type ? Color.accentColor : Color.clear)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Issues list
                List {
                    ForEach(filteredIssues) { issue in
                        IssueRowView(issue: issue)
                    }
                }
                .listStyle(PlainListStyle())
                
                // Action buttons
                HStack {
                    Button("Scan Files") {
                        Task {
                            await issueDetector.scanFiles(fileManager.uploadedFiles)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(issueDetector.isScanning || fileManager.uploadedFiles.isEmpty)
                    
                    Spacer()
                    
                    if !issueDetector.autoFixes.isEmpty {
                        Button("Apply Auto-Fixes") {
                            // Implementation for applying fixes
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("Smart Enhancement")
        }
    }
}

struct IssueRowView: View {
    let issue: DetectedIssue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Severity indicator
                Circle()
                    .fill(issue.severity.color)
                    .frame(width: 8, height: 8)
                
                Text(issue.title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(issue.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(issue.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(issue.file):\(issue.line)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !issue.suggestion.isEmpty {
                    Text("💡 \(issue.suggestion)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ScanControlsView: View {
    @StateObject private var issueDetector = IssueDetector.shared
    @EnvironmentObject private var fileManager: FileManagerService
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Scan Controls")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Analyze uploaded files for security vulnerabilities, performance issues, and code quality problems.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                Task {
                    await issueDetector.scanFiles(fileManager.uploadedFiles)
                }
            }) {
                HStack {
                    Image(systemName: "magnifyingglass.circle.fill")
                    Text("Start Smart Analysis")
                }
                .font(.headline)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(issueDetector.isScanning || fileManager.uploadedFiles.isEmpty)
            
            if issueDetector.isScanning {
                ProgressView(value: issueDetector.scanProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                Text("Scanning... \(Int(issueDetector.scanProgress * 100))%")
                    .font(.caption)
            }
        }
        .padding()
    }
}
