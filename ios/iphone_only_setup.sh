#!/bin/bash

# Script to configure Xcode project for iPhone only
# Run this on your Mac before submitting to App Store

echo "Configuring project for iPhone only..."

# Set the targeted device family to iPhone only (1)
# This ensures the App Store listing shows iPhone compatibility only
/usr/libexec/PlistBuddy -c "Set :TARGETED_DEVICE_FAMILY 1" ios/Flutter/Generated.xcconfig

# Update build settings
echo "TARGETED_DEVICE_FAMILY=1" >> ios/Flutter/Release.xcconfig
echo "TARGETED_DEVICE_FAMILY=1" >> ios/Flutter/Debug.xcconfig

# Display completion message
echo "Configuration complete! Your app is now set for iPhone only."
echo "When you build the project on Mac, it will be configured for iPhone only."
echo ""
echo "Important: After running this script, build your app with:"
echo "flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter build ios --release"
echo ""
echo "Then open in Xcode to archive and submit:"
echo "open ios/Runner.xcworkspace" 