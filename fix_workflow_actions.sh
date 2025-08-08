#!/bin/bash

# Fix deprecated GitHub Actions across all workflows
echo "🔧 Fixing deprecated GitHub Actions in workflows..."

WORKFLOW_DIR=".github/workflows"

# Function to update actions in a file
update_actions_in_file() {
    local file="$1"
    echo "📝 Updating actions in $file..."
    
    # Update actions/upload-artifact from v3 to v4
    sed -i '' 's/actions\/upload-artifact@v3/actions\/upload-artifact@v4/g' "$file"
    
    # Update actions/cache from v3 to v4  
    sed -i '' 's/actions\/cache@v3/actions\/cache@v4/g' "$file"
    
    # Update actions/setup-python from v4 to v5
    sed -i '' 's/actions\/setup-python@v4/actions\/setup-python@v5/g' "$file"
    
    # Update actions/github-script from v6 to v7
    sed -i '' 's/actions\/github-script@v6/actions\/github-script@v7/g' "$file"
    
    # Update github/codeql-action from v2 to v3
    sed -i '' 's/github\/codeql-action@v2/github\/codeql-action@v3/g' "$file"
    
    # Update peter-evans/create-pull-request from v5 to v7
    sed -i '' 's/peter-evans\/create-pull-request@v5/peter-evans\/create-pull-request@v7/g' "$file"
    
    echo "✅ Updated actions in $file"
}

# Find all workflow files and update them
if [ -d "$WORKFLOW_DIR" ]; then
    for workflow_file in "$WORKFLOW_DIR"/*.yml; do
        if [ -f "$workflow_file" ]; then
            update_actions_in_file "$workflow_file"
        fi
    done
    echo "🎉 All workflow files updated!"
else
    echo "❌ Workflow directory not found: $WORKFLOW_DIR"
    exit 1
fi

echo "✅ GitHub Actions update complete!"
echo "📋 Updated actions:"
echo "  • actions/upload-artifact: v3 → v4"
echo "  • actions/cache: v3 → v4"  
echo "  • actions/setup-python: v4 → v5"
echo "  • actions/github-script: v6 → v7"
echo "  • github/codeql-action: v2 → v3"
echo "  • peter-evans/create-pull-request: v5 → v7"
