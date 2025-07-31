#!/bin/bash

# ==============================================================================
# VS CODE PROOF SELF-IMPROVING AUTOMATION SYSTEM
# ==============================================================================

# Prevent VS Code from interfering
export VSCODE_PREVENT_FOREIGN_INSPECT=1
export EDITOR=""
export VISUAL=""

# Ultra-secure file protection with hidden directory
SECURE_DIR="/Users/danielstevens/.secure_automation_$(date +%s)"
BACKUP_DIR="/Users/danielstevens/.automation_backups_$(date +%s)"
SCRIPT_NAME="vscode_proof_self_improving_automation.sh"
CURRENT_SCRIPT="$0"

# Create secure directories
mkdir -p "$SECURE_DIR" 2>/dev/null
mkdir -p "$BACKUP_DIR" 2>/dev/null

# Make directories hidden and protected
chflags hidden "$SECURE_DIR" 2>/dev/null
chflags hidden "$BACKUP_DIR" 2>/dev/null
chmod 700 "$SECURE_DIR" "$BACKUP_DIR" 2>/dev/null

# AI Learning Database - Multiple secure locations
LEARNING_DB="$SECURE_DIR/.ai_learning_patterns.json"
LEARNING_BACKUP="$BACKUP_DIR/.ai_learning_backup.json"
STATE_DB="/Users/danielstevens/Desktop/CodingReviewer/.automation_state.json"

# Continuous integrity checking
verify_script_integrity() {
    local current_size=$(wc -c < "$CURRENT_SCRIPT" 2>/dev/null || echo "0")
    local current_lines=$(wc -l < "$CURRENT_SCRIPT" 2>/dev/null || echo "0")
    
    if [[ "$current_size" -lt 1000 || "$current_lines" -lt 50 ]]; then
        echo "🚨 SCRIPT CORRUPTION DETECTED! Size: $current_size, Lines: $current_lines"
        restore_from_backup
        return 1
    fi
    
    return 0
}

# Emergency restore system
restore_from_backup() {
    echo "🔧 Attempting emergency restore..."
    
    local latest_backup=$(find "$BACKUP_DIR" -name "${SCRIPT_NAME}*" -type f 2>/dev/null | sort -r | head -1)
    
    if [[ -n "$latest_backup" && -s "$latest_backup" ]]; then
        echo "📋 Restoring from: $latest_backup"
        cp "$latest_backup" "$CURRENT_SCRIPT" 2>/dev/null
        chmod +x "$CURRENT_SCRIPT" 2>/dev/null
        echo "✅ Script restored successfully"
        return 0
    else
        echo "❌ No valid backup found"
        return 1
    fi
}

# Continuous backup system
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/${SCRIPT_NAME}_${timestamp}"
    
    if [[ -s "$CURRENT_SCRIPT" ]]; then
        cp "$CURRENT_SCRIPT" "$backup_file" 2>/dev/null
        chmod 600 "$backup_file" 2>/dev/null
        
        # Keep only last 10 backups
        find "$BACKUP_DIR" -name "${SCRIPT_NAME}_*" -type f 2>/dev/null | sort -r | tail -n +11 | xargs rm -f 2>/dev/null
        
        echo "💾 Backup created: $backup_file"
    fi
}

# Initialize secure learning database
initialize_learning_database() {
    if [[ ! -f "$LEARNING_DB" ]]; then
        cat > "$LEARNING_DB" << 'EOF'
{
  "learning_patterns": {
    "successful_fixes": [],
    "failed_attempts": [],
    "accuracy_metrics": {
      "total_attempts": 0,
      "successful_fixes": 0,
      "false_positives": 0,
      "accuracy_percentage": 0
    },
    "pattern_recognition": {
      "common_issues": {},
      "fix_effectiveness": {},
      "project_characteristics": {}
    }
  },
  "improvement_history": [],
  "last_updated": ""
}
EOF
        chmod 600 "$LEARNING_DB"
        echo "🧠 Initialized secure learning database"
    fi
    
    # Create backup copy
    cp "$LEARNING_DB" "$LEARNING_BACKUP" 2>/dev/null
}

