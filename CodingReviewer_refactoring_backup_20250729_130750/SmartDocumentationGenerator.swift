//
//  SmartDocumentationGenerator.swift
//  CodingReviewer
//
//  Phase 4: Smart Code Documentation Generator
//  Created on July 25, 2025
//

import Foundation
import SwiftUI
import Combine

// MARK: - Smart Documentation Generator

final class SmartDocumentationGenerator: ObservableObject {

    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var generatedDocumentation: GeneratedDocumentation?
    @Published var documentationSuggestions: [DocumentationSuggestion] = []

    private let logger = AppLogger.shared
    private let aiService: any AIServiceProtocol

    init(aiService: any AIServiceProtocol) {
        self.aiService = aiService
        logger.log("📚 Smart Documentation Generator initialized", level: .info, category: .ai)
    }

    // MARK: - Main Documentation Generation Interface

    @MainActor
    func generateDocumentation(
        for codeFile: CodeFile,
        style: DocumentationStyle = .comprehensive
    ) async -> GeneratedDocumentation {

        isGenerating = true
        generationProgress = 0.0

        logger.log("📚 Generating documentation for \(codeFile.name)", level: .info, category: .ai)

        let documentation = GeneratedDocumentation(
            fileName: codeFile.name,
            language: codeFile.language,
            style: style,
            sections: []
        )

        // Generate different sections based on content analysis
        var sections: [DocumentationSection] = []

        // Overview section
        sections.append(await generateOverviewSection(for: codeFile))
        await updateProgress(0.2)

        // API documentation
        sections.append(contentsOf: await generateAPIDocumentation(for: codeFile))
        await updateProgress(0.4)

        // Usage examples
        sections.append(contentsOf: await generateUsageExamples(for: codeFile))
        await updateProgress(0.6)

        // Architecture notes
        sections.append(contentsOf: await generateArchitectureNotes(for: codeFile))
        await updateProgress(0.8)

        // Best practices and warnings
        sections.append(contentsOf: await generateBestPractices(for: codeFile))
        await updateProgress(1.0)

        let finalDocumentation = GeneratedDocumentation(
            fileName: codeFile.name,
            language: codeFile.language,
            style: style,
            sections: sections
        )

        generatedDocumentation = finalDocumentation
        isGenerating = false

        logger.log("📚 Documentation generation complete for \(codeFile.name)", level: .info, category: .ai)
        return finalDocumentation
    }

    @MainActor
    func generateMarkdownDocumentation(
        for files: [CodeFile],
        projectName: String
    ) async -> MarkdownDocumentation {

        logger.log("📚 Generating Markdown documentation for \(files.count) files", level: .info, category: .ai)

        let readmeContent = await generateREADME(for: files, projectName: projectName)
        let apiReference = await generateAPIReference(for: files)
        let architectureGuide = await generateArchitectureGuide(for: files)
        let contributingGuide = await generateContributingGuide(for: files)

        return MarkdownDocumentation(
            readme: readmeContent,
            apiReference: apiReference,
            architectureGuide: architectureGuide,
            contributingGuide: contributingGuide,
            additionalDocuments: []
        )
    }

    @MainActor
    func suggestDocumentationImprovements(
        for codeFile: CodeFile
    ) async -> [DocumentationSuggestion] {

        logger.log("📚 Analyzing documentation improvements for \(codeFile.name)", level: .info, category: .ai)

        var suggestions: [DocumentationSuggestion] = []

        // Analyze code for missing documentation
        suggestions.append(contentsOf: analyzeMissingDocumentation(in: codeFile))
        suggestions.append(contentsOf: analyzeDocumentationQuality(in: codeFile))
        suggestions.append(contentsOf: suggestDocumentationStructure(for: codeFile))

        documentationSuggestions = suggestions

        logger.log("📚 Found \(suggestions.count) documentation suggestions", level: .info, category: .ai)
        return suggestions
    }

    // MARK: - Section Generation

    private func generateOverviewSection(for codeFile: CodeFile) async -> DocumentationSection {
        let content = await analyzeCodePurpose(codeFile.content, language: codeFile.language)

        return DocumentationSection(
            type: .overview,
            title: "Overview",
            content: content,
            codeExamples: [],
            crossReferences: []
        )
    }

