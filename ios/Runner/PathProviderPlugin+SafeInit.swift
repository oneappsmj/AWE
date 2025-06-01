import Flutter
import path_provider_foundation

extension PathProviderPlugin {
    // Provide a safe fallback for registration
    static func safeRegister(with registrar: FlutterPluginRegistrar) {
        do {
            register(with: registrar)
        } catch {
            // Log the error but don't crash
            print("PathProviderPlugin registration failed: \(error)")
        }
    }
}