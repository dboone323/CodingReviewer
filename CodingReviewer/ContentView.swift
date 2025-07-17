//
//  ContentView.swift
//  CodingReviewer
//
//  Created by Daniel Stevens on 7/16/25.
//

import SwiftUI

/// Accessibility helper for improved VoiceOver support
struct AccessibilityHelper {
    static func announceAnalysisComplete(_ result: String) {
        #if canImport(AppKit)
        let announcement = "Analysis completed. Found \(result.components(separatedBy: "\n").count) results."
        NSAccessibility.post(
            element: NSApp.mainWindow ?? NSApp,
            notification: .announcementRequested,
            userInfo: [.announcement: announcement]
        )
        #endif
    }
    
    static func announceAnalysisStarted() {
        #if canImport(AppKit)
        let announcement = "Starting code analysis..."
        NSAccessibility.post(
            element: NSApp.mainWindow ?? NSApp,
            notification: .announcementRequested,
            userInfo: [.announcement: announcement]
        )
        #endif
    }
}

struct ContentView: View {
    @StateObject private var viewModel = CodeReviewViewModel()
    @State private var codeInput: String = ""
    @State private var showingClearAlert = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                headerSection
                
                // Main Content
                mainContent
                
                // Status Bar
                statusBar
            }
            .navigationTitle("CodeReviewer")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("About") {
                        showingAbout = true
                    }
                    .accessibilityLabel("About CodeReviewer")
                }
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .onAppear {
            setupSampleCode()
        }
        .alert("Clear Code", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAll()
            }
        } message: {
            Text("Are you sure you want to clear the code input and results?")
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title)
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("CodeReviewer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Analyze Swift code for quality, security, and performance issues")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Divider()
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        HSplitView {
            // Input Section
            inputSection
            
            // Results Section
            resultsSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Input Header
            HStack {
                Label("Swift Code Input", systemImage: "curlybraces")
                    .font(.headline)
                    .accessibilityLabel("Code input section")
                
                Spacer()
                
                Text("\(codeInput.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Character count: \(codeInput.count)")
            }
            
            // Text Editor
            ZStack(alignment: .topLeading) {
                TextEditor(text: $codeInput)
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.errorMessage != nil ? .red : .gray.opacity(0.3), lineWidth: 1)
                    )
                    .accessibilityLabel("Code input text editor")
                    .accessibilityHint("Enter Swift code here for analysis")
                
                if codeInput.isEmpty {
                    Text("Paste your Swift code here...")
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .monospaced))
                        .padding(20)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxHeight: .infinity)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Clear") {
                    showingClearAlert = true
                }
                .buttonStyle(.bordered)
                .disabled(codeInput.isEmpty)
                .accessibilityLabel("Clear code input")
                .accessibilityHint("Clears the code input and analysis results")
                
                Button("Sample Code") {
                    setupSampleCode()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Load sample code")
                .accessibilityHint("Loads sample Swift code for demonstration")
                
                Spacer()
                
                Button {
                    AccessibilityHelper.announceAnalysisStarted()
                    viewModel.analyze(codeInput)
                } label: {
                    HStack {
                        if viewModel.isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Analyzing...")
                        } else {
                            Image(systemName: "play.circle.fill")
                            Text("Analyze Code")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isAnalyzing)
                .accessibilityLabel(viewModel.isAnalyzing ? "Analyzing code" : "Analyze code")
                .accessibilityHint("Starts code analysis for quality, security, and performance issues")
            }
            
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal, 4)
                    .accessibilityLabel("Error: \(errorMessage)")
            }
        }
        .padding(24)
        .frame(minWidth: 400)
    }
    
    @ViewBuilder
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Results Header
            HStack {
                Label("Analysis Results", systemImage: "doc.text.below.ecg")
                    .font(.headline)
                    .accessibilityLabel("Analysis results section")
                
                Spacer()
                
                if !viewModel.analysisResult.isEmpty {
                    Button("Copy Results") {
                        copyResults()
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Copy analysis results")
                    .accessibilityHint("Copies the analysis results to clipboard")
                    
                    Button("Clear Results") {
                        viewModel.clearResults()
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Clear analysis results")
                }
            }
            
            // Results Content
            ScrollView {
                if viewModel.analysisResult.isEmpty {
                    emptyResultsView
                } else {
                    resultsContentView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(24)
        .frame(minWidth: 400)
    }
    
    @ViewBuilder
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                Text("No analysis results yet")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Enter Swift code and click 'Analyze Code' to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .accessibilityLabel("No analysis results available")
        .accessibilityHint("Enter code and click analyze to see results")
    }
    
    @ViewBuilder
    private var resultsContentView: some View {
        HStack {
            Text(viewModel.analysisResult)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(16)
                .accessibilityLabel("Analysis results")
                .accessibilityValue(viewModel.analysisResult)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var statusBar: some View {
        HStack {
            if viewModel.isAnalyzing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Analyzing code...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Analysis in progress")
            } else {
                Text("Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Ready for analysis")
            }
            
            Spacer()
            
            Text("CodeReviewer v1.0")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
        .overlay(
            Divider(), alignment: .top
        )
    }
    
    // MARK: - Helper Methods
    
    private func setupSampleCode() {
        codeInput = """
        import Foundation
        
        class UserManager {
            var users: [String] = []
            
            func addUser(_ name: String) {
                users.append(name)
            }
            
            func getUser(at index: Int) -> String {
                return users[index]  // Potential crash - no bounds checking
            }
            
            func authenticateUser(password: String) -> Bool {
                let hardcodedPassword = "password123"  // Security issue
                return password == hardcodedPassword
            }
        }
        
        // TODO: Add proper error handling
        let manager = UserManager()
        manager.addUser("John")
        let user = manager.getUser(at: 0)  // Force unwrapping equivalent
        """
    }
    
    private func clearAll() {
        codeInput = ""
        viewModel.clearResults()
    }
    
    private func copyResults() {
        #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(viewModel.analysisResult, forType: .string)
        #endif
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("CodeReviewer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Features:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Code quality analysis", systemImage: "checkmark.circle")
                        Label("Security vulnerability detection", systemImage: "lock.shield")
                        Label("Performance optimization suggestions", systemImage: "speedometer")
                        Label("Swift best practices validation", systemImage: "swift")
                    }
                    .font(.subheadline)
                }
                
                Spacer()
                
                Text("Built with SwiftUI for macOS")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(40)
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 700)
}
