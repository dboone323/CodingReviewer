#!/bin/bash

# 🔍 Comprehensive System Diagnosis
# Identifies REAL issues without false positives

set -euo pipefail

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"
DIAGNOSIS_DIR="$PROJECT_PATH/.system_diagnosis"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}🔍 Comprehensive System Diagnosis${NC}"
echo -e "${BOLD}${CYAN}==================================${NC}"
echo ""

mkdir -p "$DIAGNOSIS_DIR"
cd "$PROJECT_PATH"

# Track real issues found
declare -a REAL_ISSUES=()
declare -a FALSE_POSITIVES=()
declare -a WORKING_SYSTEMS=()

log_real_issue() {
    local issue="$1"
    REAL_ISSUES+=("$issue")
    echo -e "${RED}❌ REAL ISSUE: $issue${NC}"
}

log_false_positive() {
    local fp="$1" 
    FALSE_POSITIVES+=("$fp")
    echo -e "${YELLOW}⚠️ FALSE POSITIVE: $fp${NC}"
}

log_working_system() {
    local system="$1"
    WORKING_SYSTEMS+=("$system")
    echo -e "${GREEN}✅ WORKING: $system${NC}"
}

# Phase 1: Swift Project Integrity Check
diagnose_swift_project() {
    echo -e "\n${BOLD}${BLUE}📱 Phase 1: Swift Project Integrity${NC}"
    echo "=================================="
    
    # Check if Xcode project exists and is valid
    if [[ -f "CodingReviewer.xcodeproj/project.pbxproj" ]]; then
        log_working_system "Xcode project file exists"
        
        # Try to open project and check for corruption
        if plutil -lint "CodingReviewer.xcodeproj/project.pbxproj" >/dev/null 2>&1; then
            log_working_system "Xcode project file is valid XML/plist"
        else
            log_real_issue "Xcode project file is corrupted"
        fi
    else
        log_real_issue "Xcode project file missing"
    fi
    
    # Check Swift file syntax without building
    echo -e "${BLUE}🔍 Checking Swift file syntax...${NC}"
    local swift_errors=0
    local swift_files_checked=0
    
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            ((swift_files_checked++))
            # Use swiftc to check syntax without building
            if ! swiftc -typecheck "$file" >/dev/null 2>&1; then
                log_real_issue "Swift syntax error in $(basename "$file")"
                ((swift_errors++))
            fi
        fi
    done < <(find CodingReviewer -name "*.swift" -print0 2>/dev/null)
    
    if [[ $swift_errors -eq 0 && $swift_files_checked -gt 0 ]]; then
        log_working_system "All $swift_files_checked Swift files have valid syntax"
    fi
}

