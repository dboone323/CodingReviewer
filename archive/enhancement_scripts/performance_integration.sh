#!/bin/bash

# 🚀 Performance-Optimized Master Orchestrator Integration
# Adds smart performance monitoring to existing orchestrator without slowing it down

set -euo pipefail

# Performance monitoring integration
PERF_MONITOR="$(dirname "$0")/advanced_performance_monitor.sh"

# Initialize performance monitoring if available
initialize_performance_integration() {
    if [[ -f "$PERF_MONITOR" ]]; then
        chmod +x "$PERF_MONITOR"
        "$PERF_MONITOR" init > /dev/null 2>&1
        PERFORMANCE_ENABLED=true
    else
        PERFORMANCE_ENABLED=false
    fi
}

# Smart task wrapper that only shows progress for potentially slow operations
perf_monitor_task() {
    local task_name="$1"
    local estimated_duration="$2"  # in seconds
    local estimated_items="${3:-1}"
    shift 3
    local command="$@"
    
    if [[ "$PERFORMANCE_ENABLED" == "true" ]]; then
        # Only show progress for tasks estimated to take >5 seconds
        if (( $(echo "$estimated_duration > 5" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "\033[0;36m⏳ $task_name (estimated: ${estimated_duration}s)\033[0m"
        fi
        
        "$PERF_MONITOR" monitor "$task_name" "$estimated_items" $command
    else
        # Run without monitoring if performance monitor unavailable
        eval "$command"
    fi
}

# Quick performance check (minimal overhead)
quick_perf_check() {
    local task_name="$1"
    local start_time="$2"
    
    if [[ "$PERFORMANCE_ENABLED" == "true" ]]; then
        local duration=$(echo "$(date +%s.%N) - $start_time" | bc -l 2>/dev/null || echo "0")
        if (( $(echo "$duration > 10" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "\033[1;33m🐌 $task_name took ${duration}s - consider optimization\033[0m"
        fi
    fi
}

# Generate performance summary at the end
generate_performance_summary() {
    if [[ "$PERFORMANCE_ENABLED" == "true" ]]; then
        echo ""
        echo -e "\033[1;37m📊 PERFORMANCE SUMMARY\033[0m"
        echo -e "\033[1;37m=====================\033[0m"
        "$PERF_MONITOR" report
        "$PERF_MONITOR" analyze
    fi
}

# Export this for use in other scripts
export -f perf_monitor_task
export -f quick_perf_check
export -f generate_performance_summary
export PERFORMANCE_ENABLED

# Initialize when sourced
initialize_performance_integration

echo -e "\033[0;32m✅ Performance monitoring integration ready\033[0m"
