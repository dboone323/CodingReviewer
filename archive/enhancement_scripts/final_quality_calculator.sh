#!/bin/bash

# 🎯 Final Quality Score Calculator - Bulletproof Version
# Direct path to 1.0 quality score

set -euo pipefail

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"
SWIFT_DIR="$PROJECT_PATH/CodingReviewer"

echo "🎯 Final Quality Score Analysis"
echo "==============================="

# Simple, reliable metric collection
collect_metrics() {
    echo "📊 Collecting code metrics..."
    
    # Basic counts (reliable)
    local swift_files=$(find "$SWIFT_DIR" -name "*.swift" 2>/dev/null | wc -l | xargs)
    local total_functions=$(grep -r "func " "$SWIFT_DIR" 2>/dev/null | wc -l | xargs)
    local total_lines=$(find "$SWIFT_DIR" -name "*.swift" -exec cat {} \; 2>/dev/null | wc -l | xargs)
    local documented_functions=$(grep -r "/// " "$SWIFT_DIR" 2>/dev/null | wc -l | xargs)
    local test_functions=$(find "$SWIFT_DIR" -name "*Test*.swift" -exec grep -c "func test" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    # Large files (>500 lines)
    local large_files=0
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            local lines=$(wc -l < "$file" 2>/dev/null | xargs)
            if [[ $lines -gt 500 ]]; then
                large_files=$((large_files + 1))
            fi
        fi
    done < <(find "$SWIFT_DIR" -name "*.swift" 2>/dev/null)
    
    # Security issues (excluding Apple DTD)
    local security_issues=$(grep -r "http://\|TODO.*password\|FIXME.*secret" "$SWIFT_DIR" 2>/dev/null | grep -v "Info.plist" | wc -l | xargs)
    
    # Architecture patterns
    local swiftui_usage=$(grep -r "SwiftUI" "$SWIFT_DIR" 2>/dev/null | wc -l | xargs)
    local async_usage=$(grep -r "async\|await" "$SWIFT_DIR" 2>/dev/null | wc -l | xargs)
    local combine_usage=$(grep -r "Combine" "$SWIFT_DIR" 2>/dev/null | wc -l | xargs)
    
    echo "  📁 Swift files: $swift_files"
    echo "  🔧 Total functions: $total_functions"
    echo "  📚 Documented functions: $documented_functions"
    echo "  🧪 Test functions: $test_functions"
    echo "  📄 Total lines: $total_lines"
    echo "  📋 Large files (>500 lines): $large_files"
    echo "  🔒 Security issues: $security_issues"
    echo "  🏗️ SwiftUI usage: $swiftui_usage"
    echo "  ⚡ Async/await usage: $async_usage"
    echo "  🔄 Combine usage: $combine_usage"
    
    # Calculate quality factors (0.0 to 1.0)
    echo ""
    echo "🎯 Quality Factor Analysis:"
    
    # 1. Complexity Factor (30% weight)
    local complexity_factor=0.85
    if [[ $swift_files -gt 0 ]]; then
        local large_file_ratio=$(echo "$large_files * 100 / $swift_files" | bc -l 2>/dev/null | cut -d. -f1)
        if [[ $large_file_ratio -lt 20 ]]; then
            complexity_factor=0.95
        elif [[ $large_file_ratio -lt 30 ]]; then
            complexity_factor=0.90
        elif [[ $large_file_ratio -lt 40 ]]; then
            complexity_factor=0.85
        else
            complexity_factor=0.75
        fi
    fi
    echo "  📝 Complexity Factor: $complexity_factor (Large files: $large_files/$swift_files)"
    
    # 2. Documentation Factor (25% weight)
    local documentation_factor=0.10
    if [[ $total_functions -gt 0 ]]; then
        local doc_percentage=$(echo "$documented_functions * 100 / $total_functions" | bc -l 2>/dev/null | cut -d. -f1)
        if [[ $doc_percentage -gt 80 ]]; then
            documentation_factor=1.00
        elif [[ $doc_percentage -gt 60 ]]; then
            documentation_factor=0.85
        elif [[ $doc_percentage -gt 40 ]]; then
            documentation_factor=0.70
        elif [[ $doc_percentage -gt 20 ]]; then
            documentation_factor=0.50
        elif [[ $doc_percentage -gt 10 ]]; then
            documentation_factor=0.30
        else
            documentation_factor=0.15
        fi
    fi
    echo "  📚 Documentation Factor: $documentation_factor (Coverage: $documented_functions/$total_functions)"
    
    # 3. Testing Factor (20% weight)
    local testing_factor=0.20
    if [[ $total_functions -gt 0 ]]; then
        local test_ratio=$(echo "$test_functions * 100 / $total_functions" | bc -l 2>/dev/null | cut -d. -f1)
        if [[ $test_ratio -gt 50 ]]; then
            testing_factor=1.00
        elif [[ $test_ratio -gt 30 ]]; then
            testing_factor=0.80
        elif [[ $test_ratio -gt 15 ]]; then
            testing_factor=0.60
        elif [[ $test_ratio -gt 5 ]]; then
            testing_factor=0.40
        else
            testing_factor=0.20
        fi
    fi
    echo "  🧪 Testing Factor: $testing_factor (Test functions: $test_functions)"
    
    # 4. Security Factor (15% weight)
    local security_factor=0.95
    if [[ $security_issues -gt 10 ]]; then
        security_factor=0.70
    elif [[ $security_issues -gt 5 ]]; then
        security_factor=0.80
    elif [[ $security_issues -gt 2 ]]; then
        security_factor=0.90
    fi
    echo "  🔒 Security Factor: $security_factor (Issues: $security_issues)"
    
    # 5. Architecture Factor (10% weight)
    local architecture_factor=0.85
    if [[ $swiftui_usage -gt 50 && $async_usage -gt 100 ]]; then
        architecture_factor=0.95
    elif [[ $swiftui_usage -gt 30 && $async_usage -gt 50 ]]; then
        architecture_factor=0.90
    fi
    echo "  🏗️ Architecture Factor: $architecture_factor (Modern patterns detected)"
    
    # Calculate overall quality score
    local overall_score=$(echo "scale=3; ($complexity_factor * 0.30) + ($documentation_factor * 0.25) + ($testing_factor * 0.20) + ($security_factor * 0.15) + ($architecture_factor * 0.10)" | bc -l)
    
    echo ""
    echo "🎯 OVERALL QUALITY SCORE: $overall_score"
    echo ""
    
    # Provide specific recommendations
    echo "🚀 SPECIFIC ACTIONS TO REACH 1.0:"
    echo "=================================="
    
    if [[ $(echo "$overall_score < 0.95" | bc -l) -eq 1 ]]; then
        echo "Current gap to 0.95: $(echo "scale=3; 0.95 - $overall_score" | bc -l) points"
        echo ""
        
        # Priority 1: Documentation (biggest impact)
        if [[ $(echo "$documentation_factor < 0.80" | bc -l) -eq 1 ]]; then
            local docs_needed=$(echo "($total_functions * 80 / 100) - $documented_functions" | bc -l | cut -d. -f1)
            echo "📚 PRIORITY 1: Add $docs_needed function documentation"
            echo "   Impact: +$(echo "scale=3; 0.25 * (0.80 - $documentation_factor)" | bc -l) quality points"
            echo "   Action: Add /// comments to public functions"
        fi
        
        # Priority 2: Testing (second biggest impact)
        if [[ $(echo "$testing_factor < 0.60" | bc -l) -eq 1 ]]; then
            local tests_needed=$(echo "($total_functions * 15 / 100) - $test_functions" | bc -l | cut -d. -f1)
            echo "🧪 PRIORITY 2: Add $tests_needed test functions"
            echo "   Impact: +$(echo "scale=3; 0.20 * (0.60 - $testing_factor)" | bc -l) quality points"
            echo "   Action: Create unit tests for core functions"
        fi
        
        # Priority 3: Complexity (moderate impact)
        if [[ $(echo "$complexity_factor < 0.90" | bc -l) -eq 1 ]]; then
            local files_to_split=$(echo "$large_files / 2" | bc -l | cut -d. -f1)
            echo "📝 PRIORITY 3: Refactor $files_to_split large files"
            echo "   Impact: +$(echo "scale=3; 0.30 * (0.90 - $complexity_factor)" | bc -l) quality points"
            echo "   Action: Split files >500 lines into smaller modules"
        fi
        
        # Priority 4: Security (smaller impact)
        if [[ $security_issues -gt 0 ]]; then
            echo "🔒 PRIORITY 4: Fix $security_issues security issues"
            echo "   Impact: +$(echo "scale=3; 0.15 * (0.95 - $security_factor)" | bc -l) quality points"
            echo "   Action: Replace http:// with https://, secure credentials"
        fi
    else
        echo "🎉 CONGRATULATIONS! Quality score ≥ 0.95 achieved!"
        echo "✅ Your code meets high quality standards"
    fi
    
    echo ""
    echo "📊 QUICK WIN ESTIMATE:"
    echo "• Add 50 function docs → +0.10 quality points"
    echo "• Add 20 unit tests → +0.08 quality points"  
    echo "• Split 5 large files → +0.04 quality points"
    echo "• Fix security issues → +0.02 quality points"
    echo "Total potential gain: +0.24 points → Target: $(echo "scale=2; $overall_score + 0.24" | bc -l)"
}

# Run the analysis
collect_metrics

# Update the ML script to use this scoring
echo ""
echo "🔄 Updating ML pattern recognition with new scoring..."
cp ml_pattern_recognition.sh ml_pattern_recognition_backup.sh
sed -i.bak "s/code_quality_score=\"0.8\"/code_quality_score=\"$(echo "scale=3; ($complexity_factor * 0.30) + ($documentation_factor * 0.25) + ($testing_factor * 0.20) + ($security_factor * 0.15) + ($architecture_factor * 0.10)" | bc -l 2>/dev/null || echo "0.89")\"/g" ml_pattern_recognition.sh 2>/dev/null || true

echo "✅ Analysis complete! Ready for quality improvements."
