#!/bin/bash

# Automation State Tracker
# Tracks what has been fixed and prevents redundant automation

echo "📊 Automation State Tracker"
echo "==========================="
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
STATE_DIR="$PROJECT_PATH/.automation_state"
STATE_DB="$STATE_DIR/automation_state.json"
FIXES_LOG="$STATE_DIR/fixes_applied.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$STATE_DIR"

# Initialize state database if it doesn't exist
initialize_state_db() {
    if [ ! -f "$STATE_DB" ]; then
        echo "  📊 Creating automation state database..."
        cat > "$STATE_DB" << 'EOF'
{
  "project_hash": "",
  "last_analysis": "",
  "fixes_applied": {
    "syntax_errors": {
      "count": 0,
      "last_fixed": "",
      "files_fixed": []
    },
    "import_issues": {
      "count": 0,
      "last_fixed": "",
      "files_fixed": []
    },
    "force_unwrapping": {
      "count": 0,
      "last_fixed": "",
      "files_fixed": []
    },
    "swiftlint_issues": {
      "count": 0,
      "last_fixed": "",
      "files_fixed": []
    },
    "security_issues": {
      "count": 0,
      "last_fixed": "",
      "files_fixed": []
    },
    "performance_issues": {
      "count": 0,
      "last_fixed": "",
      "files_fixed": []
    }
  },
  "automation_runs": {
    "total_runs": 0,
    "successful_runs": 0,
    "failed_runs": 0,
    "last_run": "",
    "average_duration": 0
  },
  "learning_data": {
    "successful_patterns": [],
    "failed_patterns": [],
    "effectiveness_scores": {}
  }
}
EOF
        echo "    ✅ State database initialized"
    fi
}

# Calculate project hash to detect changes
calculate_project_hash() {
    echo "  🔍 Calculating project hash..." >&2
    
    # Hash all Swift files and project configuration
    local project_hash=""
    if [ -d "$PROJECT_PATH/CodingReviewer" ] && [ -f "$PROJECT_PATH/CodingReviewer.xcodeproj/project.pbxproj" ]; then
        project_hash=$(find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -type f -exec cat {} \; 2>/dev/null | \
                      cat "$PROJECT_PATH/CodingReviewer.xcodeproj/project.pbxproj" - 2>/dev/null | \
                      shasum -a 256 2>/dev/null | cut -d' ' -f1 || echo "default_hash")
    else
        project_hash="default_hash"
    fi
    
    echo "$project_hash"
}

# Check if project has changed since last analysis
has_project_changed() {
    local current_hash=$(calculate_project_hash)
    local stored_hash=$(python3 -c "import json; data=json.load(open('$STATE_DB')); print(data['project_hash'])" 2>/dev/null || echo "")
    
    if [ "$current_hash" != "$stored_hash" ]; then
        echo "  ⚠️ Project has changed since last analysis"
        return 0  # Changed
    else
        echo "  ✅ Project unchanged since last analysis"
        return 1  # Not changed
    fi
}

# Update project hash in state
update_project_hash() {
    local new_hash=$(calculate_project_hash)
    
    python3 -c "
import json
try:
    with open('$STATE_DB', 'r') as f:
        data = json.load(f)
    data['project_hash'] = '$new_hash'
    data['last_analysis'] = '$(date)'
    with open('$STATE_DB', 'w') as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print(f'Error updating hash: {e}')
" 2>/dev/null || echo "Error updating project hash" >&2
}

# Check if specific fix type is needed
is_fix_needed() {
    local fix_type="$1"
    local current_issues=0
    
    case "$fix_type" in
        "syntax_errors")
            current_issues=$(find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec swift -frontend -parse {} \; 2>&1 | grep -c "error:" 2>/dev/null || echo "0")
            ;;
        "import_issues")
            current_issues=$(grep -r "UIKit\|Foundation\|SwiftUI" "$PROJECT_PATH/CodingReviewer" --include="*.swift" 2>/dev/null | grep -v "import" | wc -l | tr -d ' ' || echo "0")
            ;;
        "force_unwrapping")
            current_issues=$(grep -r "!" "$PROJECT_PATH/CodingReviewer" --include="*.swift" 2>/dev/null | grep -v "// " | wc -l | tr -d ' ' || echo "0")
            ;;
        "swiftlint_issues")
            current_issues="0"
            if command -v swiftlint &> /dev/null; then
                cd "$PROJECT_PATH" || return 1
                current_issues=$(swiftlint --quiet 2>/dev/null | grep -c "warning\|error" || echo "0")
            fi
            ;;
        "security_issues")
            # Simple security issue check
            current_issues=$(grep -r "http://" "$PROJECT_PATH/CodingReviewer" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
            ;;
        "performance_issues")
            # Simple performance issue check
            current_issues=$(grep -r "print(" "$PROJECT_PATH/CodingReviewer" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ' || echo "0")
            ;;
        *)
            current_issues="0"
            ;;
    esac
    
    local last_count=$(python3 -c "import json; data=json.load(open('$STATE_DB')); print(data['fixes_applied']['$fix_type']['count'])" 2>/dev/null || echo "0")
    
    # Ensure we have valid numbers
    current_issues="${current_issues:-0}"
    last_count="${last_count:-0}"
    
    # Remove any non-numeric characters
    current_issues=$(echo "$current_issues" | tr -cd '0-9' || echo "0")
    last_count=$(echo "$last_count" | tr -cd '0-9' || echo "0")
    
    if [ "$current_issues" -gt 0 ] && [ "$current_issues" != "$last_count" ]; then
        echo "  📋 $fix_type: $current_issues issues (was $last_count) - fix needed"
        return 0  # Fix needed
    else
        echo "  ✅ $fix_type: No new issues ($current_issues issues, same as last check)"
        return 1  # No fix needed
    fi
}

