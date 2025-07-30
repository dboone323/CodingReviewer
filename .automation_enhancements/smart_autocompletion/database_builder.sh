#!/bin/bash

# Project Completion Database Builder
# Builds comprehensive database of project-specific completions

build_completion_database() {
    local project_path="$1"
    local database_file="$2"
    
    echo "💾 Building project completion database..."
    
    # Initialize database structure
    cat > "$database_file" << DATABASE
{
  "project_path": "$project_path",
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "completion_data": {
DATABASE
    
    # Extract all Swift files
    extract_swift_symbols "$project_path" "$database_file"
    
    # Build function signatures
    extract_function_signatures "$project_path" "$database_file"
    
    # Extract class and struct definitions
    extract_type_definitions "$project_path" "$database_file"
    
    # Build property completions
    extract_property_definitions "$project_path" "$database_file"
    
    # Extract protocol definitions
    extract_protocol_definitions "$project_path" "$database_file"
    
    # Build import completions
    extract_import_patterns "$project_path" "$database_file"
    
    # Close database structure
    echo '  }' >> "$database_file"
    echo '}' >> "$database_file"
    
    echo "✅ Completion database built successfully"
}

extract_swift_symbols() {
    local project_path="$1"
    local database="$2"
    
    echo "  • Extracting Swift symbols..."
    
    local swift_files=$(find "$project_path" -name "*.swift" 2>/dev/null)
    local symbol_count=0
    
    echo '    "symbols": [' >> "$database"
    
    echo "$swift_files" | while IFS= read -r file; do
        if [ -f "$file" ]; then
            # Extract class names
            grep "class [a-zA-Z_][a-zA-Z0-9_]*" "$file" | while read -r line; do
                local class_name=$(echo "$line" | sed 's/.*class \([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/')
                if [ $symbol_count -gt 0 ]; then echo "," >> "$database"; fi
                echo "      {\"type\": \"class\", \"name\": \"$class_name\", \"file\": \"$(basename "$file")\"}" >> "$database"
                symbol_count=$((symbol_count + 1))
            done
            
            # Extract struct names
            grep "struct [a-zA-Z_][a-zA-Z0-9_]*" "$file" | while read -r line; do
                local struct_name=$(echo "$line" | sed 's/.*struct \([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/')
                if [ $symbol_count -gt 0 ]; then echo "," >> "$database"; fi
                echo "      {\"type\": \"struct\", \"name\": \"$struct_name\", \"file\": \"$(basename "$file")\"}" >> "$database"
                symbol_count=$((symbol_count + 1))
            done
            
            # Extract enum names
            grep "enum [a-zA-Z_][a-zA-Z0-9_]*" "$file" | while read -r line; do
                local enum_name=$(echo "$line" | sed 's/.*enum \([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/')
                if [ $symbol_count -gt 0 ]; then echo "," >> "$database"; fi
                echo "      {\"type\": \"enum\", \"name\": \"$enum_name\", \"file\": \"$(basename "$file")\"}" >> "$database"
                symbol_count=$((symbol_count + 1))
            done
        fi
    done
    
    echo "" >> "$database"
    echo '    ],' >> "$database"
}

extract_function_signatures() {
    local project_path="$1"
    local database="$2"
    
    echo "  • Extracting function signatures..."
    
    local swift_files=$(find "$project_path" -name "*.swift" 2>/dev/null)
    
    echo '    "functions": [' >> "$database"
    
    local function_count=0
    echo "$swift_files" | while IFS= read -r file; do
        if [ -f "$file" ]; then
            grep "func [a-zA-Z_][a-zA-Z0-9_]*" "$file" | while read -r line; do
                local function_signature=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*{.*//')
                local function_name=$(echo "$line" | sed 's/.*func \([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/')
                
                if [ $function_count -gt 0 ]; then echo "," >> "$database"; fi
                echo "      {" >> "$database"
                echo "        \"name\": \"$function_name\"," >> "$database"
                echo "        \"signature\": \"$(echo "$function_signature" | sed 's/"/\\"/g')\"," >> "$database"
                echo "        \"file\": \"$(basename "$file")\"" >> "$database"
                echo "      }" >> "$database"
                function_count=$((function_count + 1))
            done
        fi
    done
    
    echo "" >> "$database"
    echo '    ],' >> "$database"
}

extract_type_definitions() {
    local project_path="$1"
    local database="$2"
    
    echo "  • Extracting type definitions..."
    
    echo '    "types": [' >> "$database"
    
    local swift_files=$(find "$project_path" -name "*.swift" 2>/dev/null)
    local type_count=0
    
    echo "$swift_files" | while IFS= read -r file; do
        if [ -f "$file" ]; then
            # Extract typealias
            grep "typealias [a-zA-Z_][a-zA-Z0-9_]*" "$file" | while read -r line; do
                local type_alias=$(echo "$line" | sed 's/.*typealias \([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/')
                
                if [ $type_count -gt 0 ]; then echo "," >> "$database"; fi
                echo "      {\"type\": \"typealias\", \"name\": \"$type_alias\", \"file\": \"$(basename "$file")\"}" >> "$database"
                type_count=$((type_count + 1))
            done
        fi
    done
    
    echo "" >> "$database"
    echo '    ],' >> "$database"
}

extract_property_definitions() {
    local project_path="$1"
    local database="$2"
    
    echo "  • Extracting property definitions..."
    
    echo '    "properties": [' >> "$database"
    
    local swift_files=$(find "$project_path" -name "*.swift" 2>/dev/null)
    local property_count=0
    
    echo "$swift_files" | while IFS= read -r file; do
        if [ -f "$file" ]; then
            # Extract let/var declarations
            grep -E "(let|var) [a-zA-Z_][a-zA-Z0-9_]*" "$file" | while read -r line; do
                local property_name=$(echo "$line" | sed 's/.* \(let\|var\) \([a-zA-Z_][a-zA-Z0-9_]*\).*/\2/')
                local property_type=$(echo "$line" | grep -o ": [a-zA-Z_][a-zA-Z0-9_]*" | sed 's/: //')
                
                if [ $property_count -gt 0 ]; then echo "," >> "$database"; fi
                echo "      {" >> "$database"
                echo "        \"name\": \"$property_name\"," >> "$database"
                echo "        \"type\": \"$property_type\"," >> "$database"
                echo "        \"file\": \"$(basename "$file")\"" >> "$database"
                echo "      }" >> "$database"
                property_count=$((property_count + 1))
            done
        fi
    done
    
    echo "" >> "$database"
    echo '    ],' >> "$database"
}

extract_protocol_definitions() {
    local project_path="$1"
    local database="$2"
    
    echo "  • Extracting protocol definitions..."
    
    echo '    "protocols": [' >> "$database"
    
    local swift_files=$(find "$project_path" -name "*.swift" 2>/dev/null)
    local protocol_count=0
    
    echo "$swift_files" | while IFS= read -r file; do
        if [ -f "$file" ]; then
            grep "protocol [a-zA-Z_][a-zA-Z0-9_]*" "$file" | while read -r line; do
                local protocol_name=$(echo "$line" | sed 's/.*protocol \([a-zA-Z_][a-zA-Z0-9_]*\).*/\1/')
                
                if [ $protocol_count -gt 0 ]; then echo "," >> "$database"; fi
                echo "      {\"name\": \"$protocol_name\", \"file\": \"$(basename "$file")\"}" >> "$database"
                protocol_count=$((protocol_count + 1))
            done
        fi
    done
    
    echo "" >> "$database"
    echo '    ],' >> "$database"
}

extract_import_patterns() {
    local project_path="$1"
    local database="$2"
    
    echo "  • Extracting import patterns..."
    
    echo '    "imports": [' >> "$database"
    
    local swift_files=$(find "$project_path" -name "*.swift" 2>/dev/null)
    local imports=$(echo "$swift_files" | xargs grep "^import " 2>/dev/null | sed 's/.*import //' | sort -u)
    
    local import_count=0
    echo "$imports" | while IFS= read -r import_name; do
        if [ -n "$import_name" ]; then
            if [ $import_count -gt 0 ]; then echo "," >> "$database"; fi
            echo "      \"$import_name\"" >> "$database"
            import_count=$((import_count + 1))
        fi
    done
    
    echo "" >> "$database"
    echo '    ]' >> "$database"
}

# Update database incrementally
update_completion_database() {
    local project_path="$1"
    local database_file="$2"
    local changed_files="$3"
    
    echo "🔄 Updating completion database for changed files..."
    
    # For now, rebuild entire database (could be optimized for incremental updates)
    build_completion_database "$project_path" "$database_file"
    
    echo "✅ Database updated successfully"
}

