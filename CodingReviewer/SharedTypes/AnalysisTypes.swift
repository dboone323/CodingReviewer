//
// AnalysisTypes.swift
// CodingReviewer
//
// SharedTypes Module - Analysis and result-specific types
// Created on July 27, 2025
//

import Foundation

// MARK: - Analysis Engine Types

enum AnalysisEngine: String, CaseIterable {
    case ai = "AI"
    case pattern = "Pattern"
    case combined = "Combined"

    var displayName: String {
        rawValue
    }

    var description: String {
        switch self {
        case .ai: "AI-powered analysis using language models"
        case .pattern: "Pattern-based static analysis"
        case .combined: "Combined AI and pattern analysis"
        }
    }
}

enum AnalysisScope: String, CaseIterable {
    case file = "File"
    case project = "Project"
    case folder = "Folder"
    case selection = "Selection"

    var systemImage: String {
        switch self {
        case .file: "doc"
        case .project: "folder"
        case .folder: "folder.badge.plus"
        case .selection: "selection.pin.in.out"
        }
    }
}

enum AnalysisMode: String, CaseIterable {
    case quick = "Quick"
    case standard = "Standard"
    case detailed = "Detailed"
    case comprehensive = "Comprehensive"

    var description: String {
        switch self {
        case .quick: "Fast analysis with basic checks"
        case .standard: "Standard analysis with common patterns"
        case .detailed: "Detailed analysis with comprehensive checks"
        case .comprehensive: "Complete analysis with all features"
        }
    }

    var estimatedTime: String {
        switch self {
        case .quick: "< 30 seconds"
        case .standard: "1-2 minutes"
        case .detailed: "3-5 minutes"
        case .comprehensive: "5-10 minutes"
        }
    }
}

// MARK: - Pattern Analysis Types

enum PatternType: String, CaseIterable {
    case antiPattern = "Anti-Pattern"
    case designPattern = "Design Pattern"
    case codeSmell = "Code Smell"
    case bestPractice = "Best Practice"
    case architecture = "Architecture"
    case performance = "Performance"
    case security = "Security"
    case maintainability = "Maintainability"

    var systemImage: String {
        switch self {
        case .antiPattern: "exclamationmark.triangle"
        case .designPattern: "building.columns"
        case .codeSmell: "nose"
        case .bestPractice: "star"
        case .architecture: "building.2"
        case .performance: "speedometer"
        case .security: "lock.shield"
        case .maintainability: "wrench.and.screwdriver"
        }
    }
}

enum PatternConfidence: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case certain = "Certain"

    var color: String {
        switch self {
        case .low: "red"
        case .medium: "orange"
        case .high: "green"
        case .certain: "blue"
        }
    }

    var percentage: Int {
        switch self {
        case .low: 25
        case .medium: 50
        case .high: 75
        case .certain: 95
        }
    }
}

// MARK: - Quality Metrics Types

enum QualityMetric: String, CaseIterable {
    case complexity = "Complexity"
    case maintainability = "Maintainability"
    case readability = "Readability"
    case testability = "Testability"
    case performance = "Performance"
    case security = "Security"
    case documentation = "Documentation"
    case consistency = "Consistency"

    var systemImage: String {
        switch self {
        case .complexity: "brain"
        case .maintainability: "wrench.and.screwdriver"
        case .readability: "eye"
        case .testability: "testtube.2"
        case .performance: "speedometer"
        case .security: "lock.shield"
        case .documentation: "doc.text"
        case .consistency: "checkmark.seal"
        }
    }

    var description: String {
        switch self {
        case .complexity: "Code complexity analysis"
        case .maintainability: "Ease of maintenance and modification"
        case .readability: "Code clarity and comprehension"
        case .testability: "Ease of writing tests"
        case .performance: "Execution efficiency"
        case .security: "Security vulnerability assessment"
        case .documentation: "Code documentation quality"
        case .consistency: "Code style and pattern consistency"
        }
    }
}

enum ComplexityLevel: String, CaseIterable {
    case simple = "Simple"
    case moderate = "Moderate"
    case complex = "Complex"
    case veryComplex = "Very Complex"

    var color: String {
        switch self {
        case .simple: "green"
        case .moderate: "yellow"
        case .complex: "orange"
        case .veryComplex: "red"
        }
    }

    var range: String {
        switch self {
        case .simple: "1-5"
        case .moderate: "6-10"
        case .complex: "11-20"
        case .veryComplex: "20+"
        }
    }
}

// MARK: - Documentation Types

enum DocumentationType: String, CaseIterable {
    case inline = "Inline"
    case function = "Function"
    case classType = "Class"
    case module = "Module"
    case readme = "README"
    case api = "API"
    case technical = "Technical"
    case user = "User Guide"

    var systemImage: String {
        switch self {
        case .inline: "text.alignleft"
        case .function: "function"
        case .classType: "curlybraces"
        case .module: "shippingbox"
        case .readme: "doc.text"
        case .api: "doc.richtext"
        case .technical: "doc.on.doc"
        case .user: "book"
        }
    }
}

enum DocumentationQuality: String, CaseIterable {
    case missing = "Missing"
    case minimal = "Minimal"
    case adequate = "Adequate"
    case good = "Good"
    case excellent = "Excellent"

    var color: String {
        switch self {
        case .missing: "red"
        case .minimal: "orange"
        case .adequate: "yellow"
        case .good: "green"
        case .excellent: "blue"
        }
    }

    var score: Int {
        switch self {
        case .missing: 0
        case .minimal: 25
        case .adequate: 50
        case .good: 75
        case .excellent: 100
        }
    }
}

// MARK: - Fix and Suggestion Types

enum SharedFixCategory: String, CaseIterable {
    case automatic = "Automatic"
    case assisted = "Assisted"
    case manual = "Manual"
    case review = "Review Required"

    var systemImage: String {
        switch self {
        case .automatic: "wand.and.rays"
        case .assisted: "hand.point.up.left"
        case .manual: "hand.tap"
        case .review: "eye"
        }
    }

    var description: String {
        switch self {
        case .automatic: "Can be fixed automatically"
        case .assisted: "Requires user confirmation"
        case .manual: "Requires manual intervention"
        case .review: "Needs code review"
        }
    }
}

enum FixStatus: String, CaseIterable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case applied = "Applied"
    case rejected = "Rejected"
    case failed = "Failed"

    var systemImage: String {
        switch self {
        case .pending: "clock"
        case .inProgress: "gear"
        case .applied: "checkmark.circle"
        case .rejected: "xmark.circle"
        case .failed: "exclamationmark.triangle"
        }
    }

    var color: String {
        switch self {
        case .pending: "gray"
        case .inProgress: "blue"
        case .applied: "green"
        case .rejected: "orange"
        case .failed: "red"
        }
    }
}

// MARK: - Refactoring Types

struct RefactoringSuggestion {
    let type: RefactoringType
    let description: String
    let impact: Impact
    let effort: Effort

    enum RefactoringType {
        case extractMethod
        case extractClass
        case reduceNesting
        case simplifyConditionals
        case introduceParameterObject
    }

    enum Impact {
        case high, medium, low
    }

    enum Effort {
        case high, medium, low
    }
}
