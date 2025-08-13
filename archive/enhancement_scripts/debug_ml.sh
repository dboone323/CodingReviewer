#!/bin/bash

# Debug ML Analysis Script

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"

echo "🔍 Debugging ML Analysis..."

total_functions=0
total_classes=0
file_count=0

# Process each file individually with debugging
while IFS= read -r -d '' file; do
    if [[ -f "$file" ]]; then
        file_count=$((file_count + 1))
        
        echo "Processing file #$file_count: $file"
        
        func_count=$(grep -c "func " "$file" 2>/dev/null || echo "0")
        class_count=$(grep -c "class " "$file" 2>/dev/null || echo "0")
        
        echo "  Functions found: $func_count"
        echo "  Classes found: $class_count"
        
        # Ensure numeric values
        func_count=${func_count:-0}
        class_count=${class_count:-0}
        
        # Validate they are numbers
        if [[ "$func_count" =~ ^[0-9]+$ ]] && [[ "$class_count" =~ ^[0-9]+$ ]]; then
            total_functions=$((total_functions + func_count))
            total_classes=$((total_classes + class_count))
            
            echo "  Running totals: Functions=$total_functions, Classes=$total_classes"
        else
            echo "  ERROR: Non-numeric values detected!"
        fi
        
        # Only process first 5 files for debugging
        if [[ $file_count -ge 5 ]]; then
            break
        fi
    fi
done < <(find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -print0 2>/dev/null)

echo ""
echo "Final Results:"
echo "Files processed: $file_count"
echo "Total functions: $total_functions"
echo "Total classes: $total_classes"
