// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ReminderRecordsTable extends ReminderRecords
    with TableInfo<$ReminderRecordsTable, ReminderRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryModeMeta = const VerificationMeta(
    'deliveryMode',
  );
  @override
  late final GeneratedColumn<String> deliveryMode = GeneratedColumn<String>(
    'delivery_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spokenMessageMeta = const VerificationMeta(
    'spokenMessage',
  );
  @override
  late final GeneratedColumn<String> spokenMessage = GeneratedColumn<String>(
    'spoken_message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _toneIdMeta = const VerificationMeta('toneId');
  @override
  late final GeneratedColumn<String> toneId = GeneratedColumn<String>(
    'tone_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('soft_chime'),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _snoozeMinutesMeta = const VerificationMeta(
    'snoozeMinutes',
  );
  @override
  late final GeneratedColumn<int> snoozeMinutes = GeneratedColumn<int>(
    'snooze_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _timeLabelMeta = const VerificationMeta(
    'timeLabel',
  );
  @override
  late final GeneratedColumn<String> timeLabel = GeneratedColumn<String>(
    'time_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerAtMillisMeta = const VerificationMeta(
    'triggerAtMillis',
  );
  @override
  late final GeneratedColumn<int> triggerAtMillis = GeneratedColumn<int>(
    'trigger_at_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMillisMeta = const VerificationMeta(
    'createdAtMillis',
  );
  @override
  late final GeneratedColumn<int> createdAtMillis = GeneratedColumn<int>(
    'created_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMillisMeta = const VerificationMeta(
    'updatedAtMillis',
  );
  @override
  late final GeneratedColumn<int> updatedAtMillis = GeneratedColumn<int>(
    'updated_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    detail,
    type,
    deliveryMode,
    spokenMessage,
    toneId,
    enabled,
    snoozeMinutes,
    timeLabel,
    triggerAtMillis,
    createdAtMillis,
    updatedAtMillis,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    } else if (isInserting) {
      context.missing(_detailMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('delivery_mode')) {
      context.handle(
        _deliveryModeMeta,
        deliveryMode.isAcceptableOrUnknown(
          data['delivery_mode']!,
          _deliveryModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryModeMeta);
    }
    if (data.containsKey('spoken_message')) {
      context.handle(
        _spokenMessageMeta,
        spokenMessage.isAcceptableOrUnknown(
          data['spoken_message']!,
          _spokenMessageMeta,
        ),
      );
    }
    if (data.containsKey('tone_id')) {
      context.handle(
        _toneIdMeta,
        toneId.isAcceptableOrUnknown(data['tone_id']!, _toneIdMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('snooze_minutes')) {
      context.handle(
        _snoozeMinutesMeta,
        snoozeMinutes.isAcceptableOrUnknown(
          data['snooze_minutes']!,
          _snoozeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('time_label')) {
      context.handle(
        _timeLabelMeta,
        timeLabel.isAcceptableOrUnknown(data['time_label']!, _timeLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_timeLabelMeta);
    }
    if (data.containsKey('trigger_at_millis')) {
      context.handle(
        _triggerAtMillisMeta,
        triggerAtMillis.isAcceptableOrUnknown(
          data['trigger_at_millis']!,
          _triggerAtMillisMeta,
        ),
      );
    }
    if (data.containsKey('created_at_millis')) {
      context.handle(
        _createdAtMillisMeta,
        createdAtMillis.isAcceptableOrUnknown(
          data['created_at_millis']!,
          _createdAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMillisMeta);
    }
    if (data.containsKey('updated_at_millis')) {
      context.handle(
        _updatedAtMillisMeta,
        updatedAtMillis.isAcceptableOrUnknown(
          data['updated_at_millis']!,
          _updatedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      deliveryMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_mode'],
      )!,
      spokenMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spoken_message'],
      )!,
      toneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tone_id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      snoozeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_minutes'],
      )!,
      timeLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_label'],
      )!,
      triggerAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trigger_at_millis'],
      ),
      createdAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_millis'],
      )!,
      updatedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_millis'],
      )!,
    );
  }

  @override
  $ReminderRecordsTable createAlias(String alias) {
    return $ReminderRecordsTable(attachedDatabase, alias);
  }
}

class ReminderRecord extends DataClass implements Insertable<ReminderRecord> {
  final String id;
  final String title;
  final String detail;
  final int type;
  final String deliveryMode;
  final String spokenMessage;
  final String toneId;
  final bool enabled;
  final int snoozeMinutes;
  final String timeLabel;
  final int? triggerAtMillis;
  final int createdAtMillis;
  final int updatedAtMillis;
  const ReminderRecord({
    required this.id,
    required this.title,
    required this.detail,
    required this.type,
    required this.deliveryMode,
    required this.spokenMessage,
    required this.toneId,
    required this.enabled,
    required this.snoozeMinutes,
    required this.timeLabel,
    this.triggerAtMillis,
    required this.createdAtMillis,
    required this.updatedAtMillis,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['detail'] = Variable<String>(detail);
    map['type'] = Variable<int>(type);
    map['delivery_mode'] = Variable<String>(deliveryMode);
    map['spoken_message'] = Variable<String>(spokenMessage);
    map['tone_id'] = Variable<String>(toneId);
    map['enabled'] = Variable<bool>(enabled);
    map['snooze_minutes'] = Variable<int>(snoozeMinutes);
    map['time_label'] = Variable<String>(timeLabel);
    if (!nullToAbsent || triggerAtMillis != null) {
      map['trigger_at_millis'] = Variable<int>(triggerAtMillis);
    }
    map['created_at_millis'] = Variable<int>(createdAtMillis);
    map['updated_at_millis'] = Variable<int>(updatedAtMillis);
    return map;
  }

  ReminderRecordsCompanion toCompanion(bool nullToAbsent) {
    return ReminderRecordsCompanion(
      id: Value(id),
      title: Value(title),
      detail: Value(detail),
      type: Value(type),
      deliveryMode: Value(deliveryMode),
      spokenMessage: Value(spokenMessage),
      toneId: Value(toneId),
      enabled: Value(enabled),
      snoozeMinutes: Value(snoozeMinutes),
      timeLabel: Value(timeLabel),
      triggerAtMillis: triggerAtMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(triggerAtMillis),
      createdAtMillis: Value(createdAtMillis),
      updatedAtMillis: Value(updatedAtMillis),
    );
  }

  factory ReminderRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRecord(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      detail: serializer.fromJson<String>(json['detail']),
      type: serializer.fromJson<int>(json['type']),
      deliveryMode: serializer.fromJson<String>(json['deliveryMode']),
      spokenMessage: serializer.fromJson<String>(json['spokenMessage']),
      toneId: serializer.fromJson<String>(json['toneId']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      snoozeMinutes: serializer.fromJson<int>(json['snoozeMinutes']),
      timeLabel: serializer.fromJson<String>(json['timeLabel']),
      triggerAtMillis: serializer.fromJson<int?>(json['triggerAtMillis']),
      createdAtMillis: serializer.fromJson<int>(json['createdAtMillis']),
      updatedAtMillis: serializer.fromJson<int>(json['updatedAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'detail': serializer.toJson<String>(detail),
      'type': serializer.toJson<int>(type),
      'deliveryMode': serializer.toJson<String>(deliveryMode),
      'spokenMessage': serializer.toJson<String>(spokenMessage),
      'toneId': serializer.toJson<String>(toneId),
      'enabled': serializer.toJson<bool>(enabled),
      'snoozeMinutes': serializer.toJson<int>(snoozeMinutes),
      'timeLabel': serializer.toJson<String>(timeLabel),
      'triggerAtMillis': serializer.toJson<int?>(triggerAtMillis),
      'createdAtMillis': serializer.toJson<int>(createdAtMillis),
      'updatedAtMillis': serializer.toJson<int>(updatedAtMillis),
    };
  }

  ReminderRecord copyWith({
    String? id,
    String? title,
    String? detail,
    int? type,
    String? deliveryMode,
    String? spokenMessage,
    String? toneId,
    bool? enabled,
    int? snoozeMinutes,
    String? timeLabel,
    Value<int?> triggerAtMillis = const Value.absent(),
    int? createdAtMillis,
    int? updatedAtMillis,
  }) => ReminderRecord(
    id: id ?? this.id,
    title: title ?? this.title,
    detail: detail ?? this.detail,
    type: type ?? this.type,
    deliveryMode: deliveryMode ?? this.deliveryMode,
    spokenMessage: spokenMessage ?? this.spokenMessage,
    toneId: toneId ?? this.toneId,
    enabled: enabled ?? this.enabled,
    snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    timeLabel: timeLabel ?? this.timeLabel,
    triggerAtMillis: triggerAtMillis.present
        ? triggerAtMillis.value
        : this.triggerAtMillis,
    createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
  );
  ReminderRecord copyWithCompanion(ReminderRecordsCompanion data) {
    return ReminderRecord(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      detail: data.detail.present ? data.detail.value : this.detail,
      type: data.type.present ? data.type.value : this.type,
      deliveryMode: data.deliveryMode.present
          ? data.deliveryMode.value
          : this.deliveryMode,
      spokenMessage: data.spokenMessage.present
          ? data.spokenMessage.value
          : this.spokenMessage,
      toneId: data.toneId.present ? data.toneId.value : this.toneId,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      snoozeMinutes: data.snoozeMinutes.present
          ? data.snoozeMinutes.value
          : this.snoozeMinutes,
      timeLabel: data.timeLabel.present ? data.timeLabel.value : this.timeLabel,
      triggerAtMillis: data.triggerAtMillis.present
          ? data.triggerAtMillis.value
          : this.triggerAtMillis,
      createdAtMillis: data.createdAtMillis.present
          ? data.createdAtMillis.value
          : this.createdAtMillis,
      updatedAtMillis: data.updatedAtMillis.present
          ? data.updatedAtMillis.value
          : this.updatedAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRecord(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('detail: $detail, ')
          ..write('type: $type, ')
          ..write('deliveryMode: $deliveryMode, ')
          ..write('spokenMessage: $spokenMessage, ')
          ..write('toneId: $toneId, ')
          ..write('enabled: $enabled, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('timeLabel: $timeLabel, ')
          ..write('triggerAtMillis: $triggerAtMillis, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    detail,
    type,
    deliveryMode,
    spokenMessage,
    toneId,
    enabled,
    snoozeMinutes,
    timeLabel,
    triggerAtMillis,
    createdAtMillis,
    updatedAtMillis,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRecord &&
          other.id == this.id &&
          other.title == this.title &&
          other.detail == this.detail &&
          other.type == this.type &&
          other.deliveryMode == this.deliveryMode &&
          other.spokenMessage == this.spokenMessage &&
          other.toneId == this.toneId &&
          other.enabled == this.enabled &&
          other.snoozeMinutes == this.snoozeMinutes &&
          other.timeLabel == this.timeLabel &&
          other.triggerAtMillis == this.triggerAtMillis &&
          other.createdAtMillis == this.createdAtMillis &&
          other.updatedAtMillis == this.updatedAtMillis);
}

class ReminderRecordsCompanion extends UpdateCompanion<ReminderRecord> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> detail;
  final Value<int> type;
  final Value<String> deliveryMode;
  final Value<String> spokenMessage;
  final Value<String> toneId;
  final Value<bool> enabled;
  final Value<int> snoozeMinutes;
  final Value<String> timeLabel;
  final Value<int?> triggerAtMillis;
  final Value<int> createdAtMillis;
  final Value<int> updatedAtMillis;
  final Value<int> rowid;
  const ReminderRecordsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.detail = const Value.absent(),
    this.type = const Value.absent(),
    this.deliveryMode = const Value.absent(),
    this.spokenMessage = const Value.absent(),
    this.toneId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.snoozeMinutes = const Value.absent(),
    this.timeLabel = const Value.absent(),
    this.triggerAtMillis = const Value.absent(),
    this.createdAtMillis = const Value.absent(),
    this.updatedAtMillis = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderRecordsCompanion.insert({
    required String id,
    required String title,
    required String detail,
    required int type,
    required String deliveryMode,
    this.spokenMessage = const Value.absent(),
    this.toneId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.snoozeMinutes = const Value.absent(),
    required String timeLabel,
    this.triggerAtMillis = const Value.absent(),
    required int createdAtMillis,
    required int updatedAtMillis,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       detail = Value(detail),
       type = Value(type),
       deliveryMode = Value(deliveryMode),
       timeLabel = Value(timeLabel),
       createdAtMillis = Value(createdAtMillis),
       updatedAtMillis = Value(updatedAtMillis);
  static Insertable<ReminderRecord> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? detail,
    Expression<int>? type,
    Expression<String>? deliveryMode,
    Expression<String>? spokenMessage,
    Expression<String>? toneId,
    Expression<bool>? enabled,
    Expression<int>? snoozeMinutes,
    Expression<String>? timeLabel,
    Expression<int>? triggerAtMillis,
    Expression<int>? createdAtMillis,
    Expression<int>? updatedAtMillis,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (detail != null) 'detail': detail,
      if (type != null) 'type': type,
      if (deliveryMode != null) 'delivery_mode': deliveryMode,
      if (spokenMessage != null) 'spoken_message': spokenMessage,
      if (toneId != null) 'tone_id': toneId,
      if (enabled != null) 'enabled': enabled,
      if (snoozeMinutes != null) 'snooze_minutes': snoozeMinutes,
      if (timeLabel != null) 'time_label': timeLabel,
      if (triggerAtMillis != null) 'trigger_at_millis': triggerAtMillis,
      if (createdAtMillis != null) 'created_at_millis': createdAtMillis,
      if (updatedAtMillis != null) 'updated_at_millis': updatedAtMillis,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? detail,
    Value<int>? type,
    Value<String>? deliveryMode,
    Value<String>? spokenMessage,
    Value<String>? toneId,
    Value<bool>? enabled,
    Value<int>? snoozeMinutes,
    Value<String>? timeLabel,
    Value<int?>? triggerAtMillis,
    Value<int>? createdAtMillis,
    Value<int>? updatedAtMillis,
    Value<int>? rowid,
  }) {
    return ReminderRecordsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      type: type ?? this.type,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      spokenMessage: spokenMessage ?? this.spokenMessage,
      toneId: toneId ?? this.toneId,
      enabled: enabled ?? this.enabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      timeLabel: timeLabel ?? this.timeLabel,
      triggerAtMillis: triggerAtMillis ?? this.triggerAtMillis,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (deliveryMode.present) {
      map['delivery_mode'] = Variable<String>(deliveryMode.value);
    }
    if (spokenMessage.present) {
      map['spoken_message'] = Variable<String>(spokenMessage.value);
    }
    if (toneId.present) {
      map['tone_id'] = Variable<String>(toneId.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (snoozeMinutes.present) {
      map['snooze_minutes'] = Variable<int>(snoozeMinutes.value);
    }
    if (timeLabel.present) {
      map['time_label'] = Variable<String>(timeLabel.value);
    }
    if (triggerAtMillis.present) {
      map['trigger_at_millis'] = Variable<int>(triggerAtMillis.value);
    }
    if (createdAtMillis.present) {
      map['created_at_millis'] = Variable<int>(createdAtMillis.value);
    }
    if (updatedAtMillis.present) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRecordsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('detail: $detail, ')
          ..write('type: $type, ')
          ..write('deliveryMode: $deliveryMode, ')
          ..write('spokenMessage: $spokenMessage, ')
          ..write('toneId: $toneId, ')
          ..write('enabled: $enabled, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('timeLabel: $timeLabel, ')
          ..write('triggerAtMillis: $triggerAtMillis, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReminderRecordsTable reminderRecords = $ReminderRecordsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [reminderRecords];
}

typedef $$ReminderRecordsTableCreateCompanionBuilder =
    ReminderRecordsCompanion Function({
      required String id,
      required String title,
      required String detail,
      required int type,
      required String deliveryMode,
      Value<String> spokenMessage,
      Value<String> toneId,
      Value<bool> enabled,
      Value<int> snoozeMinutes,
      required String timeLabel,
      Value<int?> triggerAtMillis,
      required int createdAtMillis,
      required int updatedAtMillis,
      Value<int> rowid,
    });
typedef $$ReminderRecordsTableUpdateCompanionBuilder =
    ReminderRecordsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> detail,
      Value<int> type,
      Value<String> deliveryMode,
      Value<String> spokenMessage,
      Value<String> toneId,
      Value<bool> enabled,
      Value<int> snoozeMinutes,
      Value<String> timeLabel,
      Value<int?> triggerAtMillis,
      Value<int> createdAtMillis,
      Value<int> updatedAtMillis,
      Value<int> rowid,
    });

class $$ReminderRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ReminderRecordsTable> {
  $$ReminderRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryMode => $composableBuilder(
    column: $table.deliveryMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spokenMessage => $composableBuilder(
    column: $table.spokenMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toneId => $composableBuilder(
    column: $table.toneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeLabel => $composableBuilder(
    column: $table.timeLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get triggerAtMillis => $composableBuilder(
    column: $table.triggerAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReminderRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReminderRecordsTable> {
  $$ReminderRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryMode => $composableBuilder(
    column: $table.deliveryMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spokenMessage => $composableBuilder(
    column: $table.spokenMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toneId => $composableBuilder(
    column: $table.toneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeLabel => $composableBuilder(
    column: $table.timeLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get triggerAtMillis => $composableBuilder(
    column: $table.triggerAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReminderRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReminderRecordsTable> {
  $$ReminderRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get deliveryMode => $composableBuilder(
    column: $table.deliveryMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get spokenMessage => $composableBuilder(
    column: $table.spokenMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toneId =>
      $composableBuilder(column: $table.toneId, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeLabel =>
      $composableBuilder(column: $table.timeLabel, builder: (column) => column);

  GeneratedColumn<int> get triggerAtMillis => $composableBuilder(
    column: $table.triggerAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMillis => $composableBuilder(
    column: $table.createdAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMillis => $composableBuilder(
    column: $table.updatedAtMillis,
    builder: (column) => column,
  );
}

class $$ReminderRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReminderRecordsTable,
          ReminderRecord,
          $$ReminderRecordsTableFilterComposer,
          $$ReminderRecordsTableOrderingComposer,
          $$ReminderRecordsTableAnnotationComposer,
          $$ReminderRecordsTableCreateCompanionBuilder,
          $$ReminderRecordsTableUpdateCompanionBuilder,
          (
            ReminderRecord,
            BaseReferences<
              _$AppDatabase,
              $ReminderRecordsTable,
              ReminderRecord
            >,
          ),
          ReminderRecord,
          PrefetchHooks Function()
        > {
  $$ReminderRecordsTableTableManager(
    _$AppDatabase db,
    $ReminderRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> detail = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String> deliveryMode = const Value.absent(),
                Value<String> spokenMessage = const Value.absent(),
                Value<String> toneId = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> snoozeMinutes = const Value.absent(),
                Value<String> timeLabel = const Value.absent(),
                Value<int?> triggerAtMillis = const Value.absent(),
                Value<int> createdAtMillis = const Value.absent(),
                Value<int> updatedAtMillis = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderRecordsCompanion(
                id: id,
                title: title,
                detail: detail,
                type: type,
                deliveryMode: deliveryMode,
                spokenMessage: spokenMessage,
                toneId: toneId,
                enabled: enabled,
                snoozeMinutes: snoozeMinutes,
                timeLabel: timeLabel,
                triggerAtMillis: triggerAtMillis,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String detail,
                required int type,
                required String deliveryMode,
                Value<String> spokenMessage = const Value.absent(),
                Value<String> toneId = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> snoozeMinutes = const Value.absent(),
                required String timeLabel,
                Value<int?> triggerAtMillis = const Value.absent(),
                required int createdAtMillis,
                required int updatedAtMillis,
                Value<int> rowid = const Value.absent(),
              }) => ReminderRecordsCompanion.insert(
                id: id,
                title: title,
                detail: detail,
                type: type,
                deliveryMode: deliveryMode,
                spokenMessage: spokenMessage,
                toneId: toneId,
                enabled: enabled,
                snoozeMinutes: snoozeMinutes,
                timeLabel: timeLabel,
                triggerAtMillis: triggerAtMillis,
                createdAtMillis: createdAtMillis,
                updatedAtMillis: updatedAtMillis,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReminderRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReminderRecordsTable,
      ReminderRecord,
      $$ReminderRecordsTableFilterComposer,
      $$ReminderRecordsTableOrderingComposer,
      $$ReminderRecordsTableAnnotationComposer,
      $$ReminderRecordsTableCreateCompanionBuilder,
      $$ReminderRecordsTableUpdateCompanionBuilder,
      (
        ReminderRecord,
        BaseReferences<_$AppDatabase, $ReminderRecordsTable, ReminderRecord>,
      ),
      ReminderRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReminderRecordsTableTableManager get reminderRecords =>
      $$ReminderRecordsTableTableManager(_db, _db.reminderRecords);
}
