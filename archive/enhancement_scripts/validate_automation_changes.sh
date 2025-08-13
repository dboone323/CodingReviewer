#!/bin/bash

# 🔍 Automation Changes Validator
# Validates that automation scripts don't introduce new problems

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"

echo "🔍 AUTOMATION CHANGES VALIDATOR"
echo "==============================="

# Check for common problematic patterns introduced by automation
check_problematic_patterns() {
    echo "🔍 Checking for problematic patterns..."
    
    local issues_found=0
    
    # 1. Check for incorrect self?. in initializers
    echo "  Checking for self?. in initializers..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -l "init(" {} \; | xargs grep -n "self?\." | grep -v "weak self"; then
        echo "  ❌ Found self?. in initializers (should be self.)"
        issues_found=$((issues_found + 1))
    else
        echo "  ✅ No self?. issues in initializers"
    fi
    
    # 2. Check for incorrect self?. in MainActor.run blocks
    echo "  Checking for self?. in MainActor.run blocks..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec awk '/MainActor\.run/,/^[[:space:]]*}/ { if (/self\?\. / && !/weak self/) print FILENAME ":" NR ":" $0 }' {} \; | head -5; then
        echo "  ⚠️  Found potential self?. issues in MainActor.run blocks"
        issues_found=$((issues_found + 1))
    else
        echo "  ✅ No self?. issues in MainActor.run blocks"
    fi
    
    # 3. Check for missing return types causing optional issues
    echo "  Checking for missing return types..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -n "-> .*?" {} \; | head -3; then
        echo "  ⚠️  Found functions returning optionals - may need unwrapping"
    else
        echo "  ✅ No obvious optional return type issues"
    fi
    
    # 4. Check for syntax errors that automation might introduce
    echo "  Checking for potential syntax errors..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -n "await.*?\..*(" {} \; | head -3; then
        echo "  ⚠️  Found potential await + optional chaining issues"
        issues_found=$((issues_found + 1))
    else
        echo "  ✅ No obvious await + optional chaining issues"
    fi
    
    return $issues_found
}

# Run the checks
check_problematic_patterns
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    echo ""
    echo "✅ All automation validation checks passed!"
else
    echo ""
    echo "⚠️  Found $exit_code categories of issues that need attention"
    echo "Run the improved automation scripts to fix these issues"
fi

exit $exit_code
