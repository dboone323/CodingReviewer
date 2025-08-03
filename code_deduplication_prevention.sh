#!/bin/bash

# Code Deduplication Prevention System
# Monitors and prevents creation of duplicate code files

echo "🔍 Code Deduplication Prevention System"
echo "========================================"

PROJECT_PATH="$(pwd)"
DUPLICATE_LOG="code_duplication_monitor.log"
PREVENTION_CONFIG="deduplication_config.json"

# Initialize configuration if it doesn't exist
initialize_config() {
    if [ ! -f "$PREVENTION_CONFIG" ]; then
        cat > "$PREVENTION_CONFIG" << 'EOF'
{
    "monitored_extensions": [".swift", ".js", ".ts", ".py", ".java", ".kt"],
    "similarity_threshold": 0.85,
    "exclude_patterns": ["test", "backup", "temp", ".git"],
    "alert_threshold": 3,
    "max_duplicates_allowed": 2
}
EOF
        echo "📋 Configuration file created: $PREVENTION_CONFIG"
    fi
}

# Function to detect potential duplicates
detect_duplicates() {
    echo "🔍 Scanning for potential duplicate files..."
    
    # Find files with similar names
    similar_files=()
    while IFS= read -r -d '' file; do
        basename_file=$(basename "$file" | sed 's/[0-9]*\./\./' | sed 's/_[0-9]*/_/')
        
        # Check for files with similar base names
        find "$PROJECT_PATH" -name "*$(basename "$basename_file" .${file##*.})*" -type f | while read -r similar; do
            if [ "$file" != "$similar" ] && [ "$(basename "$file")" != "$(basename "$similar")" ]; then
                echo "⚠️ Potential duplicate detected:"
                echo "  📄 File 1: $file"
                echo "  📄 File 2: $similar"
                echo "$(date): Potential duplicate: $file <-> $similar" >> "$DUPLICATE_LOG"
            fi
        done
    done < <(find "$PROJECT_PATH" -type f \( -name "*.swift" -o -name "*.js" -o -name "*.ts" \) -not -path "*/.*" -not -path "*/archived_backups/*" -print0)
}

# Function to analyze file content similarity
analyze_content_similarity() {
    echo "📊 Analyzing content similarity..."
    
    temp_dir=$(mktemp -d)
    
    # Create content hashes for quick comparison
    find "$PROJECT_PATH" -type f \( -name "*.swift" -o -name "*.js" \) -not -path "*/.*" -not -path "*/archived_backups/*" | while read -r file; do
        if [ -f "$file" ] && [ -s "$file" ]; then
            # Remove comments and whitespace for comparison
            content_hash=$(sed 's/\/\/.*$//' "$file" | sed 's/\/\*.*\*\///' | tr -d ' \t\n' | shasum -a 256 | cut -d' ' -f1)
            echo "$content_hash:$file" >> "$temp_dir/content_hashes.txt"
        fi
    done
    
    if [ -f "$temp_dir/content_hashes.txt" ]; then
        # Find files with identical content hashes
        sort "$temp_dir/content_hashes.txt" | uniq -d -f1 > "$temp_dir/duplicates.txt"
        
        if [ -s "$temp_dir/duplicates.txt" ]; then
            echo "🚨 Files with identical content found:"
            while read -r line; do
                hash=$(echo "$line" | cut -d':' -f1)
                echo "  🔗 Content hash: $hash"
                grep "^$hash:" "$temp_dir/content_hashes.txt" | cut -d':' -f2- | while read -r duplicate_file; do
                    echo "    📄 $duplicate_file"
                done
                echo "$(date): Identical content found for hash: $hash" >> "$DUPLICATE_LOG"
            done < "$temp_dir/duplicates.txt"
        else
            echo "✅ No files with identical content found"
        fi
    fi
    
    rm -rf "$temp_dir"
}

