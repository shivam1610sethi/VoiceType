#!/bin/bash

# VoiceType Notarization Script
# Usage: ./notarize.sh

set -e

# Configuration - Update these values
APPLE_ID="your-apple-id@example.com"
TEAM_ID="YOUR_TEAM_ID"
APP_PATH="./build/VoiceType.app"
BUNDLE_ID="com.voicetype.app"

echo "🔐 VoiceType Notarization Script"
echo "================================="

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App not found at $APP_PATH"
    echo "Please build the app first in Xcode (Product → Archive)"
    exit 1
fi

# Create zip for notarization
echo "📦 Creating zip for notarization..."
ZIP_PATH="./build/VoiceType.zip"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

# Submit for notarization
echo "📤 Submitting to Apple for notarization..."
echo "   This may take a few minutes..."

xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "@keychain:AC_PASSWORD" \
    --wait

# Check notarization status
echo "✅ Notarization complete!"

# Staple the ticket
echo "📎 Stapling notarization ticket to app..."
xcrun stapler staple "$APP_PATH"

# Verify
echo "🔍 Verifying notarization..."
spctl --assess --verbose "$APP_PATH"

echo ""
echo "✅ VoiceType is now notarized and ready for distribution!"
echo "   App location: $APP_PATH"
echo ""
echo "Next steps:"
echo "  1. Run ./create-dmg.sh to create a distributable DMG"
echo "  2. Upload the DMG to your website"
