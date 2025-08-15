#!/bin/bash

# AI Excellence System Monitoring Script
# Prevents dependency issues and system failures

echo "🤖 AI Excellence System Monitor"
echo "==============================="

# Check if Python dependencies are installed
check_dependencies() {
    echo "🔍 Checking Python ML dependencies..."
    
    DEPS=("numpy" "pandas" "scikit-learn" "torch")
    MISSING_DEPS=()
    
    for dep in "${DEPS[@]}"; do
        if python3 -c "import $dep" 2>/dev/null; then
            echo "  ✅ $dep: Installed"
        else
            echo "  ❌ $dep: Missing"
            MISSING_DEPS+=("$dep")
        fi
    done
    
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        echo ""
        echo "⚠️  Missing dependencies detected!"
        echo "Installing missing packages..."
        python3 -m pip install "${MISSING_DEPS[@]}"
        
        if [ $? -eq 0 ]; then
            echo "✅ Dependencies installed successfully"
        else
            echo "❌ Failed to install dependencies"
            echo "Manual installation required: pip install ${MISSING_DEPS[*]}"
            return 1
        fi
    fi
    
    return 0
}

# Quick AI system test
test_ai_system() {
    echo ""
    echo "🧠 Testing AI system components..."
    
    # Test neural networks
    echo "  Testing neural networks..."
    if python3 ai_intelligence/neural_networks/performance_predictor.py > /dev/null 2>&1; then
        echo "  ✅ Neural networks: Operational"
    else
        echo "  ❌ Neural networks: Failed"
        return 1
    fi
    
    # Test autonomous systems (quick test)
    echo "  Testing autonomous systems..."
    if bash ai_intelligence/autonomous_systems/optimization_engine.sh > /dev/null 2>&1; then
        echo "  ✅ Autonomous systems: Operational"
    else
        echo "  ❌ Autonomous systems: Failed"
        return 1
    fi
    
    return 0
}

# Generate alert if system is failing
generate_alert() {
    local issue_type="$1"
    local session_id="monitor_$(date +%Y%m%d_%H%M%S)"
    
    cat > "ai_data/alerts/alert_${session_id}.json" << EOF
{
  "alert_type": "ai_system_failure",
  "session_id": "${session_id}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "issue": "${issue_type}",
  "status": "needs_attention",
  "recommendations": [
    "Run full health check: python3 ai_intelligence/ai_system_health_check.py",
    "Check dependencies: pip install -r requirements.txt",
    "Verify AI configuration: ai_intelligence/ai_config.json"
  ],
  "automated_response": "System monitoring detected AI component failure"
}
EOF

    echo "🚨 Alert generated: ai_data/alerts/alert_${session_id}.json"
}

# Main monitoring flow
main() {
    # Create alerts directory
    mkdir -p ai_data/alerts
    
    # Check dependencies
    if ! check_dependencies; then
        generate_alert "dependency_failure"
        echo "🚨 Dependency check failed - alert generated"
        exit 1
    fi
    
    # Test AI system
    if ! test_ai_system; then
        generate_alert "system_failure"
        echo "🚨 AI system test failed - alert generated"
        exit 1
    fi
    
    echo ""
    echo "✅ AI Excellence System Monitor: All systems operational"
    echo "📊 Last check: $(date)"
    
    # Update status file
    cat > ai_data/system_status.json << EOF
{
  "last_check": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "operational",
  "dependencies": "installed",
  "neural_networks": "operational",
  "autonomous_systems": "operational",
  "monitor_version": "1.0"
}
EOF
    
    return 0
}

# Run main function
main "$@"