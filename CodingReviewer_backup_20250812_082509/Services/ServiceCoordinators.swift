import Foundation
import Combine
import SwiftUI

// MARK: - Service Coordinators

// This file provides coordination between different services following clean architecture

// MARK: - TeamProductivity (moved here to resolve circular dependency)

public struct TeamProductivity: Sendable {
    public let analysesPerUser: Double
    public let averageQualityScore: Double
    public let issueResolutionRate: Double
    public let codeReviewEfficiency: Double

    public init(
        analysesPerUser: Double,
        averageQualityScore: Double,
        issueResolutionRate: Double,
        codeReviewEfficiency: Double
    ) {
        self.analysesPerUser = analysesPerUser
        self.averageQualityScore = averageQualityScore
        self.issueResolutionRate = issueResolutionRate
        self.codeReviewEfficiency = codeReviewEfficiency
    }
}

// MARK: - Legacy Type Aliases for Backward Compatibility

// These provide type aliases for existing code without duplicating class definitions
public typealias AIDashboardView = EmptyView

// Note: Actual implementations of these classes exist in their respective files:
// - AILearningCoordinator.swift
// - AutomaticFixEngine.swift
// - EnhancedAICodeGenerator.swift
// - PerformanceAnalyzer (in CodeAnalyzers.swift)
// - EnhancedEnterpriseAnalyticsDashboard (in Views/EnterpriseAnalyticsDashboard.swift)
