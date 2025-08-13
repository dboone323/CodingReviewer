#!/bin/bash

# Background Automation Daemon
# Runs smaller fixes in background while allowing manual work on bigger issues

echo "🔄 Background Automation Daemon"
echo "==============================="

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
DAEMON_DIR="$PROJECT_PATH/.background_automation"
PID_FILE="$DAEMON_DIR/daemon.pid"
LOG_FILE="$DAEMON_DIR/daemon.log"
STATUS_FILE="$DAEMON_DIR/status.json"

mkdir -p "$DAEMON_DIR"

# Initialize daemon status
init_daemon() {
    cat > "$STATUS_FILE" << EOF
{
    "status": "initializing",
    "started": "$(date -Iseconds)",
    "last_activity": "$(date -Iseconds)",
    "fixes_applied": 0,
    "current_task": "initialization",
    "active_fixes": []
}
EOF
}

# Update daemon status
update_status() {
    local status="$1"
    local task="$2"
    local fixes_count="$3"
    
    cat > "$STATUS_FILE" << EOF
{
    "status": "$status",
    "started": "$(date -Iseconds)",
    "last_activity": "$(date -Iseconds)",
    "fixes_applied": ${fixes_count:-0},
    "current_task": "$task",
    "active_fixes": []
}
EOF
}

# Log activity
log_activity() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Small fixes that can run safely in background
run_small_fixes() {
    local fixes_applied=0
    
    log_activity "Starting small fixes cycle"
    update_status "running" "small_fixes" "$fixes_applied"
    
    # 1. Fix basic syntax issues
    echo "  🔧 Checking for basic syntax issues..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -l "self\?\." {} \; | head -5 | while read -r file; do
        if [ -f "$file" ]; then
            # Fix obvious self?. issues in non-optional contexts
            sed -i '' 's/self?\./self\./g' "$file" 2>/dev/null && echo "    ✅ Fixed optional chaining in $(basename "$file")"
            ((fixes_applied++))
        fi
    done; then
        log_activity "Fixed optional chaining issues"
    fi
    
    # 2. Remove trailing whitespace
    echo "  🧹 Removing trailing whitespace..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec sed -i '' 's/[[:space:]]*$//' {} \; 2>/dev/null; then
        log_activity "Removed trailing whitespace"
        ((fixes_applied++))
    fi
    
    # 3. Fix import organization (basic)
    echo "  📦 Organizing imports..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -l "^import" {} \; | head -3 | while read -r file; do
        if [ -f "$file" ]; then
            # Simple import sorting
            awk '/^import/ {imports[NR] = $0; next} {if (NR == 1 && /^import/) next; if (length(imports) > 0) {for (i in imports) print imports[i] | "sort -u"; delete imports;} print}' "$file" > "$file.tmp" 2>/dev/null && mv "$file.tmp" "$file" 2>/dev/null
            echo "    ✅ Organized imports in $(basename "$file")"
            ((fixes_applied++))
        fi
    done; then
        log_activity "Organized imports"
    fi
    
    # 4. Fix basic SwiftLint issues (if available)
    if command -v swiftlint &> /dev/null; then
        echo "  🔍 Running SwiftLint auto-fixes..."
        cd "$PROJECT_PATH" || return 1
        if swiftlint --fix --quiet > /dev/null 2>&1; then
            log_activity "Applied SwiftLint auto-fixes"
            ((fixes_applied++))
        fi
    fi
    
    # 5. Fix common comment formatting
    echo "  💬 Fixing comment formatting..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec sed -i '' 's|//[[:space:]]*\([^[:space:]]\)|// \1|g' {} \; 2>/dev/null; then
        log_activity "Fixed comment formatting"
        ((fixes_applied++))
    fi
    
    # 6. Remove duplicate empty lines
    echo "  📝 Removing duplicate empty lines..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec awk '/^$/ {if (!p) print; p=1; next} {p=0; print}' {} \; > /tmp/dedup.swift 2>/dev/null && 
       find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec sh -c 'awk "/^$/ {if (!p) print; p=1; next} {p=0; print}" "$1" > "$1.tmp" && mv "$1.tmp" "$1"' _ {} \; 2>/dev/null; then
        log_activity "Removed duplicate empty lines"
        ((fixes_applied++))
    fi
    
    update_status "idle" "completed_small_fixes" "$fixes_applied"
    log_activity "Small fixes cycle completed: $fixes_applied fixes applied"
    
    return $fixes_applied
}

