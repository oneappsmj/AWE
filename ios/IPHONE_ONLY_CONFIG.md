# iPhone-Only Configuration Guide

When preparing your app for App Store submission as iPhone-only (no iPad support), follow these steps on your Mac:

## 1. Info.plist Changes (Already Completed)

The Info.plist has already been configured with:

- `UIDeviceFamily` set to `[1]` (iPhone only)
- Empty `UISupportedInterfaceOrientations~ipad` array
- `UIRequiresFullScreen` set to `true`

## 2. Xcode Project Settings

When opening the project on your Mac, you'll need to make these changes in Xcode:

1. Open the Xcode workspace:

   ```
   open ios/Runner.xcworkspace
   ```

2. Select the Runner project in the Project Navigator (left sidebar)

3. Select the "Runner" target

4. Go to the "Build Settings" tab

5. Search for "targeted device family"

6. Change the value to "iPhone" or "1" (instead of "iPhone, iPad" or "1,2")

7. Build Settings > Deployment > Targeted Device Family > Set to "iPhone"

## 3. Run the Setup Script

Run the provided setup script before building for release:

```
chmod +x ios/iphone_only_setup.sh
./ios/iphone_only_setup.sh
```

## 4. App Store Connect Settings

When uploading to App Store Connect:

1. In the App Store Connect web interface, go to your app
2. In the "App Information" section, find "iPhone / iPod Touch"
3. Make sure only iPhone/iPod is checked, not iPad

## 5. Final Build and Submit

After making these changes:

```
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
```

Then archive and upload using Xcode.

## Verification

To verify your app is iPhone-only:

1. In App Store Connect, check the app preview shows only iPhone devices
2. In the App Information page, only iPhone should be selected as a supported device
3. When published, the app should only appear in searches on iPhones, not iPads
