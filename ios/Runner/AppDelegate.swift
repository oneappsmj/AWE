import UIKit
import Flutter
import AVKit
import AVFoundation
import path_provider_foundation

// Add this extension directly in AppDelegate.swift
extension PathProviderPlugin {
    // Provide a safe fallback for registration
    static func safeRegister(with registrar: FlutterPluginRegistrar?) {
         guard let registrar = registrar else {
            print("PathProviderPlugin registration failed: Registrar is nil")
            return
        }
        do {
            register(with: registrar)
        } catch {
            print("PathProviderPlugin registration failed: \(error)")
        }
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var pipController: AVPictureInPictureController?
    private var pipPlayer: AVPlayer?
    private var pipChannel: FlutterMethodChannel?
    private var playerViewController: AVPlayerViewController?
    private var pipSetupWorkItem: DispatchWorkItem?
    
    override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    // Configure audio session safely
    do {
        try configureAudioSession()
    } catch {
        print("Failed to configure audio session: \(error.localizedDescription)")
    }
    
    let controller = window?.rootViewController as! FlutterViewController
    
    // Initialize channels first
    setupThumbnailChannel(controller: controller)
    setupPipChannel(controller: controller)
    
    // Use our safe registration method from the extension
    let registry = controller as FlutterPluginRegistry
    // With this:
     // Safe registration for path_provider
    if let registrar = registry.registrar(forPlugin: "PathProviderPlugin") {
        PathProviderPlugin.register(with: registrar) // Use direct registration
    } else {
        print("Warning: PathProviderPlugin registrar is nil")
    }
    
    // Register all other plugins
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
    
    // MARK: - Application Lifecycle
    override func applicationWillEnterForeground(_ application: UIApplication) {
        do {
            try handleForegroundTransition()
        } catch {
            print("Error in foreground transition: \(error)")
        }
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        do {
            try handleBackgroundTransition()
        } catch {
            print("Error in background transition: \(error)")
        }
    }
    
    override func applicationWillTerminate(_ application: UIApplication) {
        cleanupPiPResources()
    }
    
    // MARK: - PIP Functionality
    private func handleStartPip(filePath: String, position: Double, result: @escaping FlutterResult) {
        // Cleanup existing PiP resources first
        cleanupPiPResources()
        
        // Check if PiP is supported on this device
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            result(FlutterError(code: "PIP_NOT_SUPPORTED", message: "Picture in Picture is not supported on this device", details: nil))
            return
        }
        
        // Check if file exists
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: filePath) else {
            result(FlutterError(code: "FILE_NOT_FOUND", message: "Video file not found at path: \(filePath)", details: nil))
            return
        }
        
        let url = URL(fileURLWithPath: filePath)
        
        // Create asset to validate the media before playing
        let asset = AVAsset(url: url)
        let playableKey = "playable"
        
