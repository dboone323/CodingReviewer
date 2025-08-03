# Line Length Analysis Report

## Files with Long Lines (>120 characters):

### CodingReviewer/UnifiedDataModels.swift
```
65:     init(id: UUID = UUID(), fileName: String, filePath: String, fileType: String, issuesFound: Int, issues: [AnalysisIssue], analysisDate: Date = Date()) {
105:     init(id: UUID = UUID(), name: String, path: String, size: Int, content: String, type: String, uploadDate: Date = Date()) {
```

### CodingReviewer/IntelligentCodeAnalyzer.swift
```
108:             let projectStructure = ProjectStructure(name: URL(fileURLWithPath: projectPath).lastPathComponent, rootPath: projectPath, files: [])
119:             os_log("Project analysis completed with %d total files", log: logger, type: .info, result.project.files.count)
422:                 description: "\(count) \(category.rawValue.lowercased()) issues found (\(highPriorityCount) high-priority)",
```

### CodingReviewer/MLCodeInsightsModels.swift
```
119:     public init(linesOfCode: Int, functionCount: Int, variableCount: Int, complexityScore: Double, dependencyCount: Int) {
177:     public init(type: ChangeType, linesAdded: Int, linesRemoved: Int, functionsModified: Int, complexityDelta: Double, fileName: String, isPublicAPI: Bool) {
```

### CodingReviewer/PatternAnalysisView.swift
```
29:                 AnalysisFeatureItem(icon: "magnifyingglass", title: "Code Smell Detection", description: "Identify code smells automatically")
30:                 AnalysisFeatureItem(icon: "arrow.triangle.2.circlepath", title: "Refactoring Suggestions", description: "Smart refactoring recommendations")
31:                 AnalysisFeatureItem(icon: "chart.bar", title: "Complexity Analysis", description: "Measure code complexity metrics")
32:                 AnalysisFeatureItem(icon: "link", title: "Dependency Analysis", description: "Analyze code dependencies")
```

### CodingReviewer/FileManagerService.swift
```
140:     init(file: CodeFile, analysisResults: [EnhancedAnalysisItem], aiAnalysisResult: String? = nil, duration: TimeInterval) {
424:         logger.log("📁 Upload completed via FileUploadManager: \(successfulFiles.count) successful, \(uploadResult.failedFiles.count) failed")
586:         logger.log("✅ Analysis completed for \(file.name) in \(String(format: "%.2f", duration))s with \(record.analysisResults.count) results")
632:                     message: "High number of force unwraps (\(forceUnwrapCount)) detected. Consider using safe unwrapping.",
658:                             message: "Long function detected (\(functionLineCount) lines). Consider breaking into smaller functions.",
```

### CodingReviewer/OpenAIService.swift
```
41:         logger.log("AI analysis completed with \(analysisResponse.suggestions.count) suggestions", level: .info, category: .ai)
263:             if line.trimmingCharacters(in: .whitespaces).hasPrefix("{") || line.trimmingCharacters(in: .whitespaces).hasPrefix("[") {
271:             if (line.trimmingCharacters(in: .whitespaces).hasSuffix("}") || line.trimmingCharacters(in: .whitespaces).hasSuffix("]")) && inJSON {
327:         You are an expert code reviewer and software architect with deep knowledge of software engineering best practices, security, and performance optimization. Your role is to provide thorough, actionable feedback on code quality, security vulnerabilities, performance issues, and suggest improvements.
```

### CodingReviewer/AICodeReviewService.swift
```
438:             suggestions.append("🔒 Consider using safe unwrapping patterns (if let, guard let) instead of force unwrapping for better safety")
443:             suggestions.append("✨ Excellent use of SwiftUI property wrappers - consider @StateObject for object initialization")
485:             suggestions.append("📦 Consider using 'const' or 'let' instead of 'var' for better scoping and immutability")
523:             suggestions.append("📏 Large file detected (\(lines.count) lines) - consider breaking into smaller, more maintainable modules")
533:             suggestions.append("🏷️ Consider using more descriptive variable names instead of temporary placeholders")
```

### CodingReviewer/AutomatedTestSuite.swift
```
32:             UploadedFile(name: codeFile.name, path: codeFile.path, size: codeFile.size, content: codeFile.content, type: codeFile.language.rawValue)
280:             // AppLogger.shared.log("Applied fix: \(fix.title) - \(fix.description)") // TODO: Replace print with proper logging
```

