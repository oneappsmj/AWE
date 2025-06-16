#!/bin/bash
# privacy_bundle_fix.sh
# This script creates empty privacy bundle files for plugins that require them
# Run this script before building the iOS app

# Make sure we're in the project root directory
cd "$(dirname "$0")/.."

echo "Creating empty privacy bundles for plugins..."

# Create directories for all required privacy bundles
mkdir -p "build/ios/Release-iphoneos/sqflite_darwin/sqflite_darwin_privacy.bundle"
mkdir -p "build/ios/Release-iphoneos/share_plus/share_plus_privacy.bundle"
mkdir -p "build/ios/Release-iphoneos/shared_preferences_foundation/shared_preferences_foundation_privacy.bundle"
mkdir -p "build/ios/Release-iphoneos/video_player_avfoundation/video_player_avfoundation_privacy.bundle"
mkdir -p "build/ios/Release-iphoneos/path_provider_foundation/path_provider_foundation_privacy.bundle"
mkdir -p "build/ios/Debug-iphoneos/sqflite_darwin/sqflite_darwin_privacy.bundle"
mkdir -p "build/ios/Debug-iphoneos/share_plus/share_plus_privacy.bundle"
mkdir -p "build/ios/Debug-iphoneos/shared_preferences_foundation/shared_preferences_foundation_privacy.bundle"
mkdir -p "build/ios/Debug-iphoneos/video_player_avfoundation/video_player_avfoundation_privacy.bundle"
mkdir -p "build/ios/Debug-iphoneos/path_provider_foundation/path_provider_foundation_privacy.bundle"

# Create empty placeholder files
touch "build/ios/Release-iphoneos/sqflite_darwin/sqflite_darwin_privacy.bundle/sqflite_darwin_privacy"
touch "build/ios/Release-iphoneos/share_plus/share_plus_privacy.bundle/share_plus_privacy"
touch "build/ios/Release-iphoneos/shared_preferences_foundation/shared_preferences_foundation_privacy.bundle/shared_preferences_foundation_privacy"
touch "build/ios/Release-iphoneos/video_player_avfoundation/video_player_avfoundation_privacy.bundle/video_player_avfoundation_privacy"
touch "build/ios/Release-iphoneos/path_provider_foundation/path_provider_foundation_privacy.bundle/path_provider_foundation_privacy"
touch "build/ios/Debug-iphoneos/sqflite_darwin/sqflite_darwin_privacy.bundle/sqflite_darwin_privacy"
touch "build/ios/Debug-iphoneos/share_plus/share_plus_privacy.bundle/share_plus_privacy"
touch "build/ios/Debug-iphoneos/shared_preferences_foundation/shared_preferences_foundation_privacy.bundle/shared_preferences_foundation_privacy"
touch "build/ios/Debug-iphoneos/video_player_avfoundation/video_player_avfoundation_privacy.bundle/video_player_avfoundation_privacy"
touch "build/ios/Debug-iphoneos/path_provider_foundation/path_provider_foundation_privacy.bundle/path_provider_foundation_privacy"

echo "Successfully created privacy bundle placeholders" 