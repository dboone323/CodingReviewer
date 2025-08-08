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
        switch colorIdentifier {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "teal": return .teal
        case "indigo": return .indigo
        case "gray": return .gray
        default: return .primary
        }
    }
}

extension ProcessingJob.JobStatus {
    var color: Color {
        switch colorIdentifier {
        case "orange": return .orange
        case "blue": return .blue
        case "yellow": return .yellow
        case "green": return .green
        case "red": return .red
        case "gray": return .gray
        default: return .primary
        }
    }
}

extension ProcessingJob.JobPriority {
    var color: Color {
        switch colorIdentifier {
        case "gray": return .gray
        case "blue": return .blue
        case "orange": return .orange
        case "red": return .red
        default: return .primary
        }
    }
}

extension SystemLoad.LoadLevel {
    var color: Color {
        switch colorIdentifier {
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        default: return .primary
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
