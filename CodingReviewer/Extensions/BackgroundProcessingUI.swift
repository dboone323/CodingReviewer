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
        case .codeAnalysis: .blue
        case .documentation: .green
        case .testing: .red
        case .refactoring: .orange
        case .optimization: .purple
        }
    }
}

extension ProcessingJob.JobStatus {
    var color: Color {
        switch self {
        case .pending: .orange
        case .queued: .yellow
        case .running: .blue
        case .paused: .purple
        case .completed: .green
        case .failed: .red
        case .cancelled: .gray
        }
    }
}

extension SystemLoad.LoadLevel {
    var color: Color {
        switch self {
        case .low: .green
        case .medium: .yellow
        case .high: .orange
        case .critical: .red
        }
    }
}

// MARK: - UI Extensions for Code Types

extension Severity {
    var color: Color {
        switch colorIdentifier {
        case "blue": .blue
        case "orange": .orange
        case "red": .red
        case "purple": .purple
        default: .primary
        }
    }
}

extension QualityLevel {
    var color: Color {
        switch colorIdentifier {
        case "green": .green
        case "blue": .blue
        case "yellow": .yellow
        case "orange": .orange
        case "red": .red
        default: .primary
        }
    }
}

extension EffortLevel {
    var color: Color {
        switch colorIdentifier {
        case "green": .green
        case "blue": .blue
        case "yellow": .yellow
        case "orange": .orange
        case "red": .red
        default: .primary
        }
    }
}

extension ImpactLevel {
    var color: Color {
        switch colorIdentifier {
        case "gray": .gray
        case "blue": .blue
        case "yellow": .yellow
        case "orange": .orange
        case "red": .red
        default: .primary
        }
    }
}

extension ProcessingJob.JobPriority {
    var color: Color {
        switch colorIdentifier {
        case "gray": .gray
        case "blue": .blue
        case "orange": .orange
        case "red": .red
        default: .primary
        }
    }
}