    private func generateAPIDocumentation(for codeFile: CodeFile) async -> [DocumentationSection] {
        var sections: [DocumentationSection] = []

        // Extract classes, methods, and properties
        let apiElements = extractAPIElements(from: codeFile.content, language: codeFile.language)

        for element in apiElements {
            let documentation = await generateElementDocumentation(element, in: codeFile)
            sections.append(documentation)
        }

        return sections
    }

    private func generateUsageExamples(for codeFile: CodeFile) async -> [DocumentationSection] {
        let examples = await generateCodeExamples(for: codeFile)

        if examples.isEmpty {
            return []
        }

        return [DocumentationSection(
            type: .usage,
            title: "Usage Examples",
            content: "Here are some examples of how to use this code:",
            codeExamples: examples,
            crossReferences: []
        )]
    }

    private func generateArchitectureNotes(for codeFile: CodeFile) async -> [DocumentationSection] {
        let architectureInfo = await analyzeArchitecture(codeFile.content, language: codeFile.language)

        if architectureInfo.isEmpty {
            return []
        }

        return [DocumentationSection(
            type: .architecture,
            title: "Architecture",
            content: architectureInfo,
            codeExamples: [],
            crossReferences: []
        )]
    }

    private func generateBestPractices(for codeFile: CodeFile) async -> [DocumentationSection] {
        let practices = await analyzeBestPractices(codeFile.content, language: codeFile.language)

        if practices.isEmpty {
            return []
        }

        return [DocumentationSection(
            type: .bestPractices,
            title: "Best Practices & Considerations",
            content: practices,
            codeExamples: [],
            crossReferences: []
        )]
    }

    // MARK: - Markdown Generation

    private func generateREADME(for files: [CodeFile], projectName: String) async -> String {
        let readme = """
        # \(projectName)

        ## Overview

        \(await generateProjectOverview(files))

        ## Features

        \(await generateFeatureList(files))

        ## Installation

        \(generateInstallationInstructions(for: files))

        ## Usage

        \(await generateQuickStartGuide(files))

        ## API Reference

        See [API Reference](API_REFERENCE.md) for detailed documentation.

        ## Architecture

        See [Architecture Guide](ARCHITECTURE.md) for detailed information about the project structure.

        ## Contributing

        See [Contributing Guide](CONTRIBUTING.md) for information on how to contribute to this project.

        ## License

        [Add license information here]
        """

        return readme
    }

    private func generateAPIReference(for files: [CodeFile]) async -> String {
        var apiRef = """
        # API Reference

        This document provides detailed information about the public API.

        """

        for file in files {
            let elements = extractAPIElements(from: file.content, language: file.language)
            if !elements.isEmpty {
                apiRef += "\n## \(file.name)\n\n"

                for element in elements {
                    apiRef += await formatAPIElementMarkdown(element, in: file)
                }
            }
        }

        return apiRef
    }

    private func generateArchitectureGuide(for files: [CodeFile]) async -> String {
        return """
        # Architecture Guide

        This document describes the overall architecture of the project.

        ## Overview

        \(await generateArchitectureOverview(files))

        ## Components

        \(await generateComponentDocumentation(files))

        ## Design Patterns

        \(await generateDesignPatternDocumentation(files))

        ## Data Flow

        \(await generateDataFlowDocumentation(files))
        """
    }

    private func generateContributingGuide(for files: [CodeFile]) async -> String {
        return """
        # Contributing Guide

        Thank you for your interest in contributing to this project!

        ## Development Setup

        \(generateDevelopmentSetup(for: files))

        ## Code Style

        \(await generateCodeStyleGuide(files))

        ## Testing

        \(generateTestingGuide(for: files))

        ## Pull Request Process

        1. Fork the repository
        2. Create a feature branch
        3. Make your changes
        4. Add tests if applicable
        5. Ensure all tests pass
        6. Submit a pull request

        ## Code Review Process

        All pull requests will be reviewed by project maintainers.
        """
    }

    // MARK: - AI-Powered Analysis

    private func analyzeCodePurpose(_ code: String, language: CodeLanguage) async -> String {
        do {
            // Use specialized prompt for code purpose analysis
            let purposePrompt = "Analyze the purpose of this \(language.displayName) code. Focus on what it does and its main functionality:\n\n\(code)"
            let response = try await aiService.explainCode(purposePrompt, language: language)
            return response
        } catch {
            logger.log("❌ Failed to analyze code purpose: \(error)", level: .error, category: .ai)
            return "This code contains various functions and classes. See the implementation for details."
        }
    }

