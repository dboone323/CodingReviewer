#!/bin/bash

# 🔥 AUTOMATION READINESS ASSESSMENT
# Comprehensive check before running full automation

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
NC='\033[0m'

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"
READINESS_SCORE=0
TOTAL_CHECKS=0

print_header() {
    echo -e "${WHITE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║              🔥 AUTOMATION READINESS ASSESSMENT               ║${NC}"
    echo -e "${WHITE}║                 Comprehensive System Check                    ║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_item() {
    local description="$1"
    local condition="$2"
    ((TOTAL_CHECKS++))
    
    if eval "$condition"; then
        echo -e "${GREEN}✅ $description${NC}"
        ((READINESS_SCORE++))
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        return 1
    fi
}

warn_item() {
    local description="$1"
    local condition="$2"
    ((TOTAL_CHECKS++))
    
    if eval "$condition"; then
        echo -e "${GREEN}✅ $description${NC}"
        ((READINESS_SCORE++))
        return 0
    else
        echo -e "${YELLOW}⚠️  $description${NC}"
        # Don't fail, but note the warning
        return 1
    fi
}

info_item() {
    local description="$1"
    local info="$2"
    echo -e "${BLUE}ℹ️  $description: $info${NC}"
}

# Core System Checks
check_core_systems() {
    echo -e "${CYAN}🔧 CORE AUTOMATION SYSTEMS${NC}"
    echo -e "${CYAN}===========================${NC}"
    
    check_item "Ultra Master Orchestrator V4" "[[ -f 'ultra_enhanced_master_orchestrator_v4.sh' ]]"
    check_item "Ultra Build Validator V3" "[[ -f 'ultra_enhanced_build_validator_v3.sh' ]]"
    check_item "Ultra Safety System" "[[ -f 'ultra_enhanced_automation_safety_system.sh' ]]"
    check_item "Ultra State Tracker" "[[ -f 'ultra_enhanced_automation_state_tracker.sh' ]]"
    check_item "Ultra Security Scanner" "[[ -f 'ultra_enhanced_intelligent_security_scanner.sh' ]]"
    check_item "VS Code-Proof AI Learning" "[[ -f 'vscode_proof_self_improving_automation.sh' ]]"
    
    echo ""
}

# Performance Optimization Checks
check_performance_optimizations() {
    echo -e "${PURPLE}⚡ PERFORMANCE OPTIMIZATIONS${NC}"
    echo -e "${PURPLE}============================${NC}"
    
    check_item "Performance Monitor Available" "[[ -f 'simple_performance_monitor.sh' ]]"
    check_item "Task Optimizer Available" "[[ -f 'task_optimizer.sh' ]]"
    check_item "Performance Integration" "[[ -f 'performance_integration.sh' ]]"
    
    # Check for optimization flags in files
    check_item "Build Validator Optimized" "grep -q 'PARALLEL_PROCESSING=true' ultra_enhanced_build_validator_v3.sh 2>/dev/null"
    check_item "Security Scanner Optimized" "grep -q 'DIFFERENTIAL_SCAN=true' ultra_enhanced_intelligent_security_scanner.sh 2>/dev/null"
    check_item "AI Learning Optimized" "grep -q 'PATTERN_CACHE=true' vscode_proof_self_improving_automation.sh 2>/dev/null"
    
    # Check cache directories
    check_item "Build Cache Directory" "[[ -d '.build_cache' ]]"
    check_item "Security Cache Directory" "[[ -d '.security_cache' ]]"
    check_item "AI Cache Directory" "[[ -d '.ai_cache' ]]"
    check_item "Performance Monitoring Directory" "[[ -d '.performance_monitoring' ]]"
    
    echo ""
}

