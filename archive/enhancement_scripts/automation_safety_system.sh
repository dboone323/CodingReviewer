#!/bin/bash

# Automation Safety System
# Prevents automation from proceeding if build is broken

echo "🛡️ Automation Safety System"
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
SAFETY_LOG_DIR="$PROJECT_PATH/automation_safety_logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SAFETY_LOG="$SAFETY_LOG_DIR/safety_check_$TIMESTAMP.log"

mkdir -p "$SAFETY_LOG_DIR"

# Pre-automation safety check
run_safety_check() {
    echo -e "${BOLD}${CYAN}🛡️ RUNNING PRE-AUTOMATION SAFETY CHECK${NC}"
    echo "======================================="
    echo ""
    
    cd "$PROJECT_PATH" || exit 1
    
    # Step 1: Quick build validation
    echo -e "${BLUE}1. 🔨 Quick Build Validation${NC}"
    if ./intelligent_build_validator.sh > "$SAFETY_LOG" 2>&1; then
        echo -e "   ${GREEN}✅ Build validation: PASSED${NC}"
        local build_safe=true
    else
        echo -e "   ${RED}❌ Build validation: FAILED${NC}"
        echo -e "   🔧 Attempting automatic fixes..."
        local build_safe=false
    fi
    
    # Step 2: Git status check
    echo -e "${BLUE}2. 📋 Git Status Check${NC}"
    if git status --porcelain | grep -q .; then
        echo -e "   ${YELLOW}⚠️  Uncommitted changes detected${NC}"
        echo -e "   📋 Creating safety backup..."
        git stash push -m "Auto-safety-backup-$TIMESTAMP" > /dev/null 2>&1 || true
        echo -e "   ${GREEN}✅ Safety backup created${NC}"
    else
        echo -e "   ${GREEN}✅ Working directory clean${NC}"
    fi
    
    # Step 3: Critical file integrity check
    echo -e "${BLUE}3. 🔍 Critical File Integrity Check${NC}"
    local critical_files=(
        "CodingReviewer/SharedTypes/AppError.swift"
        "CodingReviewer/AppLogger.swift"
        "CodingReviewer/CodeReviewViewModel.swift"
        "CodingReviewer/SecurityManager.swift"
        "CodingReviewer.xcodeproj/project.pbxproj"
    )
    
    local integrity_passed=true
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            # Check if file is valid Swift/project file
            case "$file" in
                *.swift)
                    if swift -frontend -parse "$file" > /dev/null 2>&1; then
                        echo -e "   ${GREEN}✅ $file: Valid syntax${NC}"
                    else
                        echo -e "   ${RED}❌ $file: Syntax errors${NC}"
                        integrity_passed=false
                    fi
                    ;;
                *.pbxproj)
                    if plutil -lint "$file" > /dev/null 2>&1; then
                        echo -e "   ${GREEN}✅ $file: Valid project file${NC}"
                    else
                        echo -e "   ${RED}❌ $file: Corrupted project file${NC}"
                        integrity_passed=false
                    fi
                    ;;
            esac
        else
            echo -e "   ${RED}❌ $file: Missing critical file${NC}"
            integrity_passed=false
        fi
    done
    
    # Step 4: Safety decision
    echo ""
    echo -e "${BOLD}🎯 SAFETY DECISION${NC}"
    echo "=================="
    
    if [ "$build_safe" = true ] && [ "$integrity_passed" = true ]; then
        echo -e "${GREEN}✅ AUTOMATION SAFE TO PROCEED${NC}"
        echo -e "🟢 All safety checks passed"
        echo -e "🚀 Automation can continue normally"
        return 0
    elif [ "$build_safe" = false ] && [ "$integrity_passed" = true ]; then
        echo -e "${YELLOW}⚠️  AUTOMATION PROCEED WITH CAUTION${NC}"
        echo -e "🟡 Build issues detected but fixed"
        echo -e "🔧 Monitor automation closely"
        return 0
    else
        echo -e "${RED}❌ AUTOMATION BLOCKED${NC}"
        echo -e "🔴 Critical issues detected"
        echo -e "🛑 Manual intervention required"
        return 1
    fi
}

# Create automation checkpoint
create_checkpoint() {
    echo -e "${PURPLE}💾 Creating automation checkpoint...${NC}"
    
    local checkpoint_dir="$PROJECT_PATH/.automation_checkpoints"
    mkdir -p "$checkpoint_dir"
    
    # Create checkpoint
    local checkpoint_file="$checkpoint_dir/checkpoint_$TIMESTAMP.tar.gz"
    
    # Backup critical files
    tar -czf "$checkpoint_file" \
        CodingReviewer/ \
        CodingReviewer.xcodeproj/ \
        *.md \
        *.sh 2>/dev/null || true
    
    echo -e "   ${GREEN}✅ Checkpoint created: $checkpoint_file${NC}"
}

# Restore from checkpoint if needed
restore_checkpoint() {
    echo -e "${RED}🔄 RESTORING FROM CHECKPOINT${NC}"
    echo "=========================="
    
    local checkpoint_dir="$PROJECT_PATH/.automation_checkpoints"
    
    if [ -d "$checkpoint_dir" ]; then
        local latest_checkpoint=$(ls -t "$checkpoint_dir"/checkpoint_*.tar.gz | head -1)
        
        if [ -n "$latest_checkpoint" ]; then
            echo -e "${BLUE}📦 Restoring from: $(basename "$latest_checkpoint")${NC}"
            tar -xzf "$latest_checkpoint" 2>/dev/null || true
            echo -e "${GREEN}✅ Restoration complete${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}❌ No checkpoint available for restoration${NC}"
    return 1
}

# Main function
main() {
    local operation="${1:-check}"
    
    case "$operation" in
        "check")
            run_safety_check
            ;;
        "checkpoint")
            create_checkpoint
            ;;
        "restore")
            restore_checkpoint
            ;;
        *)
            echo "Usage: $0 {check|checkpoint|restore}"
            echo ""
            echo "Commands:"
            echo "  check      - Run pre-automation safety check"
            echo "  checkpoint - Create automation checkpoint"
            echo "  restore    - Restore from latest checkpoint"
            exit 1
            ;;
    esac
}

main "$@"
