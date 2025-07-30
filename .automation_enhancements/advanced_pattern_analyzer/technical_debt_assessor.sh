#!/bin/bash

# Technical Debt Assessor
# Quantifies and prioritizes technical debt

assess_technical_debt() {
    local target_file="$1"
    local output_file="$2"
    
    echo "📊 Assessing technical debt in $(basename "$target_file")..."
    
    cat > "$output_file" << REPORT
# Technical Debt Assessment Report
File: $target_file
Generated: $(date)

## Technical Debt Analysis

REPORT
    
    # Calculate maintainability score
    calculate_maintainability_score "$target_file" "$output_file"
    
    # Assess code complexity
    assess_code_complexity "$target_file" "$output_file"
    
    # Check documentation coverage
    assess_documentation_coverage "$target_file" "$output_file"
    
    # Evaluate test coverage indicators
    assess_test_coverage_indicators "$target_file" "$output_file"
    
    # Check for TODO/FIXME comments
    assess_todo_debt "$target_file" "$output_file"
    
    # Calculate overall debt score
    calculate_debt_score "$target_file" "$output_file"
    
    echo "✅ Technical debt assessment complete"
}

calculate_maintainability_score() {
    local file="$1"
    local report="$2"
    
    echo "  • Calculating maintainability score..."
    
    local total_lines=$(wc -l < "$file")
    local function_count=$(grep -c "func " "$file")
    local class_count=$(grep -c "class \|struct " "$file")
    local comment_lines=$(grep -c "//" "$file")
    
    # Calculate average function length
    local avg_function_length=0
    if [ "$function_count" -gt 0 ]; then
        avg_function_length=$((total_lines / function_count))
    fi
    
    # Calculate comment ratio
    local comment_ratio=0
    if [ "$total_lines" -gt 0 ]; then
        comment_ratio=$((comment_lines * 100 / total_lines))
    fi
    
    echo "### 📈 Maintainability Metrics" >> "$report"
    echo "- **Total Lines**: $total_lines" >> "$report"
    echo "- **Functions**: $function_count" >> "$report"
    echo "- **Classes/Structs**: $class_count" >> "$report"
    echo "- **Average Function Length**: $avg_function_length lines" >> "$report"
    echo "- **Comment Ratio**: $comment_ratio%" >> "$report"
    echo "" >> "$report"
    
    # Score calculation (simplified)
    local maintainability_score=100
    
    # Penalize long functions
    if [ "$avg_function_length" -gt 20 ]; then
        maintainability_score=$((maintainability_score - 20))
    fi
    
    # Penalize low comment ratio
    if [ "$comment_ratio" -lt 10 ]; then
        maintainability_score=$((maintainability_score - 15))
    fi
    
    # Reward good structure
    if [ "$function_count" -gt 0 ] && [ "$avg_function_length" -lt 15 ]; then
        maintainability_score=$((maintainability_score + 10))
    fi
    
    echo "- **Maintainability Score**: $maintainability_score/100" >> "$report"
    echo "" >> "$report"
}

assess_code_complexity() {
    local file="$1"
    local report="$2"
    
    echo "  • Assessing code complexity..."
    
    # Count decision points (simplified cyclomatic complexity)
    local if_count=$(grep -c "if\|guard\|switch\|case" "$file")
    local loop_count=$(grep -c "for\|while\|repeat" "$file")
    local catch_count=$(grep -c "catch\|try" "$file")
    
    local complexity_score=$((if_count + loop_count + catch_count))
    
    echo "### 🌀 Complexity Metrics" >> "$report"
    echo "- **Decision Points**: $if_count" >> "$report"
    echo "- **Loops**: $loop_count" >> "$report"
    echo "- **Error Handling**: $catch_count" >> "$report"
    echo "- **Estimated Cyclomatic Complexity**: $complexity_score" >> "$report"
    
    if [ "$complexity_score" -gt 20 ]; then
        echo "- **⚠️ Warning**: High complexity detected" >> "$report"
    elif [ "$complexity_score" -gt 10 ]; then
        echo "- **ℹ️ Info**: Moderate complexity" >> "$report"
    else
        echo "- **✅ Good**: Low complexity" >> "$report"
    fi
    echo "" >> "$report"
}