        asset.loadValuesAsynchronously(forKeys: [playableKey]) { [weak self] in
            guard let self = self else { 
                DispatchQueue.main.async {
                    result(FlutterError(code: "INSTANCE_GONE", message: "AppDelegate instance no longer available", details: nil))
                }
                return 
            }
            
            var error: NSError? = nil
            let status = asset.statusOfValue(forKey: playableKey, error: &error)
            
            DispatchQueue.main.async {
                if status == .failed || error != nil {
                    result(FlutterError(code: "MEDIA_ERROR", 
                                      message: "Cannot play media: \(error?.localizedDescription ?? "Unknown error")", 
                                      details: nil))
                    return
                }
                
                do {
                    try self.configureAudioSessionForPlayback()
                } catch {
                    print("Audio session config error: \(error)")
                    // Continue despite audio session error
                }
                
                // Only create player after asset validation
                self.pipPlayer = AVPlayer(url: url)
                
                if position > 0 {
                    let cmTime = CMTime(seconds: position / 1000.0, preferredTimescale: 1000)
                    self.pipPlayer?.seek(to: cmTime)
                }
                
                do {
                    try self.setupPlayerViewController()
                    self.setupPictureInPicture(result: result)
                    self.pipPlayer?.play()
                } catch {
                    result(FlutterError(code: "PIP_SETUP_ERROR", message: "Error setting up PiP: \(error.localizedDescription)", details: nil))
                    self.cleanupPiPResources()
                }
            }
        }
    }
    
    private func handleStopPip(result: @escaping FlutterResult) {
        if pipController?.isPictureInPictureActive == true {
            pipController?.stopPictureInPicture()
        }
        cleanupPiPResources()
        result(nil)
    }
    
    // MARK: - Thumbnail Generation
    private func generateThumbnail(videoPath: String, thumbnailPath: String, maxWidth: Int, quality: Int, result: @escaping FlutterResult) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: videoPath) else {
            result(FlutterError(code: "FILE_NOT_FOUND", message: "Video file not found at path: \(videoPath)", details: nil))
            return
        }
        
        let url = URL(fileURLWithPath: videoPath)
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: maxWidth, height: maxWidth)
        
        // Ensure video duration is valid
        if asset.duration.seconds <= 0 {
            result(FlutterError(code: "INVALID_VIDEO", message: "Invalid video duration", details: nil))
            return
        }
        
        let time = CMTime(seconds: asset.duration.seconds / 2, preferredTimescale: 600)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            
            if let data = uiImage.jpegData(compressionQuality: CGFloat(quality)/100.0) {
                // Ensure directory exists
                let thumbnailURL = URL(fileURLWithPath: thumbnailPath)
                try fileManager.createDirectory(at: thumbnailURL.deletingLastPathComponent(), 
                                             withIntermediateDirectories: true)
                
                try data.write(to: thumbnailURL)
                result(thumbnailPath)
            } else {
                result(FlutterError(code: "IMAGE_ERROR", message: "Failed to create JPEG data", details: nil))
            }
        } catch {
            result(FlutterError(code: "THUMBNAIL_ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    // MARK: - Configuration Methods
    private func configureAudioSession() throws {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try AVAudioSession.sharedInstance().setActive(true)
    }
    
    private func configureAudioSessionForPlayback() throws {
        try AVAudioSession.sharedInstance().setCategory(.playback,
                                                      mode: .moviePlayback,
                                                      options: [.allowAirPlay, .allowBluetooth])
        try AVAudioSession.sharedInstance().setActive(true)
    }
    
    private func setupThumbnailChannel(controller: FlutterViewController) {
        let thumbnailChannel = FlutterMethodChannel(
            name: "native_thumbnail",
            binaryMessenger: controller.binaryMessenger
        )
        
        thumbnailChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "Thumbnail channel unavailable", details: nil))
                return
            }
            
            guard call.method == "generateThumbnail",
                  let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String,
                  let thumbnailPath = args["thumbnailPath"] as? String,
                  let maxWidth = args["maxWidth"] as? Int,
                  let quality = args["quality"] as? Int else {
                result(FlutterMethodNotImplemented)
                return
            }
            
            self.generateThumbnail(
                videoPath: videoPath,
                thumbnailPath: thumbnailPath,
                maxWidth: maxWidth,
                quality: quality,
                result: result
            )
        }
    }
    
    private func setupPipChannel(controller: FlutterViewController) {
        pipChannel = FlutterMethodChannel(
            name: "pip_channel",
            binaryMessenger: controller.binaryMessenger
        )
        
        pipChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "PiP channel unavailable", details: nil))
                return
            }
            
            switch call.method {
            case "startPip":
               guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String,
                  let position = args["position"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for startPip", details: nil))
                return
            }
            self.handleStartPip(filePath: path, position: position, result: result)
            case "stopPip":
                self.handleStopPip(result: result)
            case "isPipSupported":
                 let isSupported = AVPictureInPictureController.isPictureInPictureSupported()
                 result(isSupported)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    // MARK: - PIP Helper Methods
    private func setupPlayerViewController() throws {
    // Clean up any existing player view controller
    if let existingVC = playerViewController {
        existingVC.willMove(toParent: nil)
        existingVC.view.removeFromSuperview()
        existingVC.removeFromParent()
        existingVC.player = nil
    }
    
    playerViewController = AVPlayerViewController()
    guard let playerVC = playerViewController else {
        throw NSError(domain: "com.downloadsplatform", code: 1001, 
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create AVPlayerViewController"])
    }
    
    playerVC.player = pipPlayer
    playerVC.allowsPictureInPicturePlayback = true
    playerVC.showsPlaybackControls = true // Show controls for better user experience

    // Add to view hierarchy properly
    playerVC.view.frame = CGRect(x: 0, y: 0, width: 1, height: 1) // Minimal size initially
    playerVC.view.isHidden = true // Hide initially
    
    guard let rootVC = window?.rootViewController else {
        throw NSError(domain: "com.downloadsplatform", code: 1002, 
                    userInfo: [NSLocalizedDescriptionKey: "Root view controller not available"])
    }
    
    rootVC.view.addSubview(playerVC.view)
    rootVC.addChild(playerVC)
    playerVC.didMove(toParent: rootVC)
}
    
    private func setupPictureInPicture(result: @escaping FlutterResult) {
        // Cancel any existing setup
        pipSetupWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else {
                result(FlutterError(code: "INSTANCE_GONE", message: "AppDelegate instance no longer available", details: nil))
                return
            }
            
            guard let playerViewController = self.playerViewController else {
                result(FlutterError(code: "PIP_ERROR", message: "Player view controller not available", details: nil))
                self.cleanupPiPResources()
                return
            }
            
            // Find AVPlayerLayer using safe unwrapping
            guard let playerLayer = playerViewController.playerView?.layer as? AVPlayerLayer else {
                result(FlutterError(code: "PIP_ERROR", message: "Player layer not available", details: nil))
                self.cleanupPiPResources()
                return
            }
            
            guard AVPictureInPictureController.isPictureInPictureSupported() else {
                result(FlutterError(code: "PIP_ERROR", message: "Picture in Picture not supported on this device", details: nil))
                self.cleanupPiPResources()
                return
            }
            
            // Create PiP controller with safely unwrapped player layer
            self.pipController = AVPictureInPictureController(playerLayer: playerLayer)
            self.pipController?.delegate = self
             
            
            // Add observer only if controller initialized successfully
            if self.pipController != nil {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.handleBackgroundTransition),
                    name: UIApplication.didEnterBackgroundNotification,
                    object: nil
                )
                
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.handleForegroundTransition),
                    name: UIApplication.willEnterForegroundNotification,
                    object: nil
                )
                
                // Start PiP with additional error handling
                guard let pipController = self.pipController else {
                    result(FlutterError(code: "PIP_ERROR", message: "PiP controller not initialized", details: nil))
                    self.cleanupPiPResources()
                    return
                }
                
                if pipController.isPictureInPicturePossible {
                    if #available(iOS 14.2, *) {
                        // Use canStartPictureInPictureAutomaticallyFromInline for iOS 14.2+
                        pipController.canStartPictureInPictureAutomaticallyFromInline = true
                    }
                    
                    // FIXED: Safe unwrapping before calling startPictureInPicture()
                    pipController.startPictureInPicture()
                    result(nil)
                } else {
                    result(FlutterError(code: "PIP_ERROR", message: "PiP not possible at this moment", details: nil))
                    self.cleanupPiPResources()
                }
            } else {
                result(FlutterError(code: "PIP_ERROR", message: "Failed to initialize PiP controller", details: nil))
                self.cleanupPiPResources()
            }
        }
        
        pipSetupWorkItem = workItem
        
        // Add timeout for PiP setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            if let workItem = self?.pipSetupWorkItem, !workItem.isCancelled {
                workItem.cancel()
                result(FlutterError(code: "PIP_TIMEOUT", message: "PiP setup timed out", details: nil))
                self?.cleanupPiPResources()
            }
        }
    }
    
    private func cleanupPiPResources() {
        // Cancel any pending work items
        pipSetupWorkItem?.cancel()
        pipSetupWorkItem = nil
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    
        
        // Safely stop playback
        pipPlayer?.pause()
        pipPlayer = nil
        
        // Safely stop PiP if active
        if pipController?.isPictureInPictureActive == true {
            pipController?.stopPictureInPicture()
        }
        pipController?.delegate = nil
        pipController = nil
        
        // Clean up player view controller
        if let playerVC = playerViewController {
            playerVC.willMove(toParent: nil)
            playerVC.view.removeFromSuperview()
            playerVC.removeFromParent()
        }
        playerViewController = nil
    }
    
    // MARK: - Lifecycle Handlers
    @objc private func handleBackgroundTransition() throws {
    // Only start PiP if we have an active player
    if let player = pipPlayer, player.rate > 0,
       let controller = pipController, 
       !controller.isPictureInPictureActive,
       controller.isPictureInPicturePossible {
        controller.startPictureInPicture()
    }
    
    // Proper background task handling
    var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
        // Clean up on expiration
        self?.pipPlayer?.pause()
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }
}
    
    @objc private func handleForegroundTransition() throws {
        if pipController?.isPictureInPictureActive == true {
            pipController?.stopPictureInPicture()
        }
    }
    
    // MARK: - Orientation
    override func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}