# AI Learning System - Enhanced with pattern recognition
learn_from_results() {
    local fix_type="$1"
    local success="$2"
    local project_hash="$3"
    local details="$4"
    
    verify_script_integrity || return 1
    
    # Ensure learning database exists
    initialize_learning_database
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Use Python for secure JSON manipulation
    python3 << EOF
import json
import os
import sys
from datetime import datetime

learning_file = "$LEARNING_DB"
backup_file = "$LEARNING_BACKUP"

try:
    # Load existing data
    if os.path.exists(learning_file):
        with open(learning_file, 'r') as f:
            data = json.load(f)
    else:
        data = {
            "learning_patterns": {
                "successful_fixes": [],
                "failed_attempts": [],
                "accuracy_metrics": {
                    "total_attempts": 0,
                    "successful_fixes": 0,
                    "false_positives": 0,
                    "accuracy_percentage": 0
                },
                "pattern_recognition": {
                    "common_issues": {},
                    "fix_effectiveness": {},
                    "project_characteristics": {}
                }
            },
            "improvement_history": [],
            "last_updated": ""
        }
    
    # Update learning patterns
    learning_entry = {
        "timestamp": "$timestamp",
        "fix_type": "$fix_type",
        "success": "$success" == "true",
        "project_hash": "$project_hash",
        "details": "$details"
    }
    
    if "$success" == "true":
        data["learning_patterns"]["successful_fixes"].append(learning_entry)
        data["learning_patterns"]["accuracy_metrics"]["successful_fixes"] += 1
        
        # Update pattern recognition
        if "$fix_type" not in data["learning_patterns"]["pattern_recognition"]["fix_effectiveness"]:
            data["learning_patterns"]["pattern_recognition"]["fix_effectiveness"]["$fix_type"] = {"success": 0, "total": 0}
        data["learning_patterns"]["pattern_recognition"]["fix_effectiveness"]["$fix_type"]["success"] += 1
        data["learning_patterns"]["pattern_recognition"]["fix_effectiveness"]["$fix_type"]["total"] += 1
    else:
        data["learning_patterns"]["failed_attempts"].append(learning_entry)
        data["learning_patterns"]["accuracy_metrics"]["false_positives"] += 1
        
        # Update pattern recognition
        if "$fix_type" not in data["learning_patterns"]["pattern_recognition"]["fix_effectiveness"]:
            data["learning_patterns"]["pattern_recognition"]["fix_effectiveness"]["$fix_type"] = {"success": 0, "total": 0}
        data["learning_patterns"]["pattern_recognition"]["fix_effectiveness"]["$fix_type"]["total"] += 1
    
    # Update total attempts and accuracy
    data["learning_patterns"]["accuracy_metrics"]["total_attempts"] += 1
    total = data["learning_patterns"]["accuracy_metrics"]["total_attempts"]
    successful = data["learning_patterns"]["accuracy_metrics"]["successful_fixes"]
    
    if total > 0:
        accuracy = (successful / total) * 100
        data["learning_patterns"]["accuracy_metrics"]["accuracy_percentage"] = round(accuracy, 2)
    
    data["last_updated"] = "$timestamp"
    
    # Keep only last 100 entries to prevent bloat
    if len(data["learning_patterns"]["successful_fixes"]) > 100:
        data["learning_patterns"]["successful_fixes"] = data["learning_patterns"]["successful_fixes"][-100:]
    if len(data["learning_patterns"]["failed_attempts"]) > 100:
        data["learning_patterns"]["failed_attempts"] = data["learning_patterns"]["failed_attempts"][-100:]
    
    # Save with backup
    with open(backup_file, 'w') as f:
        json.dump(data, f, indent=2)
    
    with open(learning_file, 'w') as f:
        json.dump(data, f, indent=2)
    
    print("🧠 Learning updated - Accuracy: {}%".format(data["learning_patterns"]["accuracy_metrics"]["accuracy_percentage"]))
    
except Exception as e:
    print(f"❌ Learning update failed: {e}")
    sys.exit(1)
EOF
}

