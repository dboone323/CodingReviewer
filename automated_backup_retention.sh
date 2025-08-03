#!/bin/bash

# Automated Backup Retention Policy
# Manages backup directories and prevents accumulation

echo "🗂️  Automated Backup Retention System"
echo "===================================="

BACKUP_ROOT="./archived_backups"
RETENTION_DAYS=30
MAX_BACKUPS=10

# Create backup root if it doesn't exist
mkdir -p "$BACKUP_ROOT"

echo "📊 Current backup status:"
if [ -d "$BACKUP_ROOT" ]; then
    backup_count=$(find "$BACKUP_ROOT" -type d -mindepth 1 | wc -l)
    backup_size=$(du -sh "$BACKUP_ROOT" 2>/dev/null | cut -f1)
    echo "  📁 Backup directories: $backup_count"
    echo "  💾 Total size: $backup_size"
else
    echo "  📁 No backup directory found"
fi

# Function to archive old backups
archive_old_backups() {
    echo "🔄 Checking for backups older than $RETENTION_DAYS days..."
    
    find "$BACKUP_ROOT" -type d -mindepth 1 -mtime +$RETENTION_DAYS -exec rm -rf {} + 2>/dev/null
    
    # Limit number of backups
    backup_dirs=($(find "$BACKUP_ROOT" -type d -mindepth 1 -maxdepth 1 | sort -r))
    if [ ${#backup_dirs[@]} -gt $MAX_BACKUPS ]; then
        echo "🧹 Removing excess backups (keeping $MAX_BACKUPS most recent)..."
        for ((i=MAX_BACKUPS; i<${#backup_dirs[@]}; i++)); do
            echo "  🗑️  Removing: ${backup_dirs[i]}"
            rm -rf "${backup_dirs[i]}"
        done
    fi
}

# Function to compress old backups
compress_backups() {
    echo "🗜️  Compressing backups older than 7 days..."
    
    find "$BACKUP_ROOT" -type d -mindepth 1 -mtime +7 -not -name "*.tar.gz" | while read -r backup_dir; do
        if [ -d "$backup_dir" ]; then
            echo "  📦 Compressing: $backup_dir"
            tar -czf "$backup_dir.tar.gz" -C "$(dirname "$backup_dir")" "$(basename "$backup_dir")" 2>/dev/null
            if [ $? -eq 0 ]; then
                rm -rf "$backup_dir"
                echo "  ✅ Compressed and removed: $backup_dir"
            fi
        fi
    done
}

# Function to create backup inventory
create_inventory() {
    echo "📋 Creating backup inventory..."
    
    inventory_file="$BACKUP_ROOT/backup_inventory.md"
    cat > "$inventory_file" << EOF
# Backup Inventory
Generated: $(date)

## Current Backups
EOF
    
    find "$BACKUP_ROOT" -mindepth 1 -maxdepth 2 -type d | sort | while read -r backup_path; do
        backup_name=$(basename "$backup_path")
        backup_size=$(du -sh "$backup_path" 2>/dev/null | cut -f1)
        backup_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$backup_path" 2>/dev/null || date)
        
        echo "- **$backup_name**: $backup_size (Modified: $backup_date)" >> "$inventory_file"
    done
    
    echo "  📄 Inventory saved to: $inventory_file"
}

# Main execution
echo "🚀 Starting backup retention process..."

archive_old_backups
compress_backups
create_inventory

echo "✅ Backup retention completed"
echo "📊 Final status:"
if [ -d "$BACKUP_ROOT" ]; then
    final_count=$(find "$BACKUP_ROOT" -type d -mindepth 1 | wc -l)
    final_size=$(du -sh "$BACKUP_ROOT" 2>/dev/null | cut -f1)
    echo "  📁 Backup directories: $final_count"
    echo "  💾 Total size: $final_size"
fi
