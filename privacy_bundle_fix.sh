#!/bin/bash
# privacy_bundle_fix.sh
# This script creates empty privacy bundle files for plugins that require them
# Run this script before building the iOS app

# Make sure we're in the project root directory
cd "$(dirname "$0")/.."

echo "=== Privacy Bundle Fix Script ==="
echo "Creating empty privacy bundles for plugins..."

# Define the list of plugins requiring privacy bundles
PLUGINS=(
  "sqflite_darwin"
  "share_plus"
  "shared_preferences_foundation"
  "video_player_avfoundation"
  "path_provider_foundation"
  "flutter_secure_storage"
  "url_launcher_ios"
)

# Define all possible build configurations
BUILD_CONFIGS=(
  "Debug-iphoneos"
  "Release-iphoneos"
  "Debug-iphonesimulator"
  "Release-iphonesimulator"
)

# Define potential base directories
BASE_DIRS=(
  "build/ios"
  "ios/Flutter"
  "build/ios/iphoneos"
  "ios/build"
)

echo "Creating privacy bundles in all possible locations..."

# First method: Create bundles in all potential build locations
for plugin in "${PLUGINS[@]}"; do
  for config in "${BUILD_CONFIGS[@]}"; do
    for base_dir in "${BASE_DIRS[@]}"; do
      # Create plugin directory
      mkdir -p "${base_dir}/${config}/${plugin}/${plugin}_privacy.bundle"
      
      # Create empty placeholder file
      touch "${base_dir}/${config}/${plugin}/${plugin}_privacy.bundle/${plugin}_privacy"
      
      echo "✓ Created ${base_dir}/${config}/${plugin}/${plugin}_privacy.bundle"
    done
  done
done

# Second method: Create bundles directly in the app bundle directories
for config in "${BUILD_CONFIGS[@]}"; do
  for base_dir in "${BASE_DIRS[@]}"; do
    mkdir -p "${base_dir}/${config}/Runner.app"
    
    for plugin in "${PLUGINS[@]}"; do
      mkdir -p "${base_dir}/${config}/Runner.app/${plugin}_privacy.bundle"
      touch "${base_dir}/${config}/Runner.app/${plugin}_privacy.bundle/${plugin}_privacy"
      echo "✓ Created ${base_dir}/${config}/Runner.app/${plugin}_privacy.bundle"
    done
  done
done

# Third method: Create in other known locations
for plugin in "${PLUGINS[@]}"; do
  mkdir -p "build/ios/iphoneos/Runner.app/${plugin}_privacy.bundle"
  touch "build/ios/iphoneos/Runner.app/${plugin}_privacy.bundle/${plugin}_privacy"
  
  mkdir -p "build/ios/iphoneos/Runner.app/Frameworks/${plugin}.framework"
  mkdir -p "build/ios/iphoneos/Runner.app/Frameworks/${plugin}.framework/${plugin}_privacy.bundle"
  touch "build/ios/iphoneos/Runner.app/Frameworks/${plugin}.framework/${plugin}_privacy.bundle/${plugin}_privacy"
done

# Special video_player_avfoundation handling
echo "Adding special handling for video_player_avfoundation..."
for base_dir in "build" "ios" "ios/Flutter" "build/ios/iphoneos"; do
  mkdir -p "${base_dir}/video_player_avfoundation_privacy.bundle"
  touch "${base_dir}/video_player_avfoundation_privacy.bundle/video_player_avfoundation_privacy"
done

# Special url_launcher_ios handling
echo "Adding special handling for url_launcher_ios..."
for base_dir in "build" "ios" "ios/Flutter" "build/ios/iphoneos"; do
  mkdir -p "${base_dir}/url_launcher_ios_privacy.bundle"
  touch "${base_dir}/url_launcher_ios_privacy.bundle/url_launcher_ios_privacy"
done

# Creating symlinks as additional fallback
echo "Creating symlinks for additional fallback..."
mkdir -p build/ios/Release-iphoneos/video_player_avfoundation
mkdir -p build/ios/Debug-iphoneos/video_player_avfoundation
mkdir -p build/ios/Release-iphoneos/url_launcher_ios
mkdir -p build/ios/Debug-iphoneos/url_launcher_ios

if [ -d "build/ios/Release-iphoneos/video_player_avfoundation" ]; then
  ln -sf ../../iphoneos/Runner.app/video_player_avfoundation_privacy.bundle build/ios/Release-iphoneos/video_player_avfoundation/
fi

if [ -d "build/ios/Debug-iphoneos/video_player_avfoundation" ]; then
  ln -sf ../../iphoneos/Runner.app/video_player_avfoundation_privacy.bundle build/ios/Debug-iphoneos/video_player_avfoundation/
fi

if [ -d "build/ios/Release-iphoneos/url_launcher_ios" ]; then
  ln -sf ../../iphoneos/Runner.app/url_launcher_ios_privacy.bundle build/ios/Release-iphoneos/url_launcher_ios/
fi

if [ -d "build/ios/Debug-iphoneos/url_launcher_ios" ]; then
  ln -sf ../../iphoneos/Runner.app/url_launcher_ios_privacy.bundle build/ios/Debug-iphoneos/url_launcher_ios/
fi

# Check which directories were actually created
echo "Verifying created directories..."
find build -name "*_privacy.bundle" -type d | sort
find ios -name "*_privacy.bundle" -type d | sort

# Print environment variables that might be helpful for debugging
echo "Environment information:"
echo "PWD: $(pwd)"
echo "BUILD_DIR (if set): ${BUILD_DIR}"
echo "BUILT_PRODUCTS_DIR (if set): ${BUILT_PRODUCTS_DIR}"

echo "Successfully created privacy bundle placeholders"
exit 0 