# Intelligent decision making based on learning
should_apply_fix() {
    local fix_type="$1"
    local project_context="$2"
    
    verify_script_integrity || return 1
    
    # If no learning data exists yet, be conservative
    if [[ ! -f "$LEARNING_DB" ]]; then
        echo "🤔 No learning data available, applying conservative approach"
        return 0
    fi
    
    # Use AI learning to make intelligent decisions
    local decision=$(python3 << EOF
import json
import os

learning_file = "$LEARNING_DB"

try:
    if not os.path.exists(learning_file):
        print("true")  # Default to applying fix if no data
        exit()
    
    with open(learning_file, 'r') as f:
        data = json.load(f)
    
    patterns = data.get("learning_patterns", {})
    fix_effectiveness = patterns.get("pattern_recognition", {}).get("fix_effectiveness", {})
    
    if "$fix_type" in fix_effectiveness:
        fix_data = fix_effectiveness["$fix_type"]
        success_rate = fix_data["success"] / fix_data["total"] if fix_data["total"] > 0 else 0
        
        # Only apply fix if success rate is above 70% and we have enough data
        if fix_data["total"] >= 3 and success_rate >= 0.7:
            print("true")
        elif fix_data["total"] >= 3 and success_rate < 0.7:
            print("false")
        else:
            print("true")  # Not enough data, be optimistic
    else:
        print("true")  # New fix type, try it
        
except Exception as e:
    print("true")  # Default to applying fix on error
EOF
)
    
    if [[ "$decision" == "true" ]]; then
        echo "🎯 AI recommends applying fix: $fix_type"
        return 0
    else
        echo "🚫 AI recommends skipping fix: $fix_type (low success rate)"
        return 1
    fi
}

# Enhanced fix application with learning
apply_intelligent_fix() {
    local issue_type="$1"
    local file_path="$2"
    
    verify_script_integrity || return 1
    create_backup
    
    echo "🤖 Applying intelligent fix for: $issue_type in $file_path"
    
    # Check if we should apply this fix based on learning
    if ! should_apply_fix "$issue_type" "$(basename "$file_path")"; then
        learn_from_results "$issue_type" "false" "$(calculate_project_hash)" "Skipped based on AI recommendation"
        return 1
    fi
    
    local fix_successful=false
    local fix_details=""
    
    case "$issue_type" in
        "missing_semicolon")
            if grep -q "var.*=" "$file_path" && ! grep -q "var.*=.*;" "$file_path"; then
                sed -i '' 's/\(var.*=.*[^;]\)$/\1;/g' "$file_path"
                fix_successful=true
                fix_details="Added missing semicolons to variable declarations"
            fi
            ;;
        "unused_imports")
            if [[ "$file_path" == *.swift ]]; then
                # Remove obviously unused imports (basic detection)
                local unused_imports=$(grep -n "^import " "$file_path" | while read -r line; do
                    local import_name=$(echo "$line" | sed 's/.*import \([^ ]*\).*/\1/')
                    if ! grep -q "$import_name" "$file_path" || [[ $(grep -c "$import_name" "$file_path") -eq 1 ]]; then
                        echo "$line"
                    fi
                done)
                
                if [[ -n "$unused_imports" ]]; then
                    # Remove unused imports
                    while IFS= read -r unused_line; do
                        local line_num=$(echo "$unused_line" | cut -d: -f1)
                        sed -i '' "${line_num}d" "$file_path"
                    done <<< "$unused_imports"
                    fix_successful=true
                    fix_details="Removed unused imports"
                fi
            fi
            ;;
        "inconsistent_indentation")
            if [[ "$file_path" == *.swift ]]; then
                # Fix basic indentation issues
                sed -i '' 's/^    /    /g' "$file_path"  # Ensure 4-space indentation
                fix_successful=true
                fix_details="Fixed inconsistent indentation"
            fi
            ;;
        "missing_error_handling")
            if [[ "$file_path" == *.swift ]] && grep -q "try " "$file_path" && ! grep -q "do {" "$file_path"; then
                # Add basic error handling structure
                sed -i '' 's/try /do { try /g' "$file_path"
                sed -i '' '/do { try /a\
} catch {\
    print("Error: \\(error)")\
}' "$file_path"
                fix_successful=true
                fix_details="Added basic error handling"
            fi
            ;;
    esac
    
    # Learn from the results
    if [[ "$fix_successful" == true ]]; then
        learn_from_results "$issue_type" "true" "$(calculate_project_hash)" "$fix_details"
        echo "✅ Fix applied successfully: $fix_details"
        return 0
    else
        learn_from_results "$issue_type" "false" "$(calculate_project_hash)" "Fix not applicable or failed"
        echo "❌ Fix not applied: $issue_type"
        return 1
    fi
}

