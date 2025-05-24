#!/bin/bash

# This script ensures that the app is configured for iPhone only
# To use: chmod +x set_iphone_only.sh && ./set_iphone_only.sh

# Path to project.pbxproj
PROJECT_FILE="Runner.xcodeproj/project.pbxproj"

# Ensure project file exists
if [ ! -f "$PROJECT_FILE" ]; then
  echo "Error: project.pbxproj file not found at $PROJECT_FILE"
  exit 1
fi

# Replace "TARGETED_DEVICE_FAMILY = \"1,2\";" with "TARGETED_DEVICE_FAMILY = 1;"
sed -i '' 's/TARGETED_DEVICE_FAMILY = "1,2";/TARGETED_DEVICE_FAMILY = 1;/g' "$PROJECT_FILE"

# Ensure Info.plist has UIDeviceFamily key set to 1
INFO_PLIST="Runner/Info.plist"
if [ ! -f "$INFO_PLIST" ]; then
  echo "Error: Info.plist file not found at $INFO_PLIST"
  exit 1
fi

# Check if UIDeviceFamily exists and update it, or add it if it doesn't exist
if grep -q "UIDeviceFamily" "$INFO_PLIST"; then
  echo "UIDeviceFamily key exists, ensuring it's set to iPhone only"
  # Complex operation would require a more robust tool than sed
  # For now, this script just alerts the user to check manually
  echo "Please verify manually that UIDeviceFamily in $INFO_PLIST only contains value 1 (iPhone)"
else
  echo "UIDeviceFamily key not found, adding it"
  # Insert UIDeviceFamily key after LSRequiresIPhoneOS
  sed -i '' '/<key>LSRequiresIPhoneOS<\/key>/a\'$'\n''  <key>UIDeviceFamily<\/key>'$'\n''  <array>'$'\n''    <integer>1<\/integer>'$'\n''  <\/array>' "$INFO_PLIST"
fi

echo "iPhone-only configuration complete"
echo "IMPORTANT: Submit a new build to App Store Connect and ensure it is properly configured as iPhone-only"
echo "In App Store Connect, verify under General > App Information that 'iPhone' is the only selected device"

exit 0 