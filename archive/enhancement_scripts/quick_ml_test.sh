#!/bin/bash

# Quick ML Analysis Test - Limited Files

set -euo pipefail

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"
ML_DATA_DIR="$PROJECT_PATH/.ml_automation"

mkdir -p "$ML_DATA_DIR/data"

echo "🧠 Quick ML Analysis Test"
echo "========================"

total_functions=0
total_classes=0
total_lines=0
file_count=0

# Process only first 10 Swift files
count=0
while IFS= read -r -d '' file && [[ $count -lt 10 ]]; do
    if [[ -f "$file" ]]; then
        file_count=$((file_count + 1))
        count=$((count + 1))
        
        func_count=$(grep -c "func " "$file" 2>/dev/null | head -1 | tr -d '\n' || echo "0")
        class_count=$(grep -c "class " "$file" 2>/dev/null | head -1 | tr -d '\n' || echo "0")
        line_count=$(wc -l < "$file" 2>/dev/null | tr -d ' \n' || echo "0")
        
        # Ensure numeric values
        func_count=${func_count:-0}
        class_count=${class_count:-0}
        line_count=${line_count:-0}
        
        if [[ "$func_count" =~ ^[0-9]+$ ]] && [[ "$class_count" =~ ^[0-9]+$ ]] && [[ "$line_count" =~ ^[0-9]+$ ]]; then
            total_functions=$((total_functions + func_count))
            total_classes=$((total_classes + class_count))
            total_lines=$((total_lines + line_count))
            
            echo "  📄 File $count: $(basename "$file") - Functions: $func_count, Classes: $class_count, Lines: $line_count"
        fi
    fi
done < <(find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -print0 2>/dev/null)

# Generate JSON result
pattern_data="$ML_DATA_DIR/data/quick_analysis_$(date +%Y%m%d_%H%M%S).json"
cat > "$pattern_data" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "analysis_results": {
    "files_processed": $file_count,
    "total_functions": $total_functions,
    "total_classes": $total_classes,
    "total_lines": $total_lines,
    "avg_functions_per_file": $((file_count > 0 ? total_functions / file_count : 0)),
    "avg_lines_per_file": $((file_count > 0 ? total_lines / file_count : 0))
  },
  "test_mode": true
}
EOF

echo ""
echo "📊 Quick Analysis Results:"
echo "  Files processed: $file_count"
echo "  Total functions: $total_functions"  
echo "  Total classes: $total_classes"
echo "  Total lines: $total_lines"
echo "  Analysis saved: $pattern_data"
echo "✅ Quick ML analysis complete"
