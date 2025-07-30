#!/bin/bash

# Context Analysis Engine
# Analyzes current code context for intelligent suggestions

analyze_current_context() {
    local file_path="$1"
    local cursor_line="$2"
    local cursor_column="$3"
    local output_file="$4"
    
    echo "🔍 Analyzing context for intelligent completion..."
    
    # Initialize context report
    cat > "$output_file" << CONTEXT
{
  "file": "$file_path",
  "line": $cursor_line,
  "column": $cursor_column,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "context_analysis": {
CONTEXT
    
    # Analyze surrounding code context
    analyze_surrounding_code "$file_path" "$cursor_line" "$output_file"
    
    # Determine current scope (class, function, etc.)
    analyze_current_scope "$file_path" "$cursor_line" "$output_file"
    
    # Identify available variables and types
    analyze_available_variables "$file_path" "$cursor_line" "$output_file"
    
    # Detect import statements and available frameworks
    analyze_available_frameworks "$file_path" "$output_file"
    
    # Analyze coding patterns in current file
    analyze_coding_patterns "$file_path" "$output_file"
    
    # Close JSON structure
    echo '  }' >> "$output_file"
    echo '}' >> "$output_file"
    
    echo "✅ Context analysis complete"
}

analyze_surrounding_code() {
    local file="$1"
    local line_num="$2"
    local output="$3"
    
    echo "  • Analyzing surrounding code..."
    
    # Get context window (5 lines before and after)
    local start_line=$((line_num - 5))
    local end_line=$((line_num + 5))
    
    if [ "$start_line" -lt 1 ]; then
        start_line=1
    fi
    
    local context_lines=$(sed -n "${start_line},${end_line}p" "$file" | tr '\n' '\\n' | sed 's/"/\\"/g')
    
    echo '    "surrounding_code": {' >> "$output"
    echo "      \"context_window\": \"$context_lines\"," >> "$output"
    echo "      \"start_line\": $start_line," >> "$output"
    echo "      \"end_line\": $end_line" >> "$output"
    echo '    },' >> "$output"
}

analyze_current_scope() {
    local file="$1"
    local line_num="$2"
    local output="$3"
    
    echo "  • Determining current scope..."
    
    # Find the current function/class/struct
    local current_function=""
    local current_class=""
    local scope_indent=0
    
    # Look backwards to find enclosing scope
    for ((i=line_num; i>=1; i--)); do
        local line=$(sed -n "${i}p" "$file")
        
        # Check for function definition
        if echo "$line" | grep -q "func "; then
            current_function=$(echo "$line" | sed 's/.*func \([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/')
            break
        fi
        
        # Check for class/struct definition
        if echo "$line" | grep -q "class \|struct "; then
            current_class=$(echo "$line" | sed 's/.*\(class\|struct\) \([a-zA-Z_][a-zA-Z0-9_]*\).*/\2/')
            break
        fi
    done
    
    echo '    "current_scope": {' >> "$output"
    echo "      \"function\": \"$current_function\"," >> "$output"
    echo "      \"class\": \"$current_class\"," >> "$output"
    echo "      \"scope_level\": $scope_indent" >> "$output"
    echo '    },' >> "$output"
}

analyze_available_variables() {
    local file="$1"
    local line_num="$2"
    local output="$3"
    
    echo "  • Identifying available variables..."
    
    # Extract variable declarations before current line
    local variables=$(sed -n "1,${line_num}p" "$file" | grep -o "let [a-zA-Z_][a-zA-Z0-9_]*\|var [a-zA-Z_][a-zA-Z0-9_]*" | sed 's/let \|var //' | sort -u)
    local parameters=$(sed -n "1,${line_num}p" "$file" | grep -o "func [^(]*(\([^)]*\))" | sed 's/func [^(]*(//' | sed 's/).*//' | tr ',' '\n' | grep -o "[a-zA-Z_][a-zA-Z0-9_]*" | sort -u)
    
    echo '    "available_variables": {' >> "$output"
    echo '      "local_variables": [' >> "$output"
    
    if [ -n "$variables" ]; then
        echo "$variables" | sed 's/.*/        "&"/' | sed '$!s/$/,/' >> "$output"
    fi
    
    echo '      ],' >> "$output"
    echo '      "parameters": [' >> "$output"
    
    if [ -n "$parameters" ]; then
        echo "$parameters" | sed 's/.*/        "&"/' | sed '$!s/$/,/' >> "$output"
    fi
    
    echo '      ]' >> "$output"
    echo '    },' >> "$output"
}

analyze_available_frameworks() {
    local file="$1"
    local output="$2"
    
    echo "  • Detecting available frameworks..."
    
    # Extract import statements
    local imports=$(grep "^import " "$file" | sed 's/import //' | sort -u)
    
    echo '    "available_frameworks": [' >> "$output"
    
    if [ -n "$imports" ]; then
        echo "$imports" | sed 's/.*/      "&"/' | sed '$!s/$/,/' >> "$output"
    fi
    
    echo '    ],' >> "$output"
}

analyze_coding_patterns() {
    local file="$1"
    local output="$2"
    
    echo "  • Analyzing coding patterns..."
    
    # Detect common patterns
    local swiftui_usage=$(grep -c "struct.*View\|@State\|@Binding\|@ObservedObject" "$file")
    local uikit_usage=$(grep -c "UIViewController\|UIView\|IBOutlet\|IBAction" "$file")
    local async_usage=$(grep -c "async\|await\|Task\|Actor" "$file")
    local combine_usage=$(grep -c "Publisher\|@Published\|sink\|assign" "$file")
    
    echo '    "coding_patterns": {' >> "$output"
    echo "      \"swiftui_usage\": $swiftui_usage," >> "$output"
    echo "      \"uikit_usage\": $uikit_usage," >> "$output"
    echo "      \"async_usage\": $async_usage," >> "$output"
    echo "      \"combine_usage\": $combine_usage" >> "$output"
    echo '    }' >> "$output"
}

# Generate context-aware suggestions
generate_contextual_suggestions() {
    local context_file="$1"
    local suggestions_file="$2"
    
    echo "🧠 Generating context-aware suggestions..."
    
    # Parse context file (simplified JSON parsing)
    local current_function=$(grep '"function"' "$context_file" | sed 's/.*": "\(.*\)".*/\1/')
    local current_class=$(grep '"class"' "$context_file" | sed 's/.*": "\(.*\)".*/\1/')
    local swiftui_usage=$(grep '"swiftui_usage"' "$context_file" | sed 's/.*: \([0-9]*\).*/\1/')
    
    cat > "$suggestions_file" << SUGGESTIONS
{
  "suggestions": [
SUGGESTIONS
    
    # Generate suggestions based on context
    local suggestion_count=0
    
    # SwiftUI-specific suggestions
    if [ "$swiftui_usage" -gt 0 ]; then
        if [ $suggestion_count -gt 0 ]; then echo "," >> "$suggestions_file"; fi
        cat >> "$suggestions_file" << SWIFTUI_SUGGESTION
    {
      "type": "swiftui_view",
      "text": "VStack { }",
      "description": "Vertical stack container",
      "priority": 90,
      "category": "layout"
    },
    {
      "type": "swiftui_modifier",
      "text": ".padding()",
      "description": "Add padding to view",
      "priority": 85,
      "category": "modifier"
    },
    {
      "type": "swiftui_state",
      "text": "@State private var ",
      "description": "State variable declaration",
      "priority": 88,
      "category": "property"
    }
SWIFTUI_SUGGESTION
        suggestion_count=$((suggestion_count + 3))
    fi
    
    # Function-specific suggestions
    if [ -n "$current_function" ]; then
        if [ $suggestion_count -gt 0 ]; then echo "," >> "$suggestions_file"; fi
        cat >> "$suggestions_file" << FUNCTION_SUGGESTION
    {
      "type": "guard_statement",
      "text": "guard let",
      "description": "Safe unwrapping with early return",
      "priority": 92,
      "category": "safety"
    },
    {
      "type": "error_handling",
      "text": "do { } catch { }",
      "description": "Error handling block",
      "priority": 87,
      "category": "error_handling"
    }
FUNCTION_SUGGESTION
        suggestion_count=$((suggestion_count + 2))
    fi
    
    # Class-specific suggestions
    if [ -n "$current_class" ]; then
        if [ $suggestion_count -gt 0 ]; then echo "," >> "$suggestions_file"; fi
        cat >> "$suggestions_file" << CLASS_SUGGESTION
    {
      "type": "property",
      "text": "private let",
      "description": "Private property declaration",
      "priority": 80,
      "category": "property"
    },
    {
      "type": "initializer",
      "text": "init() { }",
      "description": "Initializer method",
      "priority": 83,
      "category": "method"
    }
CLASS_SUGGESTION
        suggestion_count=$((suggestion_count + 2))
    fi
    
    echo "" >> "$suggestions_file"
    echo "  ]," >> "$suggestions_file"
    echo "  \"suggestion_count\": $suggestion_count," >> "$suggestions_file"
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" >> "$suggestions_file"
    echo "}" >> "$suggestions_file"
    
    echo "✅ Generated $suggestion_count contextual suggestions"
}

