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
        case .openAI: "GPT models for code analysis"
        case .gemini: "Google's Gemini AI for code analysis"
        }
    }

    var keyPrefix: String {
        switch self {
        case .openAI: "sk-"
        case .gemini: "AI"
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
        case .quality: "checkmark.seal"
        case .security: "lock.shield"
        case .performance: "speedometer"
        case .documentation: "doc.text"
        case .refactoring: "arrow.triangle.2.circlepath"
        case .comprehensive: "brain.head.profile"
        }
    }

    var description: String {
        switch self {
        case .quality: "Analyze code quality and best practices"
        case .security: "Identify security vulnerabilities"
        case .performance: "Detect performance bottlenecks"
        case .documentation: "Generate and improve documentation"
        case .refactoring: "Suggest code improvements"
        case .comprehensive: "Complete analysis with all checks"
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
        case .codeQuality: "checkmark.seal"
        case .security: "lock.shield"
        case .performance: "speedometer"
        case .bestPractice: "star"
        case .refactoring: "arrow.triangle.2.circlepath"
        case .documentation: "doc.text"
        case .maintainability: "wrench.and.screwdriver"
        case .testing: "testtube.2"
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
        case .quality: "checkmark.seal"
        case .security: "lock.shield"
        case .suggestion: "lightbulb"
        case .performance: "speedometer"
        case .style: "paintbrush"
        case .logic: "brain"
        case .naming: "textformat"
        case .architecture: "building.2"
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
        case .ios: "iphone"
        case .macos: "desktopcomputer"
        case .watchos: "applewatch"
        case .tvos: "appletv"
        case .multiplatform: "rectangle.3.group"
        case .web: "globe"
        case .backend: "server.rack"
        case .library: "books.vertical"
        case .unknown: "questionmark.folder"
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
        case .pending: "clock"
        case .uploading: "arrow.up.circle"
        case .processing: "gear"
        case .completed: "checkmark.circle"
        case .failed: "xmark.circle"
        case .cancelled: "stop.circle"
        }
    }

    var color: String {
        switch self {
        case .pending: "gray"
        case .uploading: "blue"
        case .processing: "orange"
        case .completed: "green"
        case .failed: "red"
        case .cancelled: "gray"
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
        case .normal: "green"
        case .approaching: "orange"
        case .exceeded: "red"
        case .error: "purple"
        }
    }
}

enum RateLimitType: String, CaseIterable {
    case perMinute = "Per Minute"
    case perHour = "Per Hour"
    case perDay = "Per Day"
    case perMonth = "Per Month"
}
