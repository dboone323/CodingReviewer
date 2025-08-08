#!/bin/bash

# AI Refactoring Analyzer - Phase 2 CI/CD Enhancement
# MCP-Powered Code Analysis and Refactoring Recommendations

echo "🧠 AI Refactoring Analyzer - Phase 2 Enhancement"
echo "=============================================="

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REFACTORING_DIR="refactoring_reports"
REPORT_FILE="$REFACTORING_DIR/refactoring_analysis_$TIMESTAMP.json"

# Create refactoring reports directory
mkdir -p "$REFACTORING_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${CYAN}🔍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Initialize refactoring report
cat > "$REPORT_FILE" << 'EOF'
{
  "refactoring_analysis": {
    "timestamp": "",
    "version": "Phase 2 - AI Enhanced",
    "analysis_type": "comprehensive",
    "recommendations": {
      "high_priority": [],
      "medium_priority": [],
      "low_priority": [],
      "optimizations": []
    },
    "metrics": {
      "total_files_analyzed": 0,
      "total_functions_analyzed": 0,
      "complexity_score": 0,
      "maintainability_score": 0,
      "refactoring_opportunities": 0
    }
  }
}
EOF

# Update timestamp
sed -i '' "s/\"timestamp\": \"\"/\"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"/" "$REPORT_FILE"

print_status "Starting AI-powered refactoring analysis..."

# 1. Analyze code complexity
analyze_complexity() {
    print_status "Analyzing code complexity patterns..."
    
    SWIFT_FILES=$(find . -name "*.swift" -not -path "./.build/*" -not -path "./Build/*")
    TOTAL_FILES=$(echo "$SWIFT_FILES" | wc -l | tr -d ' ')
    
    COMPLEXITY_ISSUES=0
    LONG_FUNCTIONS=0
    
    # Analyze each Swift file
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            # Count lines in functions (simplified complexity measure)
            FUNC_LINES=$(grep -A 50 "func " "$file" | wc -l | tr -d ' ')
            if [ "$FUNC_LINES" -gt 500 ]; then
                LONG_FUNCTIONS=$((LONG_FUNCTIONS + 1))
            fi
            
            # Check for deeply nested code
            MAX_INDENT=$(grep -E "^[[:space:]]{20,}" "$file" | wc -l | tr -d ' ')
            if [ "$MAX_INDENT" -gt 5 ]; then
                COMPLEXITY_ISSUES=$((COMPLEXITY_ISSUES + 1))
            fi
        fi
    done <<< "$SWIFT_FILES"
    
    print_info "Analyzed $TOTAL_FILES Swift files"
    if [ $LONG_FUNCTIONS -gt 0 ]; then
        print_warning "Found $LONG_FUNCTIONS potentially long functions"
    fi
    if [ $COMPLEXITY_ISSUES -gt 0 ]; then
        print_warning "Found $COMPLEXITY_ISSUES files with deep nesting"
    fi
    
    echo "$TOTAL_FILES:$COMPLEXITY_ISSUES:$LONG_FUNCTIONS"
}

# 2. Identify duplicate code patterns
analyze_duplication() {
    print_status "Detecting code duplication patterns..."
    
    DUPLICATION_SCORE=0
    
    # Look for similar function signatures
    FUNC_SIGNATURES=$(grep -r "func " . --include="*.swift" | cut -d: -f2 | sort | uniq -c | sort -nr)
    DUPLICATE_FUNCS=$(echo "$FUNC_SIGNATURES" | awk '$1 > 1 {count++} END {print count+0}')
    
    # Look for repeated string literals
    STRING_LITERALS=$(grep -r '"[^"]{10,}"' . --include="*.swift" | wc -l | tr -d ' ')
    
    if [ "$DUPLICATE_FUNCS" -gt 3 ]; then
        DUPLICATION_SCORE=$((DUPLICATION_SCORE + 2))
        print_warning "Found $DUPLICATE_FUNCS potentially duplicate function patterns"
    fi
    
    if [ "$STRING_LITERALS" -gt 20 ]; then
        DUPLICATION_SCORE=$((DUPLICATION_SCORE + 1))
        print_info "High number of string literals detected: $STRING_LITERALS"
    fi
    
    echo "$DUPLICATION_SCORE:$DUPLICATE_FUNCS:$STRING_LITERALS"
}

