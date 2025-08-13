#!/bin/bash

# Fix Codable conformance issues for Swift 6 strict concurrency
# This fixes all struct/enum: Codable, Sendable patterns

echo "🔧 Fixing Codable conformances for Swift 6..."

# Find all Swift files with Codable, Sendable conformances
find . -name "*.swift" -type f | while read -r file; do
    if grep -q "struct.*: Codable, Sendable" "$file" || grep -q "enum.*: Codable, Sendable" "$file"; then
        echo "Processing: $file"
        
        # Replace struct: Codable, Sendable with @preconcurrency
        sed -i '' 's/struct \([^:]*\): Codable, Sendable/struct \1: @preconcurrency Codable, Sendable/g' "$file"
        
        # Replace enum: Codable, Sendable with @preconcurrency  
        sed -i '' 's/enum \([^:]*\): Codable, Sendable/enum \1: @preconcurrency Codable, Sendable/g' "$file"
        
        # Handle private struct cases
        sed -i '' 's/private struct \([^:]*\): Codable, Sendable/private struct \1: @preconcurrency Codable, Sendable/g' "$file"
        
        # Handle public struct cases
        sed -i '' 's/public struct \([^:]*\): Codable, Sendable/public struct \1: @preconcurrency Codable, Sendable/g' "$file"
    fi
done

# Fix specific complex cases
echo "🔧 Fixing DocumentationSuggestion..."
if [[ -f "CodingReviewer/SmartDocumentationGenerator.swift" ]]; then
    sed -i '' 's/struct DocumentationSuggestion: Codable, Sendable, Identifiable/struct DocumentationSuggestion: @preconcurrency Codable, Sendable, Identifiable/g' "CodingReviewer/SmartDocumentationGenerator.swift"
fi

echo "✅ Codable conformance fixes completed!"

# Test compilation
echo "🧪 Testing compilation..."
xcodebuild -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' build -quiet && echo "✅ Build successful!" || echo "❌ Build failed - checking errors..."
