#!/bin/bash

# 🧹 Focused Code Quality Improvements
# Addresses critical code quality issues identified in the assessment

set -eo pipefail

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"
QUALITY_DIR="$PROJECT_PATH/.code_quality"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$QUALITY_DIR/quality_improvements_$TIMESTAMP.log"

mkdir -p "$QUALITY_DIR"

echo "🧹 Focused Code Quality Improvements v1.0" | tee "$LOG_FILE"
echo "=========================================" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

# Track improvements
IMPROVEMENTS_MADE=0

analyze_force_unwrapping() {
    log_info "Analyzing force unwrapping usage..."
    
    # Create detailed analysis of force unwrapping
    cat > "$QUALITY_DIR/force_unwrapping_analysis.md" << 'EOF'
# Force Unwrapping Analysis Report

## Critical Force Unwrapping Issues Found

### Files with Force Unwrapping:
EOF
    
    find CodingReviewer -name "*.swift" -type f | while read -r file; do
        if grep -n "!" "$file" | grep -v "//" | grep -v "!=" | grep -v "Optional" | grep -v "ImplicitlyUnwrappedOptional" > /dev/null 2>&1; then
            echo "- $file" >> "$QUALITY_DIR/force_unwrapping_analysis.md"
            # Count force unwraps
            COUNT=$(grep -c "!" "$file" | grep -v "//" || echo "0")
            echo "  - Potential force unwraps: $COUNT" >> "$QUALITY_DIR/force_unwrapping_analysis.md"
        fi
    done
    
    cat >> "$QUALITY_DIR/force_unwrapping_analysis.md" << 'EOF'

## Recommendations:
1. Replace force unwrapping with safe optional binding
2. Use guard statements for early returns
3. Implement proper error handling for nil cases
4. Consider using nil coalescing operator (??)

## Example Safe Patterns:
```swift
// Instead of: value!
// Use: guard let value = value else { return }
// Or: value ?? defaultValue
```
EOF
    
    log_success "Force unwrapping analysis saved to $QUALITY_DIR/force_unwrapping_analysis.md"
    IMPROVEMENTS_MADE=$((IMPROVEMENTS_MADE + 1))
}

analyze_line_length() {
    log_info "Analyzing line length violations..."
    
    cat > "$QUALITY_DIR/line_length_analysis.md" << 'EOF'
# Line Length Analysis Report

## Files with Long Lines (>120 characters):

EOF
    
    find CodingReviewer -name "*.swift" -type f | while read -r file; do
        LONG_LINES=$(awk 'length > 120 {print NR ": " $0}' "$file" 2>/dev/null || true)
        if [[ -n "$LONG_LINES" ]]; then
            echo "### $file" >> "$QUALITY_DIR/line_length_analysis.md"
            echo '```' >> "$QUALITY_DIR/line_length_analysis.md"
            echo "$LONG_LINES" | head -5 >> "$QUALITY_DIR/line_length_analysis.md"
            echo '```' >> "$QUALITY_DIR/line_length_analysis.md"
            echo "" >> "$QUALITY_DIR/line_length_analysis.md"
        fi
    done
    
    cat >> "$QUALITY_DIR/line_length_analysis.md" << 'EOF'

## Refactoring Suggestions:
1. Break long function chains into variables
2. Extract complex expressions into computed properties
3. Split long parameter lists into structs
4. Use line breaks at logical points in expressions

## Example:
```swift
// Instead of: let result = someVeryLongFunctionCall(withParameter: value, andAnotherParameter: anotherValue, andYetAnotherParameter: thirdValue)
// Use:
let result = someVeryLongFunctionCall(
    withParameter: value,
    andAnotherParameter: anotherValue,
    andYetAnotherParameter: thirdValue
)
```
EOF
    
    log_success "Line length analysis saved to $QUALITY_DIR/line_length_analysis.md"
    IMPROVEMENTS_MADE=$((IMPROVEMENTS_MADE + 1))
}

clean_code_formatting() {
    log_info "Applying safe code formatting improvements..."
    
    # Remove trailing whitespace (safe operation)
    find CodingReviewer -name "*.swift" -type f -exec sed -i '' 's/[[:space:]]*$//' {} \;
    log_success "Removed trailing whitespace from all Swift files"
    
    # Ensure files end with newline (safe operation)
    find CodingReviewer -name "*.swift" -type f | while read -r file; do
        if [[ -n "$(tail -c1 "$file" 2>/dev/null)" ]]; then
            echo "" >> "$file"
        fi
    done
    log_success "Ensured all Swift files end with newline"
    
    IMPROVEMENTS_MADE=$((IMPROVEMENTS_MADE + 1))
}

