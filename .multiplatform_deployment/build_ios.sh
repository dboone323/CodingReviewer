#!/bin/bash

echo "📱 Building iOS Application..."

SCHEME="CodingReviewer"
CONFIGURATION="Release"
ARCHIVE_PATH="build/ios/CodingReviewer.xcarchive"
IPA_PATH="build/ios/CodingReviewer.ipa"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/ios
mkdir -p build/ios

# Archive the project
echo "📦 Creating archive..."
xcodebuild archive \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates

if [ $? -ne 0 ]; then
    echo "❌ Archive failed"
    exit 1
fi

# Export IPA
echo "📤 Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "build/ios" \
    -exportOptionsPlist "ExportOptions.plist"

if [ $? -ne 0 ]; then
    echo "❌ Export failed"
    exit 1
fi

echo "✅ iOS build completed successfully"
echo "📱 IPA location: $IPA_PATH"
