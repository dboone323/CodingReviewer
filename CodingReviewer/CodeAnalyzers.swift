import Foundation

struct CodeAnalyzers {
    // Simple static analyzers that work with our unified data models
    
    static func analyzeSwiftCode(_ code: String, filename: String) -> [AnalysisResult] {
        var results: [AnalysisResult] = []
        let lines = code.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            
            // Basic Swift code analysis
            if line.contains("TODO") || line.contains("FIXME") {
                results.append(AnalysisResult(
                    type: "Documentation",
                    severity: "warning",
                    message: "TODO/FIXME comment found",
                    lineNumber: lineNumber
                ))
            }
            
            if line.contains("print(") && !line.contains("//") {
                results.append(AnalysisResult(
                    type: "Debug",
                    severity: "info",
                    message: "Debug print statement found",
                    lineNumber: lineNumber
                ))
            }
            
            if line.trimmingCharacters(in: .whitespaces).isEmpty && 
               index < lines.count - 1 && 
               lines[index + 1].trimmingCharacters(in: .whitespaces).isEmpty {
                results.append(AnalysisResult(
                    type: "Formatting",
                    severity: "style",
                    message: "Multiple consecutive empty lines",
                    lineNumber: lineNumber
                ))
            }
        }
        
        return results
    }
    
    static func analyzeGenericCode(_ code: String, filename: String) -> [AnalysisResult] {
        var results: [AnalysisResult] = []
        let lines = code.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            
            // Generic code analysis
            if line.count > 120 {
                results.append(AnalysisResult(
                    type: "Style",
                    severity: "warning",
                    message: "Line too long (\(line.count) characters)",
                    lineNumber: lineNumber
                ))
            }
            
            if line.contains("TODO") || line.contains("FIXME") || line.contains("HACK") {
                results.append(AnalysisResult(
                    type: "Documentation",
                    severity: "info",
                    message: "Code comment requiring attention found",
                    lineNumber: lineNumber
                ))
            }
        }
        
        return results
    }
    
    static func performQuickAnalysis(for file: UploadedFile) -> [AnalysisResult] {
        guard !file.content.isEmpty else {
            return [AnalysisResult(
                type: "File Access",
                severity: "error",
                message: "Unable to read file content",
                lineNumber: 1
            )]
        }
        
        let fileExtension = (file.name as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "swift":
            return analyzeSwiftCode(file.content, filename: file.name)
        default:
            return analyzeGenericCode(file.content, filename: file.name)
        }
    }
}