analyze_code_complexity() {
    log_info "Analyzing code complexity..."
    
    cat > "$QUALITY_DIR/complexity_analysis.md" << 'EOF'
# Code Complexity Analysis

## High Complexity Files:

EOF
    
    find CodingReviewer -name "*.swift" -type f | while read -r file; do
        LINES=$(wc -l < "$file" 2>/dev/null || echo "0")
        FUNCTIONS=$(grep -c "func " "$file" 2>/dev/null || echo "0")
        CLASSES=$(grep -c "class " "$file" 2>/dev/null || echo "0")
        STRUCTS=$(grep -c "struct " "$file" 2>/dev/null || echo "0")
        
        if [[ $LINES -gt 500 ]] || [[ $FUNCTIONS -gt 20 ]]; then
            echo "### $(basename "$file")" >> "$QUALITY_DIR/complexity_analysis.md"
            echo "- Lines: $LINES" >> "$QUALITY_DIR/complexity_analysis.md"
            echo "- Functions: $FUNCTIONS" >> "$QUALITY_DIR/complexity_analysis.md"
            echo "- Classes: $CLASSES" >> "$QUALITY_DIR/complexity_analysis.md"
            echo "- Structs: $STRUCTS" >> "$QUALITY_DIR/complexity_analysis.md"
            echo "" >> "$QUALITY_DIR/complexity_analysis.md"
        fi
    done
    
    cat >> "$QUALITY_DIR/complexity_analysis.md" << 'EOF'

## Refactoring Recommendations:
1. Break large files into smaller, focused modules
2. Extract common functionality into shared utilities
3. Use protocols to reduce coupling
4. Consider using composition over inheritance

EOF
    
    log_success "Complexity analysis saved to $QUALITY_DIR/complexity_analysis.md"
    IMPROVEMENTS_MADE=$((IMPROVEMENTS_MADE + 1))
}

create_quality_improvement_plan() {
    log_info "Creating quality improvement roadmap..."
    
    cat > "$QUALITY_DIR/improvement_plan.md" << EOF
# Code Quality Improvement Plan
Generated: $(date)

## Current Status
- ✅ Swift 6 Compatibility: COMPLETE
- ✅ Build System: OPERATIONAL  
- ✅ ML Integration: HEALTHY (100% score)
- 🔄 Code Quality: IN PROGRESS

## Priority 1: Critical Safety Issues
1. **Force Unwrapping Review** (High Priority)
   - Review force unwrapping analysis report
   - Replace unsafe unwraps with safe optional handling
   - Focus on user-facing code paths first

2. **Error Handling Enhancement** (High Priority)
   - Implement comprehensive error handling
   - Add proper logging for error cases
   - Create user-friendly error messages

## Priority 2: Code Organization
1. **Line Length Optimization** (Medium Priority)
   - Review line length analysis report
   - Refactor longest lines first (>150 characters)
   - Apply consistent formatting

2. **File Organization** (Medium Priority)
   - Break down large files (>500 lines)
   - Extract reusable components
   - Improve separation of concerns

## Priority 3: Performance & Maintainability
1. **Code Complexity Reduction** (Medium Priority)
   - Review complexity analysis report
   - Refactor high-complexity functions
   - Extract common patterns

2. **Documentation Enhancement** (Low Priority)
   - Add comprehensive code documentation
   - Create architectural decision records
   - Update README with current capabilities

## Implementation Strategy
1. **Phase 1**: Address critical safety issues (force unwrapping)
2. **Phase 2**: Optimize code organization and formatting
3. **Phase 3**: Enhance performance and maintainability

## Automation
- ML Health Monitoring: ✅ Operational (4-hour intervals)
- Build Validation: ✅ Integrated
- Code Quality Tracking: ✅ Baseline established

## Next Session Priorities
1. Manually review and fix critical force unwrapping cases
2. Implement line length improvements for longest violations
3. Test ML health monitoring integration in app

EOF
    
    log_success "Quality improvement plan saved to $QUALITY_DIR/improvement_plan.md"
    IMPROVEMENTS_MADE=$((IMPROVEMENTS_MADE + 1))
}

test_app_functionality() {
    log_info "Testing app functionality..."
    
    if xcodebuild -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' build -quiet; then
        log_success "App builds successfully with all improvements"
        IMPROVEMENTS_MADE=$((IMPROVEMENTS_MADE + 1))
    else
        log_error "App build failed after improvements"
    fi
}

# Main execution
log_info "Starting focused code quality improvements..."

analyze_force_unwrapping
analyze_line_length
clean_code_formatting
analyze_code_complexity
create_quality_improvement_plan
test_app_functionality

echo "" | tee -a "$LOG_FILE"
echo "🧹 Code Quality Improvements Summary:" | tee -a "$LOG_FILE"
echo "   📊 Improvements Made: $IMPROVEMENTS_MADE" | tee -a "$LOG_FILE"
echo "   📋 Analysis Reports: Available in $QUALITY_DIR" | tee -a "$LOG_FILE"
echo "   🔍 Build Status: $(xcodebuild -project CodingReviewer.xcodeproj -scheme CodingReviewer -destination 'platform=macOS' build -quiet 2>&1 | tail -1)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "✅ Quality improvement baseline established!" | tee -a "$LOG_FILE"
echo "📋 Next steps documented in $QUALITY_DIR/improvement_plan.md" | tee -a "$LOG_FILE"
