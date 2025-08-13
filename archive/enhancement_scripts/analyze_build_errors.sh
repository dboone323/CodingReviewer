#!/bin/bash

# 📊 Intelligent Build Error Analyzer
# Categorizes and prioritizes build errors for efficient fixing

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"

echo "📊 INTELLIGENT BUILD ERROR ANALYZER"
echo "===================================="

# Run build and capture errors
echo "🔍 Analyzing current build errors..."
BUILD_OUTPUT=$(xcodebuild -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS,arch=arm64' build 2>&1)

# Count total errors
TOTAL_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "error:" || echo "0")
echo "📊 Total errors found: $TOTAL_ERRORS"

if [[ $TOTAL_ERRORS -eq 0 ]]; then
    echo "✅ BUILD SUCCEEDED! No errors found."
    exit 0
fi

echo ""
echo "🔍 Error Analysis:"

# Categorize errors
echo "  Analyzing error types..."

# Optional chaining errors
OPT_CHAIN_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "cannot use optional chaining on non-optional" || echo "0")
if [[ $OPT_CHAIN_ERRORS -gt 0 ]]; then
    echo "  🔗 Optional Chaining: $OPT_CHAIN_ERRORS errors"
    echo "     Fix: Run ./fix_optional_chaining.sh"
fi

# Type conversion errors
TYPE_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "cannot convert value of type" || echo "0")
if [[ $TYPE_ERRORS -gt 0 ]]; then
    echo "  🔄 Type Conversion: $TYPE_ERRORS errors"
    echo "     Fix: Check return types and optional unwrapping"
fi

# Missing symbol errors
MISSING_SYMBOLS=$(echo "$BUILD_OUTPUT" | grep -c "cannot find.*in scope" || echo "0")
if [[ $MISSING_SYMBOLS -gt 0 ]]; then
    echo "  🔍 Missing Symbols: $MISSING_SYMBOLS errors"
    echo "     Fix: Add missing variables/imports"
fi

# Syntax errors
SYNTAX_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "expected.*declaration\|unexpected.*identifier" || echo "0")
if [[ $SYNTAX_ERRORS -gt 0 ]]; then
    echo "  📝 Syntax Errors: $SYNTAX_ERRORS errors"
    echo "     Fix: Check file structure and syntax"
fi

echo ""
echo "🎯 Recommended fix order:"
echo "  1. Fix syntax errors first (they can mask other issues)"
echo "  2. Run optional chaining fixes"
echo "  3. Address missing symbols"
echo "  4. Handle type conversion issues"

# Show specific files with most errors
echo ""
echo "📁 Files with most errors:"
echo "$BUILD_OUTPUT" | grep "error:" | awk -F: '{print $1}' | sort | uniq -c | sort -nr | head -5 | while read count file; do
    echo "  $count errors: $(basename "$file")"
done

