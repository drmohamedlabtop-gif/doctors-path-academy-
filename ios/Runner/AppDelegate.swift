import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    if #available(iOS 11.0, *) {
        NotificationCenter.default.addObserver(self, selector: #selector(screenRecordingStatusChanged), name: UIScreen.capturedDidChangeNotification, object: nil)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc private func screenRecordingStatusChanged() {
    if #available(iOS 11.0, *) {
        let isRecording = UIScreen.main.isCaptured
        if isRecording {
            // Show a black screen or an alert to the user
            window.isHidden = true
        } else {
            window.isHidden = false
        }
    }
  }
}
