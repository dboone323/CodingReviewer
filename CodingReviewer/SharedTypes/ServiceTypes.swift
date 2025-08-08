//
// ServiceTypes.swift
// CodingReviewer
//
// SharedTypes Module - Service and AI-related types
// Created on July 27, 2025
//

import Foundation

// MARK: - AI Service Types

enum AIProvider: String, CaseIterable {
    case openAI = "OpenAI"
    case gemini = "Google Gemini"

    var displayName: String {
        rawValue
    }

    var description: String {
        switch self {
        case .openAI: return "GPT models for code analysis"
        case .gemini: return "Google's Gemini AI for code analysis"
        }
    }

    var keyPrefix: String {
        switch self {
        case .openAI: return "sk-"
        case .gemini: return "AI"
        }
    }
}

enum AnalysisType: String, CaseIterable {
    case quality = "Quality"
    case security = "Security"
    case performance = "Performance"
    case documentation = "Documentation"
    case refactoring = "Refactoring"
    case comprehensive = "Comprehensive"

    var systemImage: String {
        switch self {
        case .quality: return "checkmark.seal"
        case .security: return "lock.shield"
        case .performance: return "speedometer"
        case .documentation: return "doc.text"
        case .refactoring: return "arrow.triangle.2.circlepath"
        case .comprehensive: return "brain.head.profile"
        }
    }

    var description: String {
        switch self {
        case .quality: return "Analyze code quality and best practices"
        case .security: return "Identify security vulnerabilities"
        case .performance: return "Detect performance bottlenecks"
        case .documentation: return "Generate and improve documentation"
        case .refactoring: return "Suggest code improvements"
        case .comprehensive: return "Complete analysis with all checks"
        }
    }
}

enum SuggestionType: String, CaseIterable {
    case codeQuality = "Code Quality"
    case security = "Security"
    case performance = "Performance"
    case bestPractice = "Best Practice"
    case refactoring = "Refactoring"
    case documentation = "Documentation"
    case maintainability = "Maintainability"
    case testing = "Testing"

    var systemImage: String {
        switch self {
        case .codeQuality: return "checkmark.seal"
        case .security: return "lock.shield"
        case .performance: return "speedometer"
        case .bestPractice: return "star"
        case .refactoring: return "arrow.triangle.2.circlepath"
        case .documentation: return "doc.text"
        case .maintainability: return "wrench.and.screwdriver"
        case .testing: return "testtube.2"
        }
    }
}

// MARK: - Analysis Result Types

enum AnalysisResultType: String, CaseIterable {
    case quality = "Quality"
    case security = "Security"
    case suggestion = "Suggestion"
    case performance = "Performance"
    case style = "Style"
    case logic = "Logic"
    case naming = "Naming"
    case architecture = "Architecture"

    var displayName: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .quality: return "checkmark.seal"
        case .security: return "lock.shield"
        case .suggestion: return "lightbulb"
        case .performance: return "speedometer"
        case .style: return "paintbrush"
        case .logic: return "brain"
        case .naming: return "textformat"
        case .architecture: return "building.2"
        }
    }
}

// MARK: - File and Project Types

enum ProjectType: String, CaseIterable {
    case ios = "iOS"
    case macos = "macOS"
    case watchos = "watchOS"
    case tvos = "tvOS"
    case multiplatform = "Multiplatform"
    case web = "Web"
    case backend = "Backend"
    case library = "Library"
    case unknown = "Unknown"

    var displayName: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .ios: return "iphone"
        case .macos: return "desktopcomputer"
        case .watchos: return "applewatch"
        case .tvos: return "appletv"
        case .multiplatform: return "rectangle.3.group"
        case .web: return "globe"
        case .backend: return "server.rack"
        case .library: return "books.vertical"
        case .unknown: return "questionmark.folder"
        }
    }
}

enum FileUploadStatus: String, CaseIterable {
    case pending = "Pending"
    case uploading = "Uploading"
    case processing = "Processing"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"

    var systemImage: String {
        switch self {
        case .pending: return "clock"
        case .uploading: return "arrow.up.circle"
        case .processing: return "gear"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        case .cancelled: return "stop.circle"
        }
    }

    var color: String {
        switch self {
        case .pending: return "gray"
        case .uploading: return "blue"
        case .processing: return "orange"
        case .completed: return "green"
        case .failed: return "red"
        case .cancelled: return "gray"
        }
    }
}

// MARK: - API and Rate Limiting Types

enum APIUsageStatus: String, CaseIterable {
    case normal = "Normal"
    case approaching = "Approaching Limit"
    case exceeded = "Limit Exceeded"
    case error = "Error"

    var color: String {
        switch self {
        case .normal: return "green"
        case .approaching: return "orange"
        case .exceeded: return "red"
        case .error: return "purple"
        }
    }
}

enum RateLimitType: String, CaseIterable {
    case perMinute = "Per Minute"
    case perHour = "Per Hour"
    case perDay = "Per Day"
    case perMonth = "Per Month"
}