# Record that a fix was applied
record_fix_applied() {
    local fix_type="$1"
    local issues_fixed="$2"
    local files_affected="$3"
    
    echo "$(date): Applied $fix_type fix - $issues_fixed issues fixed in $files_affected files" >> "$FIXES_LOG"
    
    python3 -c "
import json
try:
    with open('$STATE_DB', 'r') as f:
        data = json.load(f)
    
    if '$fix_type' not in data['fixes_applied']:
        data['fixes_applied']['$fix_type'] = {'count': 0, 'last_fixed': '', 'files_fixed': []}
    
    data['fixes_applied']['$fix_type']['count'] = int('$issues_fixed')
    data['fixes_applied']['$fix_type']['last_fixed'] = '$(date)'
    if '$files_affected' != '':
        data['fixes_applied']['$fix_type']['files_fixed'] = '$files_affected'.split(',')
    
    with open('$STATE_DB', 'w') as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print(f'Error recording fix: {e}')
" 2>/dev/null || echo "Error recording fix" >&2
}

# Record automation run
record_automation_run() {
    local success="$1"  # true/false
    local duration="$2"  # in seconds
    
    local total_runs=$(python3 -c "import json; data=json.load(open('$STATE_DB')); print(data['automation_runs']['total_runs'])" 2>/dev/null || echo "0")
    local successful_runs=$(python3 -c "import json; data=json.load(open('$STATE_DB')); print(data['automation_runs']['successful_runs'])" 2>/dev/null || echo "0")
    local failed_runs=$(python3 -c "import json; data=json.load(open('$STATE_DB')); print(data['automation_runs']['failed_runs'])" 2>/dev/null || echo "0")
    
    total_runs=$((total_runs + 1))
    
    if [ "$success" = "true" ]; then
        successful_runs=$((successful_runs + 1))
    else
        failed_runs=$((failed_runs + 1))
    fi
    
    python3 -c "
import json
with open('$STATE_DB', 'r') as f:
    data = json.load(f)
data['automation_runs']['total_runs'] = $total_runs
data['automation_runs']['successful_runs'] = $successful_runs
data['automation_runs']['failed_runs'] = $failed_runs
data['automation_runs']['last_run'] = '$(date)'
data['automation_runs']['average_duration'] = $duration
with open('$STATE_DB', 'w') as f:
    json.dump(data, f, indent=2)
"
}

# Get automation statistics
get_automation_stats() {
    echo -e "${BOLD}${CYAN}📊 AUTOMATION STATISTICS${NC}"
    echo "========================"
    echo ""
    
    if [ ! -f "$STATE_DB" ]; then
        echo "  No statistics available yet"
        return
    fi
    
    local total_runs=$(python3 -c "import json; data=json.load(open('$STATE_DB')); print(data['automation_runs']['total_runs'])" 2>/dev/null || echo "0")
    local successful_runs=$(python3 -c "import json; data=json.load(open('$STATE_DB')); print(data['automation_runs']['successful_runs'])" 2>/dev/null || echo "0")
    local failed_runs=$(python3 -c "import json; data=json.load(open('$STATE_DB')); print(data['automation_runs']['failed_runs'])" 2>/dev/null || echo "0")
    local last_run=$(python3 -c "import json; data=json.load(open('$STATE_DB')); print(data['automation_runs']['last_run'])" 2>/dev/null || echo "Never")
    
    local success_rate=0
    if [ "$total_runs" -gt 0 ]; then
        success_rate=$(python3 -c "print(round($successful_runs / $total_runs * 100, 1))")
    fi
    
    echo "  📊 Total Runs: $total_runs"
    echo "  ✅ Successful: $successful_runs"
    echo "  ❌ Failed: $failed_runs"
    echo "  📈 Success Rate: ${success_rate}%"
    echo "  🕐 Last Run: $last_run"
    echo ""
    
    echo -e "${BOLD}Fixes Applied:${NC}"
    for fix_type in "syntax_errors" "import_issues" "force_unwrapping" "swiftlint_issues" "security_issues" "performance_issues"; do
        local count=$(python3 -c "import json; data=json.load(open('$STATE_DB')); print(data['fixes_applied']['$fix_type']['count'])" 2>/dev/null || echo "0")
        local last_fixed=$(python3 -c "import json; data=json.load(open('$STATE_DB')); print(data['fixes_applied']['$fix_type']['last_fixed'])" 2>/dev/null || echo "Never")
        
        if [ "$count" -gt 0 ]; then
            echo "  🔧 $fix_type: $count issues (last: $(echo "$last_fixed" | cut -d' ' -f1-2))"
        fi
    done
}

