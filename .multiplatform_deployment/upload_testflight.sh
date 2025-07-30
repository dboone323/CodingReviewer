#!/bin/bash

echo "🚀 Uploading to TestFlight..."

IPA_PATH="${1:-build/ios/CodingReviewer.ipa}"

if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA file not found: $IPA_PATH"
    exit 1
fi

# Upload using xcrun altool
echo "📤 Uploading to App Store Connect..."
xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --username "$APPLE_ID" \
    --password "$APP_SPECIFIC_PASSWORD"

if [ $? -eq 0 ]; then
    echo "✅ Successfully uploaded to TestFlight"
    echo "🔔 Beta testers will be notified automatically"
else
    echo "❌ Upload to TestFlight failed"
    exit 1
fi
