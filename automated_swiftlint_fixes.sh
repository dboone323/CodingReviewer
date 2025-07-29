#!/bin/bash

# Automated SwiftLint Quick Fixes for CodingReviewer
# This script implements immediate automated fixes for common SwiftLint violations

echo "🔧 Starting Automated SwiftLint Quick Fixes..."
echo "=============================================="

# Backup current state
echo "📋 Creating backup..."
git add -A
git commit -m "Pre-automated-fixes backup" || true

# Count current violations
echo "📊 Current SwiftLint violations:"
BEFORE_COUNT=$(swiftlint lint --quiet 2>/dev/null | wc -l | tr -d ' ')
echo "   Before fixes: $BEFORE_COUNT violations"

# 1. Fix trailing newlines and whitespace
echo ""
echo "🧹 Phase 1: Cleaning up whitespace and newlines..."
echo "------------------------------------------------"

# Remove trailing whitespace
find CodingReviewer -name "*.swift" -exec sed -i '' 's/[[:space:]]*$//' {} \;
echo "✅ Removed trailing whitespace"

# Ensure single trailing newline
find CodingReviewer -name "*.swift" -exec sed -i '' -e '$a\' {} \;
echo "✅ Fixed trailing newlines"

# 2. Run SwiftLint autocorrect
echo ""
echo "🤖 Phase 2: Running SwiftLint autocorrect..."
echo "--------------------------------------------"
if command -v swiftlint &> /dev/null; then
    swiftlint autocorrect --path CodingReviewer/ || true
    echo "✅ SwiftLint autocorrect completed"
else
    echo "⚠️ SwiftLint not found. Install with: brew install swiftlint"
fi

# 3. Replace print statements with AppLogger
echo ""
echo "🔍 Phase 3: Replacing print statements with proper logging..."
echo "------------------------------------------------------------"

# Count print statements before
PRINT_COUNT_BEFORE=$(grep -r "print(" CodingReviewer --include="*.swift" | wc -l | tr -d ' ')
echo "   Found $PRINT_COUNT_BEFORE print statements"

# Replace print statements (but preserve print statements in comments or strings)
find CodingReviewer -name "*.swift" -exec sed -i '' 's/^\([[:space:]]*\)print(/\1AppLogger.shared.debug(/g' {} \;

# Count print statements after
PRINT_COUNT_AFTER=$(grep -r "print(" CodingReviewer --include="*.swift" | wc -l | tr -d ' ')
echo "✅ Replaced $(($PRINT_COUNT_BEFORE - $PRINT_COUNT_AFTER)) print statements"

# 4. Fix redundant discardable let
echo ""
echo "🗑️  Phase 4: Fixing redundant discardable let..."
echo "------------------------------------------------"
find CodingReviewer -name "*.swift" -exec sed -i '' 's/let _ = /_ = /g' {} \;
echo "✅ Fixed redundant discardable let statements"

# 5. Add import AppLogger if needed
echo ""
echo "📦 Phase 5: Adding AppLogger imports where needed..."
echo "---------------------------------------------------"

# Find files that use AppLogger.shared but don't import AppLogger
for file in $(find CodingReviewer -name "*.swift"); do
    if grep -q "AppLogger\.shared" "$file" && ! grep -q "import.*AppLogger" "$file"; then
        # Add import after other imports
        sed -i '' '1,/^import /s/\(^import .*\)/\1\
import AppLogger/' "$file" 2>/dev/null || true
    fi
done
echo "✅ Added AppLogger imports where needed"

# 6. Check results
echo ""
echo "📊 Analyzing results..."
echo "----------------------"

# Count violations after fixes
AFTER_COUNT=$(swiftlint lint --quiet 2>/dev/null | wc -l | tr -d ' ')
FIXED_COUNT=$(($BEFORE_COUNT - $AFTER_COUNT))

echo "   Before fixes: $BEFORE_COUNT violations"
echo "   After fixes:  $AFTER_COUNT violations"
echo "   Fixed:        $FIXED_COUNT violations"

if [ $FIXED_COUNT -gt 0 ]; then
    echo "🎉 Successfully fixed $FIXED_COUNT SwiftLint violations!"
    
    # Commit the fixes
    git add -A
    git commit -m "🤖 Automated SwiftLint fixes: resolved $FIXED_COUNT violations

- Fixed trailing whitespace and newlines
- Replaced print statements with AppLogger
- Fixed redundant discardable let statements
- Added missing imports
- Applied SwiftLint autocorrect

Violations reduced from $BEFORE_COUNT to $AFTER_COUNT"
    
    echo "✅ Changes committed to git"
else
    echo "ℹ️  No additional violations were fixed"
fi

# 7. Generate updated report
echo ""
echo "📋 Generating updated quality report..."
echo "--------------------------------------"
./automated_quality_check.sh > /dev/null 2>&1

echo ""
echo "🎯 Next Steps:"
echo "- Review remaining $AFTER_COUNT violations"
echo "- Run complex function refactoring (requires manual review)"
echo "- Set up automated quality gates in CI/CD"
echo "- Create pull request with these improvements"

echo ""
echo "✅ Automated SwiftLint fixes completed!"
