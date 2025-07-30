#!/bin/bash

# Intelligent Build Validator
# Validates build integrity before and after enhancements

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

validate_build() {
    echo "🔨 Validating build integrity..."
    
    # Check if project file exists
    if [ ! -f "$PROJECT_PATH/CodingReviewer.xcodeproj/project.pbxproj" ]; then
        echo -e "${RED}❌ Project file not found${NC}"
        return 1
    fi
    
    # Quick syntax check on main Swift files
    local errors=0
    while IFS= read -r -d '' file; do
        if ! swiftc -parse "$file" > /dev/null 2>&1; then
            echo -e "${RED}❌ Syntax error in $(basename "$file")${NC}"
            ((errors++))
        fi
    done < <(find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -print0 2>/dev/null)
    
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✅ Build validation passed${NC}"
        return 0
    else
        echo -e "${RED}❌ Build validation failed: $errors syntax errors${NC}"
        return 1
    fi
}

# Run validation
validate_build
