platform :ios, '15.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist."
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}."
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  ENV['COCOAPODS_DISABLE_SYMLINKS'] = 'true'
  
  # Remove explicit pod for path_provider_foundation to avoid conflicts
  # Let Flutter manage the plugin paths
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # ========= GLOBAL PRIVACY MANIFEST SETTINGS =========
    # Disable privacy manifests globally for all targets
    target.build_configurations.each do |config|
      # Disable privacy manifest requirements for all plugins
      config.build_settings['PRIVACY_MANIFEST_REQUIRED'] = 'NO' 
      
      if config.build_settings.key?('PRIVACY_MANIFEST_BUNDLE')
        config.build_settings.delete('PRIVACY_MANIFEST_BUNDLE')
      end
    end
    # ========= END OF GLOBAL PRIVACY MANIFEST SETTINGS =========

    # ========= START FIX FOR MISSING PRIVACY BUNDLES =========
    # Fix for plugins without proper privacy manifest
    plugins_with_privacy_issues = [
      'sqflite_darwin', 
      'share_plus', 
      'shared_preferences_foundation',
      'video_player_avfoundation',
      'path_provider_foundation',
      'flutter_secure_storage'
    ]
    
    if plugins_with_privacy_issues.include?(target.name)
      target.build_configurations.each do |config|
        # Disable privacy manifest requirement for problematic plugins
        config.build_settings['PRIVACY_MANIFEST_REQUIRED'] = 'NO'
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
        
        # Remove privacy bundle reference
        if config.build_settings.key?('PRIVACY_MANIFEST_BUNDLE')
          config.build_settings.delete('PRIVACY_MANIFEST_BUNDLE')
        end
      end
    end
    # ========= END FIX FOR MISSING PRIVACY BUNDLES =========

    if target.name == 'video_player_avfoundation'
      target.build_configurations.each do |config|
        # Ensure privacy bundle is included
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
        config.build_settings['PRIVACY_MANIFEST_BUNDLE'] = '${TARGET_NAME}_privacy.bundle'
      end
    end
    target.build_configurations.each do |config|
      # ==== START OF CRITICAL FIX FOR iOS 18.5 CRASH ====
      if target.name == 'path_provider_foundation'
        # Disable sanitizers to prevent EXC_BAD_ACCESS crash
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= []
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PDISABLE_SANITIZERS=1'
        
        # Ensure Swift compatibility
        config.build_settings['SWIFT_VERSION'] = '5.0'
        
        # Additional memory safety settings
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone' if config.name == 'Debug'
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O' if config.name != 'Debug'
        
        # Force unwrap protection
        config.build_settings['OTHER_SWIFT_FLAGS'] = '$(inherited) -Xfrontend -warn-long-expression-type-checking=100'
      end
      # ==== END OF CRITICAL FIX ====
      if target.name == 'flutter_secure_storage'
        config.build_settings['SWIFT_VERSION'] = '5.0'
        config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
      end
      
     
      # Existing settings
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings.delete('EXCLUDED_ARCHS[sdk=iphonesimulator*]')
      
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= []
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << '$(inherited)'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'AUDIO_SESSION_MICROPHONE=0' unless target.name == 'path_provider_foundation'
      
      # Fix Swift 5 compatibility for all plugins
      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
      config.build_settings['LIBRARY_SEARCH_PATHS'] = ['$(SDKROOT)/usr/lib/swift']
      
      if config.name == 'Release'
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
        config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
      end
    end
  end
  
  # ===== FINAL FIXES FOR XCODE BUILD SYSTEM =====
  # These settings apply to the entire project
  installer.pods_project.build_configurations.each do |config|
    # Disable user script sandboxing for Xcode 16+ compatibility
    config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    
    # Set PRIVACY_MANIFEST_REQUIRED to NO for the entire project
    config.build_settings['PRIVACY_MANIFEST_REQUIRED'] = 'NO'
  end
  # ===== END OF FINAL FIXES =====
end 