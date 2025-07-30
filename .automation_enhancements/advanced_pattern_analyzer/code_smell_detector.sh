#!/bin/bash

# Code Smell Detection Module
# Identifies anti-patterns and suggests refactoring

detect_code_smells() {
    local target_file="$1"
    local output_file="$2"
    
    echo "🔍 Analyzing code smells in $(basename "$target_file")..."
    
    # Initialize smell report
    cat > "$output_file" << REPORT
# Code Smell Analysis Report
File: $target_file
Generated: $(date)

## Code Smells Detected

REPORT
    
    # Detect long functions
    detect_long_functions "$target_file" "$output_file"
    
    # Detect large classes
    detect_large_classes "$target_file" "$output_file"
    
    # Detect duplicate code
    detect_duplicate_code "$target_file" "$output_file"
    
    # Detect complex conditionals
    detect_complex_conditionals "$target_file" "$output_file"
    
    # Detect magic numbers
    detect_magic_numbers "$target_file" "$output_file"
    
    # Detect naming issues
    detect_naming_issues "$target_file" "$output_file"
    
    # Detect coupling issues
    detect_coupling_issues "$target_file" "$output_file"
    
    echo "✅ Code smell analysis complete"
}

detect_long_functions() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for long functions..."
    
    # Find functions with more than 20 lines
    local long_functions=0
    
    awk '
    /^[[:space:]]*func / { 
        func_start = NR; 
        func_name = $0; 
        gsub(/^[[:space:]]*func /, "", func_name);
        gsub(/\(.*/, "", func_name);
        brace_count = 0; 
        in_function = 1;
    }
    in_function && /{/ { brace_count += gsub(/{/, "{"); }
    in_function && /}/ { 
        brace_count -= gsub(/}/, "}"); 
        if (brace_count <= 0) {
            lines = NR - func_start + 1;
            if (lines > 20) {
                print "### 🚨 Long Function: " func_name > "'$report'"
                print "- **Lines**: " lines " (recommended: < 20)" >> "'$report'"
                print "- **Location**: Lines " func_start "-" NR >> "'$report'"
                print "- **Suggestion**: Break into smaller, single-purpose functions" >> "'$report'"
                print "" >> "'$report'"
            }
            in_function = 0;
        }
    }
    ' "$file"
}

detect_large_classes() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for large classes..."
    
    # Find classes/structs with more than 200 lines
    awk '
    /^[[:space:]]*(class|struct) / {
        class_start = NR;
        class_name = $0;
        gsub(/^[[:space:]]*(class|struct) /, "", class_name);
        gsub(/ .*/, "", class_name);
        brace_count = 0;
        in_class = 1;
    }
    in_class && /{/ { brace_count += gsub(/{/, "{"); }
    in_class && /}/ {
        brace_count -= gsub(/}/, "}");
        if (brace_count <= 0) {
            lines = NR - class_start + 1;
            if (lines > 200) {
                print "### 🏗️ Large Class: " class_name >> "'$report'";
                print "- **Lines**: " lines " (recommended: < 200)" >> "'$report'";
                print "- **Location**: Lines " class_start "-" NR >> "'$report'";
                print "- **Suggestion**: Extract responsibilities into separate classes" >> "'$report'";
                print "" >> "'$report'";
            }
            in_class = 0;
        }
    }
    ' "$file"
}

detect_duplicate_code() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for duplicate code..."
    
    # Simple duplicate detection based on similar lines
    local duplicates=$(awk 'length($0) > 20 {lines[NR] = $0} END {
        for (i in lines) {
            for (j in lines) {
                if (i < j && lines[i] == lines[j]) {
                    print "Lines " i " and " j ": " lines[i]
                }
            }
        }
    }' "$file" | head -5)
    
    if [ -n "$duplicates" ]; then
        echo "### 🔄 Duplicate Code Detected" >> "$report"
        echo '```' >> "$report"
        echo "$duplicates" >> "$report"
        echo '```' >> "$report"
        echo "- **Suggestion**: Extract common code into functions or constants" >> "$report"
        echo "" >> "$report"
    fi
}