# Phase 2: Python Environment Validation
diagnose_python_environment() {
    echo -e "\n${BOLD}${YELLOW}🐍 Phase 2: Python Environment Validation${NC}"
    echo "=========================================="
    
    # Check Python virtual environment
    if [[ -d ".venv" ]]; then
        log_working_system "Python virtual environment exists"
        
        # Check if environment is functional
        if [[ -f ".venv/bin/python" && -x ".venv/bin/python" ]]; then
            log_working_system "Python executable is accessible"
            
            # Test Python environment
            source .venv/bin/activate
            
            # Check Python version compatibility
            local python_version
            python_version=$(.venv/bin/python --version 2>&1 | cut -d' ' -f2)
            if [[ "$python_version" =~ ^3\.(8|9|10|11|12) ]]; then
                log_working_system "Python version $python_version is compatible"
            else
                log_real_issue "Python version $python_version may have compatibility issues"
            fi
            
            # Check critical packages
            local missing_packages=()
            for pkg in pytest jupyter pandas plotly numpy matplotlib; do
                if ! .venv/bin/python -c "import $pkg" >/dev/null 2>&1; then
                    missing_packages+=("$pkg")
                fi
            done
            
            if [[ ${#missing_packages[@]} -eq 0 ]]; then
                log_working_system "All critical Python packages available"
            else
                log_real_issue "Missing Python packages: ${missing_packages[*]}"
            fi
        else
            log_real_issue "Python virtual environment is not functional"
        fi
    else
        log_real_issue "Python virtual environment missing"
    fi
}

# Phase 3: Test System Validation
diagnose_test_systems() {
    echo -e "\n${BOLD}${PURPLE}🧪 Phase 3: Test System Validation${NC}"
    echo "=================================="
    
    # Check Python tests
    if [[ -d "python_tests" ]]; then
        log_working_system "Python tests directory exists"
        
        # Count test files
        local test_files
        test_files=$(find python_tests -name "test_*.py" | wc -l)
        if [[ $test_files -gt 0 ]]; then
            log_working_system "$test_files Python test files found"
            
            # Try running tests in dry-run mode
            if [[ -d ".venv" ]]; then
                source .venv/bin/activate
                if python -m pytest python_tests/ --collect-only >/dev/null 2>&1; then
                    log_working_system "Python tests are collectible by pytest"
                else
                    log_real_issue "Python tests have collection errors"
                fi
            fi
        else
            log_real_issue "No Python test files found"
        fi
    else
        log_real_issue "Python tests directory missing"
    fi
    
    # Check Swift tests
    if xcodebuild -list -project CodingReviewer.xcodeproj 2>/dev/null | grep -q "CodingReviewerTests"; then
        log_working_system "Swift test target exists"
    else
        log_real_issue "Swift test target missing or inaccessible"
    fi
}

# Phase 4: Build System Validation
diagnose_build_system() {
    echo -e "\n${BOLD}${GREEN}🔨 Phase 4: Build System Validation${NC}"
    echo "=================================="
    
    # Test Swift build without actually building
    echo -e "${BLUE}🔍 Checking Swift build configuration...${NC}"
    
    # Check if we can read build settings
    if xcodebuild -showBuildSettings -project CodingReviewer.xcodeproj -scheme CodingReviewer >/dev/null 2>&1; then
        log_working_system "Swift build settings accessible"
    else
        log_real_issue "Cannot access Swift build settings"
    fi
    
    # Check for common build issues
    local scheme_exists=false
    if xcodebuild -list -project CodingReviewer.xcodeproj 2>/dev/null | grep -q "CodingReviewer"; then
        scheme_exists=true
        log_working_system "CodingReviewer scheme exists"
    else
        log_real_issue "CodingReviewer scheme missing"
    fi
    
    # Quick syntax check without full build
    if [[ "$scheme_exists" == true ]]; then
        echo -e "${BLUE}🔍 Testing minimal build check...${NC}"
        # Use a timeout to prevent hanging
        if timeout 30s xcodebuild -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' -dry-run build >/dev/null 2>&1; then
            log_working_system "Build system dry-run successful"
        else
            log_real_issue "Build system has configuration issues"
        fi
    fi
}

# Phase 5: Automation Script Validation
diagnose_automation_scripts() {
    echo -e "\n${BOLD}${CYAN}🤖 Phase 5: Automation Script Validation${NC}"
    echo "========================================"
    
    # Check critical automation scripts
    local critical_scripts=(
        "integration_testing_system.sh"
        "automated_quality_enhancement.sh" 
        "master_enhanced_workflow.sh"
        "enhanced_integration_orchestrator.sh"
        "launch_enhanced.sh"
    )
    
    for script in "${critical_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if [[ -x "$script" ]]; then
                # Check script syntax
                if bash -n "$script" 2>/dev/null; then
                    log_working_system "$script has valid syntax and is executable"
                else
                    log_real_issue "$script has syntax errors"
                fi
            else
                log_real_issue "$script exists but is not executable"
            fi
        else
            log_real_issue "$script is missing"
        fi
    done
    
    # Check for script conflicts or circular dependencies
    echo -e "${BLUE}🔍 Checking for script conflicts...${NC}"
    local script_conflicts=0
    
    # Look for obvious infinite loops or problematic patterns
    for script in *.sh; do
        if [[ -f "$script" ]]; then
            # Check for self-referential calls that could cause infinite loops
            if grep -q "\./$(basename "$script")" "$script" 2>/dev/null; then
                log_real_issue "$script contains potential self-referential loop"
                ((script_conflicts++))
            fi
        fi
    done
    
    if [[ $script_conflicts -eq 0 ]]; then
        log_working_system "No obvious script conflicts detected"
    fi
}

# Phase 6: File System and Permissions
diagnose_filesystem() {
    echo -e "\n${BOLD}${RED}📁 Phase 6: File System and Permissions${NC}"
    echo "========================================"
    
    # Check project directory permissions
    if [[ -w "$PROJECT_PATH" ]]; then
        log_working_system "Project directory is writable"
    else
        log_real_issue "Project directory is not writable"
    fi
    
    # Check for disk space issues
    local available_space
    available_space=$(df -h "$PROJECT_PATH" | awk 'NR==2 {print $4}' | sed 's/[A-Za-z]*//g')
    if [[ $(echo "$available_space > 1" | bc 2>/dev/null || echo "0") -eq 1 ]]; then
        log_working_system "Adequate disk space available (${available_space}GB)"
    else
        log_real_issue "Low disk space may cause issues"
    fi
    
    # Check for file permission issues in critical directories
    local critical_dirs=(".venv" "python_src" "python_tests" "jupyter_notebooks")
    for dir in "${critical_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            if [[ -r "$dir" && -w "$dir" ]]; then
                log_working_system "$dir has correct permissions"
            else
                log_real_issue "$dir has permission issues"
            fi
        fi
    done
}

# Generate comprehensive diagnosis report
generate_diagnosis_report() {
    echo -e "\n${BOLD}${CYAN}📋 Generating Diagnosis Report${NC}"
    echo "==============================="
    
    local report_file="$DIAGNOSIS_DIR/system_diagnosis_$TIMESTAMP.md"
    
    cat > "$report_file" << EOF
# System Diagnosis Report
**Generated:** $(date)
**Project:** CodingReviewer Enhanced Integration

## Summary
- **Real Issues Found:** ${#REAL_ISSUES[@]}
- **False Positives Avoided:** ${#FALSE_POSITIVES[@]}
- **Working Systems:** ${#WORKING_SYSTEMS[@]}

## 🚨 Real Issues Requiring Action
EOF

    if [[ ${#REAL_ISSUES[@]} -eq 0 ]]; then
        echo "✅ **No real issues found!** System is healthy." >> "$report_file"
    else
        for issue in "${REAL_ISSUES[@]}"; do
            echo "- ❌ $issue" >> "$report_file"
        done
    fi

    cat >> "$report_file" << EOF

## ✅ Working Systems (Verified)
EOF

    for system in "${WORKING_SYSTEMS[@]}"; do
        echo "- ✅ $system" >> "$report_file"
    done

    if [[ ${#FALSE_POSITIVES[@]} -gt 0 ]]; then
        cat >> "$report_file" << EOF

## ⚠️ False Positives Avoided
EOF
        for fp in "${FALSE_POSITIVES[@]}"; do
            echo "- ⚠️ $fp" >> "$report_file"
        done
    fi

    cat >> "$report_file" << EOF

## Recommendations

### If Issues Found:
1. Address only the real issues listed above
2. Do NOT make changes to working systems
3. Test each fix individually
4. Re-run diagnosis after fixes

### If No Issues Found:
1. System is ready for production use
2. All integration is working correctly
3. Proceed with confidence

## Next Steps
1. Review this report carefully
2. Fix only real issues (avoid false fixes)
3. Re-run diagnosis: \`./system_diagnosis.sh\`
4. Proceed with development workflow

---
**Note:** This diagnosis specifically avoids false positives and only reports genuine issues requiring attention.
EOF

    echo -e "${GREEN}📄 Diagnosis report saved: $report_file${NC}"
}

# Main execution
main() {
    echo -e "${BOLD}🎯 Starting Comprehensive System Diagnosis${NC}"
    echo "Focusing on REAL issues, avoiding false positives"
    echo ""
    
    diagnose_swift_project
    diagnose_python_environment  
    diagnose_test_systems
    diagnose_build_system
    diagnose_automation_scripts
    diagnose_filesystem
    
    echo -e "\n${BOLD}${CYAN}📊 DIAGNOSIS COMPLETE${NC}"
    echo "===================="
    echo -e "${RED}Real Issues Found: ${#REAL_ISSUES[@]}${NC}"
    echo -e "${GREEN}Working Systems: ${#WORKING_SYSTEMS[@]}${NC}"
    echo -e "${YELLOW}False Positives Avoided: ${#FALSE_POSITIVES[@]}${NC}"
    
    generate_diagnosis_report
    
    if [[ ${#REAL_ISSUES[@]} -eq 0 ]]; then
        echo -e "\n${BOLD}${GREEN}🎉 SYSTEM IS HEALTHY!${NC}"
        echo "No real issues found. Integration is working correctly."
        return 0
    else
        echo -e "\n${BOLD}${YELLOW}⚠️ REAL ISSUES REQUIRE ATTENTION${NC}"
        echo "See diagnosis report for specific issues to address."
        return 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
