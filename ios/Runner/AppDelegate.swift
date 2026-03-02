import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    let controller = window?.rootViewController as! FlutterViewController
    let wakelockChannel = FlutterMethodChannel(
      name: "com.furqan.quran/wakelock",
      binaryMessenger: controller.binaryMessenger
    )
    wakelockChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "enable":
        UIApplication.shared.isIdleTimerDisabled = true
        result(true)
      case "disable":
        UIApplication.shared.isIdleTimerDisabled = false
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
