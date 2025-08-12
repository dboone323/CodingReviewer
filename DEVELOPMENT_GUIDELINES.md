# CodingReviewer Development Guidelines

## Code Quality Standards (August 8, 2025)

### Derived from 81→0 Error Resolution Success

## 1. Type Design Principles

### **Strategic Implementation Over Quick Fixes**
```swift
// ✅ STRATEGIC - Complete implementation from start
struct ProcessingJob: Identifiable, Sendable, Comparable {
    // ALL properties needed for complete functionality
    let id: UUID
    let type: JobType
    var status: JobStatus = .pending
    var progress: Double = 0.0
    var errorMessage: String?
    var startTime: Date?
    var completionTime: Date?
    
    // COMPLETE protocol conformance
    static func < (lhs: ProcessingJob, rhs: ProcessingJob) -> Bool {
        lhs.priority.rawValue < rhs.priority.rawValue
    }
}

// ❌ BANDAID - Leads to cascading errors
struct ProcessingJob: Identifiable {
    let id: UUID
    // Missing properties will cause errors later
}
```

### **Mutability Design Pattern**
```swift
// ✅ CLEAR SEPARATION
struct DataModel: Sendable {
    let id: UUID                    // Immutable identity
    let createdAt: Date            // Immutable metadata
    var status: Status             // Mutable runtime state
    var progress: Double           // Mutable runtime tracking
    var lastUpdated: Date          // Mutable timestamps
}
```

## 2. Concurrency Guidelines

### **Sendable vs Codable Decision Matrix**
| Use Case | Recommended Approach | Rationale |
|----------|---------------------|-----------|
| Data models in concurrent contexts | `Sendable` only | Thread safety without circular refs |
| Simple configuration | `Codable` only | No concurrency conflicts |
| Complex nested types | Neither initially | Add protocols after validation |
| Enterprise analytics | `Sendable` preferred | Concurrent data collection needs |

### **Background Processing Pattern**
```swift
// ✅ PROVEN PATTERN
class BackgroundProcessor {
    private let jobQueue = DispatchQueue(label: "processing", qos: .utility)
    
    func processJob(_ job: ProcessingJob) {
        jobQueue.async { [weak self] in
            // Background work here
            let result = self?.performWork(job)
            
            Task { @MainActor [weak self] in
                // UI updates on main thread
                self?.updateUI(with: result)
            }
        }
    }
}
```

## 3. Optional Handling Standards

### **Safe Optional Patterns**
```swift
// ✅ SAFE ARRAY PROCESSING
let validItems = items.compactMap { item in
    guard item.isValid else { return nil }
    return processedItem(from: item)
}

// ✅ SAFE URL CREATION
guard let url = URL(string: urlString) else {
    throw NetworkError.invalidURL(urlString)
}

// ✅ SAFE TIMING CALCULATIONS
func calculateDuration(from startTime: Date?) -> TimeInterval? {
    guard let startTime = startTime else { return nil }
    return Date().timeIntervalSince(startTime)
}

// ❌ DANGEROUS PATTERNS TO AVOID
let url = URL(string: urlString)!  // Force unwrap
let items = items.map { $0! }      // Force unwrap in map
```

## 4. SwiftUI Platform Guidelines

### **Cross-Platform UI Patterns**
```swift
// ✅ PLATFORM AGNOSTIC
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button("Save") { save() }
    }
}

// ✅ CONDITIONAL PLATFORM CODE
#if os(macOS)
.frame(minWidth: 800, minHeight: 600)
#else
.navigationBarTitleDisplayMode(.inline)
#endif

// ❌ PLATFORM-SPECIFIC CODE WITHOUT GUARDS
.navigationBarItems(trailing: saveButton)  // iOS only
```

### **Capture Semantics Rules**
```swift
// ✅ CLASS CONTEXTS - Use weak self
class ViewController {
    func setupTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateUI()
        }
    }
}

// ✅ STRUCT CONTEXTS - Direct capture
struct DataProcessor {
    func processInBackground() {
        DispatchQueue.global().async {
            // No need for [weak self] in structs
            processData()
        }
    }
}
```

## 5. Error Handling Patterns

