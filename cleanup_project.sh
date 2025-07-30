#!/bin/bash

# CodingReviewer Project Cleanup Script
# Removes backup directories and obsolete automation files

echo "🧹 Starting CodingReviewer Project Cleanup..."
echo "================================================"

# Change to project directory
cd "$(dirname "$0")"

# Count files before cleanup
echo "📊 Analyzing project structure..."
BEFORE_COUNT=$(find . -type f | wc -l)
BEFORE_SIZE=$(du -sh . | cut -f1)
echo "Before cleanup: $BEFORE_COUNT files, $BEFORE_SIZE total"

# Remove backup directories (keeping the most recent one as emergency backup)
echo ""
echo "🗂️  Removing backup directories..."
BACKUP_DIRS=($(ls -d CodingReviewer_backup_* 2>/dev/null | head -n -1))
if [ ${#BACKUP_DIRS[@]} -gt 0 ]; then
    for backup_dir in "${BACKUP_DIRS[@]}"; do
        echo "  Removing: $backup_dir"
        rm -rf "$backup_dir"
    done
    echo "  ✅ Kept most recent backup directory"
else
    echo "  ℹ️  No backup directories to remove"
fi

# Remove refactoring backup directories (keeping the most recent one)
echo ""
echo "🔄 Removing refactoring backup directories..."
REFACTOR_DIRS=($(ls -d CodingReviewer_refactoring_backup_* 2>/dev/null | head -n -1))
if [ ${#REFACTOR_DIRS[@]} -gt 0 ]; then
    for refactor_dir in "${REFACTOR_DIRS[@]}"; do
        echo "  Removing: $refactor_dir"
        rm -rf "$refactor_dir"
    done
    echo "  ✅ Kept most recent refactoring backup"
else
    echo "  ℹ️  No refactoring backup directories to remove"
fi

# Remove old automation scripts that are no longer needed
echo ""
echo "🤖 Cleaning up obsolete automation scripts..."
OBSOLETE_SCRIPTS=(
    "advanced_dependency_manager.sh"
    "advanced_mcp_guide.sh"
    "advanced_mcp_tools_demo.sh"
    "advanced_security_scanner.sh"
    "ai_development_assistant.sh"
    "ai_refactoring_analyzer.sh"
    "apply_refactoring_suggestions.sh"
    "automated_quality_check.sh"
    "automated_security_fixes.sh"
    "automated_swiftlint_fixes.sh"
    "autonomous_code_upgrader.sh"
    "autonomous_code_upgrader_v2.sh"
    "autonomous_code_upgrader_v3.sh"
    "autonomous_enhancement_discovery.sh"
    "autonomous_project_manager.sh"
    "build_success_report.sh"
    "complete_mcp_arsenal.sh"
    "complex_function_refactoring.sh"
    "continuous_enhancement_loop.sh"
    "final_validation.sh"
    "fix_import_issues.sh"
    "github_actions_integration.sh"
    "github_integration_helper.sh"
    "intelligent_automatic_fixes.sh"
    "intelligent_backup_manager.sh"
    "intelligent_build_validator.sh"
    "intelligent_file_scanner.sh"
    "intelligent_project_dashboard.sh"
    "intelligent_test_runner.sh"
    "intelligent_tracker_manager.sh"
    "master_automation_controller.sh"
    "mcp_success_summary.sh"
    "performance_monitoring.sh"
    "project_health_monitor.sh"
    "run_comprehensive_tests.sh"
    "smart_workflow_manager.sh"
    "ultimate_automation_system.sh"
    "ultimate_fix_syntax_errors.sh"
    "ultimate_mcp_automation.sh"
)

for script in "${OBSOLETE_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "  Removing: $script"
        rm -f "$script"
    fi
done

# Remove old hidden automation directories
echo ""
echo "📁 Cleaning up hidden automation directories..."
HIDDEN_DIRS=(
    ".ai_assistant"
    ".auto_fix_backups"
    ".autonomous_discovery"
    ".autonomous_management"
    ".autonomous_upgrades"
    ".backup_archive"
    ".build_validation"
    ".cleanup_automation"
    ".continuous_enhancement"
    ".dependency_management"
    ".file_enhancements"
    ".fix_reports"
    ".master_automation"
    ".master_controller"
    ".test_automation"
    ".tracker_automation"
    ".ultimate_automation"
    ".ultimate_backups"
    ".ultimate_reports"
    ".workflow_automation"
)

for hidden_dir in "${HIDDEN_DIRS[@]}"; do
    if [ -d "$hidden_dir" ]; then
        echo "  Removing: $hidden_dir"
        rm -rf "$hidden_dir"
    fi
done

# Remove obsolete documentation files
echo ""
echo "📄 Cleaning up obsolete documentation..."
OBSOLETE_DOCS=(
    "10_STEPS_AUTOMATION_ROADMAP.md"
    "ADVANCED_AUTOMATION_GUIDE.md"
    "ADVANCED_FEATURES_STATUS.md"
    "AUTOMATION_TIMING_OPTIMIZATION.md"
    "AUTONOMOUS_CODE_UPGRADER_SUCCESS_REPORT.md"
    "AUTONOMOUS_ENHANCEMENT_CAPABILITY_REPORT.md"
    "AUTONOMOUS_SYSTEM_TEST_RESULTS.md"
    "AUTONOMOUS_UPGRADER_LIVE_PERFORMANCE_REPORT.md"
    "BUILD_VALIDATION_REPORT.md"
    "CODE_CLEANUP_IMPROVEMENT_PLAN.md"
    "COMPLETE_AUTOMATION_SUCCESS_REPORT.md"
    "COMPREHENSIVE_IMPLEMENTATION_GUIDE.md"
    "ENHANCED_LOOP_CONTROL_REPORT.md"
    "ENHANCEMENT_PROGRESS_REPORT.md"
    "FILEUPLOAD_EXTRACTION_SUCCESS.md"
    "FILEUPLOAD_INTEGRATION_SUCCESS.md"
    "FINAL_SUCCESS_REPORT.md"
    "FOLDER_UPLOAD_TEST_REPORT.md"
    "IMPLEMENTATION_ROADMAP.md"
    "IMPROVEMENTS_IMPLEMENTATION_SUMMARY.md"
    "IMPROVEMENT_ACTION_PLAN.md"
    "MASTER_ORCHESTRATOR_LIVE_STATUS.md"
    "MCP_AUTOMATION_USER_GUIDE.md"
    "PHASE2_BUILD_SUCCESS_REPORT.md"
    "PHASE2_COMPLETE_SUCCESS_REPORT.md"
    "PHASE_3_COMPLETION_SUMMARY.md"
    "PHASE_3_IMPLEMENTATION_PLAN.md"
    "PHASE_4_COMPLETION_SUCCESS.md"
    "PHASE_4_COMPLETION_SUCCESS_REPORT.md"
    "PHASE_4_FINAL_STATUS.md"
    "PHASE_4_IMPLEMENTATION_PLAN.md"
    "PHASE_4_STATUS_REPORT.md"
    "PHASE_5_PLUS_ROADMAP.md"
    "TEST_MODERNIZATION_PLAN.md"
    "TEST_RESULTS_SUMMARY.md"
    "TEST_SUITE_SUMMARY.md"
    "UI_FIXES_SESSION_SUMMARY.md"
    "UI_INTEGRATION_SUMMARY.md"
    "UI_INTEGRATION_TEST_SUMMARY.md"
)

for doc in "${OBSOLETE_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo "  Removing: $doc"
        rm -f "$doc"
    fi
done

# Remove old log files
echo ""
echo "📋 Cleaning up old log files..."
OLD_LOGS=(
    "build_output.log"
    "core_tests_output.log"
    "validation_output.log"
    "xctests_output.log"
    ".automation_reports_index.md"
    ".last_intelligent_backup"
    ".last_ultimate_backup"
    ".mcp_validation_complete"
    ".orchestrator_cycle"
)

for log in "${OLD_LOGS[@]}"; do
    if [ -f "$log" ]; then
        echo "  Removing: $log"
        rm -f "$log"
    fi
done

# Remove old test files that may be obsolete
echo ""
echo "🧪 Cleaning up obsolete test files..."
OLD_TESTS=(
    "automated_issue_creator.swift"
    "run_all_tests.swift"
    "test_ai_and_ui_components.swift"
    "test_application_integration.swift"
    "test_code.swift"
    "test_comprehensive_runner.swift"
    "test_core_components.swift"
    "test_language_detection.swift"
    "validate_app.swift"
)

for test in "${OLD_TESTS[@]}"; do
    if [ -f "$test" ]; then
        echo "  Removing: $test"
        rm -f "$test"
    fi
done

# Clean up report directories that may be empty or obsolete
echo ""
echo "📊 Cleaning up report directories..."
REPORT_DIRS=(
    "fix_reports"
    "github_reports"
    "performance_reports"
    "quality_reports"
    "refactoring_reports"
    "security_reports"
)

for report_dir in "${REPORT_DIRS[@]}"; do
    if [ -d "$report_dir" ]; then
        if [ -z "$(ls -A "$report_dir")" ]; then
            echo "  Removing empty directory: $report_dir"
            rm -rf "$report_dir"
        else
            echo "  Keeping non-empty directory: $report_dir"
        fi
    fi
done

# Clean up any build artifacts
echo ""
echo "🔨 Cleaning up build artifacts..."
if [ -d "build" ]; then
    echo "  Removing build directory"
    rm -rf "build"
fi

# Show cleanup results
echo ""
echo "📊 Cleanup Results:"
echo "==================="
AFTER_COUNT=$(find . -type f | wc -l)
AFTER_SIZE=$(du -sh . | cut -f1)
REMOVED_COUNT=$((BEFORE_COUNT - AFTER_COUNT))

echo "Before: $BEFORE_COUNT files, $BEFORE_SIZE"
echo "After:  $AFTER_COUNT files, $AFTER_SIZE"
echo "Removed: $REMOVED_COUNT files"

echo ""
echo "✅ Project cleanup completed successfully!"
echo "🎯 Project is now ready for git commit"
