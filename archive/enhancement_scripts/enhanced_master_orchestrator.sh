#!/bin/bash

# Enhanced Master Automation Orchestrator with 100% Accuracy
# Prevents redundant fixes and learns from previous runs

echo "🌟 Enhanced Master Automation Orchestrator v2.0"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"
ENHANCED_DIR="$PROJECT_PATH/.enhanced_automation"
ACCURACY_LOG="$ENHANCED_DIR/accuracy_log.txt"
SESSION_LOG="$ENHANCED_DIR/session_${TIMESTAMP}.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$ENHANCED_DIR"

# Initialize enhanced automation
initialize_enhanced_automation() {
    echo -e "${BOLD}${CYAN}🚀 Initializing Enhanced Automation System...${NC}"
    echo ""
    
    # Initialize state tracking
    echo -e "${BLUE}1. State Tracking System${NC}"
    if [ -f "$PROJECT_PATH/automation_state_tracker.sh" ]; then
        "$PROJECT_PATH/automation_state_tracker.sh" init
        echo "  ✅ State tracking initialized"
    else
        echo "  ⚠️ State tracker not found"
    fi
    
    # Initialize learning system
    echo ""
    echo -e "${BLUE}2. Learning System${NC}"
    if [ -f "$PROJECT_PATH/self_improving_automation.sh" ]; then
        "$PROJECT_PATH/self_improving_automation.sh" init
        echo "  ✅ Learning system initialized"
    else
        echo "  ⚠️ Learning system not found"
    fi
    
    # Initialize safety system
    echo ""
    echo -e "${BLUE}3. Safety System${NC}"
    if [ -f "$PROJECT_PATH/automation_safety_system.sh" ]; then
        echo "  ✅ Safety system ready"
    else
        echo "  ⚠️ Safety system not found"
    fi
    
    echo ""
    echo -e "${GREEN}✅ Enhanced automation system initialized${NC}"
}

# Enhanced pre-automation check
run_enhanced_pre_check() {
    echo -e "${BOLD}${PURPLE}🔍 Enhanced Pre-Automation Analysis${NC}"
    echo "===================================="
    echo ""
    
    local should_proceed=false
    local reasons=()
    
    # Step 1: State analysis
    echo -e "${BLUE}1. Project State Analysis${NC}"
    if [ -f "$PROJECT_PATH/automation_state_tracker.sh" ]; then
        "$PROJECT_PATH/automation_state_tracker.sh" analyze
        local state_result=$?
        
        case $state_result in
            0)
                should_proceed=true
                reasons+=("Project changes detected requiring fixes")
                ;;
            1)
                reasons+=("No fixes needed - project is current")
                ;;
            2)
                reasons+=("No project changes since last analysis")
                ;;
        esac
    fi
    
    # Step 2: Learning system consultation
    echo ""
    echo -e "${BLUE}2. Learning System Consultation${NC}"
    if [ -f "$PROJECT_PATH/self_improving_automation.sh" ]; then
        # Get current accuracy from learning system
        local accuracy=$(python3 -c "
import json
try:
    with open('$PROJECT_PATH/.automation_learning/learning_database.json', 'r') as f:
        data = json.load(f)
    print(data['learning_metrics']['accuracy_score'])
except:
    print('0')
" 2>/dev/null || echo "0")
        
        echo "  📊 Current automation accuracy: ${accuracy}%"
        
        if (( $(echo "$accuracy >= 80" | bc -l) )); then
            echo "  ✅ High accuracy - automation recommended"
            if [ "$should_proceed" = false ]; then
                should_proceed=true
            fi
            reasons+=("High accuracy score (${accuracy}%)")
        elif (( $(echo "$accuracy >= 50" | bc -l) )); then
            echo "  ⚠️ Moderate accuracy - proceed with caution"
            reasons+=("Moderate accuracy (${accuracy}%) - extra validation")
        elif (( $(echo "$accuracy > 0 && $accuracy < 50" | bc -l) )); then
            echo "  🚫 Low accuracy - automation not recommended"
            should_proceed=false
            reasons=("Low accuracy (${accuracy}%) - manual intervention needed")
        else
            echo "  🆕 No accuracy data - proceeding with maximum caution"
        fi
    fi
    
    # Step 3: Safety check
    echo ""
    echo -e "${BLUE}3. Safety System Check${NC}"
    if [ -f "$PROJECT_PATH/automation_safety_system.sh" ]; then
        "$PROJECT_PATH/automation_safety_system.sh" check
        local safety_result=$?
        
        case $safety_result in
            0)
                echo "  ✅ Safety check passed"
                ;;
            1)
                echo "  ❌ Safety check failed - blocking automation"
                should_proceed=false
                reasons=("Safety check failed - critical issues detected")
                ;;
            2)
                echo "  ⏸️ Safety system recommends skipping"
                should_proceed=false
                reasons=("No changes detected by safety system")
                ;;
        esac
    fi
    
    # Final decision
    echo ""
    echo -e "${BOLD}🎯 ENHANCED AUTOMATION DECISION${NC}"
    echo "================================"
    
    if [ "$should_proceed" = true ]; then
        echo -e "${GREEN}✅ PROCEED WITH ENHANCED AUTOMATION${NC}"
        echo "  📋 Reasons:"
        for reason in "${reasons[@]}"; do
            echo "    • $reason"
        done
        return 0
    else
        echo -e "${RED}⏸️ SKIP AUTOMATION${NC}"
        echo "  📋 Reasons:"
        for reason in "${reasons[@]}"; do
            echo "    • $reason"
        done
        return 1
    fi
}