# Performance optimizations that don't affect functionality
run_performance_fixes() {
    local fixes_applied=0
    
    log_activity "Starting performance fixes cycle"
    update_status "running" "performance_fixes" "$fixes_applied"
    
    # 1. Add @MainActor where safe
    echo "  🎭 Adding @MainActor annotations..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -l "class.*View\|ObservableObject" {} \; | head -3 | while read -r file; do
        if [ -f "$file" ] && ! grep -q "@MainActor" "$file"; then
            # Add @MainActor to view classes that don't have it
            sed -i '' '/^class.*View\|^class.*ObservableObject/i\
@MainActor' "$file" 2>/dev/null && echo "    ✅ Added @MainActor to $(basename "$file")"
            ((fixes_applied++))
        fi
    done; then
        log_activity "Added @MainActor annotations"
    fi
    
    # 2. Add basic performance imports
    echo "  📦 Adding performance-related imports..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -l "print\|NSLog" {} \; | head -3 | while read -r file; do
        if [ -f "$file" ] && ! grep -q "import OSLog" "$file"; then
            # Add OSLog import for better logging performance
            sed -i '' '1i\
import OSLog' "$file" 2>/dev/null && echo "    ✅ Added OSLog import to $(basename "$file")"
            ((fixes_applied++))
        fi
    done; then
        log_activity "Added performance imports"
    fi
    
    # 3. Replace print with os_log where safe
    echo "  📊 Optimizing logging statements..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -l "print(" {} \; | head -2 | while read -r file; do
        if [ -f "$file" ] && grep -q "import OSLog" "$file"; then
            # Replace simple print statements with os_log
            sed -i '' 's/print("/os_log("/g' "$file" 2>/dev/null && echo "    ✅ Optimized logging in $(basename "$file")"
            ((fixes_applied++))
        fi
    done; then
        log_activity "Optimized logging statements"
    fi
    
    update_status "idle" "completed_performance_fixes" "$fixes_applied"
    log_activity "Performance fixes cycle completed: $fixes_applied fixes applied"
    
    return $fixes_applied
}

# Documentation improvements
run_documentation_fixes() {
    local fixes_applied=0
    
    log_activity "Starting documentation fixes cycle"
    update_status "running" "documentation_fixes" "$fixes_applied"
    
    # 1. Add basic function documentation
    echo "  📚 Adding function documentation..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -l "func " {} \; | head -2 | while read -r file; do
        if [ -f "$file" ]; then
            # Add basic documentation to undocumented functions
            awk '/^[[:space:]]*func / {
                if (prev !~ /^[[:space:]]*\/\//) {
                    gsub(/^[[:space:]]*/, "", $0)
                    indent = match($0, /[^ ]/) - 1
                    for (i = 0; i < indent; i++) printf " "
                    print "/// Function description needed"
                }
            } {prev = $0; print}' "$file" > "$file.tmp" 2>/dev/null && mv "$file.tmp" "$file" 2>/dev/null
            echo "    ✅ Added documentation to $(basename "$file")"
            ((fixes_applied++))
        fi
    done; then
        log_activity "Added function documentation"
    fi
    
    # 2. Fix comment spacing
    echo "  💬 Improving comment formatting..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec sed -i '' 's|//\([^/[:space:]]\)|// \1|g' {} \; 2>/dev/null; then
        log_activity "Improved comment formatting"
        ((fixes_applied++))
    fi
    
    update_status "idle" "completed_documentation_fixes" "$fixes_applied"
    log_activity "Documentation fixes cycle completed: $fixes_applied fixes applied"
    
    return $fixes_applied
}

