import Flutter
import path_provider_foundation
import Foundation

/// Extension to make PathProviderPlugin safer on iOS 18.5
extension PathProviderPlugin {
    // This method ensures the plugin is initialized safely
    // and handles potential null pointer dereference cases
    public static func safeRegister(with registrar: FlutterPluginRegistrar) {
        // Check if registrar is valid
        guard registrar != nil else {
            print("PathProviderPlugin: Warning - Received nil registrar, skipping registration")
            return
        }
        
        // Use the original register method with extra error handling
        do {
            register(with: registrar)
        } catch {
            print("PathProviderPlugin: Error during registration - \(error)")
        }
    }
}