# 3. Analyze Swift 6 concurrency patterns
analyze_concurrency() {
    print_status "Analyzing Swift 6 concurrency usage..."
    
    CONCURRENCY_SCORE=0
    
    # Count async/await usage
    ASYNC_COUNT=$(grep -r "async " . --include="*.swift" | wc -l | tr -d ' ')
    AWAIT_COUNT=$(grep -r "await " . --include="*.swift" | wc -l | tr -d ' ')
    ACTOR_COUNT=$(grep -r "actor " . --include="*.swift" | wc -l | tr -d ' ')
    MAINACTOR_COUNT=$(grep -r "@MainActor" . --include="*.swift" | wc -l | tr -d ' ')
    
    # Calculate concurrency modernization score
    if [ "$ASYNC_COUNT" -gt 0 ]; then
        CONCURRENCY_SCORE=$((CONCURRENCY_SCORE + 1))
    fi
    if [ "$ACTOR_COUNT" -gt 0 ]; then
        CONCURRENCY_SCORE=$((CONCURRENCY_SCORE + 2))
    fi
    if [ "$MAINACTOR_COUNT" -gt 0 ]; then
        CONCURRENCY_SCORE=$((CONCURRENCY_SCORE + 1))
    fi
    
    print_info "Concurrency usage: async($ASYNC_COUNT), await($AWAIT_COUNT), actors($ACTOR_COUNT)"
    
    echo "$CONCURRENCY_SCORE:$ASYNC_COUNT:$AWAIT_COUNT:$ACTOR_COUNT"
}

# 4. Identify performance optimization opportunities
analyze_performance() {
    print_status "Identifying performance optimization opportunities..."
    
    PERF_OPPORTUNITIES=0
    
    # Look for potential retain cycles
    WEAK_COUNT=$(grep -r "weak " . --include="*.swift" | wc -l | tr -d ' ')
    UNOWNED_COUNT=$(grep -r "unowned " . --include="*.swift" | wc -l | tr -d ' ')
    
    # Look for force unwrapping that could be optimized
    FORCE_UNWRAP=$(grep -r "!" . --include="*.swift" | wc -l | tr -d ' ')
    
    # Look for string concatenation in loops (potential optimization)
    STRING_CONCAT=$(grep -r '+=' . --include="*.swift" | grep -i string | wc -l | tr -d ' ')
    
    if [ "$FORCE_UNWRAP" -gt 50 ]; then
        PERF_OPPORTUNITIES=$((PERF_OPPORTUNITIES + 1))
        print_warning "High force unwrap usage: $FORCE_UNWRAP (consider optional binding)"
    fi
    
    if [ "$STRING_CONCAT" -gt 5 ]; then
        PERF_OPPORTUNITIES=$((PERF_OPPORTUNITIES + 1))
        print_info "String concatenation found: $STRING_CONCAT (consider StringBuilder pattern)"
    fi
    
    echo "$PERF_OPPORTUNITIES:$WEAK_COUNT:$FORCE_UNWRAP:$STRING_CONCAT"
}

