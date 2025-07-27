//
//  AnalysisTypes.swift
//  CodingReviewer
//
//  SharedTypes Module - Analysis and result-specific types
//  Created on July 27, 2025
//

import Foundation

// MARK: - Analysis Engine Types

enum AnalysisEngine: String, CaseIterable, Codable {
    case ai = "AI"
    case pattern = "Pattern"
    case combined = "Combined"
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .ai: return "AI-powered analysis using language models"
        case .pattern: return "Pattern-based static analysis"
        case .combined: return "Combined AI and pattern analysis"
        }
    }
}

enum AnalysisScope: String, CaseIterable, Codable {
    case file = "File"
    case project = "Project"
    case folder = "Folder"
    case selection = "Selection"
    
    var systemImage: String {
        switch self {
        case .file: return "doc"
        case .project: return "folder"
        case .folder: return "folder.badge.plus"
        case .selection: return "selection.pin.in.out"
        }
    }
}

enum AnalysisMode: String, CaseIterable, Codable {
    case quick = "Quick"
    case standard = "Standard"
    case detailed = "Detailed"
    case comprehensive = "Comprehensive"
    
    var description: String {
        switch self {
        case .quick: return "Fast analysis with basic checks"
        case .standard: return "Standard analysis with common patterns"
        case .detailed: return "Detailed analysis with comprehensive checks"
        case .comprehensive: return "Complete analysis with all features"
        }
    }
    
    var estimatedTime: String {
        switch self {
        case .quick: return "< 30 seconds"
        case .standard: return "1-2 minutes"
        case .detailed: return "3-5 minutes"
        case .comprehensive: return "5-10 minutes"
        }
    }
}

// MARK: - Pattern Analysis Types

enum PatternType: String, CaseIterable, Codable {
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
        case .antiPattern: return "exclamationmark.triangle"
        case .designPattern: return "building.columns"
        case .codeSmell: return "nose"
        case .bestPractice: return "star"
        case .architecture: return "building.2"
        case .performance: return "speedometer"
        case .security: return "lock.shield"
        case .maintainability: return "wrench.and.screwdriver"
        }
    }
}

enum PatternConfidence: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case certain = "Certain"
    
    var color: String {
        switch self {
        case .low: return "red"
        case .medium: return "orange"
        case .high: return "green"
        case .certain: return "blue"
        }
    }
    
    var percentage: Int {
        switch self {
        case .low: return 25
        case .medium: return 50
        case .high: return 75
        case .certain: return 95
        }
    }
}

// MARK: - Quality Metrics Types

enum QualityMetric: String, CaseIterable, Codable {
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
        case .complexity: return "brain"
        case .maintainability: return "wrench.and.screwdriver"
        case .readability: return "eye"
        case .testability: return "testtube.2"
        case .performance: return "speedometer"
        case .security: return "lock.shield"
        case .documentation: return "doc.text"
        case .consistency: return "checkmark.seal"
        }
    }
    
    var description: String {
        switch self {
        case .complexity: return "Code complexity analysis"
        case .maintainability: return "Ease of maintenance and modification"
        case .readability: return "Code clarity and comprehension"
        case .testability: return "Ease of writing tests"
        case .performance: return "Execution efficiency"
        case .security: return "Security vulnerability assessment"
        case .documentation: return "Code documentation quality"
        case .consistency: return "Code style and pattern consistency"
        }
    }
}

enum ComplexityLevel: String, CaseIterable, Codable {
    case simple = "Simple"
    case moderate = "Moderate"
    case complex = "Complex"
    case veryComplex = "Very Complex"
    
    var color: String {
        switch self {
        case .simple: return "green"
        case .moderate: return "yellow"
        case .complex: return "orange"
        case .veryComplex: return "red"
        }
    }
    
    var range: String {
        switch self {
        case .simple: return "1-5"
        case .moderate: return "6-10"
        case .complex: return "11-20"
        case .veryComplex: return "20+"
        }
    }
}

// MARK: - Documentation Types

enum DocumentationType: String, CaseIterable, Codable {
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
        case .inline: return "text.alignleft"
        case .function: return "function"
        case .classType: return "curlybraces"
        case .module: return "shippingbox"
        case .readme: return "doc.text"
        case .api: return "doc.richtext"
        case .technical: return "doc.on.doc"
        case .user: return "book"
        }
    }
}

enum DocumentationQuality: String, CaseIterable, Codable {
    case missing = "Missing"
    case minimal = "Minimal"
    case adequate = "Adequate"
    case good = "Good"
    case excellent = "Excellent"
    
    var color: String {
        switch self {
        case .missing: return "red"
        case .minimal: return "orange"
        case .adequate: return "yellow"
        case .good: return "green"
        case .excellent: return "blue"
        }
    }
    
    var score: Int {
        switch self {
        case .missing: return 0
        case .minimal: return 25
        case .adequate: return 50
        case .good: return 75
        case .excellent: return 100
        }
    }
}

// MARK: - Fix and Suggestion Types

enum SharedFixCategory: String, CaseIterable, Codable {
    case automatic = "Automatic"
    case assisted = "Assisted"
    case manual = "Manual"
    case review = "Review Required"
    
    var systemImage: String {
        switch self {
        case .automatic: return "wand.and.rays"
        case .assisted: return "hand.point.up.left"
        case .manual: return "hand.tap"
        case .review: return "eye"
        }
    }
    
    var description: String {
        switch self {
        case .automatic: return "Can be fixed automatically"
        case .assisted: return "Requires user confirmation"
        case .manual: return "Requires manual intervention"
        case .review: return "Needs code review"
        }
    }
}

enum FixStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case applied = "Applied"
    case rejected = "Rejected"
    case failed = "Failed"
    
    var systemImage: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "gear"
        case .applied: return "checkmark.circle"
        case .rejected: return "xmark.circle"
        case .failed: return "exclamationmark.triangle"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "gray"
        case .inProgress: return "blue"
        case .applied: return "green"
        case .rejected: return "orange"
        case .failed: return "red"
        }
    }
}