// MARK: - PIP Controller Delegate
extension AppDelegate: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        pipChannel?.invokeMethod("onPiPStarted", arguments: nil)
        playerViewController?.view.isHidden = true
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        pipChannel?.invokeMethod("onPiPStopped", arguments: nil)
        
        if UIApplication.shared.applicationState != .active {
            // App is in background, clean up resources
            cleanupPiPResources()
        } else {
            // App is active, show player in full screen
            playerViewController?.view.isHidden = false
            playerViewController?.view.frame = UIScreen.main.bounds
            // Let the Flutter app decide what to do next
        }
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        pipChannel?.invokeMethod("onPiPError", arguments: error.localizedDescription)
        cleanupPiPResources()
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        pipChannel?.invokeMethod("onRestoreFullScreen", arguments: nil)
        // Show the player in full screen
        playerViewController?.view.isHidden = false
        playerViewController?.view.frame = UIScreen.main.bounds
        completionHandler(true)
    }
}

extension AVPlayerViewController {
    var playerView: UIView? {
    // First try the direct approach
    let directResult = self.view.subviews.first(where: { $0.layer is AVPlayerLayer })
    if directResult != nil {
        return directResult
    }
    
    // Try recursive search as fallback
    for subview in self.view.subviews {
        if let found = findPlayerLayerView(in: subview) {
            return found
        }
    }
    return nil
}

private func findPlayerLayerView(in view: UIView) -> UIView? {
    if view.layer is AVPlayerLayer {
        return view
    }
    for subview in view.subviews {
        if let found = findPlayerLayerView(in: subview) {
            return found
        }
    }
    return nil
}
}