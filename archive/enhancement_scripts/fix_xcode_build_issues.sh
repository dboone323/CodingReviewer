#!/bin/bash

# Fix Xcode Build Issues Script
# Addresses duplicate output files and Swift compilation problems

echo "🔧 Starting Xcode build issue resolution..."

# Function to safely run commands
run_command() {
    echo "Running: $1"
    eval "$1"
    if [ $? -ne 0 ]; then
        echo "⚠️  Warning: Command failed but continuing..."
    fi
}

# 1. Clean all build artifacts
echo "🧹 Cleaning build artifacts..."
run_command "rm -rf ~/Library/Developer/Xcode/DerivedData/CodingReviewer-*"
run_command "rm -rf ~/Library/Caches/com.apple.dt.Xcode"
run_command "rm -rf .build"

# 2. Clean Xcode project-specific caches
echo "🗂️  Cleaning project caches..."
if [ -d "CodingReviewer.xcodeproj" ]; then
    run_command "find CodingReviewer.xcodeproj -name '*.pbxuser' -delete"
    run_command "find CodingReviewer.xcodeproj -name '*.mode1v3' -delete"
    run_command "find CodingReviewer.xcodeproj -name '*.perspectivev3' -delete"
    run_command "find CodingReviewer.xcodeproj -name 'xcuserdata' -exec rm -rf {} + 2>/dev/null"
fi

# 3. Clean Swift compiler caches
echo "⚡ Cleaning Swift compiler caches..."
run_command "rm -rf ~/Library/org.swift.swiftpm"
run_command "rm -rf ~/Library/Caches/org.swift.swiftpm"

# 4. Reset Xcode preferences (if needed)
echo "⚙️  Resetting Xcode build settings..."
run_command "defaults delete com.apple.dt.Xcode 2>/dev/null"

# 5. Clean workspace state
echo "📁 Cleaning workspace state..."
run_command "find . -name '.DS_Store' -delete"
run_command "find . -name '*.orig' -delete"

# 6. Fix potential duplicate file issues
echo "🔍 Checking for duplicate Swift files..."
find . -name "*.swift" -type f | sort | uniq -d | while read duplicate; do
    echo "⚠️  Found potential duplicate: $duplicate"
done

# 7. Validate project structure
echo "📋 Validating project structure..."
if [ ! -d "CodingReviewer.xcodeproj" ]; then
    echo "❌ Error: CodingReviewer.xcodeproj not found!"
    exit 1
fi

# 8. Build with clean slate
echo "🏗️  Attempting clean build..."
cd "$(dirname "$0")"

# Use xcodebuild with clean first
run_command "xcodebuild -project CodingReviewer.xcodeproj -scheme CodingReviewer clean"

# Wait a moment for file system to sync
sleep 2

# Build with specific settings to avoid conflicts
echo "🚀 Building project..."
xcodebuild -project CodingReviewer.xcodeproj \
    -scheme CodingReviewer \
    -configuration Debug \
    -destination "platform=macOS,arch=arm64" \
    SWIFT_COMPILATION_MODE=wholemodule \
    SWIFT_OPTIMIZATION_LEVEL=-Onone \
    build

BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
    echo "✅ Build completed successfully!"
else
    echo "❌ Build failed. Attempting additional fixes..."
    
    # Additional fix: Reset build settings
    echo "🔧 Applying additional fixes..."
    
    # Try building with different settings
    xcodebuild -project CodingReviewer.xcodeproj \
        -scheme CodingReviewer \
        -configuration Debug \
        -destination "platform=macOS" \
        SWIFT_COMPILATION_MODE=singlefile \
        build
    
    SECOND_BUILD_RESULT=$?
    
    if [ $SECOND_BUILD_RESULT -eq 0 ]; then
        echo "✅ Build completed successfully with alternative settings!"
    else
        echo "❌ Build still failing. Please check the detailed output above."
        echo "💡 Consider:"
        echo "   1. Opening Xcode and checking for scheme configuration issues"
        echo "   2. Removing and re-adding problematic Swift files"
        echo "   3. Checking for circular dependencies"
        exit 1
    fi
fi

echo "🎉 Xcode build issue resolution completed!"