#!/bin/bash

echo "💻 Building macOS Application..."

SCHEME="CodingReviewer-macOS"
CONFIGURATION="Release"
ARCHIVE_PATH="build/macos/CodingReviewer.xcarchive"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/macos
mkdir -p build/macos

# Build and archive
echo "📦 Creating macOS archive..."
xcodebuild archive \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=macOS"

if [ $? -ne 0 ]; then
    echo "❌ macOS build failed"
    exit 1
fi

echo "✅ macOS build completed successfully"
echo "💻 Archive location: $ARCHIVE_PATH"
