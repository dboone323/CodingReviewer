#!/bin/bash

# File watcher for duplicate prevention
if command -v fswatch >/dev/null 2>&1; then
    echo "👁️ Starting file watcher for duplicate prevention..."
    fswatch -o . --exclude="\.git" --exclude="archived_backups" | while read -r event; do
        echo "📁 File system change detected, checking for duplicates..."
        ./code_deduplication_prevention.sh --quick-check >/dev/null 2>&1
    done
else
    echo "ℹ️ Install fswatch for real-time duplicate monitoring"
    echo "   brew install fswatch  (on macOS)"
fi