assess_documentation_coverage() {
    local file="$1"
    local report="$2"
    
    echo "  • Assessing documentation coverage..."
    
    local public_functions=$(grep -c "public func\|open func\|func " "$file")
    local documented_functions=$(grep -B 1 "func " "$file" | grep -c "///")
    
    local coverage_percentage=0
    if [ "$public_functions" -gt 0 ]; then
        coverage_percentage=$((documented_functions * 100 / public_functions))
    fi
    
    echo "### 📚 Documentation Coverage" >> "$report"
    echo "- **Public Functions**: $public_functions" >> "$report"
    echo "- **Documented Functions**: $documented_functions" >> "$report"
    echo "- **Coverage**: $coverage_percentage%" >> "$report"
    
    if [ "$coverage_percentage" -lt 50 ]; then
        echo "- **⚠️ Action Needed**: Low documentation coverage" >> "$report"
    elif [ "$coverage_percentage" -lt 80 ]; then
        echo "- **ℹ️ Improvement**: Moderate documentation coverage" >> "$report"
    else
        echo "- **✅ Excellent**: Good documentation coverage" >> "$report"
    fi
    echo "" >> "$report"
}

assess_test_coverage_indicators() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for test coverage indicators..."
    
    # Look for corresponding test file
    local base_name=$(basename "$file" .swift)
    local test_file_pattern="${base_name}Test*"
    local test_files=$(find "$(dirname "$file")/../" -name "$test_file_pattern" 2>/dev/null)
    
    echo "### 🧪 Test Coverage Indicators" >> "$report"
    
    if [ -n "$test_files" ]; then
        echo "- **Test Files Found**: Yes" >> "$report"
        echo "$test_files" | while IFS= read -r test_file; do
            echo "  - $(basename "$test_file")" >> "$report"
        done
    else
        echo "- **Test Files Found**: No" >> "$report"
        echo "- **⚠️ Action Needed**: Create unit tests for this file" >> "$report"
    fi
    echo "" >> "$report"
}

assess_todo_debt() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for TODO/FIXME debt..."
    
    local todo_count=$(grep -c "TODO\|FIXME\|HACK" "$file")
    local todo_items=$(grep -n "TODO\|FIXME\|HACK" "$file")
    
    echo "### 📝 TODO/FIXME Debt" >> "$report"
    echo "- **Count**: $todo_count items" >> "$report"
    
    if [ "$todo_count" -gt 0 ]; then
        echo "- **Items**:" >> "$report"
        echo "$todo_items" | while IFS= read -r item; do
            local line_num=$(echo "$item" | cut -d: -f1)
            local content=$(echo "$item" | cut -d: -f2- | sed 's/^[[:space:]]*//')
            echo "  - Line $line_num: $content" >> "$report"
        done
        
        if [ "$todo_count" -gt 10 ]; then
            echo "- **⚠️ High Debt**: Many unresolved TODOs" >> "$report"
        fi
    else
        echo "- **✅ Clean**: No TODO/FIXME items found" >> "$report"
    fi
    echo "" >> "$report"
}

calculate_debt_score() {
    local file="$1"
    local report="$2"
    
    echo "  • Calculating overall debt score..."
    
    # Simple debt score calculation
    local total_lines=$(wc -l < "$file")
    local todo_count=$(grep -c "TODO\|FIXME\|HACK" "$file")
    local function_count=$(grep -c "func " "$file")
    local comment_lines=$(grep -c "//" "$file")
    
    # Base score
    local debt_score=100
    
    # Penalize based on various factors
    if [ "$todo_count" -gt 5 ]; then
        debt_score=$((debt_score - (todo_count * 2)))
    fi
    
    if [ "$total_lines" -gt 500 ]; then
        debt_score=$((debt_score - 20))
    fi
    
    local avg_function_length=0
    if [ "$function_count" -gt 0 ]; then
        avg_function_length=$((total_lines / function_count))
        if [ "$avg_function_length" -gt 25 ]; then
            debt_score=$((debt_score - 15))
        fi
    fi
    
    local comment_ratio=0
    if [ "$total_lines" -gt 0 ]; then
        comment_ratio=$((comment_lines * 100 / total_lines))
        if [ "$comment_ratio" -lt 10 ]; then
            debt_score=$((debt_score - 10))
        fi
    fi
    
    # Ensure score doesn't go below 0
    if [ "$debt_score" -lt 0 ]; then
        debt_score=0
    fi
    
    echo "### 🎯 Overall Technical Debt Score" >> "$report"
    echo "- **Score**: $debt_score/100" >> "$report"
    
    if [ "$debt_score" -gt 80 ]; then
        echo "- **Status**: ✅ Low technical debt" >> "$report"
        echo "- **Action**: Maintain current quality" >> "$report"
    elif [ "$debt_score" -gt 60 ]; then
        echo "- **Status**: ⚠️ Moderate technical debt" >> "$report"
        echo "- **Action**: Schedule refactoring in next sprint" >> "$report"
    else
        echo "- **Status**: 🚨 High technical debt" >> "$report"
        echo "- **Action**: Immediate refactoring recommended" >> "$report"
    fi
    echo "" >> "$report"
}

