#!/bin/bash

# Rollback Monitoring Service
# Continuously monitors system health for rollback triggers

echo "👁️ Starting Rollback Monitoring Service..."

MONITORING_INTERVAL=60  # Check every 60 seconds
MAX_ITERATIONS=1440     # Run for 24 hours maximum

iteration=0

while [ $iteration -lt $MAX_ITERATIONS ]; do
    echo "🔍 Health check iteration $((iteration + 1))"
    
    # Run rollback trigger check
    if [ -f "automated_rollback.sh" ]; then
        ./automated_rollback.sh check
    fi
    
    # Wait for next iteration
    sleep $MONITORING_INTERVAL
    iteration=$((iteration + 1))
done

echo "⏰ Monitoring service completed 24-hour cycle"
