#!/bin/bash

# Fix EnhancedAnalysisItem constructor calls in FileManagerService.swift

echo "🔧 Fixing EnhancedAnalysisItem constructor calls..."

FILE="/Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/FileManagerService.swift"

# Create backup
cp "$FILE" "$FILE.backup"

# Fix the constructor calls by adding required title and description parameters
# Pattern: EnhancedAnalysisItem(message: "...", severity: "...", type: "...")
# Replace with: EnhancedAnalysisItem(title: "Analysis", description: "...", severity: "...", category: "...")

sed -i.temp '
s/EnhancedAnalysisItem(\([^)]*\)message: "\([^"]*\)"\([^)]*\)severity: "\([^"]*\)"\([^)]*\)type: "\([^"]*\)"/EnhancedAnalysisItem(title: "Code Analysis", description: "\2", severity: "\4", category: "\6"/g
' "$FILE"

# Additional pattern fixes
sed -i.temp2 '
s/EnhancedAnalysisItem(\([^)]*\)message: "\([^"]*\)"/EnhancedAnalysisItem(title: "Analysis Result", description: "\2"/g
' "$FILE"

# Clean up temporary files
rm -f "$FILE.temp" "$FILE.temp2"

echo "✅ Fixed EnhancedAnalysisItem constructor calls"
echo "📄 Backup saved as: $FILE.backup"

# Validate Swift syntax
if swiftc -parse "$FILE" > /dev/null 2>&1; then
    echo "✅ Swift syntax validation passed"
else
    echo "❌ Swift syntax validation failed, reverting changes"
    mv "$FILE.backup" "$FILE"
fi
