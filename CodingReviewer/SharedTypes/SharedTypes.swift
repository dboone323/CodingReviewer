//
//  SharedTypes.swift
//  CodingReviewer
//
//  SharedTypes Module - Main import file for all shared types
//  Created on July 27, 2025
//
//  This file provides a single import point for all shared types used across the application.
//  Import this file instead of individual type files for convenience.
//

import Foundation

// Re-export all shared types for easy access
// Import SharedTypes to get access to all centralized type definitions

// MARK: - Module Organization
/*
 SharedTypes Module contains:

 1. CodeTypes.swift - Basic code and quality enums
    - CodeLanguage, Severity, QualityLevel, EffortLevel, ImpactLevel

 2. ServiceTypes.swift - AI and service-related types
    - AIProvider, AnalysisType, SuggestionType, ProjectType, FileUploadStatus
    - APIUsageStatus, RateLimitType

 3. AnalysisTypes.swift - Analysis and result-specific types
    - AnalysisEngine, AnalysisScope, AnalysisMode, PatternType, PatternConfidence
    - QualityMetric, ComplexityLevel, DocumentationType, DocumentationQuality
    - FixCategory, FixStatus

 Usage:
 - Import SharedTypes in any file that needs these type definitions
 - Replace local enum definitions with references to these centralized types
 - Use consistent naming and behavior across the entire application
 */

// MARK: - Type Aliases for Backward Compatibility
// Add type aliases here if needed for gradual migration from old enum names

// Example type aliases (uncomment and modify as needed during migration):
// typealias OldEnumName = NewEnumName
