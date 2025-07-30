# Codebase Pattern Analysis Report
Generated: Wed Jul 30 07:29:32 CDT 2025

## Analysis Summary

### Codebase Metrics
- **Total Swift Files**: 62
- **View Controllers**: 0
- **SwiftUI Views**: 81
- **Protocols**: 3

### Common Patterns Detected
#### Common Function Patterns
```swift
    func generateDocumentation(for content: String, fileName: String) async -> GeneratedDocumentation {
    func analyzeProject(at projectPath: String) async throws -> String {
    func analyzeFile(at filePath: String) async throws -> [CodeIssue] {
    private func analyzeSwiftConcurrency(lines: [String], filePath: String) -> [CodeIssue] {
    private func analyzeCodeQuality(lines: [String], filePath: String) -> [CodeIssue] {
    private func analyzePerformance(lines: [String], filePath: String) -> [CodeIssue] {
    private func analyzeSecurity(lines: [String], filePath: String) -> [CodeIssue] {
    private func analyzeSwiftBestPractices(lines: [String], filePath: String) -> [CodeIssue] {
    private func analyzeArchitecturalPatterns(lines: [String], filePath: String) -> [CodeIssue] {
            if line.contains("func ") && line.contains("{") {
```

#### Common Import Patterns
- /Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/SmartDocumentationGenerator.swift:import SwiftUI (used 1 times)
- /Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/SmartDocumentationGenerator.swift:import OSLog (used 1 times)
- /Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/SmartDocumentationGenerator.swift:import Foundation (used 1 times)
- /Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/SmartDocumentationGenerator.swift:import Combine (used 1 times)
- /Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/SharedTypes/SharedTypes.swift:import Foundation (used 1 times)
- /Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/SharedTypes/SharedTypes.swift://  This file provides a single import point for all shared types used across the application. (used 1 times)
- /Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/SharedTypes/SharedTypes.swift://  SharedTypes Module - Main import file for all shared types (used 1 times)
- /Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/SharedTypes/ServiceTypes.swift:import Foundation (used 1 times)
- /Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/SharedTypes/CodeTypes.swift:import SwiftUI (used 1 times)
- /Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/SharedTypes/CodeTypes.swift:import Foundation (used 1 times)

#### Property Patterns
- SwiftUI property wrappers found: 231
