#!/bin/bash

# Smart Automation Scheduler
# Adaptive scheduling based on system performance and load

ORCHESTRATOR="./enhanced_master_orchestrator.sh"
LOG_FILE="enhanced_master_orchestrator.log"
SCHEDULER_LOG="smart_scheduler.log"

# Default intervals (in seconds)
DEFAULT_INTERVAL=300  # 5 minutes
MIN_INTERVAL=180      # 3 minutes  
MAX_INTERVAL=1800     # 30 minutes

get_adaptive_interval() {
    local current_interval=$DEFAULT_INTERVAL
    
    # Check recent success rate
    if [ -f "$LOG_FILE" ]; then
        recent_success=$(tail -5 "$LOG_FILE" | awk -F'Success Rate: |%' '{sum += $2; count++} END {if(count > 0) print sum/count; else print 100}')
        
        # Adjust interval based on success rate
        if [ $(echo "$recent_success < 70" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
            current_interval=$MAX_INTERVAL  # Slow down if failing
        elif [ $(echo "$recent_success > 95" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
            current_interval=$MIN_INTERVAL  # Speed up if very successful
        fi
    fi
    
    # Check system load
    if command -v uptime >/dev/null 2>&1; then
        load_avg=$(uptime | awk -F'load average: ' '{print $2}' | awk '{print $1}' | sed 's/,//')
        if [ $(echo "$load_avg > 2.0" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
            current_interval=$((current_interval * 2))  # Double interval if system is loaded
        fi
    fi
    
    echo $current_interval
}

echo "$(date): Smart scheduler started" >> "$SCHEDULER_LOG"
echo "🧠 Smart Automation Scheduler Started"

while true; do
    interval=$(get_adaptive_interval)
    echo "$(date): Next run in ${interval}s (adaptive scheduling)" >> "$SCHEDULER_LOG"
    echo "⏰ Next automation run in ${interval}s"
    
    sleep $interval
    
    if [ -f "$ORCHESTRATOR" ]; then
        echo "$(date): Running automation cycle" >> "$SCHEDULER_LOG"
        "$ORCHESTRATOR" >/dev/null 2>&1 &
    fi
done
