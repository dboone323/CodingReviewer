#!/bin/bash

# Simple Code Quality Fixer for Swift 6 Project
echo "🧹 Applying code quality fixes..."

# Fix force unwrapping issues
echo "Fixing force unwrapping..."
find CodingReviewer -name "*.swift" -type f | while read -r file; do
    # Replace simple force unwrapping with safe optional handling where appropriate
    if grep -q "!" "$file"; then
        echo "  Checking force unwrapping in: $(basename "$file")"
        # This is a conservative approach - we'll identify them but not auto-fix
        # since force unwrapping may be intentional in some cases
    fi
done

# Fix print statements (replace with logger)
echo "Fixing print statements..."
find CodingReviewer -name "*.swift" -type f | while read -r file; do
    if grep -q "print(" "$file"; then
        echo "  Replacing print statements in: $(basename "$file")"
        # Replace print() with AppLogger.shared.info()
        sed -i '' 's/print(\(.*\))/AppLogger.shared.info(\1)/g' "$file"
    fi
done

# Fix line length issues by adding line breaks at logical points
echo "Checking line length issues..."
find CodingReviewer -name "*.swift" -type f | while read -r file; do
    if awk 'length > 120' "$file" | head -1 > /dev/null 2>&1; then
        echo "  Long lines found in: $(basename "$file")"
        # We'll identify but not auto-fix line length as it requires manual review
    fi
done

# Remove trailing whitespace
echo "Removing trailing whitespace..."
find CodingReviewer -name "*.swift" -type f -exec sed -i '' 's/[[:space:]]*$//' {} \;

# Ensure files end with newline
echo "Ensuring files end with newline..."
find CodingReviewer -name "*.swift" -type f | while read -r file; do
    if [[ -n "$(tail -c1 "$file")" ]]; then
        echo "" >> "$file"
    fi
done

echo "✅ Basic code quality fixes applied!"

# Test build to ensure fixes don't break anything
echo "🧪 Testing build after quality fixes..."
if xcodebuild -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' build -quiet; then
    echo "✅ Build successful after quality fixes!"
else
    echo "❌ Build failed after quality fixes"
fi