detect_complex_conditionals() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for complex conditionals..."
    
    # Find if statements with multiple && or || operators
    local complex_conditionals=$(grep -n "if.*&&.*&&\|if.*||.*||" "$file")
    
    if [ -n "$complex_conditionals" ]; then
        echo "### 🌐 Complex Conditionals" >> "$report"
        echo "$complex_conditionals" | while IFS= read -r line; do
            local line_num=$(echo "$line" | cut -d: -f1)
            echo "- **Line $line_num**: Complex boolean logic detected" >> "$report"
        done
        echo "- **Suggestion**: Extract conditions into well-named boolean variables" >> "$report"
        echo "" >> "$report"
    fi
}

detect_magic_numbers() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for magic numbers..."
    
    # Find numeric literals (excluding 0, 1, -1)
    local magic_numbers=$(grep -n "[^a-zA-Z_][0-9]\{2,\}\|[^a-zA-Z_][2-9][0-9]*" "$file" | grep -v "//")
    
    if [ -n "$magic_numbers" ]; then
        echo "### 🔢 Magic Numbers" >> "$report"
        echo "$magic_numbers" | head -5 | while IFS= read -r line; do
            local line_num=$(echo "$line" | cut -d: -f1)
            echo "- **Line $line_num**: Numeric literal should be named constant" >> "$report"
        done
        echo "- **Suggestion**: Replace magic numbers with named constants" >> "$report"
        echo "" >> "$report"
    fi
}

detect_naming_issues() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for naming issues..."
    
    # Find single character variable names (except loop counters)
    local bad_names=$(grep -n "let [a-z] \|var [a-z] " "$file" | grep -v "for [a-z] in")
    
    if [ -n "$bad_names" ]; then
        echo "### 📝 Naming Issues" >> "$report"
        echo "$bad_names" | while IFS= read -r line; do
            local line_num=$(echo "$line" | cut -d: -f1)
            echo "- **Line $line_num**: Single character variable name" >> "$report"
        done
        echo "- **Suggestion**: Use descriptive variable names" >> "$report"
        echo "" >> "$report"
    fi
}

detect_coupling_issues() {
    local file="$1"
    local report="$2"
    
    echo "  • Checking for coupling issues..."
    
    # Count import statements (high number might indicate tight coupling)
    local import_count=$(grep -c "^import " "$file")
    
    if [ "$import_count" -gt 10 ]; then
        echo "### 🔗 High Coupling Detected" >> "$report"
        echo "- **Import Count**: $import_count (recommended: < 10)" >> "$report"
        echo "- **Suggestion**: Review dependencies and consider dependency injection" >> "$report"
        echo "" >> "$report"
    fi
}

# Generate improvement suggestions based on detected smells
suggest_improvements() {
    local smell_report="$1"
    local suggestions_file="$2"
    
    cat > "$suggestions_file" << SUGGESTIONS
# Automated Improvement Suggestions
Generated: $(date)

## Refactoring Recommendations

Based on the code smell analysis, here are prioritized improvement suggestions:

### High Priority
1. **Extract Method**: Break down long functions into smaller, focused methods
2. **Extract Class**: Split large classes to follow Single Responsibility Principle
3. **Replace Magic Number with Named Constant**: Improve code readability

### Medium Priority
1. **Simplify Conditional Expressions**: Extract complex boolean logic
2. **Remove Duplicate Code**: Create reusable functions or constants
3. **Improve Variable Names**: Use descriptive, intention-revealing names

### Low Priority
1. **Reduce Dependencies**: Review and minimize import statements
2. **Add Documentation**: Document complex logic and public interfaces

## Automated Fixes Available
- Magic number replacement
- Variable renaming suggestions
- Function extraction opportunities

SUGGESTIONS
}