# 5. Generate AI-powered recommendations
generate_recommendations() {
    local complexity_data="$1"
    local duplication_data="$2"
    local concurrency_data="$3"
    local performance_data="$4"
    
    print_status "Generating AI-powered refactoring recommendations..."
    
    # Parse data
    IFS=':' read -r total_files complexity_issues long_functions <<< "$complexity_data"
    IFS=':' read -r dup_score duplicate_funcs string_literals <<< "$duplication_data"
    IFS=':' read -r conc_score async_count await_count actor_count <<< "$concurrency_data"
    IFS=':' read -r perf_ops weak_count force_unwrap string_concat <<< "$performance_data"
    
    # Calculate overall scores
    COMPLEXITY_SCORE=$((100 - complexity_issues * 10))
    MAINTAINABILITY_SCORE=$((100 - dup_score * 15))
    TOTAL_OPPORTUNITIES=$((complexity_issues + dup_score + perf_ops))
    
    # Generate specific recommendations
    RECOMMENDATIONS=()
    
    if [ "$long_functions" -gt 0 ]; then
        RECOMMENDATIONS+=("Break down $long_functions long functions into smaller, focused methods")
    fi
    
    if [ "$complexity_issues" -gt 2 ]; then
        RECOMMENDATIONS+=("Reduce nesting levels in $complexity_issues files using early returns and guard statements")
    fi
    
    if [ "$duplicate_funcs" -gt 3 ]; then
        RECOMMENDATIONS+=("Extract common functionality from $duplicate_funcs duplicate function patterns")
    fi
    
    if [ "$async_count" -lt 5 ] && [ "$total_files" -gt 10 ]; then
        RECOMMENDATIONS+=("Consider adopting more Swift 6 concurrency patterns for better performance")
    fi
    
    if [ "$force_unwrap" -gt 30 ]; then
        RECOMMENDATIONS+=("Replace $force_unwrap force unwraps with safer optional binding patterns")
    fi
    
    # Update JSON report with AI analysis
    python3 -c "
import json
import sys

try:
    with open('$REPORT_FILE', 'r') as f:
        data = json.load(f)
    
    # Update metrics
    data['refactoring_analysis']['metrics']['total_files_analyzed'] = $total_files
    data['refactoring_analysis']['metrics']['complexity_score'] = max(0, $COMPLEXITY_SCORE)
    data['refactoring_analysis']['metrics']['maintainability_score'] = max(0, $MAINTAINABILITY_SCORE)
    data['refactoring_analysis']['metrics']['refactoring_opportunities'] = $TOTAL_OPPORTUNITIES
    
    # Add high priority recommendations
    if $complexity_issues > 3:
        data['refactoring_analysis']['recommendations']['high_priority'].append('Critical complexity reduction needed')
    if $dup_score > 2:
        data['refactoring_analysis']['recommendations']['high_priority'].append('Significant code duplication detected')
    
    # Add medium priority recommendations
    if $long_functions > 0:
        data['refactoring_analysis']['recommendations']['medium_priority'].append(f'$long_functions long functions need refactoring')
    if $force_unwrap > 30:
        data['refactoring_analysis']['recommendations']['medium_priority'].append('Excessive force unwrapping usage')
    
    # Add optimization recommendations
    if $async_count < 5:
        data['refactoring_analysis']['recommendations']['optimizations'].append('Adopt more Swift 6 concurrency patterns')
    if $string_concat > 5:
        data['refactoring_analysis']['recommendations']['optimizations'].append('Optimize string concatenation patterns')
    
    with open('$REPORT_FILE', 'w') as f:
        json.dump(data, f, indent=2)
        
    print('Refactoring report updated successfully')
except Exception as e:
    print(f'Error updating report: {e}', file=sys.stderr)
" 2>/dev/null || echo "Note: JSON report update requires Python 3"
    
    # Print recommendations
    if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
        print_info "AI-Generated Recommendations:"
        for rec in "${RECOMMENDATIONS[@]}"; do
            echo "  🎯 $rec"
        done
    else
        print_success "Code quality is excellent - no major refactoring needed!"
    fi
    
    echo "$COMPLEXITY_SCORE:$MAINTAINABILITY_SCORE:$TOTAL_OPPORTUNITIES"
}