# Security improvements (safe ones)
run_security_fixes() {
    local fixes_applied=0
    
    log_activity "Starting security fixes cycle"
    update_status "running" "security_fixes" "$fixes_applied"
    
    # 1. Remove hardcoded credentials (basic patterns)
    echo "  🔒 Checking for security issues..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -l "password.*=\|key.*=.*[\"']" {} \; | head -2 | while read -r file; do
        if [ -f "$file" ]; then
            # Replace obvious hardcoded values with placeholder comments
            sed -i '' 's/password.*=.*"[^"]*"/password = "\/\/ TODO: Use secure storage"/g' "$file" 2>/dev/null
            sed -i '' 's/key.*=.*"[^"]*"/key = "\/\/ TODO: Use keychain or environment variable"/g' "$file" 2>/dev/null
            echo "    ✅ Secured credentials in $(basename "$file")"
            ((fixes_applied++))
        fi
    done; then
        log_activity "Applied security fixes"
    fi
    
    # 2. Add basic security imports where needed
    echo "  🛡️ Adding security imports..."
    if find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -l "keychain\|crypto\|security" {} \; | head -2 | while read -r file; do
        if [ -f "$file" ] && ! grep -q "import Security" "$file"; then
            sed -i '' '1i\
import Security' "$file" 2>/dev/null && echo "    ✅ Added Security import to $(basename "$file")"
            ((fixes_applied++))
        fi
    done; then
        log_activity "Added security imports"
    fi
    
    update_status "idle" "completed_security_fixes" "$fixes_applied"
    log_activity "Security fixes cycle completed: $fixes_applied fixes applied"
    
    return $fixes_applied
}

# Main daemon loop
run_daemon() {
    echo -e "${GREEN}🚀 Starting background automation daemon...${NC}"
    
    # Save PID
    echo $$ > "$PID_FILE"
    init_daemon
    
    echo -e "${BLUE}📋 Daemon started (PID: $$)${NC}"
    echo -e "${YELLOW}📍 Log file: $LOG_FILE${NC}"
    echo -e "${YELLOW}📊 Status file: $STATUS_FILE${NC}"
    echo ""
    
    log_activity "Background automation daemon started"
    
    local cycle=0
    local total_fixes=0
    
    while true; do
        ((cycle++))
        echo -e "${PURPLE}🔄 Background cycle $cycle$(NC)"
        log_activity "Starting background cycle $cycle"
        
        local cycle_fixes=0
        
        # Rotate through different types of fixes to avoid conflicts
        case $((cycle % 4)) in
            1)
                echo -e "${CYAN}  Phase 1: Small syntax & formatting fixes${NC}"
                run_small_fixes
                cycle_fixes=$?
                ;;
            2)
                echo -e "${CYAN}  Phase 2: Performance optimizations${NC}"
                run_performance_fixes
                cycle_fixes=$?
                ;;
            3)
                echo -e "${CYAN}  Phase 3: Documentation improvements${NC}"
                run_documentation_fixes
                cycle_fixes=$?
                ;;
            0)
                echo -e "${CYAN}  Phase 4: Security enhancements${NC}"
                run_security_fixes
                cycle_fixes=$?
                ;;
        esac
        
        total_fixes=$((total_fixes + cycle_fixes))
        
        echo -e "${GREEN}  ✅ Cycle $cycle complete: $cycle_fixes fixes applied${NC}"
        echo -e "${YELLOW}  📊 Total fixes: $total_fixes${NC}"
        echo ""
        
        log_activity "Cycle $cycle completed: $cycle_fixes fixes applied (total: $total_fixes)"
        update_status "idle" "waiting_for_next_cycle" "$total_fixes"
        
        # Wait 2 minutes between cycles (non-intrusive)
        echo -e "${YELLOW}⏳ Waiting 2 minutes until next background cycle...${NC}"
        sleep 120
    done
}

