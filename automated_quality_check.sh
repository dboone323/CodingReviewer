#!/bin/bash

# Automated Code Quality Dashboard for CodingReviewer
# This script leverages MCP capabilities for comprehensive analysis

set -e

PROJECT_ROOT="/Users/danielstevens/Desktop/CodingReviewer"
REPORT_DIR="$PROJECT_ROOT/quality_reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "🔍 Starting Automated Code Quality Analysis..."

# Create reports directory
mkdir -p "$REPORT_DIR"

# 1. SwiftLint Analysis
echo "📋 Running SwiftLint Analysis..."
if command -v swiftlint &> /dev/null; then
    swiftlint lint --reporter json > "$REPORT_DIR/swiftlint_$TIMESTAMP.json" || true
    swiftlint lint > "$REPORT_DIR/swiftlint_$TIMESTAMP.txt" || true
    echo "✅ SwiftLint analysis complete"
else
    echo "⚠️ SwiftLint not installed. Install with: brew install swiftlint"
fi

# 2. Build Analysis
echo "🔨 Running Build Analysis..."
xcodebuild -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' clean build 2>&1 | tee "$REPORT_DIR/build_$TIMESTAMP.log"

# 3. Test Analysis
echo "🧪 Running Test Suite..."
xcodebuild test -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' 2>&1 | tee "$REPORT_DIR/tests_$TIMESTAMP.log"

# 4. Code Metrics
echo "📊 Calculating Code Metrics..."
find CodingReviewer -name "*.swift" -exec wc -l {} + > "$REPORT_DIR/code_metrics_$TIMESTAMP.txt"

# 5. Generate Summary Report
echo "📝 Generating Summary Report..."
cat > "$REPORT_DIR/summary_$TIMESTAMP.md" << EOF
# Code Quality Report - $TIMESTAMP

## Overview
- **Analysis Date**: $(date)
- **Project**: CodingReviewer
- **Branch**: $(git branch --show-current)
- **Commit**: $(git rev-parse --short HEAD)

## Files Analyzed
\`\`\`
$(find CodingReviewer -name "*.swift" | wc -l) Swift files
$(find CodingReviewer -name "*.swift" -exec wc -l {} + | tail -1)
\`\`\`

## SwiftLint Results
$(if [ -f "$REPORT_DIR/swiftlint_$TIMESTAMP.txt" ]; then cat "$REPORT_DIR/swiftlint_$TIMESTAMP.txt" | head -20; fi)

## Next Steps
- Review SwiftLint violations
- Address any build warnings
- Ensure all tests pass
- Consider automated fixes where applicable
EOF

echo "✅ Quality analysis complete! Reports saved to $REPORT_DIR"
echo "📊 Summary report: $REPORT_DIR/summary_$TIMESTAMP.md"

# Optional: Open the report
open "$REPORT_DIR/summary_$TIMESTAMP.md"