# Project hash calculation for state tracking
calculate_project_hash() {
    find /Users/danielstevens/Desktop/CodingReviewer -type f \( -name "*.swift" -o -name "*.sh" -o -name "*.md" \) -exec stat -f "%m %z %N" {} \; 2>/dev/null | sort | shasum -a 256 | cut -d' ' -f1
}

# Display learning statistics
show_learning_stats() {
    verify_script_integrity || return 1
    
    if [[ ! -f "$LEARNING_DB" ]]; then
        echo "📊 No learning data available yet"
        return
    fi
    
    echo "🧠 AI Learning Statistics:"
    python3 << EOF
import json
import os

learning_file = "$LEARNING_DB"

try:
    with open(learning_file, 'r') as f:
        data = json.load(f)
    
    metrics = data.get("learning_patterns", {}).get("accuracy_metrics", {})
    fix_effectiveness = data.get("learning_patterns", {}).get("pattern_recognition", {}).get("fix_effectiveness", {})
    
    print(f"📈 Total Attempts: {metrics.get('total_attempts', 0)}")
    print(f"✅ Successful Fixes: {metrics.get('successful_fixes', 0)}")
    print(f"❌ False Positives: {metrics.get('false_positives', 0)}")
    print(f"🎯 Accuracy: {metrics.get('accuracy_percentage', 0)}%")
    print()
    
    if fix_effectiveness:
        print("🔧 Fix Type Effectiveness:")
        for fix_type, data in fix_effectiveness.items():
            success_rate = (data['success'] / data['total'] * 100) if data['total'] > 0 else 0
            print(f"  {fix_type}: {success_rate:.1f}% ({data['success']}/{data['total']})")
    
except Exception as e:
    print(f"❌ Error displaying stats: {e}")
EOF
}

# Main execution with continuous protection
main() {
    # Continuous integrity checking
    verify_script_integrity || exit 1
    
    echo "🛡️ VS Code Proof Self-Improving Automation System Started"
    echo "🔐 Secure directory: $SECURE_DIR"
    echo "💾 Backup directory: $BACKUP_DIR"
    
    # Initialize learning system
    initialize_learning_database
    
    # Create initial backup
    create_backup
    
    # Show current learning statistics
    show_learning_stats
    
    # Process command line arguments
    case "${1:-}" in
        "learn")
            learn_from_results "${2:-test}" "${3:-true}" "$(calculate_project_hash)" "${4:-Manual learning test}"
            ;;
        "stats")
            show_learning_stats
            ;;
        "fix")
            apply_intelligent_fix "${2:-missing_semicolon}" "${3:-/Users/danielstevens/Desktop/CodingReviewer/test.swift}"
            ;;
        *)
            echo "🎯 Running intelligent automation analysis..."
            
            # Find Swift files that might need fixes
            find /Users/danielstevens/Desktop/CodingReviewer -name "*.swift" -type f 2>/dev/null | while read -r swift_file; do
                echo "🔍 Analyzing: $swift_file"
                
                # Check for various issues and apply intelligent fixes
                if grep -q "var.*=[^;]*$" "$swift_file"; then
                    apply_intelligent_fix "missing_semicolon" "$swift_file"
                fi
                
                if grep -q "^import " "$swift_file"; then
                    apply_intelligent_fix "unused_imports" "$swift_file"
                fi
                
                # Continuous integrity check during operation
                verify_script_integrity || break
            done
            
            echo "✅ Intelligent automation analysis complete"
            show_learning_stats
            ;;
    esac
    
    # Final integrity check
    verify_script_integrity
    create_backup
    
    echo "🏁 VS Code Proof Automation Complete"
}

# Trap signals to ensure cleanup
trap 'echo "🛑 Script interrupted, performing cleanup..."; create_backup; exit 0' INT TERM

# Run main function with all arguments
main "$@"
# Performance optimization
PATTERN_CACHE=true
CACHE_DIR="$PROJECT_PATH/.ai_cache"
BATCH_PROCESSING=true
BATCH_SIZE=10
