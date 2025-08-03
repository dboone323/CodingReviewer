#!/bin/bash

# Comprehensive Swift 6 concurrency fixes
echo "🔧 Comprehensive Swift 6 concurrency fixes..."

# Fix all CodingKeys conformances with @preconcurrency
find . -name "*.swift" -type f | while read -r file; do
    if grep -q "enum.*CodingKeys.*CodingKey" "$file"; then
        echo "Fixing CodingKeys in: $file"
        sed -i '' 's/enum \(.*CodingKeys.*\): String, CodingKey/enum \1: String, @preconcurrency CodingKey/g' "$file"
    fi
done

# Fix structs with Identifiable, Sendable, Codable patterns
find . -name "*.swift" -type f | while read -r file; do
    if grep -q "struct.*: Identifiable, Sendable, Codable" "$file"; then
        echo "Fixing Identifiable+Codable in: $file"
        sed -i '' 's/struct \([^:]*\): Identifiable, Sendable, Codable/struct \1: Identifiable, Sendable, @preconcurrency Codable/g' "$file"
    fi
done

# Fix additional Codable patterns we missed
find . -name "*.swift" -type f | while read -r file; do
    # Fix enum: Codable patterns
    if grep -q "enum.*: Codable" "$file"; then
        echo "Fixing enum Codable in: $file"
        sed -i '' 's/enum \([^:]*\): Codable/enum \1: @preconcurrency Codable/g' "$file"
    fi
    
    # Fix struct: Codable patterns (not already handled)
    if grep -q "struct.*: Codable$" "$file"; then
        echo "Fixing standalone Codable in: $file"
        sed -i '' 's/struct \([^:]*\): Codable$/struct \1: @preconcurrency Codable/g' "$file"
    fi
done

echo "✅ All concurrency fixes applied!"

# Test compilation
echo "🧪 Testing compilation..."
xcodebuild -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' build -quiet && echo "✅ Build successful!" || echo "❌ Build failed - additional fixes needed"
