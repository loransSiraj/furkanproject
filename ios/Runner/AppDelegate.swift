import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    let registrar = self.registrar(forPlugin: "WakelockPlugin")!
    let wakelockChannel = FlutterMethodChannel(
      name: "com.furqan.quran/wakelock",
      binaryMessenger: registrar.messenger()
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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