    private func analyzeArchitecture(_ code: String, language: CodeLanguage) async -> String {
        do {
            // Use specialized prompt for architecture analysis
            let architecturePrompt = "Analyze the architecture and design patterns in this \(language.displayName) code. Focus on structure, patterns, and organization:\n\n\(code)"
            let response = try await aiService.explainCode(architecturePrompt, language: language)
            return response
        } catch {
            logger.log("❌ Failed to analyze architecture: \(error)", level: .error, category: .ai)
            return ""
        }
    }

    private func analyzeBestPractices(_ code: String, language: CodeLanguage) async -> String {
        do {
            // Use specialized prompt for best practices analysis
            let practicesPrompt = "Analyze this \(language.displayName) code for best practices, code quality, and improvement recommendations:\n\n\(code)"
            let response = try await aiService.explainCode(practicesPrompt, language: language)
            return response
        } catch {
            logger.log("❌ Failed to analyze best practices: \(error)", level: .error, category: .ai)
            return ""
        }
    }

    // MARK: - Code Analysis Helpers

    private func extractAPIElements(from code: String, language: CodeLanguage) -> [APIElement] {
        var elements: [APIElement] = []

        switch language {
        case .swift:
            elements.append(contentsOf: extractSwiftAPIElements(from: code))
        case .python:
            elements.append(contentsOf: extractPythonAPIElements(from: code))
        case .javascript, .typescript:
            elements.append(contentsOf: extractJavaScriptAPIElements(from: code))
        default:
            elements.append(contentsOf: extractGenericAPIElements(from: code))
        }

        return elements
    }

    private func extractSwiftAPIElements(from code: String) -> [APIElement] {
        var elements: [APIElement] = []
        let lines = code.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Extract classes
            if trimmedLine.contains("class ") && !trimmedLine.hasPrefix("//") {
                let name = extractEntityName(from: trimmedLine, keyword: "class")
                elements.append(APIElement(
                    type: .classType,
                    name: name,
                    signature: trimmedLine,
                    documentation: "",
                    lineNumber: index + 1
                ))
            }

            // Extract functions
            if trimmedLine.contains("func ") && !trimmedLine.hasPrefix("//") {
                let name = extractEntityName(from: trimmedLine, keyword: "func")
                elements.append(APIElement(
                    type: .function,
                    name: name,
                    signature: trimmedLine,
                    documentation: "",
                    lineNumber: index + 1
                ))
            }

            // Extract properties
            if (trimmedLine.contains("var ") || trimmedLine.contains("let ")) &&
               !trimmedLine.hasPrefix("//") &&
               (trimmedLine.contains("public") || trimmedLine.contains("open")) {
                let name = extractPropertyName(from: trimmedLine)
                elements.append(APIElement(
                    type: .property,
                    name: name,
                    signature: trimmedLine,
                    documentation: "",
                    lineNumber: index + 1
                ))
            }
        }

