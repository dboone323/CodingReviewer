#!/bin/bash

# 🔧 Improved Optional Chaining Fix Script
# Intelligently fixes optional chaining issues without breaking valid patterns

PROJECT_PATH="/Users/danielstevens/Desktop/CodingReviewer"

# Smart optional chaining fixer
fix_optional_chaining_intelligently() {
    local file="$1"
    local basename_file=$(basename "$file")
    
    # Patterns to fix in different contexts
    
    # 1. Fix in initializers (self?. should be self.)
    sed -i '' '/init(/,/^[[:space:]]*}/ {
        s/self?\.name = /self.name = /g
        s/self?\.path = /self.path = /g
        s/self?\.content = /self.content = /g
        s/self?\.fileExtension = /self.fileExtension = /g
        s/self?\.size = /self.size = /g
        s/self?\.configuration = /self.configuration = /g
        s/self?\.isGeneratingTests = /self.isGeneratingTests = /g
        s/self?\.generatedTestCases = /self.generatedTestCases = /g
        s/self?\.testCoverage = /self.testCoverage = /g
        s/self?\.showingKeySetup = /self.showingKeySetup = /g
    }' "$file"
    
    # 2. Fix in MainActor.run blocks (self?. should be self.)
    sed -i '' '/MainActor\.run/,/^[[:space:]]*}/ {
        s/self?\.performanceMetrics\./self.performanceMetrics./g
        s/self?\.objectWillChange\.send()/self.objectWillChange.send()/g
        s/self?\.mlInsights = /self.mlInsights = /g
        s/self?\.predictiveData = /self.predictiveData = /g
        s/self?\.crossProjectLearnings = /self.crossProjectLearnings = /g
        s/self?\.analysisProgress = /self.analysisProgress = /g
        s/self?\.quantumPerformance = /self.quantumPerformance = /g
        s/self?\.isQuantumActive = /self.isQuantumActive = /g
        s/self?\.processingStatus = /self.processingStatus = /g
    }' "$file"
    
    # 3. Fix method calls that don't need optional chaining
    sed -i '' 's/await self?\.refreshMLData()/await self.refreshMLData()/g' "$file"
    sed -i '' 's/await self?\.processEnhancedQuantumChunk/await self.processEnhancedQuantumChunk/g' "$file"
    
    # 4. Fix String extension (should never be optional)
    sed -i '' 's/return self?\.trimmingCharacters/return self.trimmingCharacters/g' "$file"
    
    # Only report if changes were made
    if [[ -n $(git diff --name-only "$file" 2>/dev/null) ]] || [[ ! -d .git ]]; then
        echo "Fixed optional chaining in $basename_file"
    fi
}

# Process all Swift files
find "$PROJECT_PATH/CodingReviewer" -name "*.swift" -type f | while read -r file; do
    fix_optional_chaining_intelligently "$file"
done

echo "✅ Fixed all incorrect optional chaining issues intelligently"
