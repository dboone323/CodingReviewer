# Contributing to CodeReviewer

Thank you for your interest in contributing to CodeReviewer! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Bugs
1. Check existing issues to avoid duplicates
2. Use the bug report template
3. Provide detailed reproduction steps
4. Include system information and code samples

### Suggesting Features
1. Check existing feature requests
2. Use the feature request template
3. Explain the use case and benefits
4. Consider implementation complexity

### Code Contributions
1. Fork the repository
2. Create a feature branch
3. Follow coding standards
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

## 🏗 Development Setup

### Prerequisites
- macOS 13.0 or later
- Xcode 14.0 or later
- Swift 5.7 or later
- Git

### Local Development
```bash
# Clone your fork
git clone https://github.com/yourusername/CodingReviewer.git
cd CodingReviewer

# Open in Xcode
open CodingReviewer.xcodeproj

# Build and run
⌘+R in Xcode
```

### Testing
```bash
# Run unit tests
⌘+U in Xcode

# Run UI tests
⌘+Shift+U in Xcode

# Run specific test
xcodebuild test -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' -only-testing:CodingReviewerTests/SpecificTest
```

## 📝 Coding Standards

### Swift Style Guide
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint for code formatting
- Maximum line length: 120 characters
- Use meaningful variable and function names
- Prefer `let` over `var` when possible

### **CodingReviewer-Specific Standards (August 8, 2025)**

**CRITICAL: Review DEVELOPMENT_GUIDELINES.md and VALIDATION_RULES.md before contributing**

#### **Type Implementation Requirements**
```swift
// ✅ REQUIRED - Complete type implementation
struct NewDataType: Identifiable, Sendable {
    let id: UUID                    // Always include ID
    let createdAt: Date            // Immutable metadata
    var status: Status             // Mutable runtime state
    var lastUpdated: Date          // Track changes
    
    // Complete protocol implementations required
    // No partial implementations allowed
}

// ❌ FORBIDDEN - Incomplete types lead to cascading errors
struct NewDataType: Identifiable {
    let id: UUID
    // Missing properties will cause build failures
}
```

#### **Concurrency Safety Rules**
- **Always use `Sendable`** for data models in concurrent contexts
- **Avoid `Codable`** in complex nested types (causes circular references)
- **Use `[weak self]`** only in class contexts with retain cycle risk
- **No `@preconcurrency`** annotations (indicates architectural problems)

#### **Architecture Boundary Enforcement**
- **SharedTypes/**: Pure data models only (NO SwiftUI imports)
- **Extensions/**: UI extensions for data models only
- **Components/**: Reusable UI components only
- **Never import SwiftUI** in SharedTypes/ folder

#### **Error Prevention Patterns**
```swift
// ✅ SAFE OPTIONAL HANDLING
guard let url = URL(string: urlString) else {
    throw ValidationError.invalidURL
}

let validItems = items.compactMap { item in
    guard item.isValid else { return nil }
    return item
}

// ❌ FORBIDDEN PATTERNS
let url = URL(string: urlString)!  // Force unwrap
let item = items.first!            // Force unwrap
```

#### **Platform Compatibility Requirements**
```swift
// ✅ CROSS-PLATFORM UI
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button("Action") { /* action */ }
    }
}

// ❌ PLATFORM-SPECIFIC CODE
.navigationBarItems(trailing: button)  // iOS only
```

### Code Organization
```swift
// MARK: - Properties
private var someProperty: String

// MARK: - Lifecycle
override func viewDidLoad() {
    super.viewDidLoad()
}

// MARK: - Actions
@IBAction private func buttonTapped(_ sender: UIButton) {
}