        return elements
    }

    private func extractPythonAPIElements(from code: String) -> [APIElement] {
        var elements: [APIElement] = []
        let lines = code.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Extract classes
            if trimmedLine.hasPrefix("class ") {
                let name = extractEntityName(from: trimmedLine, keyword: "class")
                elements.append(APIElement(
                    type: .classType,
                    name: name,
                    signature: trimmedLine,
                    documentation: "",
                    lineNumber: index + 1
                ))
            }

            // Extract functions
            if trimmedLine.hasPrefix("def ") {
                let name = extractEntityName(from: trimmedLine, keyword: "def")
                elements.append(APIElement(
                    type: .function,
                    name: name,
                    signature: trimmedLine,
                    documentation: "",
                    lineNumber: index + 1
                ))
            }
        }

        return elements
    }

    private func extractJavaScriptAPIElements(from code: String) -> [APIElement] {
        var elements: [APIElement] = []
        let lines = code.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Extract functions
            if trimmedLine.contains("function ") || trimmedLine.contains("const ") && trimmedLine.contains("=>") {
                let name = extractJSFunctionName(from: trimmedLine)
                elements.append(APIElement(
                    type: .function,
                    name: name,
                    signature: trimmedLine,
                    documentation: "",
                    lineNumber: index + 1
                ))
            }

            // Extract classes
            if trimmedLine.hasPrefix("class ") {
                let name = extractEntityName(from: trimmedLine, keyword: "class")
                elements.append(APIElement(
                    type: .classType,
                    name: name,
                    signature: trimmedLine,
                    documentation: "",
                    lineNumber: index + 1
                ))
            }
        }

        return elements
    }

    private func extractGenericAPIElements(from code: String) -> [APIElement] {
        // Basic extraction for other languages
        return []
    }

    // MARK: - Documentation Analysis

    private func analyzeMissingDocumentation(in codeFile: CodeFile) -> [DocumentationSuggestion] {
        var suggestions: [DocumentationSuggestion] = []
        let elements = extractAPIElements(from: codeFile.content, language: codeFile.language)

        for element in elements {
            if element.documentation.isEmpty {
                suggestions.append(DocumentationSuggestion(
                    type: .missingDocumentation,
                    severity: .medium,
                    location: CodeLocation(line: element.lineNumber, column: 1, fileName: codeFile.name),
                    suggestion: "Add documentation for \(element.type.rawValue) '\(element.name)'",
                    details: "This \(element.type.rawValue) lacks documentation. Consider adding a description of its purpose, parameters, and return value.",
                    estimatedEffort: .low
                ))
            }
        }

        return suggestions
    }

    private func analyzeDocumentationQuality(in codeFile: CodeFile) -> [DocumentationSuggestion] {
        var suggestions: [DocumentationSuggestion] = []

        // Check for README file
        if codeFile.name.lowercased().contains("readme") {
            // Analyze README quality
            if codeFile.content.count < 500 {
                suggestions.append(DocumentationSuggestion(
                    type: .improveDocumentationQuality,
                    severity: .medium,
                    location: CodeLocation(line: 1, column: 1, fileName: codeFile.name),
                    suggestion: "Expand README with more comprehensive information",
                    details: "The README appears to be quite brief. Consider adding sections for installation, usage examples, and contribution guidelines.",
                    estimatedEffort: .medium
                ))
            }
        }

        return suggestions
    }

    private func suggestDocumentationStructure(for codeFile: CodeFile) -> [DocumentationSuggestion] {
        var suggestions: [DocumentationSuggestion] = []

        let elements = extractAPIElements(from: codeFile.content, language: codeFile.language)
        let classCount = elements.filter { $0.type == .classType }.count

        if classCount > 3 {
            suggestions.append(DocumentationSuggestion(
                type: .structureImprovement,
                severity: .low,
                location: CodeLocation(line: 1, column: 1, fileName: codeFile.name),
                suggestion: "Consider creating separate documentation files for each major component",
                details: "This file contains multiple classes (\(classCount)). Consider creating individual documentation files or sections for better organization.",
                estimatedEffort: .medium
            ))
        }

        return suggestions
    }

    // MARK: - Helper Methods

    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            self.generationProgress = progress
        }
        try? await Task.sleep(nanoseconds: 100_000_000) // Small delay for UI
    }

    private func extractEntityName(from line: String, keyword: String) -> String {
        guard let keywordRange = line.range(of: keyword) else { return "Unknown" }

        let afterKeyword = String(line[keywordRange.upperBound...])
        let components = afterKeyword.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: CharacterSet(charactersIn: " ({:<"))

        return components.first?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
    }

    private func extractPropertyName(from line: String) -> String {
        let words = line.components(separatedBy: .whitespaces)

        for (index, word) in words.enumerated() {
            if word == "var" || word == "let", index + 1 < words.count {
                return words[index + 1].trimmingCharacters(in: CharacterSet(charactersIn: ":"))
            }
        }

        return "Unknown"
    }

    private func extractJSFunctionName(from line: String) -> String {
        if line.contains("function ") {
            return extractEntityName(from: line, keyword: "function")
        } else if line.contains("const ") && line.contains("=>") {
            return extractEntityName(from: line, keyword: "const")
        }
        return "Unknown"
    }

    private func generateElementDocumentation(_ element: APIElement, in codeFile: CodeFile) async -> DocumentationSection {
        return DocumentationSection(
            type: .api,
            title: "\(element.type.rawValue.capitalized): \(element.name)",
            content: "Documentation for \(element.name)",
            codeExamples: [CodeExample(
                title: "Signature",
                code: element.signature,
                language: codeFile.language.rawValue
            )],
            crossReferences: []
        )
    }

    private func generateCodeExamples(for codeFile: CodeFile) async -> [CodeExample] {
        // Generate usage examples based on the code content
        return [
            CodeExample(
                title: "Basic Usage",
                code: "// Example usage of \(codeFile.name)",
                language: codeFile.language.rawValue
            )
        ]
    }

    // MARK: - Project-Level Documentation Helpers

    private func generateProjectOverview(_ files: [CodeFile]) async -> String {
        let languageStats = Dictionary(grouping: files, by: { $0.language })
        let primaryLanguage = languageStats.max(by: { $0.value.count < $1.value.count })?.key ?? .unknown

        return """
        This project is primarily written in \(primaryLanguage.rawValue) and contains \(files.count) source files.
        The codebase demonstrates modern software development practices and architectural patterns.
        """
    }

    private func generateFeatureList(_ files: [CodeFile]) async -> String {
        var features: [String] = []

        // Analyze files for common features
        for file in files {
            if file.content.contains("API") || file.content.contains("Service") {
                features.append("- API integration and service layer")
            }
            if file.content.contains("UI") || file.content.contains("View") {
                features.append("- User interface components")
            }
            if file.content.contains("Database") || file.content.contains("Core Data") {
                features.append("- Data persistence")
            }
        }

        return features.isEmpty ? "- Modern software architecture\n- Clean code principles" : features.joined(separator: "\n")
    }

    private func generateInstallationInstructions(for files: [CodeFile]) -> String {
        let languages = Set(files.map { $0.language })

        if languages.contains(.swift) {
            return """
            ### Prerequisites
            - Xcode 12.0 or later
            - iOS 14.0+ / macOS 11.0+

            ### Installation
            1. Clone the repository
            2. Open the `.xcodeproj` file in Xcode
            3. Build and run the project
            """
        } else if languages.contains(.python) {
            return """
            ### Prerequisites
            - Python 3.8 or later
            - pip package manager

            ### Installation
            ```bash
            pip install -r requirements.txt
            ```
            """
        } else {
            return """
            ### Prerequisites
            [Add prerequisites here]

            ### Installation
            [Add installation instructions here]
            """
        }
    }

    private func generateQuickStartGuide(_ files: [CodeFile]) async -> String {
        return """
        ```
        // Quick start example
        // Add your basic usage example here
        ```

        For more detailed examples, see the individual component documentation.
        """
    }

    private func formatAPIElementMarkdown(_ element: APIElement, in file: CodeFile) async -> String {
        return """

        ### \(element.name)

        **Type:** \(element.type.rawValue.capitalized)
        **File:** \(file.name):\(element.lineNumber)

        ```\(file.language.rawValue)
        \(element.signature)
        ```

        \(element.documentation.isEmpty ? "*Documentation pending*" : element.documentation)

        """
    }

    private func generateArchitectureOverview(_ files: [CodeFile]) async -> String {
        return """
        The application follows a modular architecture with clear separation of concerns.
        Components are organized into logical layers that promote maintainability and testability.
        """
    }

    private func generateComponentDocumentation(_ files: [CodeFile]) async -> String {
        var components: [String] = []

        for file in files {
            if file.name.contains("Service") {
                components.append("- **\(file.name)**: Service layer component")
            } else if file.name.contains("View") {
                components.append("- **\(file.name)**: User interface component")
            } else if file.name.contains("Model") {
                components.append("- **\(file.name)**: Data model")
            }
        }

        return components.isEmpty ? "Components will be documented as the project grows." : components.joined(separator: "\n")
    }

    private func generateDesignPatternDocumentation(_ files: [CodeFile]) async -> String {
        return """
        The codebase employs several design patterns:

        - **MVVM**: Model-View-ViewModel for UI architecture
        - **Dependency Injection**: For loose coupling and testability
        - **Observer Pattern**: For reactive programming and state management
        """
    }

    private func generateDataFlowDocumentation(_ files: [CodeFile]) async -> String {
        return """
        Data flows through the application in a unidirectional manner:

        1. User interactions trigger actions in the View layer
        2. ViewModels process these actions and update the Model
        3. Model changes propagate back to the View through reactive bindings
        """
    }

    private func generateDevelopmentSetup(for files: [CodeFile]) -> String {
        let languages = Set(files.map { $0.language })

        if languages.contains(.swift) {
            return """
            1. Install Xcode from the App Store
            2. Clone the repository: `git clone [repository-url]`
            3. Open the project in Xcode
            4. Ensure you have the latest Swift toolchain
            """
        } else {
            return """
            1. Clone the repository: `git clone [repository-url]`
            2. Install dependencies
            3. Set up your development environment
            """
        }
    }

    private func generateCodeStyleGuide(_ files: [CodeFile]) async -> String {
        let languages = Set(files.map { $0.language })

        if languages.contains(.swift) {
            return """
            - Follow Swift naming conventions
            - Use meaningful variable and function names
            - Keep functions focused and concise
            - Add documentation comments for public APIs
            - Use SwiftLint for consistent formatting
            """
        } else {
            return """
            - Follow language-specific conventions
            - Use meaningful naming
            - Keep code modular and well-documented
            - Follow established patterns in the codebase
            """
        }
    }

    private func generateTestingGuide(for files: [CodeFile]) -> String {
        return """
        - Write unit tests for all business logic
        - Use integration tests for complex workflows
        - Aim for good test coverage
        - Follow the existing test patterns in the codebase
        """
    }
}