### CodingReviewer/ComplexityAnalyzer.swift
```
60:                 description: "High cyclomatic complexity (\(complexity.cyclomaticComplexity)). Consider extracting smaller methods.",
69:                 description: "Deep nesting (\(complexity.maxNestingLevel) levels). Use guard statements and early returns.",
78:                 description: "High cognitive complexity (\(complexity.cognitiveComplexity)). Simplify conditional logic.",
```

### CodingReviewer/AIServiceProtocol.swift
```
16: // TODO: Review error handling in this file - Consider wrapping force unwraps and try statements in proper error handling
```

### CodingReviewer/EnhancedAIInsightsView.swift
```
212:                         description: "Run ML analysis to see intelligent insights about your code patterns and automation.",
636:                     value: mlService.mlInsights.isEmpty ? "N/A" : "\(Int(mlService.mlInsights.map(\.confidence).reduce(0, +) / Double(mlService.mlInsights.count) * 100))%",
```

### CodingReviewer/AutomaticFixEngine.swift
```
41:             await learningCoordinator.recordFailure(fix: failedFix.fix.description, error: failedFix.error.localizedDescription, context: filePath)
116:     private func applyFixes(_ fixes: [AutomaticFix], to content: String, filePath: String) async throws -> FixApplicationResult {
132:                 os_log("Failed to apply fix: %@ - %@", log: logger, type: .error, fix.description, error.localizedDescription)
242:         if line.contains("variable") && line.contains("was never mutated") && line.contains("consider changing to 'let'") {
```

### CodingReviewer/MLIntegrationService.swift
```
69:         task.arguments = ["-c", "cd '\(ProcessInfo.processInfo.environment["HOME"] ?? "")/Desktop/CodingReviewer' && ./ml_pattern_recognition.sh"]
92:         task.arguments = ["-c", "cd '\(ProcessInfo.processInfo.environment["HOME"] ?? "")/Desktop/CodingReviewer' && ./predictive_analytics.sh"]
115:         task.arguments = ["-c", "cd '\(ProcessInfo.processInfo.environment["HOME"] ?? "")/Desktop/CodingReviewer' && ./advanced_ai_integration.sh"]
188:             logger.log("📝 Created temp file list with \(fileData.count) files for ML processing", level: .info, category: .ai)
```

### CodingReviewer/AdvancedAIProjectAnalyzer.swift
```
21:     @Published var riskAssessment: RiskAssessment = RiskAssessment(overallRisk: 0.0, criticalRisks: [], mitigation: "No assessment available")
288:                 description: "Security analysis found \(results.security.vulnerabilities.count) potential vulnerabilities",
557:     init(overallScore: Double, dependencyHealth: Double, architectureHealth: Double, performanceHealth: Double, securityHealth: Double, qualityHealth: Double, riskLevel: Double, lastUpdated: Date) {
570:     var dependencies: DependencyAnalysisResult = DependencyAnalysisResult(score: 0.0, outdatedDependencies: [], vulnerableDependencies: [], conflictingDependencies: [])
571:     var architecture: ArchitectureAnalysisResult = ArchitectureAnalysisResult(score: 0.0, patterns: [], violations: [], suggestions: [])
```

### CodingReviewer/PerformanceTracker.swift
```
39:             AppLogger.shared.logWarning("Slow operation detected: \(operation) took \(String(format: "%.3f", duration))s")
```

### CodingReviewer/QuantumUIV2.swift
```
75:                 MetricBadge(title: "Consciousness", value: String(format: "%.1f%%", quantumEngine.consciousnessLevel), color: .blue)
76:                 MetricBadge(title: "Bio-Health", value: String(format: "%.1f%%", quantumEngine.biologicalAdaptation), color: .green)
77:                 MetricBadge(title: "Quantum", value: String(format: "%.1f%%", quantumEngine.quantumPerformance), color: .purple)
117:                         .stroke(quantumEngine.isQuantumActive ? Color.purple : Color.gray.opacity(0.3), lineWidth: quantumEngine.isQuantumActive ? 2 : 1)
219:                 MetricCard(title: "Consciousness", value: String(format: "%.1f%%", result.consciousnessScore), color: .blue)
```

### CodingReviewer/AIDashboardView.swift
```
192:                     .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: isRefreshing.wrappedValue)
380:     private func QuickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
448:             Text("AI has learned common patterns from your codebase and can predict potential issues before they occur.")
604:                 .background(recommendation.priority.rawValue == 3 ? Color.red : recommendation.priority.rawValue == 2 ? Color.orange : Color.blue)
```

