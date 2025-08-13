#!/bin/bash

# File Corruption Detective
# Monitors the self_improving_automation.sh file and catches what's modifying it

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"
TARGET_FILE="$PROJECT_PATH/self_improving_automation.sh"
LOG_FILE="$PROJECT_PATH/.file_corruption_log.txt"

echo "🕵️ File Corruption Detective Started: $(date)" >> "$LOG_FILE"
echo "📋 Monitoring: $TARGET_FILE" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"

# Get initial file info
initial_size=$(stat -f%z "$TARGET_FILE" 2>/dev/null || echo "0")
initial_lines=$(wc -l < "$TARGET_FILE" 2>/dev/null || echo "0")

echo "Initial file size: $initial_size bytes" >> "$LOG_FILE"
echo "Initial line count: $initial_lines lines" >> "$LOG_FILE"

# Monitor for 60 seconds
for i in {1..60}; do
    current_size=$(stat -f%z "$TARGET_FILE" 2>/dev/null || echo "0")
    current_lines=$(wc -l < "$TARGET_FILE" 2>/dev/null || echo "0")
    
    if [[ $current_size -ne $initial_size || $current_lines -ne $initial_lines ]]; then
        echo "🚨 CHANGE DETECTED at $(date)!" >> "$LOG_FILE"
        echo "Size changed from $initial_size to $current_size bytes" >> "$LOG_FILE"
        echo "Lines changed from $initial_lines to $current_lines lines" >> "$LOG_FILE"
        
        # Capture running processes
        echo "📋 Running processes at time of change:" >> "$LOG_FILE"
        ps aux | grep -E "(bash|sh|automation)" >> "$LOG_FILE"
        
        # Check what might be writing to the file
        echo "📋 Open file handles:" >> "$LOG_FILE"
        lsof "$TARGET_FILE" 2>/dev/null >> "$LOG_FILE" || echo "No open handles found" >> "$LOG_FILE"
        
        echo "===============================================" >> "$LOG_FILE"
        
        # Update baseline
        initial_size=$current_size
        initial_lines=$current_lines
    fi
    
    sleep 1
done

echo "🕵️ File Corruption Detective Finished: $(date)" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"

# Show results
echo "📋 Monitoring Results:"
tail -20 "$LOG_FILE"
