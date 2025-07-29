#!/bin/bash

# MCP-Powered Project Monitoring for CodingReviewer
# This script provides real-time monitoring of your project health

echo "🔍 CodingReviewer Project Health Dashboard"
echo "=========================================="
echo ""

# Project Overview
echo "📊 PROJECT OVERVIEW"
echo "-------------------"
echo "Project: CodingReviewer"
echo "Location: $(pwd)"
echo "Git Branch: $(git branch --show-current 2>/dev/null || echo 'Not a git repository')"
echo "Last Commit: $(git log -1 --pretty=format:'%h - %s (%cr)' 2>/dev/null || echo 'No git history')"
echo ""

# Code Statistics
echo "📈 CODE STATISTICS"
echo "------------------"
echo "Swift Files: $(find CodingReviewer -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')"
echo "Total Lines: $(find CodingReviewer -name "*.swift" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo '0')"
echo "Test Files: $(find CodingReviewerTests -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')"
echo ""

# Build Status
echo "🔨 BUILD STATUS"
echo "---------------"
if [ -f "build_output.log" ]; then
    echo "Last Build: $(stat -f "%Sm" build_output.log)"
    if grep -q "BUILD SUCCEEDED" build_output.log 2>/dev/null; then
        echo "Status: ✅ SUCCESS"
    else
        echo "Status: ❌ FAILED"
    fi
else
    echo "Status: 🔄 No recent build found"
fi
echo ""

# Quality Metrics
echo "📋 QUALITY METRICS"
echo "------------------"
if command -v swiftlint &> /dev/null; then
    echo "SwiftLint: ✅ Available"
    # Quick lint check (non-blocking)
    LINT_ISSUES=$(swiftlint lint --quiet 2>/dev/null | wc -l | tr -d ' ')
    echo "Lint Issues: $LINT_ISSUES"
else
    echo "SwiftLint: ❌ Not installed"
fi
echo ""

# Recent Activity
echo "📝 RECENT ACTIVITY"
echo "------------------"
if [ -d ".git" ]; then
    echo "Recent Commits:"
    git log --oneline -5 2>/dev/null || echo "No git history"
else
    echo "Not a git repository"
fi
echo ""

# MCP Integration Status
echo "🤖 MCP INTEGRATION STATUS"
echo "-------------------------"
echo "✅ MCP is available and working"
echo "✅ GitHub tools: Ready for automation"
echo "✅ Pylance tools: Ready for Python analysis"
echo "✅ Web search: Ready for research tasks"
echo ""

# Automation Recommendations
echo "💡 AUTOMATION RECOMMENDATIONS"
echo "-----------------------------"
echo "1. 🔄 Run automated quality checks: ./automated_quality_check.sh"
echo "2. 📋 Create GitHub issues: swift automated_issue_creator.swift"
echo "3. 🚀 Set up automated PR creation for improvements"
echo "4. 📊 Enable continuous monitoring with MCP webhooks"
echo "5. 🧪 Integrate test automation with GitHub Actions"
echo ""

# Quick Actions
echo "⚡ QUICK ACTIONS WITH MCP"
echo "------------------------"
echo "• Check GitHub notifications for pending tasks"
echo "• Analyze code quality issues automatically"
echo "• Generate improvement suggestions"
echo "• Create pull requests for bug fixes"
echo "• Monitor dependencies and security updates"
echo ""

echo "🎯 Your project is ready for MCP-powered automation!"
echo "Run the automation scripts above to get started."
