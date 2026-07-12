import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AppPreferences {
  AppPreferences._();

  static const _fileName = 'speaking_clock_preferences.json';
  static const _onboardingCompleteKey = 'onboardingComplete';

  static bool get _isTestEnvironment => Platform.environment.containsKey('FLUTTER_TEST');

  static Future<bool> isOnboardingComplete() async {
    if (_isTestEnvironment) return true;
    final values = await _readValues();
    return values[_onboardingCompleteKey] == true;
  }

  static Future<void> setOnboardingComplete(bool complete) async {
    if (_isTestEnvironment) return;
    final values = await _readValues();
    values[_onboardingCompleteKey] = complete;
    await _writeValues(values);
  }

  static Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(path.join(directory.path, _fileName));
  }

  static Future<Map<String, Object?>> _readValues() async {
    final file = await _file();
    if (!await file.exists()) return {};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, Object?>) return decoded;
    } on Object {
      return {};
    }
    return {};
  }

  static Future<void> _writeValues(Map<String, Object?> values) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(values));
  }
}
