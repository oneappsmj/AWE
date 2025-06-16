import Flutter
import path_provider_foundation
import Foundation

/// Extension to make PathProviderPlugin safer on iOS 18.5
extension PathProviderPlugin {
    // Safer registration method that handles nil values and exceptions
    public static func safeRegister(with registrar: FlutterPluginRegistrar?) {
        guard let registrar = registrar else {
            print("[CRITICAL] PathProviderPlugin registration failed: Registrar is nil")
            return
        }
        
        do {
            register(with: registrar)
            print("[SUCCESS] PathProviderPlugin registered successfully")
        } catch let error {
            print("[ERROR] PathProviderPlugin registration failed with error: \(error)")
        }
    }
    
    // Helper method to create privacy bundles at runtime if missing
    public static func createPrivacyBundleIfNeeded() {
        if let bundlePath = Bundle.main.bundlePath {
            let privacyBundlePath = bundlePath + "/path_provider_foundation_privacy.bundle"
            if !FileManager.default.fileExists(atPath: privacyBundlePath) {
                do {
                    try FileManager.default.createDirectory(
                        atPath: privacyBundlePath,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    
                    // Create empty file
                    FileManager.default.createFile(
                        atPath: privacyBundlePath + "/path_provider_foundation_privacy",
                        contents: nil
                    )
                    print("[SUCCESS] Created path_provider privacy bundle at runtime")
                } catch {
                    print("[WARNING] Failed to create privacy bundle: \(error)")
                }
            }
        }
    }
}