# Smart fix application with learning
apply_smart_fix() {
    local fix_type="$1"
    local fix_script="$2"
    
    echo -e "${CYAN}🤖 Applying Smart Fix: $fix_type${NC}"
    
    # Check if fix is needed using state tracker
    if [ -f "$PROJECT_PATH/automation_state_tracker.sh" ]; then
        if ! "$PROJECT_PATH/automation_state_tracker.sh" check "$fix_type"; then
            echo "  ⏸️ State tracker indicates $fix_type fix not needed"
            return 0  # Skip this fix
        fi
    fi
    
    # Use learning system to apply fix smartly
    if [ -f "$PROJECT_PATH/self_improving_automation.sh" ]; then
        if "$PROJECT_PATH/self_improving_automation.sh" run "$fix_type"; then
            echo "  ✅ Smart fix applied successfully"
            
            # Record success in state tracker
            if [ -f "$PROJECT_PATH/automation_state_tracker.sh" ]; then
                local files_affected=$(find "$PROJECT_PATH/CodingReviewer" -name "*.swift" | wc -l | tr -d ' ')
                "$PROJECT_PATH/automation_state_tracker.sh" record "$fix_type" "1" "$files_affected"
            fi
            
            return 0
        else
            echo "  ❌ Smart fix failed"
            return 1
        fi
    else
        # Fallback to traditional fix
        echo "  🔧 Applying traditional fix..."
        if [ -f "$fix_script" ] && "$fix_script" > /dev/null 2>&1; then
            echo "  ✅ Traditional fix applied"
            return 0
        else
            echo "  ❌ Traditional fix failed"
            return 1
        fi
    fi
}