// MARK: - Supporting Types

struct GeneratedDocumentation: Codable {
    let fileName: String
    let language: CodeLanguage
    let style: DocumentationStyle
    let sections: [DocumentationSection]
    let generatedAt: Date

    init(fileName: String, language: CodeLanguage, style: DocumentationStyle, sections: [DocumentationSection]) {
        self.fileName = fileName
        self.language = language
        self.style = style
        self.sections = sections
        self.generatedAt = Date()
    }
}

struct DocumentationSection: Codable, Identifiable {
    let id = UUID()
    let type: DocumentationSectionType
    let title: String
    let content: String
    let codeExamples: [CodeExample]
    let crossReferences: [String]
}

struct CodeExample: Codable, Identifiable {
    let id = UUID()
    let title: String
    let code: String
    let language: String
    let description: String?

    init(title: String, code: String, language: String, description: String? = nil) {
        self.title = title
        self.code = code
        self.language = language
        self.description = description
    }
}

struct APIElement: Codable {
    let type: APIElementType
    let name: String
    let signature: String
    let documentation: String
    let lineNumber: Int
}

struct DocumentationSuggestion: Identifiable, Codable {
    let id = UUID()
    let type: DocumentationSuggestionType
    let severity: DocumentationSeverity
    let location: CodeLocation
    let suggestion: String
    let details: String
    let estimatedEffort: DocumentationEffort
}

