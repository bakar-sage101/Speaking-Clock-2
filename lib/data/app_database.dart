import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class ReminderRecords extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get detail => text()();
  IntColumn get type => integer()();
  TextColumn get deliveryMode => text()();
  TextColumn get spokenMessage => text().withDefault(const Constant(''))();
  TextColumn get toneId => text().withDefault(const Constant('soft_chime'))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get snoozeMinutes => integer().withDefault(const Constant(10))();
  TextColumn get timeLabel => text()();
  IntColumn get triggerAtMillis => integer().nullable()();
  IntColumn get createdAtMillis => integer()();
  IntColumn get updatedAtMillis => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [ReminderRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.open() => AppDatabase(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<ReminderRecord>> allReminders() {
    return (select(reminderRecords)..orderBy([
          (table) => OrderingTerm(
            expression: table.triggerAtMillis,
            mode: OrderingMode.asc,
          ),
        ]))
        .get();
  }

  Future<void> saveReminder(ReminderRecordsCompanion reminder) {
    return into(reminderRecords).insertOnConflictUpdate(reminder);
  }

  Future<void> deleteReminderById(String id) {
    return (delete(
      reminderRecords,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<void> setReminderEnabled(String id, bool enabled) {
    return (update(
      reminderRecords,
    )..where((table) => table.id.equals(id))).write(
      ReminderRecordsCompanion(
        enabled: Value(enabled),
        updatedAtMillis: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return NativeDatabase.memory();
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'speaking_clock.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