### **Comprehensive Error Management**
```swift
// ✅ COMPLETE ERROR HANDLING
enum ProcessingError: Error, LocalizedError {
    case invalidInput(String)
    case processingFailed(underlying: Error)
    case systemResourceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let input):
            return "Invalid input: \(input)"
        case .processingFailed(let error):
            return "Processing failed: \(error.localizedDescription)"
        case .systemResourceUnavailable:
            return "System resources unavailable"
        }
    }
}

// ✅ PROPER ERROR PROPAGATION
func processData() throws -> ProcessedData {
    guard isValidInput() else {
        throw ProcessingError.invalidInput("Data validation failed")
    }
    
    do {
        return try performProcessing()
    } catch {
        throw ProcessingError.processingFailed(underlying: error)
    }
}
```

## 6. Testing Guidelines

### **Testable Architecture Patterns**
```swift
// ✅ DEPENDENCY INJECTION FOR TESTING
protocol ProcessingService {
    func process(_ job: ProcessingJob) throws -> ProcessingResult
}

class ProductionProcessor: ProcessingService {
    func process(_ job: ProcessingJob) throws -> ProcessingResult {
        // Real implementation
    }
}

class MockProcessor: ProcessingService {
    func process(_ job: ProcessingJob) throws -> ProcessingResult {
        // Test implementation
    }
}
```

## 7. Performance Guidelines

### **System Resource Management**
```swift
// ✅ EFFICIENT RESOURCE TRACKING
struct SystemLoad: Sendable {
    let timestamp: Date
    var cpuUsage: Double
    var memoryUsage: Double
    var diskUsage: Double
    
    mutating func update() {
        cpuUsage = SystemMonitor.currentCPU()
        memoryUsage = SystemMonitor.currentMemory()
        diskUsage = SystemMonitor.currentDisk()
    }
}
```

## 8. Code Review Checklist

### **Pre-Commit Validation**
- [ ] **Type Completeness**: All required properties implemented?
- [ ] **Protocol Conformance**: Complete implementation of all protocols?
- [ ] **Concurrency Safety**: Sendable conformance where needed?
- [ ] **Optional Safety**: All optionals handled with guard/compactMap?
- [ ] **Platform Compatibility**: Code works on target platforms?
- [ ] **Error Handling**: Comprehensive error cases covered?
- [ ] **Capture Semantics**: Appropriate weak/strong references?
- [ ] **Mutability Clarity**: Clear let vs var usage?
- [ ] **Testing**: Unit tests for complex logic?
- [ ] **Documentation**: Public interfaces documented?

## 9. Debugging Methodology

### **Systematic Error Resolution**
1. **Pattern Analysis**: Group similar errors by root cause
2. **Strategic Implementation**: Fix fundamental design, not symptoms
3. **Incremental Validation**: Build after each logical group
4. **Architecture Alignment**: Ensure fixes support overall design
5. **Regression Prevention**: Add tests for fixed issues

### **Error Classification System**
- **Type Errors**: Missing properties, incomplete protocols
- **Concurrency Errors**: MainActor conflicts, Sendable issues
- **Platform Errors**: API compatibility, framework usage
- **Logic Errors**: Optional handling, data flow
- **Architecture Errors**: Circular dependencies, layer violations

## 10. Success Metrics

### **Build Quality Indicators**
- Zero compilation errors on first attempt
- Clean architecture with clear separation
- No warnings in release builds
- Consistent code patterns across modules
- Stable performance under load

### **Code Quality Metrics**
- Protocol conformance completeness: 100%
- Optional safety coverage: 100%
- Platform compatibility tests: Pass
- Architecture rule compliance: 100%
- Error handling coverage: Complete

## Implementation Strategy

**When facing multiple errors:**
1. Don't apply quick fixes
2. Analyze patterns and root causes
3. Implement complete solutions
4. Validate architecture alignment
5. Test incrementally

**Result:** This methodology successfully reduced 81 compilation errors to 0 and achieved a stable, functioning application.

## Conclusion

These guidelines represent proven patterns derived from successfully resolving complex compilation issues through strategic implementation rather than bandaid fixes. Following these patterns prevents the fix-rollback cycle and ensures stable, maintainable code.

**Key Principle:** Implement it right the first time, and you won't need to fix fixes later.
