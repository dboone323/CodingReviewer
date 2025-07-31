#!/bin/bash

# 🚀 Simple Performance Monitor
# Compatible with all bash versions, tracks task performance efficiently

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"
PERF_DIR="$PROJECT_PATH/.performance_monitoring"
PERF_LOG="$PERF_DIR/simple_performance.log"

# Performance thresholds
FAST_THRESHOLD=2
SLOW_THRESHOLD=10
VERY_SLOW_THRESHOLD=30

# Simple performance tracking
TOTAL_TASKS=0
COMPLETED_TASKS=0

# Initialize performance monitoring
init_performance() {
    mkdir -p "$PERF_DIR"
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - Simple performance monitoring initialized" > "$PERF_LOG"
    echo -e "${GREEN}✅ Performance monitoring initialized${NC}"
}

# Smart progress bar that doesn't slow things down
show_progress() {
    local task_name="$1"
    local current="$2"
    local total="$3"
    
    # Only show progress for larger operations
    if [[ "$total" -gt 5 ]]; then
        local percentage=$((current * 100 / total))
        local bar_length=15
        local filled_length=$((percentage * bar_length / 100))
        
        local bar=""
        for ((i=0; i<filled_length; i++)); do bar+="█"; done
        for ((i=filled_length; i<bar_length; i++)); do bar+="░"; done
        
        # Only update every few iterations to avoid slowdown
        if [[ $((current % 3)) -eq 0 ]] || [[ "$current" -eq "$total" ]]; then
            printf "\r${CYAN}⏳ %s [%s] %d%%${NC}" "$task_name" "$bar" "$percentage"
            if [[ "$current" -eq "$total" ]]; then
                echo "" # New line when complete
            fi
        fi
    fi
}

# Time a task execution with minimal overhead
time_task() {
    local task_name="$1"
    shift
    local command="$@"
    
    echo -e "${BLUE}🚀 Starting: ${task_name}${NC}"
    local start_time=$(date +%s)
    
    # Execute command
    local exit_code=0
    eval "$command" || exit_code=$?
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Analyze performance
    local status_icon="⚡"
    local status_color="$GREEN"
    local status_text="FAST"
    
    if [[ "$duration" -gt "$VERY_SLOW_THRESHOLD" ]]; then
        status_icon="🚨"
        status_color="$RED"
        status_text="VERY SLOW"
    elif [[ "$duration" -gt "$SLOW_THRESHOLD" ]]; then
        status_icon="🐌"
        status_color="$RED"  
        status_text="SLOW"
    elif [[ "$duration" -gt "$FAST_THRESHOLD" ]]; then
        status_icon="⏱️"
        status_color="$YELLOW"
        status_text="NORMAL"
    fi
    
    # Log and display results
    echo -e "${status_color}${status_icon} ${task_name}: ${duration}s (${status_text})${NC}"
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - $task_name: ${duration}s - $status_text" >> "$PERF_LOG"
    
    # Suggest optimizations for slow tasks
    if [[ "$duration" -gt "$SLOW_THRESHOLD" ]]; then
        suggest_optimization "$task_name" "$duration"
    fi
    
    TOTAL_TASKS=$((TOTAL_TASKS + 1))
    COMPLETED_TASKS=$((COMPLETED_TASKS + 1))
    
    return $exit_code
}

# Suggest optimizations for slow tasks
suggest_optimization() {
    local task_name="$1"
    local duration="$2"
    
    echo -e "${YELLOW}💡 Optimization suggestion for '$task_name' (${duration}s):${NC}"
    
    case "$task_name" in
        *"build"*|*"validation"*)
            echo -e "${BLUE}  • Enable parallel processing${NC}"
            echo -e "${BLUE}  • Use incremental builds${NC}"
            ;;
        *"security"*|*"scan"*)
            echo -e "${BLUE}  • Use differential scanning${NC}"
            echo -e "${BLUE}  • Exclude vendor directories${NC}"
            ;;
        *"ai"*|*"learning"*)
            echo -e "${BLUE}  • Enable pattern caching${NC}"
            echo -e "${BLUE}  • Use batch processing${NC}"
            ;;
        *)
            echo -e "${BLUE}  • Consider breaking into smaller tasks${NC}"
            echo -e "${BLUE}  • Look for parallelization opportunities${NC}"
            ;;
    esac
}

# Show performance summary  
show_summary() {
    echo ""
    echo -e "${WHITE}📊 PERFORMANCE SUMMARY${NC}"
    echo -e "${WHITE}=====================${NC}"
    echo -e "${GREEN}📈 Total Tasks Completed: $COMPLETED_TASKS${NC}"
    
    # Count slow tasks from log
    if [[ -f "$PERF_LOG" ]]; then
        local slow_count=$(grep -c "SLOW\|VERY SLOW" "$PERF_LOG" 2>/dev/null || echo "0")
        local fast_count=$(grep -c "FAST" "$PERF_LOG" 2>/dev/null || echo "0")
        local normal_count=$(grep -c "NORMAL" "$PERF_LOG" 2>/dev/null || echo "0")
        
        # Remove any newlines or extra characters
        slow_count=$(echo "$slow_count" | tr -d '\n' | tr -d ' ')
        fast_count=$(echo "$fast_count" | tr -d '\n' | tr -d ' ')
        normal_count=$(echo "$normal_count" | tr -d '\n' | tr -d ' ')
        
        echo -e "${GREEN}⚡ Fast Tasks: $fast_count${NC}"
        echo -e "${YELLOW}⏱️  Normal Tasks: $normal_count${NC}"
        echo -e "${RED}🐌 Slow Tasks: $slow_count${NC}"
        
        if [[ "$slow_count" -gt 0 ]] 2>/dev/null; then
            echo ""
            echo -e "${YELLOW}🔧 Consider running optimizations to improve slow tasks${NC}"
            echo -e "${CYAN}💡 Run: ./task_optimizer.sh apply${NC}"
        fi
    fi
}

# Quick performance check for inline use
quick_check() {
    local task_name="$1"
    local start_time="$2"
    
    local duration=$(echo "$(date +%s) - $start_time" | bc 2>/dev/null || echo "0")
    
    if [[ "$duration" -gt "$SLOW_THRESHOLD" ]]; then
        echo -e "${YELLOW}🐌 $task_name took ${duration}s - consider optimization${NC}"
    fi
}

# Export functions for use in other scripts
export -f show_progress 2>/dev/null || true
export -f time_task 2>/dev/null || true
export -f quick_check 2>/dev/null || true

# Main interface
main() {
    local command="${1:-help}"
    
    case "$command" in
        "init")
            init_performance
            ;;
        "time")
            shift
            time_task "$@"
            ;;
        "summary"|"report")
            show_summary
            ;;
        "check")
            quick_check "$2" "$3"
            ;;
        "progress")
            show_progress "$2" "$3" "$4"
            ;;
        "help"|*)
            echo -e "${WHITE}🚀 Simple Performance Monitor${NC}"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  init                    - Initialize performance monitoring"
            echo "  time <task> <command>   - Time a task execution"
            echo "  summary                 - Show performance summary"
            echo "  check <task> <start>    - Quick performance check"
            echo "  progress <task> <n> <t> - Show progress bar"
            echo ""
            echo "Examples:"
            echo "  $0 time \"Build\" \"./build_script.sh\""
            echo "  $0 progress \"Processing\" 50 100"
            ;;
    esac
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