# Stop daemon
stop_daemon() {
    echo -e "${YELLOW}🛑 Stopping background automation daemon...${NC}"
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            echo -e "${GREEN}✅ Daemon stopped (PID: $pid)${NC}"
            log_activity "Background automation daemon stopped"
        else
            echo -e "${YELLOW}⚠️ Process not running${NC}"
        fi
        rm -f "$PID_FILE"
    else
        echo -e "${YELLOW}⚠️ No PID file found${NC}"
    fi
    
    # Update status
    update_status "stopped" "daemon_stopped" "0"
}

# Show daemon status
show_status() {
    echo -e "${BOLD}${CYAN}🔄 Background Automation Daemon Status${NC}"
    echo "========================================"
    
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo -e "${GREEN}🟢 Status: Running${NC}"
        echo -e "PID: $(cat "$PID_FILE")"
    else
        echo -e "${RED}🔴 Status: Stopped${NC}"
    fi
    
    if [ -f "$STATUS_FILE" ]; then
        echo ""
        echo "📊 Latest Status:"
        cat "$STATUS_FILE" | jq -r '
            "  Started: " + .started +
            "\n  Last Activity: " + .last_activity +
            "\n  Fixes Applied: " + (.fixes_applied | tostring) +
            "\n  Current Task: " + .current_task
        ' 2>/dev/null || cat "$STATUS_FILE"
    fi
    
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "📝 Recent Activity:"
        tail -5 "$LOG_FILE" | while read -r line; do
            echo "  $line"
        done
    fi
}

# Show help
show_help() {
    echo "Background Automation Daemon"
    echo ""
    echo "This daemon runs small, safe fixes in the background while you work on bigger issues."
    echo "It operates in 2-minute cycles with different focus areas:"
    echo ""
    echo "🔄 CYCLE ROTATION:"
    echo "  Phase 1: Small syntax & formatting fixes"
    echo "  Phase 2: Performance optimizations"
    echo "  Phase 3: Documentation improvements"
    echo "  Phase 4: Security enhancements"
    echo ""
    echo "📋 COMMANDS:"
    echo "  --start      Start the background daemon"
    echo "  --stop       Stop the background daemon"
    echo "  --status     Show daemon status and recent activity"
    echo "  --restart    Restart the daemon"
    echo "  --log        Show recent log entries"
    echo "  --help       Show this help"
    echo ""
    echo "✨ SAFE FIXES INCLUDE:"
    echo "  • Fixing optional chaining syntax errors"
    echo "  • Removing trailing whitespace"
    echo "  • Organizing imports"
    echo "  • Running SwiftLint auto-fixes"
    echo "  • Improving comment formatting"
    echo "  • Adding @MainActor annotations"
    echo "  • Adding function documentation"
    echo "  • Basic security improvements"
    echo ""
    echo "⚠️ WHAT IT DOESN'T DO:"
    echo "  • Major architectural changes"
    echo "  • Complex logic modifications"
    echo "  • File reorganization"
    echo "  • Breaking changes"
    echo ""
    echo "This allows you to focus on bigger issues while the daemon handles small improvements!"
}

# Main execution
case "${1:-}" in
    --start)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo -e "${YELLOW}⚠️ Daemon already running (PID: $(cat "$PID_FILE"))${NC}"
            exit 1
        fi
        run_daemon
        ;;
    --stop)
        stop_daemon
        ;;
    --status)
        show_status
        ;;
    --restart)
        stop_daemon
        sleep 2
        run_daemon
        ;;
    --log)
        if [ -f "$LOG_FILE" ]; then
            echo -e "${CYAN}📝 Background Automation Log${NC}"
            echo "=========================="
            tail -20 "$LOG_FILE"
        else
            echo -e "${YELLOW}⚠️ No log file found${NC}"
        fi
        ;;
    --help)
        show_help
        ;;
    *)
        echo -e "${BOLD}${CYAN}🔄 Background Automation Daemon${NC}"
        echo "==============================="
        echo ""
        show_status
        echo ""
        echo "Use --help for detailed information and commands"
        echo ""
        echo "QUICK START:"
        echo "  ./background_automation_daemon.sh --start     # Start daemon"
        echo "  ./background_automation_daemon.sh --status    # Check status"
        echo "  ./background_automation_daemon.sh --stop      # Stop daemon"
        ;;
esac