# Main analysis function
main() {
    print_status "Initializing Phase 2 AI refactoring analyzer..."
    
    # Run all analyses
    COMPLEXITY_DATA=$(analyze_complexity)
    DUPLICATION_DATA=$(analyze_duplication)
    CONCURRENCY_DATA=$(analyze_concurrency)
    PERFORMANCE_DATA=$(analyze_performance)
    
    # Generate recommendations
    SCORES=$(generate_recommendations "$COMPLEXITY_DATA" "$DUPLICATION_DATA" "$CONCURRENCY_DATA" "$PERFORMANCE_DATA")
    IFS=':' read -r complexity_score maintainability_score opportunities <<< "$SCORES"
    
    # Generate summary report
    cat > "$REFACTORING_DIR/refactoring_summary_$TIMESTAMP.md" << SUMMARY_EOF
# 🧠 AI Refactoring Analysis Report

**Analysis Date**: $(date)
**Analyzer Version**: Phase 2 - AI Enhanced

## Code Quality Scores
- **Complexity Score**: $complexity_score/100
- **Maintainability Score**: $maintainability_score/100
- **Refactoring Opportunities**: $opportunities

## Analysis Summary
$(echo "$COMPLEXITY_DATA" | IFS=':' read total_files complexity_issues long_functions; echo "- **Files Analyzed**: $total_files")
$(echo "$DUPLICATION_DATA" | IFS=':' read dup_score duplicate_funcs string_literals; echo "- **Duplicate Patterns**: $duplicate_funcs")
$(echo "$CONCURRENCY_DATA" | IFS=':' read conc_score async_count await_count actor_count; echo "- **Async Functions**: $async_count")
$(echo "$PERFORMANCE_DATA" | IFS=':' read perf_ops weak_count force_unwrap string_concat; echo "- **Force Unwraps**: $force_unwrap")

## Priority Matrix
$(if [ $opportunities -eq 0 ]; then
    echo "✅ **Excellent Code Quality** - No immediate refactoring needed"
elif [ $opportunities -le 3 ]; then
    echo "🟡 **Good Code Quality** - Minor improvements possible"
    echo "- Focus on code organization and documentation"
else
    echo "🔴 **Refactoring Recommended** - Multiple improvement opportunities"
    echo "- Prioritize complexity reduction and duplication elimination"
fi)

## Swift 6 Readiness
$(echo "$CONCURRENCY_DATA" | IFS=':' read conc_score async_count await_count actor_count
if [ $conc_score -ge 3 ]; then
    echo "✅ **Well-prepared for Swift 6** - Good concurrency adoption"
elif [ $conc_score -ge 1 ]; then
    echo "🟡 **Partially ready for Swift 6** - Some concurrency patterns in use"
else
    echo "🔴 **Swift 6 migration needed** - Limited concurrency adoption"
fi)

## Recommended Actions
1. Review high-priority refactoring opportunities
2. Implement suggested complexity reductions
3. Enhance Swift 6 concurrency adoption
4. Establish automated refactoring checks

## Next Steps
- Review detailed JSON report for specific recommendations
- Implement refactoring changes incrementally
- Set up continuous code quality monitoring
- Schedule regular refactoring analysis

---
*Generated by AI Refactoring Analyzer - Phase 2*
SUMMARY_EOF
    
    # Final summary
    print_info "Refactoring Analysis Summary:"
    echo "  📊 Complexity Score: $complexity_score/100"
    echo "  🔧 Maintainability Score: $maintainability_score/100"
    echo "  🎯 Opportunities: $opportunities"
    echo "  📄 Report: $REPORT_FILE"
    
    if [ $opportunities -eq 0 ]; then
        print_success "Excellent code quality - no refactoring needed!"
    elif [ $opportunities -le 3 ]; then
        print_warning "Minor refactoring opportunities identified"
    else
        print_warning "Multiple refactoring opportunities - review recommended"
    fi
    
    print_success "AI refactoring analysis completed successfully!"
    print_info "Reports saved to $REFACTORING_DIR/"
    
    return $opportunities
}

# Execute main function
main "$@"