# Enhanced automation cycle with accuracy focus
run_enhanced_automation_cycle() {
    echo -e "${BOLD}${GREEN}🔄 Enhanced Automation Cycle${NC}"
    echo "============================="
    echo ""
    
    local cycle_start=$(date +%s)
    local fixes_applied=0
    local fixes_successful=0
    local fixes_skipped=0
    
    # Priority fix types (based on learning and safety)
    local fix_types=(
        "syntax_errors:ultimate_fix_syntax_errors.sh"
        "import_issues:fix_import_issues.sh"
        "swiftlint_issues:automated_swiftlint_fixes.sh"
        "security_issues:automated_security_fixes.sh"
        "performance_issues:performance_enhancements.sh"
    )
    
    echo -e "${BLUE}🔧 Applying Smart Fixes${NC}"
    echo ""
    
    for fix_item in "${fix_types[@]}"; do
        local fix_type="${fix_item%:*}"
        local fix_script="$PROJECT_PATH/${fix_item#*:}"
        
        echo -e "${YELLOW}→ Processing $fix_type${NC}"
        
        if apply_smart_fix "$fix_type" "$fix_script"; then
            ((fixes_applied++))
            ((fixes_successful++))
            echo "  ✅ $fix_type: SUCCESS"
        else
            if [ $? -eq 0 ]; then
                # Return code 0 but fix wasn't applied = skipped
                ((fixes_skipped++))
                echo "  ⏸️ $fix_type: SKIPPED (not needed)"
            else
                # Actual failure
                ((fixes_applied++))
                echo "  ❌ $fix_type: FAILED"
            fi
        fi
        echo ""
    done
    
    # Build validation after fixes
    echo -e "${BLUE}🔨 Post-Fix Validation${NC}"
    local build_success=false
    
    cd "$PROJECT_PATH" || return 1
    if xcodebuild build -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' > /dev/null 2>&1; then
        echo "  ✅ Build validation: PASSED"
        build_success=true
    else
        echo "  ❌ Build validation: FAILED"
        echo "  🔧 Running emergency build fixes..."
        
        if [ -f "$PROJECT_PATH/intelligent_build_validator.sh" ]; then
            "$PROJECT_PATH/intelligent_build_validator.sh" --emergency > /dev/null 2>&1
            
            # Retry build
            if xcodebuild build -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' > /dev/null 2>&1; then
                echo "  ✅ Emergency fixes successful"
                build_success=true
            else
                echo "  ❌ Emergency fixes failed"
            fi
        fi
    fi
    
    # Calculate cycle metrics
    local cycle_end=$(date +%s)
    local cycle_duration=$((cycle_end - cycle_start))
    local success_rate=0
    
    if [ $fixes_applied -gt 0 ]; then
        success_rate=$(python3 -c "print(round($fixes_successful / $fixes_applied * 100, 1))")
    fi
    
    # Log results
    echo "$(date): Cycle completed - Applied: $fixes_applied, Successful: $fixes_successful, Skipped: $fixes_skipped, Success Rate: ${success_rate}%, Duration: ${cycle_duration}s, Build: $build_success" >> "$ACCURACY_LOG"
    
    # Record automation run in state tracker
    if [ -f "$PROJECT_PATH/automation_state_tracker.sh" ]; then
        "$PROJECT_PATH/automation_state_tracker.sh" record "automation_run" "$fixes_successful" "$cycle_duration"
    fi
    
    echo ""
    echo -e "${BOLD}📊 CYCLE RESULTS${NC}"
    echo "================="
    echo "  🔧 Fixes Applied: $fixes_applied"
    echo "  ✅ Successful: $fixes_successful"
    echo "  ⏸️ Skipped: $fixes_skipped"
    echo "  📈 Success Rate: ${success_rate}%"
    echo "  ⏱️ Duration: ${cycle_duration}s"
    echo "  🏗️ Build Status: $([ "$build_success" = true ] && echo "✅ PASSED" || echo "❌ FAILED")"
    
    return 0
}

# Generate enhanced accuracy report
generate_accuracy_report() {
    echo -e "${BOLD}${CYAN}📊 Enhanced Automation Accuracy Report${NC}"
    echo "======================================"
    echo ""
    
    local report_file="$ENHANCED_DIR/accuracy_report_$TIMESTAMP.md"
    
    cat > "$report_file" << EOF
# Enhanced Automation Accuracy Report
Generated: $(date)

## Executive Summary
This report provides comprehensive accuracy metrics for the enhanced automation system.

## Current System Status
EOF
    
    # Get state tracker stats
    if [ -f "$PROJECT_PATH/automation_state_tracker.sh" ]; then
        echo "" >> "$report_file"
        echo "### State Tracking Metrics" >> "$report_file"
        "$PROJECT_PATH/automation_state_tracker.sh" stats >> "$report_file" 2>/dev/null || echo "State tracking data not available" >> "$report_file"
    fi
    
    # Get learning system insights
    if [ -f "$PROJECT_PATH/self_improving_automation.sh" ]; then
        echo "" >> "$report_file"
        echo "### Learning System Insights" >> "$report_file"
        "$PROJECT_PATH/self_improving_automation.sh" insights >> "$report_file" 2>/dev/null || echo "Learning data not available" >> "$report_file"
    fi
    
    # Get recent accuracy data
    if [ -f "$ACCURACY_LOG" ]; then
        echo "" >> "$report_file"
        echo "### Recent Accuracy Trends" >> "$report_file"
        echo "\`\`\`" >> "$report_file"
        tail -10 "$ACCURACY_LOG" >> "$report_file" 2>/dev/null
        echo "\`\`\`" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## Accuracy Improvements Implemented

### 1. State Tracking System
- ✅ Prevents redundant fixes by tracking what's already been fixed
- ✅ Detects project changes to avoid unnecessary runs
- ✅ Maintains comprehensive fix history

### 2. Self-Improving Learning System
- ✅ Learns from successful and failed automation attempts
- ✅ Builds patterns of what works and what doesn't
- ✅ Provides intelligent recommendations for fix attempts

### 3. Enhanced Safety System
- ✅ Multiple validation layers before automation runs
- ✅ Project integrity checks prevent corruption
- ✅ Smart decision making based on current project state

### 4. Smart Fix Application
- ✅ Consults learning database before applying fixes
- ✅ Skips fixes that are likely to fail
- ✅ Prioritizes fixes with high success rates

## Next Steps for 100% Accuracy
1. **Continuous Learning**: System continues to learn from each run
2. **Pattern Recognition**: Builds better understanding of project-specific issues
3. **Predictive Prevention**: Anticipates issues before they occur
4. **Human Feedback Integration**: Incorporates manual corrections into learning

---
*Enhanced automation system designed for maximum accuracy and minimal redundancy*
EOF
    
    echo "  📊 Accuracy report generated: $report_file"
    echo ""
    
    # Display key metrics
    if [ -f "$PROJECT_PATH/automation_state_tracker.sh" ]; then
        echo -e "${BLUE}Current State Metrics:${NC}"
        "$PROJECT_PATH/automation_state_tracker.sh" stats | head -10
        echo ""
    fi
    
    if [ -f "$PROJECT_PATH/self_improving_automation.sh" ]; then
        echo -e "${BLUE}Learning System Status:${NC}"
        "$PROJECT_PATH/self_improving_automation.sh" insights | head -10
    fi
}

