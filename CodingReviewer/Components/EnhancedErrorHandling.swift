import Foundation
//
//  EnhancedErrorHandling.swift
//  CodingReviewer
//
//  Created by Phase 3 Production Enhancement on 8/5/25.
//

import SwiftUI

// MARK: - Enhanced Error Types

enum EnhancedError: Error, Identifiable, Sendable {
    case networkTimeout
    case invalidCode
    case analysisFailure(String)
    case fileReadError
    case apiKeyMissing
    case rateLimitExceeded
    case unknown(String)
    
    var id: String { localizedDescription }
    
    var localizedDescription: String {
        switch self {
        case .networkTimeout:
            return "Network timeout occurred"
        case .invalidCode:
            return "Invalid code format"
        case .analysisFailure(let reason):
            return "Analysis failed: \(reason)"
        case .fileReadError:
            return "Unable to read file"
        case .apiKeyMissing:
            return "Please configure your API key in settings"
        case .rateLimitExceeded:
            return "Too many requests have been made. Please wait before trying again"
        case .unknown(let message):
            return message
        }
    }
    
    var failureReason: String {
        switch self {
        case .networkTimeout:
            return "The request took too long to complete"
        case .invalidCode:
            return "The provided code contains syntax errors or is not in a supported format"
        case .analysisFailure(let reason):
            return reason
        case .fileReadError:
            return "The file may be corrupted, too large, or in an unsupported format"
        case .apiKeyMissing:
            return "No API key has been configured for the AI analysis service"
        case .rateLimitExceeded:
            return "Too many requests have been made in a short time period"
        case .unknown(let message):
            return message
        }
    }
    
    var recoverySuggestion: String {
        switch self {
        case .networkTimeout:
            return "Check your internet connection and try again. If the problem persists, the service may be temporarily unavailable."
        case .invalidCode:
            return "Please check your code for syntax errors and ensure it's in a supported programming language."
        case .analysisFailure:
            return "Try simplifying your code or breaking it into smaller chunks for analysis."
        case .fileReadError:
            return "Try using a different file, or copy and paste the code directly into the text editor."
        case .apiKeyMissing:
            return "Go to Settings and configure your OpenAI or Google AI API key to enable analysis features."
        case .rateLimitExceeded:
            return "Please wait a few minutes before trying again, or consider upgrading your API plan for higher limits."
        case .unknown:
            return "Please try again. If the problem persists, contact support."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .networkTimeout, .rateLimitExceeded:
            return .warning
        case .invalidCode, .fileReadError:
            return .info
        case .analysisFailure, .unknown:
            return .error
        case .apiKeyMissing:
            return .critical
        }
    }
    
    var actionable: Bool {
        switch self {
        case .apiKeyMissing, .invalidCode, .fileReadError:
            return true
        case .networkTimeout, .rateLimitExceeded:
            return true
        case .analysisFailure, .unknown:
            return false
        }
    }
}

// MARK: - Error Severity

enum ErrorSeverity {
    case info
    case warning
    case error
    case critical
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Enhanced Error View

struct EnhancedErrorView: View {
    let error: EnhancedError
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Error header
            HStack(spacing: 12) {
                Image(systemName: error.severity.icon)
                    .font(.title2)
                    .foregroundColor(error.severity.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(error.localizedDescription)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !error.failureReason.isEmpty {
                        Text(error.failureReason)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                
                if onDismiss != nil {
                    Button(action: { onDismiss?() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Recovery suggestion
            if !error.recoverySuggestion.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What can you do?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(error.recoverySuggestion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 34) // Align with text above
            }
            
            // Action buttons
            HStack(spacing: 12) {
                if error.actionable {
                    actionButton
                }
                
                if onRetry != nil {
                    Button(action: { onRetry?() }) {
                        Label("Try Again", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Text(isExpanded ? "Less Info" : "More Info")
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.leading, 34)
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Error Details")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("Type: \(String(describing: error).components(separatedBy: "(").first ?? "Unknown")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Severity: \(String(describing: error.severity).capitalized)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Actionable: \(error.actionable ? "Yes" : "No")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 34)
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(error.severity.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var actionButton: some View {
        switch error {
        case .apiKeyMissing:
            Button(action: openSettings) {
                Label("Open Settings", systemImage: "gear")
            }
            .buttonStyle(.bordered)
            
        case .fileReadError:
            Button(action: selectDifferentFile) {
                Label("Choose File", systemImage: "doc")
            }
            .buttonStyle(.bordered)
            
        case .networkTimeout:
            Button(action: checkConnection) {
                Label("Check Connection", systemImage: "wifi")
            }
            .buttonStyle(.bordered)
            
        default:
            EmptyView()
        }
    }
    
    private func openSettings() {
        // This would typically trigger navigation to settings
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func selectDifferentFile() {
        // This would typically trigger file picker
        AppLogger.shared.debug("File picker would be opened")
    }
    
    private func checkConnection() {
        // This would typically run network diagnostics
        AppLogger.shared.debug("Network connection check initiated")
    }
}

// MARK: - Error Toast Notification

struct ErrorToast: View {
    let error: EnhancedError
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.severity.icon)
                .foregroundColor(error.severity.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if !error.failureReason.isEmpty {
                    Text(error.failureReason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let error: EnhancedError
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error.severity.icon)
                .font(.system(size: 48))
                .foregroundColor(error.severity.color)
            
            VStack(spacing: 8) {
                Text(error.localizedDescription)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                if !error.failureReason.isEmpty {
                    Text(error.failureReason)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                if !error.recoverySuggestion.isEmpty {
                    Text(error.recoverySuggestion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(maxWidth: 400)
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let error: EnhancedError
    @Binding var isPresented: Bool
    let action: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.severity.icon)
                .foregroundColor(error.severity.color)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            if let action = action {
                Button("Fix", action: action)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(error.severity.color.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(error.severity.color.opacity(0.3)),
            alignment: .bottom
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        EnhancedErrorView(
            error: .apiKeyMissing,
            onRetry: { print("Retry") },
            onDismiss: { print("Dismiss") }
        )
        
        ErrorToast(
            error: .networkTimeout,
            isPresented: .constant(true)
        )
        
        ErrorStateView(
            error: .analysisFailure("Complex code structure detected"),
            onRetry: { print("Retry") }
        )
    }
    .padding()
}