// MARK: - Private Methods
private func helperMethod() {
}
```

### Documentation
- Use Swift documentation comments for public APIs
- Include usage examples for complex functions
- Document complex algorithms and business logic

```swift
/// Analyzes code for potential issues and returns results
/// - Parameter code: The source code to analyze
/// - Returns: Array of analysis results with issues found
/// - Throws: AnalysisError if code cannot be parsed
func analyzeCode(_ code: String) throws -> [AnalysisResult] {
    // Implementation
}
```

## 🧪 Testing Guidelines

### Unit Tests
- Test all public methods
- Use descriptive test names
- Follow Given-When-Then pattern
- Mock external dependencies

```swift
func testAnalyzeCode_WithValidSwiftCode_ReturnsExpectedResults() {
    // Given
    let code = "func example() { return }"
    let analyzer = CodeAnalyzer()
    
    // When
    let results = try! analyzer.analyzeCode(code)
    
    // Then
    XCTAssertEqual(results.count, 0)
}
```

### Integration Tests
- Test complete workflows
- Use real data when possible
- Verify UI interactions

### Performance Tests
- Measure analysis time for large files
- Monitor memory usage
- Set performance baselines

## 📋 Pull Request Process

### Before Submitting
1. **Code Quality**
   - [ ] Code follows style guidelines
   - [ ] All tests pass
   - [ ] No SwiftLint warnings
   - [ ] Self-review completed
   - [ ] **VALIDATION_RULES.md checklist completed**
   - [ ] **Architecture boundaries respected (see ARCHITECTURE.md)**
   - [ ] **Type implementation complete (no bandaid fixes)**

2. **CodingReviewer-Specific Validation (August 8, 2025)**
   - [ ] No SwiftUI imports in SharedTypes/ folder
   - [ ] No Codable conformance in complex nested types
   - [ ] All new types implement complete property sets
   - [ ] Platform compatibility verified (macOS/iOS if applicable)
   - [ ] Optional handling uses safe patterns only
   - [ ] No force unwrapping in production code
   - [ ] Sendable conformance for concurrent data models
   - [ ] Complete protocol conformance implementations

3. **Documentation**
   - [ ] README updated if needed
   - [ ] Code comments added
   - [ ] API documentation updated
   - [ ] **Architecture impact documented if significant**

3. **Testing**
   - [ ] Unit tests for new code
   - [ ] Integration tests if applicable
   - [ ] Manual testing completed

### Pull Request Template
Use the provided PR template and fill out all relevant sections:
- Clear description of changes
- Link to related issues
- Testing information
- Screenshots if UI changes

### Review Process
1. Automated checks must pass (CI/CD)
2. Code review by maintainers
3. Address feedback and make changes
4. Final approval and merge

## 🐛 Bug Triage

### Severity Levels
- **Critical**: Crashes, data loss, security issues
- **High**: Major feature broken, significant performance impact
- **Medium**: Minor feature issues, minor performance impact
- **Low**: Cosmetic issues, nice-to-have improvements

### Priority Labels
- `P0`: Fix immediately
- `P1`: Fix in current release
- `P2`: Fix in next release
- `P3`: Fix when time permits

## 🚀 Release Process

### Version Numbers
- Follow [Semantic Versioning](https://semver.org/)
- Format: `MAJOR.MINOR.PATCH`
- Pre-release: `1.0.0-beta.1`

### Release Branches
- `main`: Stable release code
- `develop`: Integration branch for features
- `feature/*`: Individual feature branches
- `release/*`: Release preparation branches
- `hotfix/*`: Critical bug fixes

### Release Checklist
- [ ] All features completed and tested
- [ ] Documentation updated
- [ ] Version number updated
- [ ] Release notes prepared
- [ ] Testing completed
- [ ] App Store submission (if applicable)

## 🎯 Project Structure

```
CodingReviewer/
├── CodingReviewer/          # Main app source
│   ├── Core/                # Core functionality
│   ├── UI/                  # User interface
│   ├── Models/              # Data models
│   └── Resources/           # Assets and resources
├── CodingReviewerTests/     # Unit tests
├── CodingReviewerUITests/   # UI tests
├── Documentation/           # Project documentation
└── Scripts/                 # Build and utility scripts
```

## 📞 Getting Help

### Communication Channels
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Email**: maintainers@codereviewer.app

### Resources
- [Swift Documentation](https://swift.org/documentation/)
- [Xcode User Guide](https://developer.apple.com/xcode/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)

## 📄 License

By contributing to CodeReviewer, you agree that your contributions will be licensed under the same license as the project (MIT License).

## 🙏 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for their contributions
- Special recognition for significant contributions

Thank you for contributing to CodeReviewer! 🎉
