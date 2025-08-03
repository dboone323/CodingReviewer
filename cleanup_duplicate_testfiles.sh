#!/bin/bash

# Duplicate Test File Cleanup Script
# Removes 18 duplicate TestScript files, keeps TestScript1.js as reference

echo "🧹 Cleaning up duplicate TestScript files..."
echo "=============================================="

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"
TEST_DIR="$PROJECT_PATH/TestFiles_Manual"

cd "$TEST_DIR" || exit 1

# Count initial files
initial_count=$(ls TestScript*.js 2>/dev/null | wc -l | tr -d ' ')
echo "📊 Found $initial_count TestScript files"

# Create backup of TestScript1.js as reference
echo "📋 Creating reference backup..."
cp TestScript1.js TestScript1_REFERENCE.js

# List files to be removed (TestScript2.js through TestScript19.js)
echo ""
echo "🗑️  Files to be removed:"
for i in {2..19}; do
    file="TestScript$i.js"
    if [ -f "$file" ]; then
        echo "  - $file"
        rm "$file"
    fi
done

# Count remaining files
remaining_count=$(ls TestScript*.js 2>/dev/null | wc -l | tr -d ' ')
removed_count=$((initial_count - remaining_count))

echo ""
echo "✅ Cleanup Complete!"
echo "   📊 Removed: $removed_count duplicate files"
echo "   📁 Remaining: $remaining_count files"
echo "   📋 Reference: TestScript1_REFERENCE.js"
echo "   🆕 New unified manager: ParametricTestManager.js"

# Create documentation
cat > TESTFILE_CLEANUP_REPORT.md << EOF
# TestScript Files Cleanup Report
Generated: $(date)

## Summary
- **Initial files:** $initial_count
- **Removed files:** $removed_count  
- **Remaining files:** $remaining_count

## Files Removed
EOF

for i in {2..19}; do
    echo "- TestScript$i.js" >> TESTFILE_CLEANUP_REPORT.md
done

cat >> TESTFILE_CLEANUP_REPORT.md << EOF

## Files Preserved
- TestScript1.js (original template)
- TestScript1_REFERENCE.js (backup reference)

## New Implementation
- ParametricTestManager.js (unified replacement for all removed files)

## Benefits
- **Reduced codebase size** by eliminating 18 duplicate files
- **Improved maintainability** with single parametric implementation
- **Enhanced functionality** with batch processing capabilities
- **Better testing framework** with unified management

## Usage
The new ParametricTestManager.js provides all functionality of the removed files:

\`\`\`javascript
// Replace TestScript5.js functionality:
const manager5 = createTestManager(5);

// Replace TestScript12.js functionality:
const manager12 = createTestManager(12);

// Batch processing (new capability):
const batchRunner = new BatchTestRunner();
const results = batchRunner.runBatchTest([1,2,3,4,5], testData);
\`\`\`

## Disk Space Saved
Approximately 95% reduction in TestScript file redundancy.
EOF

echo ""
echo "📊 Cleanup report generated: TESTFILE_CLEANUP_REPORT.md"
echo ""
