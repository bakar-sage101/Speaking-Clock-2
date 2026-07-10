import AlarmKit
import AVFoundation
import SwiftUI
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
        self.scheduleAlarm(arguments: call.arguments as? [String: Any], result: result)
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

  private func scheduleAlarm(arguments: [String: Any]?, result: @escaping FlutterResult) {
    guard #available(iOS 26.0, *) else {
      result(FlutterError(code: "ios_version_unsupported", message: "Reliable Alarm requires iOS 26 or later.", details: nil))
      return
    }
    guard
      let title = arguments?["title"] as? String,
      let triggerAtMillis = arguments?["triggerAtMillis"] as? Int
    else {
      result(FlutterError(code: "invalid_arguments", message: "A title and trigger time are required.", details: nil))
      return
    }

    Task {
      do {
        let soundName = try await renderSpeech(text: "It is time for \(title)")
        let presentation = AlarmPresentation(
          alert: AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: AlarmButton(
              text: "Dismiss",
              textColor: .white,
              systemImageName: "stop.circle"
            )
          )
        )
        let attributes = AlarmAttributes(
          presentation: presentation,
          metadata: ReminderAlarmMetadata(),
          tintColor: .green
        )
        let schedule = Alarm.Schedule.fixed(
          Date(timeIntervalSince1970: TimeInterval(triggerAtMillis) / 1000)
        )
        let configuration = AlarmManager.AlarmConfiguration.alarm(
          schedule: schedule,
          attributes: attributes,
          sound: .named(soundName)
        )
        _ = try await AlarmManager.shared.schedule(id: UUID(), configuration: configuration)
        result(nil)
      } catch {
        result(FlutterError(code: "alarm_schedule_failed", message: error.localizedDescription, details: nil))
      }
    }
  }

  private func renderSpeech(text: String) async throws -> String {
    let fileName = "speaking-clock-\(UUID().uuidString).caf"
    let libraryDirectory = try FileManager.default.url(
      for: .libraryDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let soundsDirectory = libraryDirectory.appendingPathComponent("Sounds", isDirectory: true)
    try FileManager.default.createDirectory(at: soundsDirectory, withIntermediateDirectories: true)
    let outputURL = soundsDirectory.appendingPathComponent(fileName)
    return try await SpeechRenderer.render(text: text, to: outputURL, fileName: fileName)
  }
}

@available(iOS 26.0, *)
private struct ReminderAlarmMetadata: AlarmMetadata {}

private final class SpeechRenderer {
  private init() {}

  private static var activeSynthesizer: AVSpeechSynthesizer?

  static func render(text: String, to outputURL: URL, fileName: String) async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
      let synthesizer = AVSpeechSynthesizer()
      activeSynthesizer = synthesizer
      let utterance = AVSpeechUtterance(string: text)
      utterance.rate = AVSpeechUtteranceDefaultSpeechRate

      var audioFile: AVAudioFile?
      var completed = false
      synthesizer.write(utterance) { buffer in
        guard !completed else { return }
        guard let pcmBuffer = buffer as? AVAudioPCMBuffer else { return }
        if pcmBuffer.frameLength == 0 {
          completed = true
          activeSynthesizer = nil
          continuation.resume(returning: fileName)
          return
        }
        do {
          if audioFile == nil {
            audioFile = try AVAudioFile(
              forWriting: outputURL,
              settings: pcmBuffer.format.settings,
              commonFormat: .pcmFormatFloat32,
              interleaved: false
            )
          }
          try audioFile?.write(from: pcmBuffer)
        } catch {
          completed = true
          activeSynthesizer = nil
          continuation.resume(throwing: error)
        }
      }
    }
  }
}
