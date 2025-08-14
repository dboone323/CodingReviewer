#!/bin/bash

# Project Cleanup Script - Remove Backup and Temporary Files
# This script cleans up backup files, temporary files, and old artifacts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🧹 Project Cleanup Script${NC}"
echo -e "${CYAN}========================${NC}"
echo

# Track cleanup statistics
deleted_files=0
deleted_dirs=0
total_size_freed=0

# Function to calculate file size
get_file_size() {
    if [[ -f "$1" ]]; then
        stat -c%s "$1" 2>/dev/null || stat -f%z "$1" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

# Function to safely delete files/directories
safe_delete() {
    local target="$1"
    local size
    
    if [[ -f "$target" ]]; then
        size=$(get_file_size "$target")
        rm -f "$target"
        deleted_files=$((deleted_files + 1))
        total_size_freed=$((total_size_freed + size))
        echo -e "   ${GREEN}✅ Deleted file: $(basename "$target")${NC}"
    elif [[ -d "$target" ]]; then
        size=$(du -sb "$target" 2>/dev/null | cut -f1 || echo 0)
        rm -rf "$target"
        deleted_dirs=$((deleted_dirs + 1))
        total_size_freed=$((total_size_freed + size))
        echo -e "   ${GREEN}✅ Deleted directory: $(basename "$target")${NC}"
    fi
}

echo -e "${BLUE}🔍 Scanning for cleanup targets...${NC}"

# 1. Remove backup files
echo -e "${YELLOW}📁 Cleaning backup files (.backup, .bak)...${NC}"
find . -name "*.backup" -type f | while read -r file; do
    safe_delete "$file"
done

find . -name "*.bak" -type f | while read -r file; do
    safe_delete "$file"
done

# 2. Remove backup directories
echo -e "${YELLOW}📁 Cleaning backup directories...${NC}"
find . -name "*_backup_*" -type d | while read -r dir; do
    safe_delete "$dir"
done

# 3. Remove temporary files
echo -e "${YELLOW}🗂️ Cleaning temporary files...${NC}"
find . -name "*.tmp" -type f | while read -r file; do
    safe_delete "$file"
done

find . -name "*.temp" -type f | while read -r file; do
    safe_delete "$file"
done

find . -name ".DS_Store" -type f | while read -r file; do
    safe_delete "$file"
done

# 4. Remove log files (except recent ones)
echo -e "${YELLOW}📄 Cleaning old log files...${NC}"
find . -name "*.log" -type f -mtime +7 | while read -r file; do
    safe_delete "$file"
done

# 5. Remove empty directories
echo -e "${YELLOW}📂 Removing empty directories...${NC}"
find . -type d -empty | while read -r dir; do
    if [[ "$dir" != "." && "$dir" != ".git"* ]]; then
        safe_delete "$dir"
    fi
done

# 6. Clean up old artifacts in archive directory
echo -e "${YELLOW}🗄️ Cleaning old archive files...${NC}"
if [[ -d "archive" ]]; then
    find archive -name "*.tar.gz" -type f -mtime +30 | while read -r file; do
        safe_delete "$file"
    done
fi

# 7. Remove duplicate files (based on filename patterns)
echo -e "${YELLOW}🔄 Removing obvious duplicates...${NC}"
find . -name "*_copy*" -type f | while read -r file; do
    safe_delete "$file"
done

find . -name "*_old*" -type f | while read -r file; do
    safe_delete "$file"
done

# 8. Clean up build artifacts
echo -e "${YELLOW}🏗️ Cleaning build artifacts...${NC}"
find . -name "*.o" -type f | while read -r file; do
    safe_delete "$file"
done

find . -name "*.pyc" -type f | while read -r file; do
    safe_delete "$file"
done

find . -name "__pycache__" -type d | while read -r dir; do
    safe_delete "$dir"
done

# 9. Remove AI recovery trigger files (they're temporary)
echo -e "${YELLOW}🤖 Cleaning AI recovery trigger files...${NC}"
find . -name ".ai_recovery_trigger" -type f | while read -r file; do
    safe_delete "$file"
done

# 10. Verify important files are still present
echo -e "${BLUE}🔍 Verifying critical files...${NC}"
critical_files=(
    ".github/workflows/ai-self-healing.yml"
    "workflow_quality_check.py"
    "Tools/Automation/ai_workflow_recovery.py"
    "requirements-recovery.txt"
    ".ai_learning_system/workflow_patterns.json"
)

for file in "${critical_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "   ${GREEN}✅ Critical file present: $file${NC}"
    else
        echo -e "   ${RED}❌ Critical file missing: $file${NC}"
    fi
done

# Convert bytes to human readable
format_size() {
    local size=$1
    if (( size > 1073741824 )); then
        echo "$(( size / 1073741824 )) GB"
    elif (( size > 1048576 )); then
        echo "$(( size / 1048576 )) MB"
    elif (( size > 1024 )); then
        echo "$(( size / 1024 )) KB"
    else
        echo "$size bytes"
    fi
}

echo
echo -e "${CYAN}📊 Cleanup Summary${NC}"
echo -e "${CYAN}=================${NC}"
echo -e "Files deleted: $deleted_files"
echo -e "Directories deleted: $deleted_dirs"
echo -e "Space freed: $(format_size $total_size_freed)"
echo

# Update .gitignore to prevent future accumulation
echo -e "${BLUE}📝 Updating .gitignore...${NC}"
cat >> .gitignore << 'EOF'

# Backup files
*.backup
*.bak
*_backup_*/
*_old
*_copy*

# Temporary files
*.tmp
*.temp
.DS_Store

# AI Recovery temporary files
.ai_recovery_trigger

# Build artifacts
*.o
*.pyc
__pycache__/

# Log files
*.log

EOF

echo -e "${GREEN}🎉 Project cleanup completed successfully!${NC}"
echo -e "${GREEN}✨ Repository is now clean and ready for commit.${NC}"
