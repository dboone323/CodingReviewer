//
// AnalysisServiceProtocol.swift
// CodingReviewer
//
// Protocol definitions for analysis services

import Foundation

protocol AnalysisServiceProtocol {
    func analyzeCode(_ code: String) async throws -> String
    func generateRecommendations(from result: String) -> [String]
}

protocol MLServiceProtocol {
    func processPatterns(_ patterns: [String]) async throws -> String
    func trainModel(with data: [String]) async throws
}

protocol CodeReviewProtocol {
    func reviewCode(_ code: String) async throws -> String
    func generateFixes(for issues: [String]) -> [String]
}
