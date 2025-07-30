#!/bin/bash

# Canary Configuration Validator

echo "🔍 Validating Canary Deployment Configuration"
echo "============================================="

config_file="${1:-canary_deployment.json}"

if [ ! -f "$config_file" ]; then
    echo "❌ Configuration file not found: $config_file"
    exit 1
fi

echo "📋 Checking configuration validity..."

# Validate JSON structure
if ! jq empty "$config_file" 2>/dev/null; then
    echo "❌ Invalid JSON format"
    exit 1
fi

# Check required fields
required_fields=("strategy" "monitoring" "automation")
for field in "${required_fields[@]}"; do
    if ! jq -e ".canary_deployment.$field" "$config_file" >/dev/null; then
        echo "❌ Missing required field: $field"
        exit 1
    fi
done

# Validate strategy parameters
initial_percentage=$(jq -r '.canary_deployment.strategy.initial_traffic_percentage' "$config_file")
max_percentage=$(jq -r '.canary_deployment.strategy.max_traffic_percentage' "$config_file")

if [ "$initial_percentage" -ge "$max_percentage" ]; then
    echo "❌ Initial traffic percentage must be less than maximum"
    exit 1
fi

echo "✅ Configuration validation passed"
echo "📊 Configuration summary:"
echo "  Initial traffic: $initial_percentage%"
echo "  Maximum traffic: $max_percentage%"
echo "  Auto-promote: $(jq -r '.canary_deployment.automation.auto_promote' "$config_file")"
echo "  Auto-rollback: $(jq -r '.canary_deployment.automation.auto_rollback' "$config_file")"