# AI Learning System Checks
check_ai_learning() {
    echo -e "${BLUE}🧠 AI LEARNING SYSTEM${NC}"
    echo -e "${BLUE}=====================${NC}"
    
    check_item "AI Learning Database" "[[ -f '.automation_learning/learning_database.json' ]]"
    
    # Check AI accuracy
    local ai_accuracy=$(python3 -c "
import json
try:
    with open('.automation_learning/learning_database.json', 'r') as f:
        data = json.load(f)
    print(data['learning_metrics']['accuracy_score'])
except:
    print('0')
" 2>/dev/null || echo "0")
    
    if (( $(echo "$ai_accuracy > 90" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${GREEN}✅ AI Learning Accuracy: ${ai_accuracy}% (Excellent)${NC}"
        ((READINESS_SCORE++))
    elif (( $(echo "$ai_accuracy > 70" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${YELLOW}⚠️  AI Learning Accuracy: ${ai_accuracy}% (Good)${NC}"
        ((READINESS_SCORE++))
    else
        echo -e "${RED}❌ AI Learning Accuracy: ${ai_accuracy}% (Needs improvement)${NC}"
    fi
    ((TOTAL_CHECKS++))
    
    info_item "AI Training Runs" "$(python3 -c "
import json
try:
    with open('.automation_learning/learning_database.json', 'r') as f:
        data = json.load(f)
    print(data['learning_metrics']['total_runs'])
except:
    print('0')
" 2>/dev/null || echo "0")"
    
    echo ""
}

# Project Integrity Checks
check_project_integrity() {
    echo -e "${GREEN}📱 PROJECT INTEGRITY${NC}"
    echo -e "${GREEN}====================${NC}"
    
    check_item "CodingReviewer App Directory" "[[ -d 'CodingReviewer' ]]"
    check_item "Xcode Project File" "[[ -f 'CodingReviewer.xcodeproj/project.pbxproj' ]]"
    check_item "Main App File" "[[ -f 'CodingReviewer/CodingReviewerApp.swift' ]]"
    check_item "ContentView File" "[[ -f 'CodingReviewer/ContentView.swift' ]]"
    check_item "Build Script Available" "[[ -f 'build_and_run.sh' ]]"
    
    # NEW: Check validation documentation exists (August 12, 2025)
    check_item "Validation Rules Documentation" "[[ -f 'VALIDATION_RULES.md' ]]"
    check_item "Development Guidelines" "[[ -f 'DEVELOPMENT_GUIDELINES.md' ]]"
    check_item "Architecture Documentation" "[[ -f 'ARCHITECTURE.md' ]]"
    check_item "Quick Reference Guide" "[[ -f 'QUICK_REFERENCE.md' ]]"
    
    # NEW: Check validation script is available
    check_item "Validation Script Available" "[[ -f 'validation_script.sh' ]]"
    
    # Check for critical Swift files
    local swift_count=$(find CodingReviewer -name "*.swift" -type f | wc -l | tr -d ' ')
    if [[ "$swift_count" -gt 20 ]]; then
        echo -e "${GREEN}✅ Swift Files: $swift_count (Good coverage)${NC}"
        ((READINESS_SCORE++))
    else
        echo -e "${YELLOW}⚠️  Swift Files: $swift_count (Limited coverage)${NC}"
    fi
    ((TOTAL_CHECKS++))
    
    # NEW: Architecture boundary validation (August 12, 2025)
    echo "  📋 Checking architecture boundaries..."
    if [ -d "CodingReviewer/SharedTypes" ]; then
        if grep -r "import SwiftUI" CodingReviewer/SharedTypes/ 2>/dev/null; then
            echo -e "${RED}❌ SwiftUI imports found in SharedTypes/ - violates architecture rules${NC}"
        else
            echo -e "${GREEN}✅ Architecture boundaries respected${NC}"
            ((READINESS_SCORE++))
        fi
        ((TOTAL_CHECKS++))
    fi
    
    echo ""
}

# Safety System Checks
check_safety_systems() {
    echo -e "${RED}🛡️  SAFETY SYSTEMS${NC}"
    echo -e "${RED}==================${NC}"
    
    check_item "Git Repository" "[[ -d '.git' ]]"
    warn_item "Clean Git Status" "[[ -z \$(git status --porcelain 2>/dev/null) ]]"
    check_item "Backup Systems Available" "[[ -f 'ultra_enhanced_automation_safety_system.sh' ]]"
    check_item "State Tracking Available" "[[ -f 'ultra_enhanced_automation_state_tracker.sh' ]]"
    
    # Check for VS Code interference protection
    warn_item "No VS Code Running" "! pgrep -f 'Visual Studio Code' > /dev/null"
    
    echo ""
}

# Runtime Environment Checks  
check_runtime_environment() {
    echo -e "${YELLOW}🔧 RUNTIME ENVIRONMENT${NC}"
    echo -e "${YELLOW}======================${NC}"
    
    check_item "Bash Available" "command -v bash > /dev/null"
    check_item "Python3 Available" "command -v python3 > /dev/null"
    check_item "Xcode Command Line Tools" "xcode-select -p > /dev/null 2>&1"
    warn_item "Xcode Application" "command -v xcodebuild > /dev/null"
    check_item "Git Available" "command -v git > /dev/null"
    warn_item "BC Calculator" "command -v bc > /dev/null"
    
    echo ""
}

# Generate readiness report
generate_readiness_report() {
    local percentage=$((READINESS_SCORE * 100 / TOTAL_CHECKS))
    
    echo -e "${WHITE}📊 READINESS ASSESSMENT RESULTS${NC}"
    echo -e "${WHITE}===============================${NC}"
    echo -e "${BLUE}Score: $READINESS_SCORE/$TOTAL_CHECKS ($percentage%)${NC}"
    echo ""
    
    if [[ "$percentage" -ge 95 ]]; then
        echo -e "${GREEN}🚀 SYSTEM READY FOR FULL AUTOMATION!${NC}"
        echo -e "${GREEN}All critical systems operational with optimizations active.${NC}"
        echo ""
        echo -e "${CYAN}💡 Recommended next steps:${NC}"
        echo -e "${CYAN}  1. Run validation check: ./validation_script.sh${NC}"
        echo -e "${CYAN}  2. Run: ./ultra_enhanced_master_orchestrator_v4.sh${NC}"
        echo -e "${CYAN}  3. Monitor performance with built-in monitoring${NC}"
        echo -e "${CYAN}  4. AI will continue learning and improving${NC}"
        echo ""
        echo -e "${BLUE}📚 IMPORTANT: Review these guides before automation:${NC}"
        echo -e "${BLUE}  • VALIDATION_RULES.md - Pre-development validation checklist${NC}"
        echo -e "${BLUE}  • DEVELOPMENT_GUIDELINES.md - Strategic implementation patterns${NC}"
        echo -e "${BLUE}  • QUICK_REFERENCE.md - Essential patterns and decision matrix${NC}"
        return 0
    elif [[ "$percentage" -ge 85 ]]; then
        echo -e "${YELLOW}⚡ SYSTEM MOSTLY READY${NC}"
        echo -e "${YELLOW}Minor issues detected but automation can proceed.${NC}"
        echo ""
        echo -e "${CYAN}💡 Recommended actions:${NC}"
        echo -e "${CYAN}  1. Address any ❌ items above if possible${NC}" 
        echo -e "${CYAN}  2. Run: ./ultra_enhanced_master_orchestrator_v4.sh${NC}"
        echo -e "${CYAN}  3. Monitor for any issues during execution${NC}"
        return 0
    elif [[ "$percentage" -ge 70 ]]; then
        echo -e "${YELLOW}⚠️  SYSTEM PARTIALLY READY${NC}"
        echo -e "${YELLOW}Some critical issues need attention before full automation.${NC}"
        echo ""
        echo -e "${RED}🔧 Required actions:${NC}"
        echo -e "${RED}  1. Fix all ❌ critical items above${NC}"
        echo -e "${RED}  2. Re-run this readiness check${NC}"
        echo -e "${RED}  3. Consider running individual components first${NC}"
        return 1
    else
        echo -e "${RED}🚨 SYSTEM NOT READY${NC}"
        echo -e "${RED}Critical systems missing or not functioning.${NC}"
        echo ""
        echo -e "${RED}🛠️  Essential actions required:${NC}"
        echo -e "${RED}  1. Address all ❌ items systematically${NC}"
        echo -e "${RED}  2. Ensure all core automation files are present${NC}"
        echo -e "${RED}  3. Run optimization setup if needed${NC}"
        echo -e "${RED}  4. Re-run this assessment${NC}"
        return 1
    fi
}

# Main execution
main() {
    print_header
    
    check_core_systems
    check_performance_optimizations
    check_ai_learning
    check_project_integrity
    check_safety_systems
    check_runtime_environment
    
    generate_readiness_report
}

# Execute
main "$@"
