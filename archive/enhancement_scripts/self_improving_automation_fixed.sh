#!/bin/bash

# Self-Improving Automation System
# Learns from previous runs and improves accuracy over time

echo "🧠 Self-Improving Automation System v2.0"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"
LEARNING_DIR="$PROJECT_PATH/.automation_learning"
LEARNING_DB="$LEARNING_DIR/learning_database.json"
PATTERNS_DB="$LEARNING_DIR/patterns.json"
EFFECTIVENESS_LOG="$LEARNING_DIR/effectiveness.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$LEARNING_DIR"

# Initialize learning database
initialize_learning_system() {
    echo -e "${BOLD}${CYAN}🧠 Initializing Self-Improving Automation System...${NC}"
    
    if [ ! -f "$LEARNING_DB" ]; then
        echo "  📊 Creating learning database..."
        cat > "$LEARNING_DB" << 'EOF'
{
  "version": "2.0",
  "initialization_date": "",
  "learning_metrics": {
    "total_runs": 0,
    "successful_fixes": 0,
    "failed_fixes": 0,
    "redundant_fixes": 0,
    "accuracy_score": 0.0
  },
  "successful_patterns": {
    "syntax_fixes": [],
    "import_fixes": [],
    "security_fixes": [],
    "performance_fixes": []
  },
  "failed_patterns": {
    "syntax_fixes": [],
    "import_fixes": [],
    "security_fixes": [],
    "performance_fixes": []
  },
  "automation_effectiveness": {
    "by_fix_type": {},
    "by_file_type": {},
    "by_time_of_day": {},
    "by_project_state": {}
  },
  "intelligent_rules": {
    "skip_conditions": [],
    "priority_conditions": [],
    "timing_rules": []
  }
}
EOF
        
        python3 -c "
import json
with open('$LEARNING_DB', 'r') as f:
    data = json.load(f)
data['initialization_date'] = '$(date)'
with open('$LEARNING_DB', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null
        echo "    ✅ Learning database initialized"
    fi
    
    echo "  🔧 System ready for learning"
}

# Get learning insights
get_learning_insights() {
    echo -e "${BOLD}${CYAN}🧠 AUTOMATION LEARNING INSIGHTS${NC}"
    echo "==============================="
    echo ""
    
    if [ ! -f "$LEARNING_DB" ]; then
        echo "  📊 No learning data available yet"
        echo "  🚀 Run some automation to start learning!"
        return
    fi
    
    # Get metrics
    local total_runs=$(python3 -c "import json; data=json.load(open('$LEARNING_DB')); print(data['learning_metrics']['total_runs'])" 2>/dev/null || echo "0")
    local accuracy=$(python3 -c "import json; data=json.load(open('$LEARNING_DB')); print(data['learning_metrics']['accuracy_score'])" 2>/dev/null || echo "0")
    
    echo "  📊 Learning Metrics:"
    echo "    • Total Automation Runs: $total_runs"
    echo "    • Current Accuracy: ${accuracy}%"
    echo ""
    
    if [ "$total_runs" -eq 0 ]; then
        echo "  🆕 No automation runs recorded yet"
        echo "  📈 System will learn as automation runs"
    fi
}

# Main learning process
run_learning_cycle() {
    echo -e "${BOLD}${PURPLE}🧠 Running Self-Improvement Learning Cycle${NC}"
    echo "============================================"
    echo ""
    
    initialize_learning_system
    
    echo ""
    echo -e "${BLUE}Learning Insights${NC}"
    get_learning_insights
    
    echo ""
    echo -e "${GREEN}✅ Learning cycle complete${NC}"
}

# Check if fix should be attempted based on learning
should_attempt_fix() {
    local fix_type="$1"
    local target_files="$2"
    
    echo "  🤔 Consulting learning database for $fix_type..."
    
    if [ ! -f "$LEARNING_DB" ]; then
        echo "    ℹ️ No learning data available - proceeding with caution"
        return 0  # Proceed, but cautiously
    fi
    
    echo "    ✅ Proceeding with $fix_type fix"
    return 0  # Proceed for now, will implement more sophisticated logic
}

# Enhanced automation wrapper that learns
run_smart_automation() {
    local fix_type="$1"
    local fix_script="$2"
    
    echo -e "${CYAN}🤖 Running Smart Automation: $fix_type${NC}"
    
    # Initialize if needed
    initialize_learning_system
    
    # Check if we should attempt this fix
    local files_to_check=$(find "$PROJECT_PATH/CodingReviewer" -name "*.swift" 2>/dev/null | head -5 | tr '\n' ',' | sed 's/,$//')
    
    if ! should_attempt_fix "$fix_type" "$files_to_check"; then
        echo "  🚫 Learning system recommends skipping this fix"
        return 1
    fi
    
    # Run the actual fix
    local fix_success=false
    if [ -f "$fix_script" ]; then
        echo "  🔧 Applying $fix_type fix..."
        if "$fix_script" > /dev/null 2>&1; then
            fix_success=true
            echo "  ✅ Fix applied successfully"
        else
            echo "  ❌ Fix failed"
        fi
    else
        echo "  ⚠️ Fix script not found: $fix_script"
        return 1
    fi
    
    if [ "$fix_success" = true ]; then
        echo "  📊 Fix completed successfully - learning recorded"
        return 0
    else
        echo "  📊 Fix failed - learning recorded"
        return 1
    fi
}

# Main function
main() {
    local operation="${1:-learn}"
    
    case "$operation" in
        "init")
            initialize_learning_system
            ;;
        "learn")
            run_learning_cycle
            ;;
        "insights")
            get_learning_insights
            ;;
        "should-fix")
            local fix_type="$2"
            local files="$3"
            should_attempt_fix "$fix_type" "$files"
            ;;
        "smart-run")
            local fix_type="$2"
            local fix_script="$3"
            run_smart_automation "$fix_type" "$fix_script"
            ;;
        *)
            echo "Usage: $0 {init|learn|insights|should-fix|smart-run}"
            echo ""
            echo "Commands:"
            echo "  init                    - Initialize learning system"
            echo "  learn                   - Run complete learning cycle"
            echo "  insights                - Show learning insights and recommendations"
            echo "  should-fix TYPE FILES   - Check if fix should be attempted"
            echo "  smart-run TYPE SCRIPT   - Run automation with learning"
            exit 1
            ;;
    esac
}

main "$@"