### CodingReviewer/PatternRecognitionEngine.swift
```
104:         logger.log("🔍 Architecture analysis complete with score: \(insights.overallScore)", level: .info, category: .ai)
510:     init(name: String, description: String, codeLocation: CodeLocation, confidence: Double, suggestion: String?, relatedPatterns: [String]) {
534:     init(type: CodeSmellType, description: String, severity: CodeSmellSeverity, location: CodeLocation, suggestion: String, impact: CodeSmellImpact) {
617:     init(type: PerformanceIssueType, description: String, severity: PerformanceIssueSeverity, location: CodeLocation, suggestion: String, estimatedImpact: PerformanceImpact) {
```

### CodingReviewer/AppLogger.swift
```
169:             await AppLogger.shared.log("Performance: \(operation) took \(String(format: "%.2f", duration))s", level: .debug, category: .performance)
```

### CodingReviewer/Views/RobustFileUploadView.swift
```
91:                         if let item = try await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL {
158:             message += "✅ Successfully uploaded \(result.successfulFiles.count) file\(result.successfulFiles.count == 1 ? "" : "s")"
167:             message += "\n\n❌ Failed to upload \(result.failedFiles.count) file\(result.failedFiles.count == 1 ? "" : "s"):"
273:             Image(systemName: isDragOver ? "folder.fill.badge.plus" : isUploading ? "arrow.clockwise" : "folder.badge.plus")
293:                 Text("Supports Swift, Python, JavaScript, TypeScript, Java, C/C++, Go, Rust, PHP, Ruby, Kotlin, C#, HTML, CSS, JSON, YAML, Markdown, Xcode projects, and more")
```

### CodingReviewer/IntelligentFixGenerator.swift
```
149:                     let safeFix = line.replacingOccurrences(of: "\(variableName)!", with: "\(variableName) ?? defaultValue")
160:                         explanation: "Force unwrapping can cause runtime crashes. Using nil coalescing (??) provides a safer alternative with a default value.",
210:                         explanation: "String concatenation in loops creates multiple string objects. Using StringBuilder or array joining is more efficient.",
```

### CodingReviewer/MLHealthMonitor.swift
```
101:         AppLogger.shared.log("ML Health Check completed: \(Int(overallScore * 100))% healthy", level: .info, category: .ai)
```

### CodingReviewer/QuantumAnalysisEngineV2.swift
```
43:         let results = await withTaskGroup(of: EnhancedAnalysisChunk.self, returning: [EnhancedAnalysisChunk].self) { group in
218:     private func calculatePerformanceMetrics(_ executionTime: TimeInterval, _ chunkCount: Int) -> QuantumPerformanceMetrics {
```

### CodingReviewer/Services/FileUploadManager.swift
```
239:                 let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
262:                 warnings.append("Directory contains more than \(configuration.maxFilesPerUpload) files. Some files were skipped.")
```

### CodingReviewer/EnhancedAICodeGenerator.swift
```
100:     func generateFunction(name: String, parameters: [Parameter], returnType: String?, context: GenerationContext) async -> String {
111:     func generateClass(name: String, superclass: String?, protocols: [String], context: GenerationContext) async -> String {
655:     init(success: Bool, generatedCode: String, confidence: Double, suggestions: [ImprovementSuggestion], metadata: GenerationMetadata, error: Error? = nil) {
```

### CodingReviewer/Debug/DataFlowDiagnostics.swift
```
134:             details: isConsistent ? "✅ Same FileManagerService instance" : "❌ Different FileManagerService instances",
169:             details: canAccess ? "✅ Can access and modify uploaded files" : "❌ Cannot access uploaded files properly",
185:             details: isSameInstance ? "✅ Environment object matches shared instance" : "❌ Environment object is different from shared instance",
208:             details: "📊 Files: \(fileManager.uploadedFiles.count), Analysis: \(fileManager.analysisHistory.count). \(expectedState)",
225:             details: files.isEmpty ? "📊 No files to analyze" : "📊 \(files.count) files across \(uniqueLanguages) languages",
```


## Refactoring Suggestions:
1. Break long function chains into variables
2. Extract complex expressions into computed properties
3. Split long parameter lists into structs
4. Use line breaks at logical points in expressions

## Example:
```swift
// Instead of: let result = someVeryLongFunctionCall(withParameter: value, andAnotherParameter: anotherValue, andYetAnotherParameter: thirdValue)
// Use:
let result = someVeryLongFunctionCall(
    withParameter: value,
    andAnotherParameter: anotherValue,
    andYetAnotherParameter: thirdValue
)
```
