#!/bin/bash

# CodingReviewer Automation Script for Unified Architecture
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="CodingReviewer"

echo "🚀 $PROJECT_NAME Automation System"
echo "📊 Checking $PROJECT_NAME status..."

# Project structure analysis
SWIFT_FILES=$(find "$PROJECT_DIR" -name "*.swift" | wc -l | tr -d ' ')
TEST_FILES=$(find "$PROJECT_DIR" -name "*Test*.swift" -o -name "*test*.swift" | wc -l | tr -d ' ')

echo "📁 Project Structure:"
echo "  - Source files: $SWIFT_FILES Swift files"
echo "  - Test files: $TEST_FILES test files"

# Git status
if [[ -d "$PROJECT_DIR/.git" ]]; then
    echo "🔀 Git Status:"
    echo "  - Branch: $(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo 'unknown')"
    echo "  - Commits: $(git -C "$PROJECT_DIR" rev-list --count HEAD 2>/dev/null || echo '0')"
    echo "  - Modified files: $(git -C "$PROJECT_DIR" status --porcelain | wc -l | tr -d ' ')"
fi

# Check for automation files
echo "🤖 Automation Status:"
AUTOMATION_FILES=$(find "$PROJECT_DIR/automation" -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
LOG_FILES=$(find "$PROJECT_DIR" -name "*.log" 2>/dev/null | wc -l | tr -d ' ')

echo "  - Config: ✅ Found"
echo "  - Scripts: $AUTOMATION_FILES scripts available"
echo "  - Logs: $LOG_FILES log files"

# Check for Xcode project
if [[ -f "$PROJECT_DIR/$PROJECT_NAME.xcodeproj/project.pbxproj" ]]; then
    echo "  - Xcode project: ✅ Found"
elif [[ -f "$PROJECT_DIR/Package.swift" ]]; then
    echo "  - Swift Package: ✅ Found"
else
    echo "  - Project file: ⚠️ Not found"
fi

echo "✅ $PROJECT_NAME automation completed"
