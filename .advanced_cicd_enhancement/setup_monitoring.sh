#!/bin/bash

# Infrastructure Monitoring Setup

echo "📊 Setting up infrastructure monitoring..."

ENVIRONMENT="${1:-staging}"

echo "🔍 Configuring CloudWatch alarms for $ENVIRONMENT..."

# CPU utilization alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "$ENVIRONMENT-high-cpu" \
    --alarm-description "High CPU utilization" \
    --metric-name CPUUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2

# Memory utilization alarm  
aws cloudwatch put-metric-alarm \
    --alarm-name "$ENVIRONMENT-high-memory" \
    --alarm-description "High memory utilization" \
    --metric-name MemoryUtilization \
    --namespace AWS/ECS \
    --statistic Average \
    --period 300 \
    --threshold 85 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2

echo "✅ Monitoring setup complete for $ENVIRONMENT"
