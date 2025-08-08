# CodingReviewer Architecture Guidelines

## Core Architectural Decisions (August 7, 2025)

### 1. **Clean Separation of Concerns**

**RULE: Data models NEVER import SwiftUI**
- `SharedTypes/` folder contains pure data models
- UI extensions go in `Extensions/` folder
- This prevents circular dependencies and concurrency issues

### 2. **Synchronous-First Approach**

**DECISION: Use sync operations with background queues, not async/await everywhere**
- Main processing logic runs synchronously on background queues
- SwiftUI updates happen on MainActor via Task { @MainActor in ... }
- Avoids complex concurrency debugging

### 3. **File Organization**

```
CodingReviewer/
├── SharedTypes/           # Pure data models (no UI imports)
│   ├── BackgroundProcessingTypes.swift
│   ├── AnalysisTypes.swift
│   └── ServiceTypes.swift
├── Extensions/            # UI extensions for data models
│   └── BackgroundProcessingUI.swift
├── Components/            # Reusable UI components
├── Views/                 # Main app views
└── Services/              # Business logic services
```

### 4. **Naming Conventions**

**RULE: Avoid generic names like "Dashboard" or "Manager"**
- Use specific names: `OptimizationDashboard`, `EnterpriseAnalyticsDashboard`
- This prevents naming conflicts as the app grows

### 5. **Concurrency Strategy**

**PATTERN: Background processing with MainActor updates**
```swift
// ✅ CORRECT
jobQueue.async { [weak self] in
    // Do background work
    let result = processJob()
    
    Task { @MainActor [weak self] in
        // Update UI on main thread
        self?.updateUI(with: result)
    }
}

// ❌ AVOID
async func processJob() async throws -> Result {
    // Complex async chains lead to debugging nightmares
}
```

### 6. **Color and UI Handling**

**PATTERN: String identifiers in data models, Color extensions in UI files**
```swift
// In SharedTypes (data model)
var colorIdentifier: String { return "blue" }

// In Extensions (UI layer)
var color: Color { 
    switch colorIdentifier {
    case "blue": return .blue
    // ...
    }
}
```

### 7. **Codable Strategy**

**CRITICAL DECISION: Avoid Codable in complex data models**
- Codable creates circular dependencies and concurrency issues
- Use simple property access for data persistence instead
- If serialization is needed, create separate DTO (Data Transfer Object) types
- Keep core data models clean and dependency-free

```swift
// ✅ CORRECT - Clean data model
struct ProcessingJob: Identifiable, Sendable {
    let id: UUID
    let type: JobType
    // ... properties only
}

// ❌ AVOID - Codable causes circular references
struct ProcessingJob: Identifiable, Sendable, Codable {
    // This leads to compiler errors and instability
}
```

## Benefits of This Architecture

1. **No circular dependencies** - Data models don't know about UI or encoding
2. **Easy testing** - Pure data models can be tested independently
3. **Clear boundaries** - Each layer has a single responsibility
4. **Stable builds** - No more back-and-forth fixes
5. **Scalable** - Easy to add new features without breaking existing code
6. **Concurrency safe** - No MainActor conflicts or encoding race conditions

## Migration Strategy

When adding new features:
1. Define data models in `SharedTypes/` first (NO Codable, NO SwiftUI imports)
2. Add UI extensions in `Extensions/` if needed
3. Build UI components that use the extensions
4. Never import SwiftUI in data model files
5. If persistence is needed, create separate serialization logic outside the core models

## Critical Rules to Prevent Issues

**NEVER ADD THESE TO SharedTypes:**
- ❌ `import SwiftUI`
- ❌ `: Codable` conformance
- ❌ `@preconcurrency` (indicates architectural problems)
- ❌ Generic names like "Dashboard" or "Manager"

**ALWAYS DO:**
- ✅ Use `Sendable` for thread safety
- ✅ Use `colorIdentifier: String` instead of `Color`
- ✅ Keep data models pure and simple
- ✅ Use specific, descriptive names

## Automation Strategy

Keep automation scripts **separate** from the main app:
- Background scripts should modify files directly
- Use file system notifications for real-time updates
- Avoid complex inter-process communication

This architecture ensures stability and prevents the fix-rollback cycle we've been experiencing.

## Summary of Changes (August 7, 2025)

**FIXED:** Circular reference and Codable concurrency issues
**SOLUTION:** Removed all Codable conformance from core data models
**RESULT:** Clean, stable architecture with zero compilation errors

**Key insight:** The Codable protocol in Swift 6 with complex nested types creates 
circular dependency issues that are nearly impossible to resolve while maintaining 
clean architecture. By removing Codable and keeping data models pure, we've 
eliminated the root cause of our instability.