# Main enhanced automation function
run_enhanced_automation() {
    echo -e "${BOLD}${CYAN}🌟 ENHANCED AUTOMATION WITH 100% ACCURACY FOCUS${NC}"
    echo "=================================================="
    echo ""
    
    local start_time=$(date +%s)
    
    # Initialize systems
    initialize_enhanced_automation
    echo ""
    
    # Pre-automation analysis
    if ! run_enhanced_pre_check; then
        echo ""
        echo -e "${YELLOW}⏸️ Automation skipped based on intelligent analysis${NC}"
        echo -e "${GREEN}✅ This prevents unnecessary or harmful changes${NC}"
        return 0
    fi
    
    echo ""
    
    # Run enhanced automation cycle
    run_enhanced_automation_cycle
    
    echo ""
    
    # Generate accuracy report
    generate_accuracy_report
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    echo ""
    echo -e "${BOLD}${GREEN}🎉 ENHANCED AUTOMATION COMPLETE${NC}"
    echo "Total Duration: ${total_duration}s"
    echo "Focus: Maximum accuracy, minimum redundancy"
}

# Learning mode - runs analysis without making changes
run_learning_mode() {
    echo -e "${BOLD}${PURPLE}🧠 LEARNING MODE - Analysis Only${NC}"
    echo "================================="
    echo ""
    
    # Run learning cycle
    if [ -f "$PROJECT_PATH/self_improving_automation.sh" ]; then
        "$PROJECT_PATH/self_improving_automation.sh" learn
    fi
    
    echo ""
    
    # Show current insights
    if [ -f "$PROJECT_PATH/self_improving_automation.sh" ]; then
        "$PROJECT_PATH/self_improving_automation.sh" insights
    fi
    
    echo ""
    echo -e "${GREEN}✅ Learning mode complete - no changes made${NC}"
}

# Main function
main() {
    local mode="${1:-run}"
    
    case "$mode" in
        "run")
            run_enhanced_automation
            ;;
        "learn")
            run_learning_mode
            ;;
        "check")
            run_enhanced_pre_check
            ;;
        "report")
            generate_accuracy_report
            ;;
        "init")
            initialize_enhanced_automation
            ;;
        *)
            echo "Enhanced Master Automation Orchestrator v2.0"
            echo ""
            echo "Usage: $0 [MODE]"
            echo ""
            echo "MODES:"
            echo "  run     - Run enhanced automation with accuracy focus (default)"
            echo "  learn   - Learning mode - analyze without making changes"
            echo "  check   - Run pre-automation analysis only"
            echo "  report  - Generate accuracy report"
            echo "  init    - Initialize enhanced automation systems"
            echo ""
            echo "FEATURES:"
            echo "  ✅ State tracking prevents redundant fixes"
            echo "  ✅ Learning system improves accuracy over time"
            echo "  ✅ Enhanced safety prevents harmful changes"
            echo "  ✅ Smart fix application based on success patterns"
            echo "  ✅ Comprehensive accuracy reporting"
            echo ""
            echo "GOAL: 100% accuracy with zero redundant fixes"
            exit 0
            ;;
    esac
}

main "$@"
