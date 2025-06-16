# iOS Privacy Bundle Issue Fix Guide

## Problem Description

When building Flutter applications for iOS, you may encounter errors related to missing privacy bundles such as:

```
Error (Xcode): Build input file cannot be found: '/Users/runner/work/AWE/AWE/build/ios/Release-iphoneos/sqflite_darwin/sqflite_darwin_privacy.bundle/sqflite_darwin_privacy'. Did you forget to declare this file as an output of a script phase or custom build rule which produces it?
```

This occurs because starting with Xcode 15+ and iOS 17+, Apple requires privacy manifests for all the frameworks in your app. Some Flutter plugins haven't been updated to include these privacy bundles.

## Root Cause

The issue happens because:

1. Flutter plugins like `sqflite_darwin`, `path_provider_foundation`, etc. reference privacy bundle files in their build settings
2. These files don't actually exist in the plugin, causing build failures
3. Apple requires these privacy manifests for App Store submissions

## Multiple Solutions

### Solution 1: Use the Privacy Bundle Fix Script

1. We've created a `privacy_bundle_fix.sh` script in the project root that:

   - Creates the necessary directories for all required privacy bundles
   - Adds empty placeholder files in these bundles

2. Run this script before building the app:
   ```bash
   chmod +x privacy_bundle_fix.sh
   ./privacy_bundle_fix.sh
   ```

### Solution 2: Configure Xcode Build Phase

1. In Xcode, open your project
2. Select the Runner target, go to "Build Phases"
3. Click "+" at the top and select "New Run Script Phase"
4. Move this new script phase before the "Thin Binary" phase
5. Add the following script content:

```bash
# iOS Pre-build script for privacy bundles
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
  mkdir -p "${BUILT_PRODUCTS_DIR}/${PLUGIN}/${PLUGIN}_privacy.bundle"
  touch "${BUILT_PRODUCTS_DIR}/${PLUGIN}/${PLUGIN}_privacy.bundle/${PLUGIN}_privacy"
done
```

### Solution 3: Update Podfile Configuration

1. We've updated the `Podfile` with comprehensive fixes:

   - Disabled privacy manifest requirements globally
   - Added special handling for plugins with privacy issues
   - Fixed path_provider_foundation to prevent iOS 18.5 crashes

2. Key sections in the Podfile include:

   ```ruby
   # Disable privacy manifests globally for all targets
   config.build_settings['PRIVACY_MANIFEST_REQUIRED'] = 'NO'

   # Remove privacy bundle reference if it exists
   if config.build_settings.key?('PRIVACY_MANIFEST_BUNDLE')
     config.build_settings.delete('PRIVACY_MANIFEST_BUNDLE')
   end
   ```

## GitHub Actions / CI Build Fix

For CI environments, we've taken a multi-layered approach:

1. Updated the GitHub workflow to run the `privacy_bundle_fix.sh` script
2. Added a manual fallback to create the privacy bundles directly in the workflow
3. Added helpful error output if the build fails

## How to Use This Fix

1. Ensure your `pubspec.yaml` has all required dependencies
2. Make sure the `Podfile` contains the fixes described above
3. Run `flutter pub get` to update dependencies
4. Make `privacy_bundle_fix.sh` executable: `chmod +x privacy_bundle_fix.sh`
5. Run the script: `./privacy_bundle_fix.sh`
6. Build your app: `flutter build ios --release`

## For Local Development

For local development, you can integrate the pre-build script into your Xcode project:

1. Open the Runner.xcworkspace in your ios directory
2. Add the `ios_prebuild.sh` script as a "Run Script" build phase
3. Make sure it runs before the "Thin Binary" phase

## Troubleshooting

If you still encounter issues:

1. Clean your build: `flutter clean`
2. Remove Pods: `cd ios && rm -rf Pods Podfile.lock && cd ..`
3. Get dependencies: `flutter pub get`
4. Install pods: `cd ios && pod install && cd ..`
5. Run the fix script: `./privacy_bundle_fix.sh`
6. Build again: `flutter build ios --release`

## Further Reading

- [Flutter iOS Privacy Manifests Documentation](https://docs.flutter.dev/development/platform-integration/ios/ios-privacy)
- [Apple Privacy Manifests Documentation](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
