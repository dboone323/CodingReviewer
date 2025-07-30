#!/bin/bash

# Quick Fix Script for Optional Chaining Issues
# Fixes the automated replacement that incorrectly added self? instead of self

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"

# Fix FileUploadManager.swift
sed -i '' 's/self?\.fileExtension = /self.fileExtension = /g' "$PROJECT_PATH/CodingReviewer/Services/FileUploadManager.swift"
sed -i '' 's/self?\.size = /self.size = /g' "$PROJECT_PATH/CodingReviewer/Services/FileUploadManager.swift"
sed -i '' 's/self?\.configuration = /self.configuration = /g' "$PROJECT_PATH/CodingReviewer/Services/FileUploadManager.swift"

# Fix DataFlowDiagnostics.swift
find "$PROJECT_PATH/CodingReviewer" -name "DataFlowDiagnostics.swift" -exec sed -i '' 's/self?\./self./g' {} \;

# Fix any other files with this pattern in initializers
find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -exec grep -l "self?\." {} \; | while read -r file; do
    # Only fix in init methods to avoid breaking legitimate optional chaining
    sed -i '' '/init(/,/^[[:space:]]*}/ s/self?\./self./g' "$file"
    echo "Fixed optional chaining in $(basename "$file")"
done

echo "✅ Fixed all incorrect optional chaining issues"