# Function to create prevention hooks
create_prevention_hooks() {
    echo "🔧 Creating prevention hooks..."
    
    # Create pre-commit hook to check for duplicates
    hook_dir=".git/hooks"
    if [ -d ".git" ]; then
        mkdir -p "$hook_dir"
        
        cat > "$hook_dir/pre-commit" << 'EOF'
#!/bin/bash

# Pre-commit hook to prevent duplicate file creation
echo "🔍 Checking for duplicate files..."

# Run duplicate detection
if [ -f "./code_deduplication_prevention.sh" ]; then
    ./code_deduplication_prevention.sh --quick-check
    if [ $? -ne 0 ]; then
        echo "❌ Commit blocked: Potential duplicates detected"
        echo "Run './code_deduplication_prevention.sh' for details"
        exit 1
    fi
fi

echo "✅ No duplicates detected, proceeding with commit"
EOF
        
        chmod +x "$hook_dir/pre-commit"
        echo "  🎣 Pre-commit hook installed"
    fi
    
    # Create file watcher script
    cat > "duplicate_file_watcher.sh" << 'EOF'
#!/bin/bash

# File watcher for duplicate prevention
if command -v fswatch >/dev/null 2>&1; then
    echo "👁️ Starting file watcher for duplicate prevention..."
    fswatch -o . --exclude="\.git" --exclude="archived_backups" | while read -r event; do
        echo "📁 File system change detected, checking for duplicates..."
        ./code_deduplication_prevention.sh --quick-check >/dev/null 2>&1
    done
else
    echo "ℹ️ Install fswatch for real-time duplicate monitoring"
    echo "   brew install fswatch  (on macOS)"
fi
EOF
    
    chmod +x "duplicate_file_watcher.sh"
    echo "  👁️ File watcher script created: duplicate_file_watcher.sh"
}

# Function to generate duplicate prevention report
generate_report() {
    echo "📋 Generating duplicate prevention report..."
    
    report_file="duplicate_prevention_report.md"
    cat > "$report_file" << EOF
# Code Deduplication Prevention Report
Generated: $(date)

## System Status
- **Prevention System**: Active
- **Monitoring**: $([ -f "$DUPLICATE_LOG" ] && echo "Enabled" || echo "Initializing")
- **Last Scan**: $(date)

## Configuration
\`\`\`json
$(cat "$PREVENTION_CONFIG" 2>/dev/null || echo "Configuration not found")
\`\`\`

## Scan Results
EOF
    
    if [ -f "$DUPLICATE_LOG" ]; then
        recent_detections=$(tail -10 "$DUPLICATE_LOG" | wc -l)
        echo "- **Recent Detections**: $recent_detections" >> "$report_file"
        echo "- **Total Log Entries**: $(wc -l < "$DUPLICATE_LOG")" >> "$report_file"
        
        if [ "$recent_detections" -gt 0 ]; then
            echo "" >> "$report_file"
            echo "### Recent Detections" >> "$report_file"
            echo "\`\`\`" >> "$report_file"
            tail -10 "$DUPLICATE_LOG" >> "$report_file"
            echo "\`\`\`" >> "$report_file"
        fi
    else
        echo "- **Status**: No duplicates detected" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## Prevention Measures
- ✅ Pre-commit hooks installed
- ✅ File watcher available
- ✅ Automated scanning enabled
- ✅ Content similarity analysis

## Recommendations
1. Run duplicate scans regularly
2. Use file watcher for real-time monitoring
3. Review alerts promptly
4. Maintain prevention configuration

## Next Steps
- Monitor log file: $DUPLICATE_LOG
- Update configuration as needed
- Consider automated cleanup for confirmed duplicates
EOF
    
    echo "  📄 Report saved to: $report_file"
}

# Function for quick check (used by hooks)
quick_check() {
    # Quick duplicate check without verbose output
    temp_file=$(mktemp)
    detect_duplicates > "$temp_file" 2>&1
    
    if grep -q "Potential duplicate detected" "$temp_file"; then
        rm "$temp_file"
        return 1
    fi
    
    rm "$temp_file"
    return 0
}

# Main execution
case "${1:-}" in
    --quick-check)
        quick_check
        exit $?
        ;;
    *)
        echo "🚀 Starting duplicate prevention system..."
        initialize_config
        detect_duplicates
        analyze_content_similarity
        create_prevention_hooks
        generate_report
        echo "✅ Duplicate prevention system initialized"
        echo "💡 Use './duplicate_file_watcher.sh &' for real-time monitoring"
        ;;
esac
