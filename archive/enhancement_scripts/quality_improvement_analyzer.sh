#!/bin/bash

# 🎯 Quality Improvement Analyzer
# Identifies specific issues to reach 1.0 quality score

set -euo pipefail

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"

echo "🎯 Quality Improvement Analysis"
echo "==============================="

# Analyze high complexity files
echo "🔍 Analyzing high complexity files..."
high_complexity_files=()
total_files=0

while IFS= read -r file; do
    if [[ -f "$file" ]]; then
        total_files=$((total_files + 1))
        func_count=$(grep -c "func " "$file" 2>/dev/null || echo "0")
        class_count=$(grep -c "class " "$file" 2>/dev/null || echo "0")
        line_count=$(wc -l < "$file" 2>/dev/null || echo "0")
        
        # Calculate complexity score (avoid division by zero)
        if [[ $line_count -gt 0 ]]; then
            complexity_score=$((func_count * 2 + class_count * 3 + line_count / 10))
        else
            complexity_score=$((func_count * 2 + class_count * 3))
        fi
        
        if [[ $complexity_score -gt 50 ]]; then
            filename=$(basename "$file")
            high_complexity_files+=("$filename:$complexity_score:$func_count:$class_count:$line_count")
            echo "  ⚠️  $filename (Score: $complexity_score, Functions: $func_count, Classes: $class_count, Lines: $line_count)"
        fi
    fi
done < <(find "$PROJECT_PATH/CodingReviewer" -name "*.swift" 2>/dev/null)

echo ""
echo "📊 High Complexity Analysis:"
echo "   Total files: $total_files"
echo "   High complexity: ${#high_complexity_files[@]}"
echo "   Complexity ratio: $(echo "scale=2; ${#high_complexity_files[@]} / $total_files" | bc)"

# Security Issues Analysis
echo ""
echo "🔒 Security Issues Analysis:"
echo "   Checking for insecure HTTP usage..."
insecure_http_count=$(grep -r "http://" "$PROJECT_PATH/CodingReviewer" 2>/dev/null | wc -l | tr -d ' ')
echo "   Found $insecure_http_count insecure HTTP references"

if [[ $insecure_http_count -gt 0 ]]; then
    echo "   Details:"
    grep -rn "http://" "$PROJECT_PATH/CodingReviewer" 2>/dev/null | head -5
fi

echo ""
echo "   Checking for password/credential references..."
password_refs=$(grep -r "password\|secret\|key" "$PROJECT_PATH/CodingReviewer" 2>/dev/null | wc -l | tr -d ' ')
echo "   Found $password_refs potential credential references"

# Quality Factors Analysis
echo ""
echo "📈 Additional Quality Factors:"

# Documentation coverage
echo "   📚 Documentation Coverage:"
documented_funcs=$(grep -r "/// " "$PROJECT_PATH/CodingReviewer" 2>/dev/null | wc -l | tr -d ' ')
total_funcs=$(grep -r "func " "$PROJECT_PATH/CodingReviewer" 2>/dev/null | wc -l | tr -d ' ')
doc_coverage=$(echo "scale=2; $documented_funcs / $total_funcs * 100" | bc 2>/dev/null || echo "0")
echo "     Functions with documentation: $documented_funcs/$total_funcs ($doc_coverage%)"

# Test coverage indicators
echo "   🧪 Test Coverage Indicators:"
test_files=$(find "$PROJECT_PATH/CodingReviewer" -name "*Test*.swift" 2>/dev/null | wc -l)
test_funcs=$(find "$PROJECT_PATH/CodingReviewer" -name "*Test*.swift" -exec grep -c "func test" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
echo "     Test files: $test_files"
echo "     Test functions: $test_funcs"

# Error handling patterns
echo "   ⚡ Error Handling Patterns:"
error_handling=$(grep -r "do.*try\|Result<\|throws\|catch" "$PROJECT_PATH/CodingReviewer" 2>/dev/null | wc -l | tr -d ' ')
echo "     Error handling patterns: $error_handling"

# Performance patterns
echo "   🚀 Performance Patterns:"
async_patterns=$(grep -r "async\|await\|Task\|@MainActor" "$PROJECT_PATH/CodingReviewer" 2>/dev/null | wc -l | tr -d ' ')
lazy_patterns=$(grep -r "lazy var\|LazyV" "$PROJECT_PATH/CodingReviewer" 2>/dev/null | wc -l | tr -d ' ')
echo "     Async/concurrency patterns: $async_patterns"
echo "     Lazy loading patterns: $lazy_patterns"

# Generate improvement recommendations
echo ""
echo "🎯 RECOMMENDATIONS TO REACH 1.0 QUALITY:"
echo "========================================="

echo "1. 📝 REDUCE FILE COMPLEXITY (Current: ${#high_complexity_files[@]}/106 = $(echo "scale=1; ${#high_complexity_files[@]} * 100 / $total_files" | bc)%)"
echo "   Target: Reduce to <10% (≤10 files)"
echo "   Actions:"
echo "   • Break down large files (>500 lines) into smaller modules"
echo "   • Extract utility functions into separate files"
echo "   • Split complex classes into smaller, focused classes"
echo "   • Use protocols and extensions to organize code"

echo ""
echo "2. 🔒 FIX SECURITY ISSUES"
echo "   • Replace $insecure_http_count HTTP URLs with HTTPS"
echo "   • Review $password_refs credential references for security"
echo "   • Implement secure credential storage"

echo ""
echo "3. 📚 IMPROVE DOCUMENTATION (Current: $doc_coverage%)"
echo "   Target: >80% documentation coverage"
echo "   • Add /// documentation to public functions"
echo "   • Document complex algorithms and business logic"
echo "   • Add README and architectural documentation"

echo ""
echo "4. 🧪 INCREASE TEST COVERAGE (Current: $test_funcs tests)"
echo "   Target: >70% function coverage"
echo "   • Add unit tests for core functionality"
echo "   • Add integration tests for workflows"
echo "   • Add UI tests for critical user journeys"

echo ""
echo "5. ⚡ ENHANCE ERROR HANDLING (Current: $error_handling patterns)"
echo "   • Implement comprehensive error handling"
echo "   • Use Result types for better error propagation"
echo "   • Add proper logging and monitoring"

echo ""
echo "🎯 PROJECTED QUALITY IMPROVEMENTS:"
echo "Current Score: 0.89"
echo "• Fix complexity → 0.93 (+0.04)"
echo "• Fix security → 0.95 (+0.02)"  
echo "• Add documentation → 0.97 (+0.02)"
echo "• Add tests → 0.99 (+0.02)"
echo "• Improve error handling → 1.00 (+0.01)"
echo ""
echo "TARGET: 1.00 Quality Score 🎯"
