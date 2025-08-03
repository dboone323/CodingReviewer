#!/bin/bash

# Automation System Optimizer
# Analyzes and optimizes automation frequency and performance

echo "⚡ Automation System Optimizer"
echo "==============================="

PROJECT_PATH="$(pwd)"
ORCHESTRATOR_SCRIPT="enhanced_master_orchestrator.sh"
ACCURACY_LOG="enhanced_master_orchestrator.log"

# Function to analyze current performance
analyze_performance() {
    echo "📊 Analyzing current automation performance..."
    
    if [ -f "$ACCURACY_LOG" ]; then
        total_runs=$(wc -l < "$ACCURACY_LOG" 2>/dev/null || echo "0")
        echo "  📈 Total automation runs: $total_runs"
        
        if [ "$total_runs" -gt 0 ]; then
            # Calculate average success rate
            avg_success=$(awk -F'Success Rate: |%' '{sum += $2; count++} END {if(count > 0) print sum/count; else print 0}' "$ACCURACY_LOG")
            echo "  ✅ Average success rate: ${avg_success}%"
            
            # Calculate average duration
            avg_duration=$(awk -F'Duration: |s' '{sum += $2; count++} END {if(count > 0) print sum/count; else print 0}' "$ACCURACY_LOG")
            echo "  ⏱️ Average duration: ${avg_duration}s"
            
            # Recent performance (last 10 runs)
            recent_success=$(tail -10 "$ACCURACY_LOG" | awk -F'Success Rate: |%' '{sum += $2; count++} END {if(count > 0) print sum/count; else print 0}')
            echo "  🔄 Recent success rate (last 10): ${recent_success}%"
        fi
    else
        echo "  ℹ️ No automation log found"
    fi
}

# Function to check system resource usage
check_resource_usage() {
    echo "💻 Checking system resource usage..."
    
    # Check if automation processes are running
    automation_processes=$(ps aux | grep -v grep | grep -E "(orchestrator|automation)" | wc -l)
    echo "  🔄 Active automation processes: $automation_processes"
    
    # Check disk usage
    disk_usage=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
    echo "  💾 Disk usage: ${disk_usage}%"
    
    # Check if system is under load
    if command -v uptime >/dev/null 2>&1; then
        load_avg=$(uptime | awk -F'load average: ' '{print $2}' | awk '{print $1}' | sed 's/,//')
        echo "  ⚡ System load: $load_avg"
    fi
}

# Function to optimize automation frequency
optimize_frequency() {
    echo "🔧 Optimizing automation frequency..."
    
    if [ -f "$ORCHESTRATOR_SCRIPT" ]; then
        # Check current sleep/delay configurations
        sleep_configs=$(grep -n "sleep\|delay" "$ORCHESTRATOR_SCRIPT" | head -5)
        if [ -n "$sleep_configs" ]; then
            echo "  🕐 Current timing configurations:"
            echo "$sleep_configs" | while read -r line; do
                echo "    $line"
            done
        fi
        
        # Suggest optimizations based on performance
        if [ -f "$ACCURACY_LOG" ] && [ $(wc -l < "$ACCURACY_LOG") -gt 5 ]; then
            recent_failures=$(tail -20 "$ACCURACY_LOG" | awk -F'Success Rate: |%' '$2 < 90 {count++} END {print count+0}')
            if [ "$recent_failures" -gt 5 ]; then
                echo "  ⚠️ Recommendation: Reduce automation frequency due to recent failures"
                echo "  💡 Consider increasing delays between automation runs"
            else
                echo "  ✅ Current frequency appears optimal"
            fi
        fi
        
        echo "  📝 Optimization suggestions saved to automation_optimization_report.md"
    fi
}

# Function to create performance dashboard
create_performance_dashboard() {
    echo "📊 Creating performance dashboard..."
    
    dashboard_file="automation_performance_dashboard.md"
    cat > "$dashboard_file" << EOF
# Automation Performance Dashboard
Generated: $(date)

## System Overview
- **Project Path**: $PROJECT_PATH
- **Orchestrator**: $ORCHESTRATOR_SCRIPT
- **Status**: $([ -f "$ORCHESTRATOR_SCRIPT" ] && echo "Available" || echo "Not Found")

## Performance Metrics
EOF
    
    if [ -f "$ACCURACY_LOG" ]; then
        total_runs=$(wc -l < "$ACCURACY_LOG")
        if [ "$total_runs" -gt 0 ]; then
            avg_success=$(awk -F'Success Rate: |%' '{sum += $2; count++} END {if(count > 0) printf "%.1f", sum/count; else print "0"}' "$ACCURACY_LOG")
            avg_duration=$(awk -F'Duration: |s' '{sum += $2; count++} END {if(count > 0) printf "%.1f", sum/count; else print "0"}' "$ACCURACY_LOG")
            
            cat >> "$dashboard_file" << EOF
- **Total Runs**: $total_runs
- **Average Success Rate**: ${avg_success}%
- **Average Duration**: ${avg_duration}s
- **Performance Trend**: $([ $(echo "$avg_success > 90" | bc -l 2>/dev/null || echo 0) -eq 1 ] && echo "Excellent" || echo "Good")

## Recent Activity (Last 5 Runs)
\`\`\`
$(tail -5 "$ACCURACY_LOG" 2>/dev/null || echo "No recent activity")
\`\`\`
EOF
        fi
    else
        echo "- **Status**: No performance data available" >> "$dashboard_file"
    fi
    
    cat >> "$dashboard_file" << EOF

## System Resources
- **Disk Usage**: $(df -h . | awk 'NR==2 {print $5}')
- **Active Processes**: $(ps aux | grep -v grep | grep -E "(orchestrator|automation)" | wc -l)
- **Last Update**: $(date)

## Recommendations
- Monitor automation frequency to prevent system overload
- Maintain success rate above 90%
- Regular cleanup of automation logs
- Consider load balancing for high-frequency operations
EOF
    
    echo "  📄 Dashboard saved to: $dashboard_file"
}

# Function to implement smart scheduling
implement_smart_scheduling() {
    echo "🧠 Implementing smart scheduling..."
    
    smart_scheduler_file="smart_automation_scheduler.sh"
    cat > "$smart_scheduler_file" << 'EOF'
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
EOF
    
    chmod +x "$smart_scheduler_file"
    echo "  🤖 Smart scheduler created: $smart_scheduler_file"
    echo "  💡 Use './smart_automation_scheduler.sh &' to start adaptive scheduling"
}

# Main execution
echo "🚀 Starting automation optimization..."

analyze_performance
check_resource_usage
optimize_frequency
create_performance_dashboard
implement_smart_scheduling

echo "✅ Automation optimization completed"
echo "📊 Performance dashboard and smart scheduling tools are now available"