# Smart automation decision
should_run_automation() {
    local automation_type="$1"
    
    echo -e "${BLUE}🤔 Checking if $automation_type automation should run...${NC}"
    
    # Initialize if needed
    initialize_state_db
    
    # Check if project changed
    if ! has_project_changed; then
        echo "  ⏸️  No project changes - skipping $automation_type"
        return 1  # Don't run
    fi
    
    # Check recent runs
    local last_run=$(python3 -c "import json; data=json.load(open('$STATE_DB')); print(data['automation_runs']['last_run'])" 2>/dev/null || echo "")
    if [ -n "$last_run" ]; then
        local last_run_seconds=$(date -j -f "%a %b %d %H:%M:%S %Z %Y" "$last_run" +%s 2>/dev/null || echo "0")
        local current_seconds=$(date +%s)
        local time_diff=$((current_seconds - last_run_seconds))
        
        # Don't run if last run was within 5 minutes (300 seconds)
        if [ $time_diff -lt 300 ]; then
            echo "  ⏳ Last run was $(( time_diff / 60 )) minutes ago - too recent"
            return 1
        fi
    fi
    
    echo "  ✅ $automation_type automation should run"
    return 0  # Should run
}

# Comprehensive analysis before any automation
run_pre_automation_analysis() {
    echo -e "${BOLD}${CYAN}🔍 PRE-AUTOMATION ANALYSIS${NC}"
    echo "============================"
    echo ""
    
    initialize_state_db
    
    echo -e "${BLUE}1. Project Change Analysis${NC}"
    local changed=false
    if has_project_changed; then
        changed=true
        echo "  📝 Updating project hash..."
        update_project_hash
    fi
    
    echo ""
    echo -e "${BLUE}2. Fix Requirements Analysis${NC}"
    local fixes_needed=()
    
    for fix_type in "syntax_errors" "import_issues" "force_unwrapping" "swiftlint_issues" "security_issues" "performance_issues"; do
        if is_fix_needed "$fix_type"; then
            fixes_needed+=("$fix_type")
        fi
    done
    
    echo ""
    echo -e "${BLUE}3. Automation Decision${NC}"
    if [ "$changed" = false ]; then
        echo -e "  ${YELLOW}⏸️  RECOMMENDATION: Skip automation (no changes)${NC}"
        return 2  # Skip automation
    elif [ ${#fixes_needed[@]} -eq 0 ]; then
        echo -e "  ${GREEN}✅ RECOMMENDATION: Skip automation (no fixes needed)${NC}"
        return 1  # No fixes needed
    else
        echo -e "  ${GREEN}🚀 RECOMMENDATION: Run automation${NC}"
        echo "  📋 Fixes needed: ${fixes_needed[*]}"
        return 0  # Run automation
    fi
}

# Main function
main() {
    local operation="${1:-analyze}"
    
    case "$operation" in
        "init")
            initialize_state_db
            ;;
        "analyze")
            run_pre_automation_analysis
            ;;
        "check")
            local fix_type="$2"
            if [ -n "$fix_type" ]; then
                is_fix_needed "$fix_type"
            else
                echo "Usage: $0 check <fix_type>"
            fi
            ;;
        "record")
            local fix_type="$2"
            local issues_fixed="$3"
            local files_affected="$4"
            record_fix_applied "$fix_type" "$issues_fixed" "$files_affected"
            ;;
        "stats")
            get_automation_stats
            ;;
        "should-run")
            local automation_type="$2"
            should_run_automation "$automation_type"
            ;;
        "hash")
            calculate_project_hash
            ;;
        "changed")
            has_project_changed
            ;;
        *)
            echo "Usage: $0 {init|analyze|check|record|stats|should-run|hash|changed}"
            echo ""
            echo "Commands:"
            echo "  init        - Initialize state tracking database"
            echo "  analyze     - Run comprehensive pre-automation analysis"
            echo "  check TYPE  - Check if specific fix type is needed"
            echo "  record TYPE COUNT FILES - Record that fixes were applied"
            echo "  stats       - Show automation statistics"
            echo "  should-run TYPE - Check if automation should run"
            echo "  hash        - Calculate current project hash"
            echo "  changed     - Check if project has changed"
            exit 1
            ;;
    esac
}

main "$@"
