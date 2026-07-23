import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var mapsConfigChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    mapsConfigChannel = FlutterMethodChannel(
      name: "serviup/maps_config",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    mapsConfigChannel?.setMethodCallHandler { call, result in
      guard call.method == "getApiKey" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String
      result(apiKey)
    }
  }
}
