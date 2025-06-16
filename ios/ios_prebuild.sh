#!/bin/bash
# iOS Pre-build script
# This will be executed before the Xcode build

echo "Running iOS pre-build script to ensure privacy bundles are created"

# Get the build configuration
BUILD_TYPE="${CONFIGURATION}"
echo "Build type: $BUILD_TYPE"

# Define base paths
BASE_DIR="${BUILD_DIR}"
TARGET_BUILD_DIR="${BUILT_PRODUCTS_DIR}"

echo "Build directory: $BASE_DIR"
echo "Target build directory: $TARGET_BUILD_DIR"

# Create necessary directories for privacy bundles
PLUGINS_WITH_PRIVACY_ISSUES=(
  "sqflite_darwin"
  "share_plus"
  "shared_preferences_foundation"
  "video_player_avfoundation"
  "path_provider_foundation"
  "flutter_secure_storage"
)

# Create empty privacy bundles for each plugin
for PLUGIN in "${PLUGINS_WITH_PRIVACY_ISSUES[@]}"; do
  echo "Creating privacy bundle for $PLUGIN"
  
  # Create directory for the privacy bundle
  mkdir -p "${TARGET_BUILD_DIR}/${PLUGIN}/${PLUGIN}_privacy.bundle"
  
  # Create empty file inside bundle
  touch "${TARGET_BUILD_DIR}/${PLUGIN}/${PLUGIN}_privacy.bundle/${PLUGIN}_privacy"
done

echo "Pre-build script completed successfully"
exit 0 