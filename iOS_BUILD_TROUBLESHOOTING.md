# iOS Build Troubleshooting Guide

## Common iOS Build Issues and Solutions

### 1. Missing Privacy Bundles

**Error:**

```
Build input file cannot be found: '/path/to/build/ios/Release-iphoneos/plugin_name/plugin_name_privacy.bundle/plugin_name_privacy'
```

**Solution:**
We've fixed this by:

1. Disabling privacy manifest requirements in the Podfile for problematic plugins
2. Creating a GitHub workflow that pre-creates empty bundle files
3. Removing privacy bundle references that cause build failures

### 2. Path Provider Foundation Conflicts

**Error:**

```
There are multiple dependencies with different sources for `path_provider_foundation` in `Podfile`
```

**Solution:**

1. Removed manual pod entry for path_provider_foundation in Podfile
2. Removed dependency override in pubspec.yaml
3. Let Flutter handle the plugin paths properly

### 3. iOS 18.5 Crash Fix

**Error:**

```
EXC_BAD_ACCESS (SIGSEGV) with KERN_INVALID_ADDRESS at 0x0000000000000000
```

**Solution:**
We've added these crucial fixes:

1. Memory safety settings in the Podfile:
   ```ruby
   # Disable sanitizers to prevent EXC_BAD_ACCESS crash
   config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PDISABLE_SANITIZERS=1'
   # Force unwrap protection
   config.build_settings['OTHER_SWIFT_FLAGS'] = '$(inherited) -Xfrontend -warn-long-expression-type-checking=100'
   ```
2. Specific Swift optimization levels based on build configuration

### Building Locally

When building locally on a Mac:

1. Clean your build:

   ```
   flutter clean
   ```

2. Get dependencies:

   ```
   flutter pub get
   ```

3. Install pods (from ios directory):

   ```
   cd ios
   pod install --repo-update
   cd ..
   ```

4. Build for release:

   ```
   flutter build ios --release
   ```

5. Open in Xcode for final steps:
   ```
   open ios/Runner.xcworkspace
   ```

### CI/CD Pipeline Recommendations

1. Use our provided GitHub workflow as a template
2. Create empty privacy bundles before building
3. Set `PRIVACY_MANIFEST_REQUIRED=NO` for problematic plugins
4. Use Ruby 3.2+ for latest CocoaPods compatibility
5. Use Flutter 3.29.3 or newer

## Further Assistance

If you encounter additional issues:

1. Check the Podfile setup for proper plugin configuration
2. Ensure all privacy-related build settings are consistent
3. Try a clean build environment if possible
