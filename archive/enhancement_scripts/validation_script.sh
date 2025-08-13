#!/bin/bash

# CodingReviewer Validation Script
# Implements validation rules from VALIDATION_RULES.md and DEVELOPMENT_GUIDELINES.md
# Called by automation scripts to ensure compliance with our architecture

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
NC='\033[0m'

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"
VALIDATION_LOG="$PROJECT_PATH/.validation_log"

echo -e "${WHITE}🔍 CodingReviewer Validation Script${NC}"
echo -e "${WHITE}Enforcing rules from VALIDATION_RULES.md and DEVELOPMENT_GUIDELINES.md${NC}"
echo "=================================="

# Validation function templates from our documentation
validate_architecture_boundaries() {
    echo -e "${CYAN}📁 Validating Architecture Boundaries...${NC}"
    
    local violations=0
    
    # Check SharedTypes/ for SwiftUI imports (FORBIDDEN per ARCHITECTURE.md)
    if [ -d "$PROJECT_PATH/CodingReviewer/SharedTypes" ]; then
        echo "  • Checking SharedTypes/ for UI imports..."
        if grep -r "import SwiftUI" "$PROJECT_PATH/CodingReviewer/SharedTypes/" 2>/dev/null; then
            echo -e "  ${RED}❌ SwiftUI imports found in SharedTypes/ - violates architecture rules${NC}"
            ((violations++))
        else
            echo -e "  ${GREEN}✅ No UI imports in SharedTypes/${NC}"
        fi
    fi
    
    # Check for complex Codable types (can cause circular references)
    echo "  • Checking for potentially problematic Codable conformance..."
    local complex_codable=$(grep -r "struct.*Codable\|class.*Codable" "$PROJECT_PATH/CodingReviewer/SharedTypes/" 2>/dev/null | grep -E "ProcessingJob|AnalyticsReport|SystemLoad" || echo "")
    if [ -n "$complex_codable" ]; then
        echo -e "  ${YELLOW}⚠️ Complex types with Codable found - may cause circular references${NC}"
        echo "$complex_codable"
    else
        echo -e "  ${GREEN}✅ No complex Codable conformance detected${NC}"
    fi
    
    return $violations
}

validate_type_implementation_patterns() {
    echo -e "${BLUE}🏗️ Validating Type Implementation Patterns...${NC}"
    
    local violations=0
    
    # Check for complete Sendable implementation
    echo "  • Checking Sendable conformance in concurrent types..."
    if [ -d "$PROJECT_PATH/CodingReviewer/SharedTypes" ]; then
        local missing_sendable=$(grep -r "struct.*ProcessingJob\|struct.*AnalyticsReport\|struct.*SystemLoad" "$PROJECT_PATH/CodingReviewer/SharedTypes/" 2>/dev/null | grep -v "Sendable" || echo "")
        if [ -n "$missing_sendable" ]; then
            echo -e "  ${RED}❌ Concurrent types missing Sendable conformance${NC}"
            echo "$missing_sendable"
            ((violations++))
        else
            echo -e "  ${GREEN}✅ Concurrent types properly implement Sendable${NC}"
        fi
    fi
    
    # Check for complete protocol implementations (strategic vs bandaid)
    echo "  • Checking for complete protocol implementations..."
    local incomplete_protocols=$(grep -r "// TODO.*protocol\|// FIXME.*protocol" "$PROJECT_PATH/CodingReviewer/" 2>/dev/null | head -5 || echo "")
    if [ -n "$incomplete_protocols" ]; then
        echo -e "  ${YELLOW}⚠️ Incomplete protocol implementations found${NC}"
        echo "$incomplete_protocols"
    else
        echo -e "  ${GREEN}✅ No incomplete protocol implementations detected${NC}"
    fi
    
    return $violations
}

