import Foundation

class ComplexityAnalyzer {
    static let shared = ComplexityAnalyzer()

    private init() {}

    /// Analyzes and processes data with comprehensive validation
    /// <#Description#>
    /// - Returns: <#description#>
    func analyzeFunction(_ content: String, in _: String) -> FunctionComplexity {
        let lines = content.components(separatedBy: .newlines)

        var cyclomaticComplexity = 1 // Base complexity;
        var cognitiveComplexity = 0
        var nestingLevel = 0
        var maxNesting = 0

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Count decision points for cyclomatic complexity
            if trimmedLine.contains("if ") || trimmedLine.contains("else") ||
                trimmedLine.contains("for ") || trimmedLine.contains("while ") ||
                trimmedLine.contains("switch ") || trimmedLine.contains("case ") ||
                trimmedLine.contains("catch ") || trimmedLine.contains("guard ")
            {
                cyclomaticComplexity += 1
            }

            // Track nesting for cognitive complexity
            if trimmedLine.hasSuffix("{") {
                nestingLevel += 1
                maxNesting = max(maxNesting, nestingLevel)
                if nestingLevel > 1 {
                    cognitiveComplexity += nestingLevel
                }
            }

            if trimmedLine.contains("}") {
                nestingLevel = max(0, nestingLevel - 1)
            }

            // Cognitive complexity penalties
            if trimmedLine.contains("&&") || trimmedLine.contains("||") {
                cognitiveComplexity += 1
            }
        }

        return FunctionComplexity(
            cyclomaticComplexity: cyclomaticComplexity,
            cognitiveComplexity: cognitiveComplexity,
            maxNestingLevel: maxNesting,
            linesOfCode: lines.count
        )
    }

    /// Creates and configures components with proper initialization
    /// <#Description#>
    /// - Returns: <#description#>
    func generateRefactoringSuggestions(for complexity: FunctionComplexity) -> [RefactoringSuggestion] {
        var suggestions: [RefactoringSuggestion] = []

        if complexity.cyclomaticComplexity > 10 {
            suggestions.append(RefactoringSuggestion(
                type: .extractMethod,
                description: "High cyclomatic complexity (\(complexity.cyclomaticComplexity)). Consider extracting smaller methods.",
                impact: .high,
                effort: .medium
            ))
        }

        if complexity.maxNestingLevel > 4 {
            suggestions.append(RefactoringSuggestion(
                type: .reduceNesting,
                description: "Deep nesting (\(complexity.maxNestingLevel) levels). Use guard statements and early returns.",
                impact: .medium,
                effort: .low
            ))
        }

        if complexity.cognitiveComplexity > 15 {
            suggestions.append(RefactoringSuggestion(
                type: .simplifyConditionals,
                description: "High cognitive complexity (\(complexity.cognitiveComplexity)). Simplify conditional logic.",
                impact: .high,
                effort: .medium
            ))
        }

        if complexity.linesOfCode > 50 {
            suggestions.append(RefactoringSuggestion(
                type: .extractMethod,
                description: "Long function (\(complexity.linesOfCode) lines). Break into smaller, focused methods.",
                impact: .medium,
                effort: .medium
            ))
        }

        return suggestions
    }
}

struct FunctionComplexity {
    let cyclomaticComplexity: Int
    let cognitiveComplexity: Int
    let maxNestingLevel: Int
    let linesOfCode: Int

    var overallComplexity: ComplexityLevel {
        let score = cyclomaticComplexity + cognitiveComplexity + maxNestingLevel

        switch score {
        case 0 ... 10: return .low
        case 11 ... 20: return .medium
        case 21 ... 30: return .high
        default: return .critical
        }
    }

    enum ComplexityLevel {
        case low, medium, high, critical

        var description: String {
            switch self {
            case .low: "Low complexity - maintainable"
            case .medium: "Medium complexity - monitor"
            case .high: "High complexity - refactor recommended"
            case .critical: "Critical complexity - refactor required"
            }
        }
    }
}
