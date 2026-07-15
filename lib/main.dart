import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/app_database.dart';
import 'data/app_preferences.dart';
import 'platform/reliability_platform.dart';

part 'app/app_colors.dart';
part 'models/reminder.dart';
part 'app/speaking_clock_app.dart';
part 'screens/onboarding/onboarding_screen.dart';
part 'screens/today/today_screen.dart';
part 'screens/routines/routines_screen.dart';
part 'screens/settings/settings_screen.dart';
part 'screens/reminder_detail/reminder_detail_screen.dart';
part 'screens/reminder_editor/reminder_editor.dart';
part 'utils/ui_helpers.dart';
part 'widgets/custom_icons.dart';

void main() => runApp(const SpeakingClockApp());
