import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  func didInitializeImplicitFlutterEngine(
    _ engineBridge: FlutterImplicitEngineBridge
  ) {
    GeneratedPluginRegistrant.register(
      with: engineBridge.pluginRegistry
    )

    let storageSecurityChannel = FlutterMethodChannel(
      name: "com.aryansanghvi.afterlens/storage_security",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    storageSecurityChannel.setMethodCallHandler {
      call,
      result in

      guard call.method == "excludeFromBackup" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let arguments = call.arguments as? [String: Any],
        let path = arguments["path"] as? String
      else {
        result(
          FlutterError(
            code: "INVALID_ARGUMENT",
            message: "Storage path was not provided.",
            details: nil
          )
        )
        return
      }

      do {
        var url = URL(
          fileURLWithPath: path,
          isDirectory: true
        )

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true

        try url.setResourceValues(
          resourceValues
        )

        result(nil)
      } catch {
        result(
          FlutterError(
            code: "BACKUP_EXCLUSION_FAILED",
            message: "Could not exclude local storage from backup.",
            details: nil
          )
        )
      }
    }
  }
}