validate_error_prevention_patterns() {
    echo -e "${RED}🛡️ Validating Error Prevention Patterns...${NC}"
    
    local violations=0
    local warnings=0
    
    # Check for force unwraps (should be minimized)
    echo "  • Checking for excessive force unwraps..."
    local force_unwraps=$(find "$PROJECT_PATH/CodingReviewer" -name "*.swift" ! -path "*/Test*" -exec grep -l "!" {} \; 2>/dev/null | wc -l | tr -d ' ')
    local dangerous_unwraps=$(find "$PROJECT_PATH/CodingReviewer" -name "*.swift" ! -path "*/Test*" -exec grep -n "?!\|!\\.\|!\\[" {} + 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$dangerous_unwraps" -gt 10 ]; then
        echo -e "  ${RED}❌ Excessive force unwraps found: $dangerous_unwraps instances${NC}"
        ((violations++))
    elif [ "$dangerous_unwraps" -gt 5 ]; then
        echo -e "  ${YELLOW}⚠️ Some force unwraps found: $dangerous_unwraps instances${NC}"
        ((warnings++))
    else
        echo -e "  ${GREEN}✅ Force unwrap usage within acceptable limits${NC}"
    fi
    
    # Check for proper optional handling patterns
    echo "  • Checking for safe optional handling patterns..."
    local guard_usage=$(find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -c "guard.*let" {} + 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "0")
    local compactmap_usage=$(find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -c "compactMap" {} + 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "0")
    
    if [ "$guard_usage" -gt 10 ] || [ "$compactmap_usage" -gt 5 ]; then
        echo -e "  ${GREEN}✅ Good use of safe optional patterns (guard: $guard_usage, compactMap: $compactmap_usage)${NC}"
    else
        echo -e "  ${YELLOW}⚠️ Limited use of safe optional patterns - consider more guard/compactMap usage${NC}"
        ((warnings++))
    fi
    
    return $violations
}

validate_build_system_compliance() {
    echo -e "${GREEN}🔨 Validating Build System Compliance...${NC}"
    
    local violations=0
    
    # Test that project builds (strategic implementation validation)
    echo "  • Testing build system..."
    if command -v xcodebuild &> /dev/null; then
        if xcodebuild -project "$PROJECT_PATH/CodingReviewer.xcodeproj" -scheme CodingReviewer -destination 'platform=macOS' build > /tmp/validation_build.log 2>&1; then
            echo -e "  ${GREEN}✅ Project builds successfully${NC}"
        else
            echo -e "  ${RED}❌ Build fails - may indicate architecture violations${NC}"
            
            # Check for specific error patterns we documented as fixed
            local strategic_errors=$(grep -i "missing.*properties\|incomplete.*protocol\|circular.*dependencies\|MainActor.*conflicts\|Sendable.*issues" /tmp/validation_build.log || echo "")
            if [ -n "$strategic_errors" ]; then
                echo -e "  ${RED}Strategic implementation errors detected:${NC}"
                echo "$strategic_errors" | head -3
                ((violations++))
            fi
        fi
        rm -f /tmp/validation_build.log
    else
        echo -e "  ${YELLOW}⚠️ Xcode not available - skipping build test${NC}"
    fi
    
    return $violations
}

validate_documentation_compliance() {
    echo -e "${PURPLE}📚 Validating Documentation Compliance...${NC}"
    
    local violations=0
    
    # Check that our validation documentation exists
    local required_docs=("VALIDATION_RULES.md" "DEVELOPMENT_GUIDELINES.md" "ARCHITECTURE.md" "QUICK_REFERENCE.md")
    
    for doc in "${required_docs[@]}"; do
        if [ -f "$PROJECT_PATH/$doc" ]; then
            echo -e "  ${GREEN}✅ $doc exists${NC}"
            
            # Check that it contains our key concepts
            if grep -q "Strategic Implementation\|validation\|architecture" "$PROJECT_PATH/$doc"; then
                echo -e "    Contains validation concepts${NC}"
            else
                echo -e "  ${YELLOW}⚠️ $doc missing validation concepts${NC}"
            fi
        else
            echo -e "  ${RED}❌ Missing required documentation: $doc${NC}"
            ((violations++))
        fi
    done
    
    return $violations
}

# Main validation execution
main() {
    local total_violations=0
    local start_time=$(date)
    
    echo "Starting validation at $start_time"
    echo ""
    
    # Run all validation checks
    validate_architecture_boundaries
    total_violations=$((total_violations + $?))
    echo ""
    
    validate_type_implementation_patterns  
    total_violations=$((total_violations + $?))
    echo ""
    
    validate_error_prevention_patterns
    total_violations=$((total_violations + $?))
    echo ""
    
    validate_build_system_compliance
    total_violations=$((total_violations + $?))
    echo ""
    
    validate_documentation_compliance
    total_violations=$((total_violations + $?))
    echo ""
    
    # Generate validation report
    echo -e "${WHITE}📊 VALIDATION SUMMARY${NC}"
    echo "==================="
    
    if [ $total_violations -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL VALIDATIONS PASSED${NC}"
        echo -e "${GREEN}Project complies with architecture and validation rules${NC}"
        echo "$(date): VALIDATION PASSED - 0 violations" >> "$VALIDATION_LOG"
        return 0
    else
        echo -e "${RED}⚠️ VALIDATION ISSUES FOUND${NC}"
        echo -e "${RED}Total violations: $total_violations${NC}"
        echo ""
        echo -e "${CYAN}📋 Recommended actions:${NC}"
        echo -e "${CYAN}1. Review VALIDATION_RULES.md for detailed guidance${NC}"
        echo -e "${CYAN}2. Apply fixes following DEVELOPMENT_GUIDELINES.md patterns${NC}"
        echo -e "${CYAN}3. Use QUICK_REFERENCE.md for essential patterns${NC}"
        echo -e "${CYAN}4. Re-run validation after fixes${NC}"
        echo "$(date): VALIDATION FAILED - $total_violations violations" >> "$VALIDATION_LOG"
        return 1
    fi
}

# Command line options
case "${1:-}" in
    --architecture)
        validate_architecture_boundaries
        ;;
    --types)
        validate_type_implementation_patterns
        ;;
    --errors)
        validate_error_prevention_patterns
        ;;
    --build)
        validate_build_system_compliance
        ;;
    --docs)
        validate_documentation_compliance
        ;;
    --quick)
        # Quick validation for automation scripts
        echo -e "${CYAN}🚀 Quick Validation Check${NC}"
        validate_architecture_boundaries > /dev/null
        arch_result=$?
        validate_build_system_compliance > /dev/null  
        build_result=$?
        
        if [ $arch_result -eq 0 ] && [ $build_result -eq 0 ]; then
            echo -e "${GREEN}✅ Quick validation passed${NC}"
            exit 0
        else
            echo -e "${RED}❌ Quick validation failed${NC}"
            exit 1
        fi
        ;;
    --help)
        echo "CodingReviewer Validation Script"
        echo ""
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "OPTIONS:"
        echo "  --architecture    Validate architecture boundaries only"
        echo "  --types          Validate type implementation patterns"
        echo "  --errors         Validate error prevention patterns"
        echo "  --build          Validate build system compliance"
        echo "  --docs           Validate documentation compliance"
        echo "  --quick          Quick validation for automation (architecture + build)"
        echo "  --help           Show this help"
        echo "  (no option)      Run complete validation suite"
        echo ""
        echo "VALIDATION RULES:"
        echo "  Based on VALIDATION_RULES.md and DEVELOPMENT_GUIDELINES.md"
        echo "  Enforces strategic implementation over bandaid fixes"
        echo "  Validates architecture boundaries and type safety"
        echo ""
        ;;
    *)
        main
        ;;
esac
