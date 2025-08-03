#!/bin/bash

#
# ML Maintenance Automation Script
# Automatically refreshes ML data and monitors system health
# Created: August 3, 2025
#

set -e

# Configuration
PROJECT_DIR="/Users/danielstevens/Desktop/CodingReviewer"
LOG_FILE="$PROJECT_DIR/ml_maintenance.log"
HEALTH_CHECK_FILE="$PROJECT_DIR/ml_health_status.json"

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Health check function
check_ml_health() {
    local status="healthy"
    local issues=()
    
    # Check ML directories exist
    for dir in ".ml_automation" ".predictive_analytics" ".cross_project_learning"; do
        if [ ! -d "$PROJECT_DIR/$dir" ]; then
            status="unhealthy"
            issues+=("Missing directory: $dir")
        fi
    done
    
    # Check for recent data files (within last 24 hours)
    local recent_files=0
    for file in $(find "$PROJECT_DIR" -name "*$(date +%Y%m%d)*" -type f 2>/dev/null | grep -E "(ml|predictive|cross)" || true); do
        ((recent_files++))
    done
    
    if [ $recent_files -eq 0 ]; then
        status="unhealthy"
        issues+=("No recent ML data files found")
    fi
    
    # Create health status JSON
    cat > "$HEALTH_CHECK_FILE" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "status": "$status",
    "recent_files_count": $recent_files,
    "issues": [$(printf '"%s",' "${issues[@]}" | sed 's/,$//')],
    "last_refresh": "$(date -Iseconds)"
}
EOF
    
    log_message "Health check completed: $status ($recent_files recent files)"
    return $([ "$status" = "healthy" ] && echo 0 || echo 1)
}

# ML data refresh function
refresh_ml_data() {
    log_message "Starting ML data refresh..."
    
    cd "$PROJECT_DIR"
    
    # Run ML scripts with timeout protection
    local scripts=("predictive_analytics.sh" "cross_project_learning.sh" "advanced_ai_integration.sh")
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            log_message "Running $script..."
            # Run with background process and timeout for macOS compatibility
            "./$script" >> "$LOG_FILE" 2>&1 &
            local script_pid=$!
            local timeout_seconds=300
            
            # Wait for completion or timeout
            local count=0
            while [ $count -lt $timeout_seconds ] && kill -0 $script_pid 2>/dev/null; do
                sleep 1
                ((count++))
            done
            
            if kill -0 $script_pid 2>/dev/null; then
                kill $script_pid 2>/dev/null
                log_message "❌ $script timed out after ${timeout_seconds}s"
            else
                wait $script_pid
                if [ $? -eq 0 ]; then
                    log_message "✅ $script completed successfully"
                else
                    log_message "❌ $script failed with error"
                fi
            fi
        else
            log_message "⚠️  Script not found or not executable: $script"
        fi
    done
    
    log_message "ML data refresh completed"
}

# Data cleanup function
cleanup_old_data() {
    log_message "Starting data cleanup..."
    
    # Remove ML data files older than 7 days
    find "$PROJECT_DIR" -type f \( -path "*/.ml_automation/*" -o -path "*/.predictive_analytics/*" -o -path "*/.cross_project_learning/*" \) -mtime +7 -delete 2>/dev/null || true
    
    # Compress old log files
    find "$PROJECT_DIR" -name "*.log" -mtime +3 -exec gzip {} \; 2>/dev/null || true
    
    log_message "Data cleanup completed"
}

# Main execution
main() {
    log_message "🚀 Starting ML maintenance cycle"
    
    # Create directories if they don't exist
    mkdir -p "$PROJECT_DIR"/{.ml_automation,.predictive_analytics,.cross_project_learning}
    
    # Run maintenance tasks
    refresh_ml_data
    cleanup_old_data
    check_ml_health
    
    if [ $? -eq 0 ]; then
        log_message "✅ ML maintenance cycle completed successfully"
        exit 0
    else
        log_message "❌ ML maintenance cycle completed with issues"
        exit 1
    fi
}

# Run main function
main "$@"
