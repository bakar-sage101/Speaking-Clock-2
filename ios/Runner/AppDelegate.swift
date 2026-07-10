import AlarmKit
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "speaking_clock/reliability",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getStatus":
        self.getAlarmStatus(result: result)
      case "requestNotifications":
        self.requestNotifications(result: result)
      case "requestExactAlarms":
        self.requestAlarmAuthorization(result: result)
      case "openDndSettings":
        self.openAppSettings(result: result)
      case "scheduleAlarm":
        result(FlutterError(code: "ios_alarm_scheduling_pending", message: "AlarmKit scheduling is not available in this build yet.", details: nil))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func getAlarmStatus(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      let notificationsEnabled = settings.authorizationStatus == .authorized ||
        settings.authorizationStatus == .provisional
      let alarmAuthorized: Bool
      if #available(iOS 26.0, *) {
        alarmAuthorized = AlarmManager.shared.authorizationState == .authorized
      } else {
        alarmAuthorized = false
      }
      result([
        "platform": "ios",
        "notificationsEnabled": notificationsEnabled,
        "exactAlarmEnabled": alarmAuthorized,
        "dndPolicyAccess": alarmAuthorized,
        "alarmVolumeEnabled": true,
      ])
    }
  }

  private func requestNotifications(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
      if let error {
        result(FlutterError(code: "notification_authorization_failed", message: error.localizedDescription, details: nil))
      } else {
        result(nil)
      }
    }
  }

  private func requestAlarmAuthorization(result: @escaping FlutterResult) {
    guard #available(iOS 26.0, *) else {
      result(FlutterError(code: "ios_version_unsupported", message: "Reliable Alarm requires iOS 26 or later.", details: nil))
      return
    }
    Task {
      do {
        _ = try await AlarmManager.shared.requestAuthorization()
        result(nil)
      } catch {
        result(FlutterError(code: "alarm_authorization_failed", message: error.localizedDescription, details: nil))
      }
    }
  }

  private func openAppSettings(result: @escaping FlutterResult) {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
    result(nil)
  }
}
