#!/bin/bash

# Fix remaining EnhancedAnalysisItem constructor calls with multiline pattern matching

echo "🔧 Fixing remaining EnhancedAnalysisItem constructor calls..."

FILE="/Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/FileManagerService.swift"

# Create backup
cp "$FILE" "$FILE.backup2"

# Use Python to handle multiline patterns more reliably
python3 << 'EOF'
import re

# Read the file
with open('/Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/FileManagerService.swift', 'r') as f:
    content = f.read()

# Pattern to match EnhancedAnalysisItem constructors with old format
pattern = r'EnhancedAnalysisItem\(\s*message:\s*"([^"]*)",\s*severity:\s*"([^"]*)",\s*type:\s*"([^"]*)"\s*\)'

# Replace with new format
def replace_constructor(match):
    message = match.group(1)
    severity = match.group(2)
    type_val = match.group(3)
    
    return f'EnhancedAnalysisItem(\n                title: "Analysis Result",\n                description: "{message}",\n                severity: "{severity}",\n                category: "{type_val}"\n            )'

# Apply replacements
content = re.sub(pattern, replace_constructor, content, flags=re.MULTILINE | re.DOTALL)

# Write back to file
with open('/Users/danielstevens/Desktop/CodingReviewer/CodingReviewer/FileManagerService.swift', 'w') as f:
    f.write(content)

print("✅ Applied multiline constructor fixes")
EOF

echo "✅ Fixed remaining EnhancedAnalysisItem constructor calls"
echo "📄 Backup saved as: $FILE.backup2"