struct MarkdownDocumentation: Codable {
    let readme: String
    let apiReference: String
    let architectureGuide: String
    let contributingGuide: String
    let additionalDocuments: [MarkdownDocument]
    let generatedAt: Date

    init(readme: String, apiReference: String, architectureGuide: String, contributingGuide: String, additionalDocuments: [MarkdownDocument]) {
        self.readme = readme
        self.apiReference = apiReference
        self.architectureGuide = architectureGuide
        self.contributingGuide = contributingGuide
        self.additionalDocuments = additionalDocuments
        self.generatedAt = Date()
    }
}

struct MarkdownDocument: Codable, Identifiable {
    let id = UUID()
    let title: String
    let fileName: String
    let content: String
}

// MARK: - Enums

enum DocumentationStyle: String, CaseIterable, Codable {
    case minimal = "Minimal"
    case standard = "Standard"
    case comprehensive = "Comprehensive"
    case apiOnly = "API Only"

    var description: String {
        switch self {
        case .minimal:
            return "Basic documentation with essential information only"
        case .standard:
            return "Standard documentation with examples and usage information"
        case .comprehensive:
            return "Detailed documentation with comprehensive examples and best practices"
        case .apiOnly:
            return "API documentation focused on public interfaces"
        }
    }
}

enum DocumentationSectionType: String, CaseIterable, Codable {
    case overview = "Overview"
    case api = "API"
    case usage = "Usage"
    case architecture = "Architecture"
    case bestPractices = "Best Practices"
    case examples = "Examples"
    case troubleshooting = "Troubleshooting"
}

enum APIElementType: String, CaseIterable, Codable {
    case classType = "Class"
    case function = "Function"
    case property = "Property"
    case constant = "Constant"
    case enumType = "Enum"
    case protocolType = "Protocol"
    case extensionType = "Extension"
}

enum DocumentationSuggestionType: String, CaseIterable, Codable {
    case missingDocumentation = "Missing Documentation"
    case improveDocumentationQuality = "Improve Quality"
    case addCodeExamples = "Add Examples"
    case structureImprovement = "Structure Improvement"
    case crossReferenceOpportunity = "Cross Reference"
}

enum DocumentationSeverity: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        }
    }
}

enum DocumentationEffort: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var description: String {
        switch self {
        case .low: return "< 30 minutes"
        case .medium: return "30 minutes - 2 hours"
        case .high: return "> 2 hours"
        }
    }
}
