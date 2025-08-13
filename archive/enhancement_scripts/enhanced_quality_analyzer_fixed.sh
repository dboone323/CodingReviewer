#!/bin/bash

# Enhanced Quality Scoring System - Fixed Version
# Comprehensive quality analysis with multiple factors

set -euo pipefail

calculate_enhanced_quality_score() {
    local swift_dir="$1"
    
    echo "Enhanced Quality Analysis Results:"
    echo "=================================="
    
    # Base metrics
    local total_files=$(find "$swift_dir" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
    local total_functions=$(grep -r "func " "$swift_dir" 2>/dev/null | wc -l | tr -d ' ')
    local total_lines=$(find "$swift_dir" -name "*.swift" -exec wc -l {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    echo "Base Metrics:"
    echo "  Total Swift files: $total_files"
    echo "  Total functions: $total_functions"
    echo "  Total lines: $total_lines"
    echo ""
    
    # Calculate complexity factor
    local high_complexity_files=0
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            local func_count=$(grep -c "func " "$file" 2>/dev/null || echo "0")
            local class_count=$(grep -c "class " "$file" 2>/dev/null || echo "0")
            local line_count=$(wc -l < "$file" 2>/dev/null || echo "0")
            
            local complexity=0
            if [[ $line_count -gt 0 ]]; then
                complexity=$((func_count * 2 + class_count * 3 + line_count / 10))
            else
                complexity=$((func_count * 2 + class_count * 3))
            fi
            
            if [[ $complexity -gt 50 ]]; then
                high_complexity_files=$((high_complexity_files + 1))
            fi
        fi
    done < <(find "$swift_dir" -name "*.swift" 2>/dev/null)
    
    local complexity_ratio=0.0
    local complexity_score=0.8
    if [[ $total_files -gt 0 ]]; then
        complexity_ratio=$(echo "scale=3; $high_complexity_files / $total_files" | bc 2>/dev/null || echo "0.1")
        complexity_score=$(echo "scale=3; 1 - ($complexity_ratio * 0.5)" | bc 2>/dev/null || echo "0.8")
    fi
    
    # Calculate documentation factor
    local documented_funcs=$(grep -r "/// " "$swift_dir" 2>/dev/null | wc -l | tr -d ' ')
    local documentation_score=0.1
    if [[ $total_functions -gt 0 ]]; then
        documentation_score=$(echo "scale=3; $documented_funcs / $total_functions" | bc 2>/dev/null || echo "0.1")
        # Cap at 1.0
        if (( $(echo "$documentation_score > 1" | bc -l 2>/dev/null || echo "0") )); then
            documentation_score="1.0"
        fi
    fi
    
    # Calculate test coverage factor
    local test_files=$(find "$swift_dir" -name "*Test*.swift" 2>/dev/null | wc -l)
    local test_funcs=$(find "$swift_dir" -name "*Test*.swift" -exec grep -c "func test" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    local test_coverage_score=0.1
    if [[ $total_functions -gt 0 ]]; then
        test_coverage_score=$(echo "scale=3; ($test_funcs * 10) / $total_functions" | bc 2>/dev/null || echo "0.1")
        # Cap at 1.0
        if (( $(echo "$test_coverage_score > 1" | bc -l 2>/dev/null || echo "0") )); then
            test_coverage_score="1.0"
        fi
    fi
    
    # Calculate security factor
    local security_issues=$(grep -r "http://\|password\|secret" "$swift_dir" 2>/dev/null | grep -v "Info.plist" | wc -l | tr -d ' ')
    local security_score=0.9
    if [[ $total_files -gt 0 ]]; then
        security_score=$(echo "scale=3; 1 - ($security_issues / ($total_files * 2))" | bc 2>/dev/null || echo "0.9")
        # Ensure minimum 0.0
        if (( $(echo "$security_score < 0" | bc -l 2>/dev/null || echo "0") )); then
            security_score="0.0"
        fi
    fi
    
    # Architecture and Performance scores (based on patterns detected)
    local swiftui_usage=$(grep -r "SwiftUI" "$swift_dir" 2>/dev/null | wc -l | tr -d ' ')
    local async_usage=$(grep -r "async\|await" "$swift_dir" 2>/dev/null | wc -l | tr -d ' ')
    local combine_usage=$(grep -r "Combine" "$swift_dir" 2>/dev/null | wc -l | tr -d ' ')
    
    local architecture_score=0.8
    local performance_score=0.8
    
    # Boost scores based on modern patterns
    if [[ $swiftui_usage -gt 50 ]]; then
        architecture_score=$(echo "scale=3; $architecture_score + 0.1" | bc)
    fi
    if [[ $async_usage -gt 100 ]]; then
        performance_score=$(echo "scale=3; $performance_score + 0.15" | bc)
    fi
    if [[ $combine_usage -gt 30 ]]; then
        architecture_score=$(echo "scale=3; $architecture_score + 0.05" | bc)
    fi
    
    # Cap scores at 1.0
    if (( $(echo "$architecture_score > 1" | bc -l 2>/dev/null || echo "0") )); then
        architecture_score="1.0"
    fi
    if (( $(echo "$performance_score > 1" | bc -l 2>/dev/null || echo "0") )); then
        performance_score="1.0"
    fi
    
    # Calculate overall quality score (weighted average)
    local overall_score=$(echo "scale=3; ($complexity_score * 0.25) + ($documentation_score * 0.20) + ($test_coverage_score * 0.20) + ($security_score * 0.15) + ($architecture_score * 0.10) + ($performance_score * 0.10)" | bc 2>/dev/null || echo "0.85")
    
    echo "Quality Factor Analysis:"
    echo "  Complexity Score: $complexity_score (25% weight) - $high_complexity_files/$total_files high complexity files"
    echo "  Documentation Score: $documentation_score (20% weight) - $documented_funcs/$total_functions documented functions"
    echo "  Test Coverage Score: $test_coverage_score (20% weight) - $test_funcs test functions"
    echo "  Security Score: $security_score (15% weight) - $security_issues security issues found"
    echo "  Architecture Score: $architecture_score (10% weight) - Modern patterns: SwiftUI($swiftui_usage), Combine($combine_usage)"
    echo "  Performance Score: $performance_score (10% weight) - Async patterns: $async_usage"
    echo ""
    echo "🎯 OVERALL QUALITY SCORE: $overall_score"
    echo ""
    
    if (( $(echo "$overall_score >= 0.95" | bc -l 2>/dev/null || echo "0") )); then
        echo "🎉 EXCELLENT! Quality score ≥ 0.95 - TARGET ACHIEVED!"
    elif (( $(echo "$overall_score >= 0.90" | bc -l 2>/dev/null || echo "0") )); then
        echo "✅ VERY GOOD! Quality score ≥ 0.90 - Close to target"
    elif (( $(echo "$overall_score >= 0.85" | bc -l 2>/dev/null || echo "0") )); then
        echo "👍 GOOD! Quality score ≥ 0.85 - Room for improvement"
    else
        echo "🔧 NEEDS WORK - Quality score < 0.85"
    fi
    
    echo ""
    echo "Improvement Recommendations:"
    if (( $(echo "$complexity_score < 0.9" | bc -l 2>/dev/null || echo "0") )); then
        echo "  📝 Reduce file complexity - Split large files into smaller modules"
    fi
    if (( $(echo "$documentation_score < 0.8" | bc -l 2>/dev/null || echo "0") )); then
        echo "  📚 Improve documentation - Add /// comments to functions"
    fi
    if (( $(echo "$test_coverage_score < 0.7" | bc -l 2>/dev/null || echo "0") )); then
        echo "  🧪 Increase test coverage - Add more unit and integration tests"
    fi
    if (( $(echo "$security_score < 0.9" | bc -l 2>/dev/null || echo "0") )); then
        echo "  🔒 Fix security issues - Address HTTP and credential references"
    fi
}

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <swift_directory>"
    exit 1
fi

calculate_enhanced_quality_score "$1"
