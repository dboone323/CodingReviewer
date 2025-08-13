//
//  BackgroundProcessingUI.swift
//  CodingReviewer
//
//  Created by Background Processing System on 8/7/25.
//  UI extensions for background processing types - separated for clean architecture
//

import SwiftUI

// MARK: - UI Extensions for Background Processing Types

extension ProcessingJob.JobType {
    var color: Color {
        switch self {
        case .codeAnalysis: return .blue
        case .documentation: return .green
        case .testing: return .red
        case .refactoring: return .orange
        case .optimization: return .purple
        }
    }
}

extension ProcessingJob.JobStatus {
    var color: Color {
        switch self {
        case .pending: return .orange
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}

extension ProcessingJob.JobPriority {
    var color: Color {
        switch self {
        case .low: return .gray
        case .normal: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

extension SystemLoad.LoadLevel {
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - UI Extensions for Code Types

extension Severity {
    var color: Color {
        switch colorIdentifier {
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        default: return .primary
        }
    }
}

extension QualityLevel {
    var color: Color {
        switch colorIdentifier {
        case "green": return .green
        case "blue": return .blue
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        default: return .primary
        }
    }
}

extension EffortLevel {
    var color: Color {
        switch colorIdentifier {
        case "green": return .green
        case "blue": return .blue
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        default: return .primary
        }
    }
}

extension ImpactLevel {
    var color: Color {
        switch colorIdentifier {
        case "gray": return .gray
        case "blue": return .blue
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        default: return .primary
        }
    }
}
