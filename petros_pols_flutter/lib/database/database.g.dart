// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AbsentPersonsTable extends AbsentPersons
    with TableInfo<$AbsentPersonsTable, AbsentPerson> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AbsentPersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personNameMeta = const VerificationMeta(
    'personName',
  );
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
    'person_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
    'stage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _month1Meta = const VerificationMeta('month1');
  @override
  late final GeneratedColumn<String> month1 = GeneratedColumn<String>(
    'month1',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstMeta = const VerificationMeta('first');
  @override
  late final GeneratedColumn<String> first = GeneratedColumn<String>(
    'first',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _secondMeta = const VerificationMeta('second');
  @override
  late final GeneratedColumn<String> second = GeneratedColumn<String>(
    'second',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thirdMeta = const VerificationMeta('third');
  @override
  late final GeneratedColumn<String> third = GeneratedColumn<String>(
    'third',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _forthMeta = const VerificationMeta('forth');
  @override
  late final GeneratedColumn<String> forth = GeneratedColumn<String>(
    'forth',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fifeMeta = const VerificationMeta('fife');
  @override
  late final GeneratedColumn<String> fife = GeneratedColumn<String>(
    'fife',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    personName,
    stage,
    month1,
    first,
    second,
    third,
    forth,
    fife,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'absent_persons';
  @override
  VerificationContext validateIntegrity(
    Insertable<AbsentPerson> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('person_name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['person_name']!, _personNameMeta),
      );
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    }
    if (data.containsKey('month1')) {
      context.handle(
        _month1Meta,
        month1.isAcceptableOrUnknown(data['month1']!, _month1Meta),
      );
    }
    if (data.containsKey('first')) {
      context.handle(
        _firstMeta,
        first.isAcceptableOrUnknown(data['first']!, _firstMeta),
      );
    }
    if (data.containsKey('second')) {
      context.handle(
        _secondMeta,
        second.isAcceptableOrUnknown(data['second']!, _secondMeta),
      );
    }
    if (data.containsKey('third')) {
      context.handle(
        _thirdMeta,
        third.isAcceptableOrUnknown(data['third']!, _thirdMeta),
      );
    }
    if (data.containsKey('forth')) {
      context.handle(
        _forthMeta,
        forth.isAcceptableOrUnknown(data['forth']!, _forthMeta),
      );
    }
    if (data.containsKey('fife')) {
      context.handle(
        _fifeMeta,
        fife.isAcceptableOrUnknown(data['fife']!, _fifeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  AbsentPerson map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AbsentPerson(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      ),
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_name'],
      ),
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage'],
      ),
      month1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month1'],
      ),
      first: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first'],
      ),
      second: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}second'],
      ),
      third: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}third'],
      ),
      forth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}forth'],
      ),
      fife: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fife'],
      ),
    );
  }

  @override
  $AbsentPersonsTable createAlias(String alias) {
    return $AbsentPersonsTable(attachedDatabase, alias);
  }
}

class AbsentPerson extends DataClass implements Insertable<AbsentPerson> {
  final int? id;
  final int? personId;
  final String? personName;
  final String? stage;
  final String? month1;
  final String? first;
  final String? second;
  final String? third;
  final String? forth;
  final String? fife;
  const AbsentPerson({
    this.id,
    this.personId,
    this.personName,
    this.stage,
    this.month1,
    this.first,
    this.second,
    this.third,
    this.forth,
    this.fife,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<int>(personId);
    }
    if (!nullToAbsent || personName != null) {
      map['person_name'] = Variable<String>(personName);
    }
    if (!nullToAbsent || stage != null) {
      map['stage'] = Variable<String>(stage);
    }
    if (!nullToAbsent || month1 != null) {
      map['month1'] = Variable<String>(month1);
    }
    if (!nullToAbsent || first != null) {
      map['first'] = Variable<String>(first);
    }
    if (!nullToAbsent || second != null) {
      map['second'] = Variable<String>(second);
    }
    if (!nullToAbsent || third != null) {
      map['third'] = Variable<String>(third);
    }
    if (!nullToAbsent || forth != null) {
      map['forth'] = Variable<String>(forth);
    }
    if (!nullToAbsent || fife != null) {
      map['fife'] = Variable<String>(fife);
    }
    return map;
  }

  AbsentPersonsCompanion toCompanion(bool nullToAbsent) {
    return AbsentPersonsCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      personName: personName == null && nullToAbsent
          ? const Value.absent()
          : Value(personName),
      stage: stage == null && nullToAbsent
          ? const Value.absent()
          : Value(stage),
      month1: month1 == null && nullToAbsent
          ? const Value.absent()
          : Value(month1),
      first: first == null && nullToAbsent
          ? const Value.absent()
          : Value(first),
      second: second == null && nullToAbsent
          ? const Value.absent()
          : Value(second),
      third: third == null && nullToAbsent
          ? const Value.absent()
          : Value(third),
      forth: forth == null && nullToAbsent
          ? const Value.absent()
          : Value(forth),
      fife: fife == null && nullToAbsent ? const Value.absent() : Value(fife),
    );
  }

  factory AbsentPerson.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AbsentPerson(
      id: serializer.fromJson<int?>(json['id']),
      personId: serializer.fromJson<int?>(json['personId']),
      personName: serializer.fromJson<String?>(json['personName']),
      stage: serializer.fromJson<String?>(json['stage']),
      month1: serializer.fromJson<String?>(json['month1']),
      first: serializer.fromJson<String?>(json['first']),
      second: serializer.fromJson<String?>(json['second']),
      third: serializer.fromJson<String?>(json['third']),
      forth: serializer.fromJson<String?>(json['forth']),
      fife: serializer.fromJson<String?>(json['fife']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int?>(id),
      'personId': serializer.toJson<int?>(personId),
      'personName': serializer.toJson<String?>(personName),
      'stage': serializer.toJson<String?>(stage),
      'month1': serializer.toJson<String?>(month1),
      'first': serializer.toJson<String?>(first),
      'second': serializer.toJson<String?>(second),
      'third': serializer.toJson<String?>(third),
      'forth': serializer.toJson<String?>(forth),
      'fife': serializer.toJson<String?>(fife),
    };
  }

  AbsentPerson copyWith({
    Value<int?> id = const Value.absent(),
    Value<int?> personId = const Value.absent(),
    Value<String?> personName = const Value.absent(),
    Value<String?> stage = const Value.absent(),
    Value<String?> month1 = const Value.absent(),
    Value<String?> first = const Value.absent(),
    Value<String?> second = const Value.absent(),
    Value<String?> third = const Value.absent(),
    Value<String?> forth = const Value.absent(),
    Value<String?> fife = const Value.absent(),
  }) => AbsentPerson(
    id: id.present ? id.value : this.id,
    personId: personId.present ? personId.value : this.personId,
    personName: personName.present ? personName.value : this.personName,
    stage: stage.present ? stage.value : this.stage,
    month1: month1.present ? month1.value : this.month1,
    first: first.present ? first.value : this.first,
    second: second.present ? second.value : this.second,
    third: third.present ? third.value : this.third,
    forth: forth.present ? forth.value : this.forth,
    fife: fife.present ? fife.value : this.fife,
  );
  AbsentPerson copyWithCompanion(AbsentPersonsCompanion data) {
    return AbsentPerson(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      personName: data.personName.present
          ? data.personName.value
          : this.personName,
      stage: data.stage.present ? data.stage.value : this.stage,
      month1: data.month1.present ? data.month1.value : this.month1,
      first: data.first.present ? data.first.value : this.first,
      second: data.second.present ? data.second.value : this.second,
      third: data.third.present ? data.third.value : this.third,
      forth: data.forth.present ? data.forth.value : this.forth,
      fife: data.fife.present ? data.fife.value : this.fife,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AbsentPerson(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('stage: $stage, ')
          ..write('month1: $month1, ')
          ..write('first: $first, ')
          ..write('second: $second, ')
          ..write('third: $third, ')
          ..write('forth: $forth, ')
          ..write('fife: $fife')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    personName,
    stage,
    month1,
    first,
    second,
    third,
    forth,
    fife,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AbsentPerson &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.personName == this.personName &&
          other.stage == this.stage &&
          other.month1 == this.month1 &&
          other.first == this.first &&
          other.second == this.second &&
          other.third == this.third &&
          other.forth == this.forth &&
          other.fife == this.fife);
}

class AbsentPersonsCompanion extends UpdateCompanion<AbsentPerson> {
  final Value<int?> id;
  final Value<int?> personId;
  final Value<String?> personName;
  final Value<String?> stage;
  final Value<String?> month1;
  final Value<String?> first;
  final Value<String?> second;
  final Value<String?> third;
  final Value<String?> forth;
  final Value<String?> fife;
  final Value<int> rowid;
  const AbsentPersonsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.personName = const Value.absent(),
    this.stage = const Value.absent(),
    this.month1 = const Value.absent(),
    this.first = const Value.absent(),
    this.second = const Value.absent(),
    this.third = const Value.absent(),
    this.forth = const Value.absent(),
    this.fife = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AbsentPersonsCompanion.insert({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.personName = const Value.absent(),
    this.stage = const Value.absent(),
    this.month1 = const Value.absent(),
    this.first = const Value.absent(),
    this.second = const Value.absent(),
    this.third = const Value.absent(),
    this.forth = const Value.absent(),
    this.fife = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<AbsentPerson> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<String>? personName,
    Expression<String>? stage,
    Expression<String>? month1,
    Expression<String>? first,
    Expression<String>? second,
    Expression<String>? third,
    Expression<String>? forth,
    Expression<String>? fife,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (personName != null) 'person_name': personName,
      if (stage != null) 'stage': stage,
      if (month1 != null) 'month1': month1,
      if (first != null) 'first': first,
      if (second != null) 'second': second,
      if (third != null) 'third': third,
      if (forth != null) 'forth': forth,
      if (fife != null) 'fife': fife,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AbsentPersonsCompanion copyWith({
    Value<int?>? id,
    Value<int?>? personId,
    Value<String?>? personName,
    Value<String?>? stage,
    Value<String?>? month1,
    Value<String?>? first,
    Value<String?>? second,
    Value<String?>? third,
    Value<String?>? forth,
    Value<String?>? fife,
    Value<int>? rowid,
  }) {
    return AbsentPersonsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      stage: stage ?? this.stage,
      month1: month1 ?? this.month1,
      first: first ?? this.first,
      second: second ?? this.second,
      third: third ?? this.third,
      forth: forth ?? this.forth,
      fife: fife ?? this.fife,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (month1.present) {
      map['month1'] = Variable<String>(month1.value);
    }
    if (first.present) {
      map['first'] = Variable<String>(first.value);
    }
    if (second.present) {
      map['second'] = Variable<String>(second.value);
    }
    if (third.present) {
      map['third'] = Variable<String>(third.value);
    }
    if (forth.present) {
      map['forth'] = Variable<String>(forth.value);
    }
    if (fife.present) {
      map['fife'] = Variable<String>(fife.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AbsentPersonsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('stage: $stage, ')
          ..write('month1: $month1, ')
          ..write('first: $first, ')
          ..write('second: $second, ')
          ..write('third: $third, ')
          ..write('forth: $forth, ')
          ..write('fife: $fife, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AbsentPrintTable extends AbsentPrint
    with TableInfo<$AbsentPrintTable, AbsentPrintData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AbsentPrintTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personNameMeta = const VerificationMeta(
    'personName',
  );
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
    'person_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageIdMeta = const VerificationMeta(
    'stageId',
  );
  @override
  late final GeneratedColumn<int> stageId = GeneratedColumn<int>(
    'stage_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageNameMeta = const VerificationMeta(
    'stageName',
  );
  @override
  late final GeneratedColumn<String> stageName = GeneratedColumn<String>(
    'stage_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaIdMeta = const VerificationMeta('areaId');
  @override
  late final GeneratedColumn<int> areaId = GeneratedColumn<int>(
    'area_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaNameMeta = const VerificationMeta(
    'areaName',
  );
  @override
  late final GeneratedColumn<String> areaName = GeneratedColumn<String>(
    'area_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streetNameMeta = const VerificationMeta(
    'streetName',
  );
  @override
  late final GeneratedColumn<String> streetName = GeneratedColumn<String>(
    'street_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
    'mobile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateFromMeta = const VerificationMeta(
    'dateFrom',
  );
  @override
  late final GeneratedColumn<String> dateFrom = GeneratedColumn<String>(
    'date_from',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateToMeta = const VerificationMeta('dateTo');
  @override
  late final GeneratedColumn<String> dateTo = GeneratedColumn<String>(
    'date_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    personName,
    stageId,
    stageName,
    areaId,
    areaName,
    streetName,
    phone,
    mobile,
    dateFrom,
    dateTo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'absent_print';
  @override
  VerificationContext validateIntegrity(
    Insertable<AbsentPrintData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('person_name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['person_name']!, _personNameMeta),
      );
    }
    if (data.containsKey('stage_id')) {
      context.handle(
        _stageIdMeta,
        stageId.isAcceptableOrUnknown(data['stage_id']!, _stageIdMeta),
      );
    }
    if (data.containsKey('stage_name')) {
      context.handle(
        _stageNameMeta,
        stageName.isAcceptableOrUnknown(data['stage_name']!, _stageNameMeta),
      );
    }
    if (data.containsKey('area_id')) {
      context.handle(
        _areaIdMeta,
        areaId.isAcceptableOrUnknown(data['area_id']!, _areaIdMeta),
      );
    }
    if (data.containsKey('area_name')) {
      context.handle(
        _areaNameMeta,
        areaName.isAcceptableOrUnknown(data['area_name']!, _areaNameMeta),
      );
    }
    if (data.containsKey('street_name')) {
      context.handle(
        _streetNameMeta,
        streetName.isAcceptableOrUnknown(data['street_name']!, _streetNameMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('mobile')) {
      context.handle(
        _mobileMeta,
        mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta),
      );
    }
    if (data.containsKey('date_from')) {
      context.handle(
        _dateFromMeta,
        dateFrom.isAcceptableOrUnknown(data['date_from']!, _dateFromMeta),
      );
    }
    if (data.containsKey('date_to')) {
      context.handle(
        _dateToMeta,
        dateTo.isAcceptableOrUnknown(data['date_to']!, _dateToMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  AbsentPrintData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AbsentPrintData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      ),
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_name'],
      ),
      stageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_id'],
      ),
      stageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage_name'],
      ),
      areaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}area_id'],
      ),
      areaName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_name'],
      ),
      streetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}street_name'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      mobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mobile'],
      ),
      dateFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_from'],
      ),
      dateTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_to'],
      ),
    );
  }

  @override
  $AbsentPrintTable createAlias(String alias) {
    return $AbsentPrintTable(attachedDatabase, alias);
  }
}

class AbsentPrintData extends DataClass implements Insertable<AbsentPrintData> {
  final int? id;
  final int? personId;
  final String? personName;
  final int? stageId;
  final String? stageName;
  final int? areaId;
  final String? areaName;
  final String? streetName;
  final String? phone;
  final String? mobile;
  final String? dateFrom;
  final String? dateTo;
  const AbsentPrintData({
    this.id,
    this.personId,
    this.personName,
    this.stageId,
    this.stageName,
    this.areaId,
    this.areaName,
    this.streetName,
    this.phone,
    this.mobile,
    this.dateFrom,
    this.dateTo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<int>(personId);
    }
    if (!nullToAbsent || personName != null) {
      map['person_name'] = Variable<String>(personName);
    }
    if (!nullToAbsent || stageId != null) {
      map['stage_id'] = Variable<int>(stageId);
    }
    if (!nullToAbsent || stageName != null) {
      map['stage_name'] = Variable<String>(stageName);
    }
    if (!nullToAbsent || areaId != null) {
      map['area_id'] = Variable<int>(areaId);
    }
    if (!nullToAbsent || areaName != null) {
      map['area_name'] = Variable<String>(areaName);
    }
    if (!nullToAbsent || streetName != null) {
      map['street_name'] = Variable<String>(streetName);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || mobile != null) {
      map['mobile'] = Variable<String>(mobile);
    }
    if (!nullToAbsent || dateFrom != null) {
      map['date_from'] = Variable<String>(dateFrom);
    }
    if (!nullToAbsent || dateTo != null) {
      map['date_to'] = Variable<String>(dateTo);
    }
    return map;
  }

  AbsentPrintCompanion toCompanion(bool nullToAbsent) {
    return AbsentPrintCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      personName: personName == null && nullToAbsent
          ? const Value.absent()
          : Value(personName),
      stageId: stageId == null && nullToAbsent
          ? const Value.absent()
          : Value(stageId),
      stageName: stageName == null && nullToAbsent
          ? const Value.absent()
          : Value(stageName),
      areaId: areaId == null && nullToAbsent
          ? const Value.absent()
          : Value(areaId),
      areaName: areaName == null && nullToAbsent
          ? const Value.absent()
          : Value(areaName),
      streetName: streetName == null && nullToAbsent
          ? const Value.absent()
          : Value(streetName),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      mobile: mobile == null && nullToAbsent
          ? const Value.absent()
          : Value(mobile),
      dateFrom: dateFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(dateFrom),
      dateTo: dateTo == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTo),
    );
  }

  factory AbsentPrintData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AbsentPrintData(
      id: serializer.fromJson<int?>(json['id']),
      personId: serializer.fromJson<int?>(json['personId']),
      personName: serializer.fromJson<String?>(json['personName']),
      stageId: serializer.fromJson<int?>(json['stageId']),
      stageName: serializer.fromJson<String?>(json['stageName']),
      areaId: serializer.fromJson<int?>(json['areaId']),
      areaName: serializer.fromJson<String?>(json['areaName']),
      streetName: serializer.fromJson<String?>(json['streetName']),
      phone: serializer.fromJson<String?>(json['phone']),
      mobile: serializer.fromJson<String?>(json['mobile']),
      dateFrom: serializer.fromJson<String?>(json['dateFrom']),
      dateTo: serializer.fromJson<String?>(json['dateTo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int?>(id),
      'personId': serializer.toJson<int?>(personId),
      'personName': serializer.toJson<String?>(personName),
      'stageId': serializer.toJson<int?>(stageId),
      'stageName': serializer.toJson<String?>(stageName),
      'areaId': serializer.toJson<int?>(areaId),
      'areaName': serializer.toJson<String?>(areaName),
      'streetName': serializer.toJson<String?>(streetName),
      'phone': serializer.toJson<String?>(phone),
      'mobile': serializer.toJson<String?>(mobile),
      'dateFrom': serializer.toJson<String?>(dateFrom),
      'dateTo': serializer.toJson<String?>(dateTo),
    };
  }

  AbsentPrintData copyWith({
    Value<int?> id = const Value.absent(),
    Value<int?> personId = const Value.absent(),
    Value<String?> personName = const Value.absent(),
    Value<int?> stageId = const Value.absent(),
    Value<String?> stageName = const Value.absent(),
    Value<int?> areaId = const Value.absent(),
    Value<String?> areaName = const Value.absent(),
    Value<String?> streetName = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> mobile = const Value.absent(),
    Value<String?> dateFrom = const Value.absent(),
    Value<String?> dateTo = const Value.absent(),
  }) => AbsentPrintData(
    id: id.present ? id.value : this.id,
    personId: personId.present ? personId.value : this.personId,
    personName: personName.present ? personName.value : this.personName,
    stageId: stageId.present ? stageId.value : this.stageId,
    stageName: stageName.present ? stageName.value : this.stageName,
    areaId: areaId.present ? areaId.value : this.areaId,
    areaName: areaName.present ? areaName.value : this.areaName,
    streetName: streetName.present ? streetName.value : this.streetName,
    phone: phone.present ? phone.value : this.phone,
    mobile: mobile.present ? mobile.value : this.mobile,
    dateFrom: dateFrom.present ? dateFrom.value : this.dateFrom,
    dateTo: dateTo.present ? dateTo.value : this.dateTo,
  );
  AbsentPrintData copyWithCompanion(AbsentPrintCompanion data) {
    return AbsentPrintData(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      personName: data.personName.present
          ? data.personName.value
          : this.personName,
      stageId: data.stageId.present ? data.stageId.value : this.stageId,
      stageName: data.stageName.present ? data.stageName.value : this.stageName,
      areaId: data.areaId.present ? data.areaId.value : this.areaId,
      areaName: data.areaName.present ? data.areaName.value : this.areaName,
      streetName: data.streetName.present
          ? data.streetName.value
          : this.streetName,
      phone: data.phone.present ? data.phone.value : this.phone,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      dateFrom: data.dateFrom.present ? data.dateFrom.value : this.dateFrom,
      dateTo: data.dateTo.present ? data.dateTo.value : this.dateTo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AbsentPrintData(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('stageId: $stageId, ')
          ..write('stageName: $stageName, ')
          ..write('areaId: $areaId, ')
          ..write('areaName: $areaName, ')
          ..write('streetName: $streetName, ')
          ..write('phone: $phone, ')
          ..write('mobile: $mobile, ')
          ..write('dateFrom: $dateFrom, ')
          ..write('dateTo: $dateTo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    personName,
    stageId,
    stageName,
    areaId,
    areaName,
    streetName,
    phone,
    mobile,
    dateFrom,
    dateTo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AbsentPrintData &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.personName == this.personName &&
          other.stageId == this.stageId &&
          other.stageName == this.stageName &&
          other.areaId == this.areaId &&
          other.areaName == this.areaName &&
          other.streetName == this.streetName &&
          other.phone == this.phone &&
          other.mobile == this.mobile &&
          other.dateFrom == this.dateFrom &&
          other.dateTo == this.dateTo);
}

class AbsentPrintCompanion extends UpdateCompanion<AbsentPrintData> {
  final Value<int?> id;
  final Value<int?> personId;
  final Value<String?> personName;
  final Value<int?> stageId;
  final Value<String?> stageName;
  final Value<int?> areaId;
  final Value<String?> areaName;
  final Value<String?> streetName;
  final Value<String?> phone;
  final Value<String?> mobile;
  final Value<String?> dateFrom;
  final Value<String?> dateTo;
  final Value<int> rowid;
  const AbsentPrintCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.personName = const Value.absent(),
    this.stageId = const Value.absent(),
    this.stageName = const Value.absent(),
    this.areaId = const Value.absent(),
    this.areaName = const Value.absent(),
    this.streetName = const Value.absent(),
    this.phone = const Value.absent(),
    this.mobile = const Value.absent(),
    this.dateFrom = const Value.absent(),
    this.dateTo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AbsentPrintCompanion.insert({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.personName = const Value.absent(),
    this.stageId = const Value.absent(),
    this.stageName = const Value.absent(),
    this.areaId = const Value.absent(),
    this.areaName = const Value.absent(),
    this.streetName = const Value.absent(),
    this.phone = const Value.absent(),
    this.mobile = const Value.absent(),
    this.dateFrom = const Value.absent(),
    this.dateTo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<AbsentPrintData> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<String>? personName,
    Expression<int>? stageId,
    Expression<String>? stageName,
    Expression<int>? areaId,
    Expression<String>? areaName,
    Expression<String>? streetName,
    Expression<String>? phone,
    Expression<String>? mobile,
    Expression<String>? dateFrom,
    Expression<String>? dateTo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (personName != null) 'person_name': personName,
      if (stageId != null) 'stage_id': stageId,
      if (stageName != null) 'stage_name': stageName,
      if (areaId != null) 'area_id': areaId,
      if (areaName != null) 'area_name': areaName,
      if (streetName != null) 'street_name': streetName,
      if (phone != null) 'phone': phone,
      if (mobile != null) 'mobile': mobile,
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AbsentPrintCompanion copyWith({
    Value<int?>? id,
    Value<int?>? personId,
    Value<String?>? personName,
    Value<int?>? stageId,
    Value<String?>? stageName,
    Value<int?>? areaId,
    Value<String?>? areaName,
    Value<String?>? streetName,
    Value<String?>? phone,
    Value<String?>? mobile,
    Value<String?>? dateFrom,
    Value<String?>? dateTo,
    Value<int>? rowid,
  }) {
    return AbsentPrintCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      stageId: stageId ?? this.stageId,
      stageName: stageName ?? this.stageName,
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      streetName: streetName ?? this.streetName,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (stageId.present) {
      map['stage_id'] = Variable<int>(stageId.value);
    }
    if (stageName.present) {
      map['stage_name'] = Variable<String>(stageName.value);
    }
    if (areaId.present) {
      map['area_id'] = Variable<int>(areaId.value);
    }
    if (areaName.present) {
      map['area_name'] = Variable<String>(areaName.value);
    }
    if (streetName.present) {
      map['street_name'] = Variable<String>(streetName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (dateFrom.present) {
      map['date_from'] = Variable<String>(dateFrom.value);
    }
    if (dateTo.present) {
      map['date_to'] = Variable<String>(dateTo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AbsentPrintCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('stageId: $stageId, ')
          ..write('stageName: $stageName, ')
          ..write('areaId: $areaId, ')
          ..write('areaName: $areaName, ')
          ..write('streetName: $streetName, ')
          ..write('phone: $phone, ')
          ..write('mobile: $mobile, ')
          ..write('dateFrom: $dateFrom, ')
          ..write('dateTo: $dateTo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AddingTable extends Adding with TableInfo<$AddingTable, AddingData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AddingTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateIdMeta = const VerificationMeta('dateId');
  @override
  late final GeneratedColumn<int> dateId = GeneratedColumn<int>(
    'date_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [dateId, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adding';
  @override
  VerificationContext validateIntegrity(
    Insertable<AddingData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_id')) {
      context.handle(
        _dateIdMeta,
        dateId.isAcceptableOrUnknown(data['date_id']!, _dateIdMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  AddingData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AddingData(
      dateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_id'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      ),
    );
  }

  @override
  $AddingTable createAlias(String alias) {
    return $AddingTable(attachedDatabase, alias);
  }
}

class AddingData extends DataClass implements Insertable<AddingData> {
  final int? dateId;
  final String? date;
  const AddingData({this.dateId, this.date});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || dateId != null) {
      map['date_id'] = Variable<int>(dateId);
    }
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<String>(date);
    }
    return map;
  }

  AddingCompanion toCompanion(bool nullToAbsent) {
    return AddingCompanion(
      dateId: dateId == null && nullToAbsent
          ? const Value.absent()
          : Value(dateId),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
    );
  }

  factory AddingData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AddingData(
      dateId: serializer.fromJson<int?>(json['dateId']),
      date: serializer.fromJson<String?>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateId': serializer.toJson<int?>(dateId),
      'date': serializer.toJson<String?>(date),
    };
  }

  AddingData copyWith({
    Value<int?> dateId = const Value.absent(),
    Value<String?> date = const Value.absent(),
  }) => AddingData(
    dateId: dateId.present ? dateId.value : this.dateId,
    date: date.present ? date.value : this.date,
  );
  AddingData copyWithCompanion(AddingCompanion data) {
    return AddingData(
      dateId: data.dateId.present ? data.dateId.value : this.dateId,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AddingData(')
          ..write('dateId: $dateId, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dateId, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AddingData &&
          other.dateId == this.dateId &&
          other.date == this.date);
}

class AddingCompanion extends UpdateCompanion<AddingData> {
  final Value<int?> dateId;
  final Value<String?> date;
  final Value<int> rowid;
  const AddingCompanion({
    this.dateId = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AddingCompanion.insert({
    this.dateId = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<AddingData> custom({
    Expression<int>? dateId,
    Expression<String>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dateId != null) 'date_id': dateId,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AddingCompanion copyWith({
    Value<int?>? dateId,
    Value<String?>? date,
    Value<int>? rowid,
  }) {
    return AddingCompanion(
      dateId: dateId ?? this.dateId,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateId.present) {
      map['date_id'] = Variable<int>(dateId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AddingCompanion(')
          ..write('dateId: $dateId, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AreasTable extends Areas with TableInfo<$AreasTable, Area> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AreasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _areaIdMeta = const VerificationMeta('areaId');
  @override
  late final GeneratedColumn<int> areaId = GeneratedColumn<int>(
    'area_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaNameMeta = const VerificationMeta(
    'areaName',
  );
  @override
  late final GeneratedColumn<String> areaName = GeneratedColumn<String>(
    'area_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [areaId, areaName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Area> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('area_id')) {
      context.handle(
        _areaIdMeta,
        areaId.isAcceptableOrUnknown(data['area_id']!, _areaIdMeta),
      );
    }
    if (data.containsKey('area_name')) {
      context.handle(
        _areaNameMeta,
        areaName.isAcceptableOrUnknown(data['area_name']!, _areaNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Area map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Area(
      areaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}area_id'],
      ),
      areaName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_name'],
      ),
    );
  }

  @override
  $AreasTable createAlias(String alias) {
    return $AreasTable(attachedDatabase, alias);
  }
}

class Area extends DataClass implements Insertable<Area> {
  final int? areaId;
  final String? areaName;
  const Area({this.areaId, this.areaName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || areaId != null) {
      map['area_id'] = Variable<int>(areaId);
    }
    if (!nullToAbsent || areaName != null) {
      map['area_name'] = Variable<String>(areaName);
    }
    return map;
  }

  AreasCompanion toCompanion(bool nullToAbsent) {
    return AreasCompanion(
      areaId: areaId == null && nullToAbsent
          ? const Value.absent()
          : Value(areaId),
      areaName: areaName == null && nullToAbsent
          ? const Value.absent()
          : Value(areaName),
    );
  }

  factory Area.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Area(
      areaId: serializer.fromJson<int?>(json['areaId']),
      areaName: serializer.fromJson<String?>(json['areaName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'areaId': serializer.toJson<int?>(areaId),
      'areaName': serializer.toJson<String?>(areaName),
    };
  }

  Area copyWith({
    Value<int?> areaId = const Value.absent(),
    Value<String?> areaName = const Value.absent(),
  }) => Area(
    areaId: areaId.present ? areaId.value : this.areaId,
    areaName: areaName.present ? areaName.value : this.areaName,
  );
  Area copyWithCompanion(AreasCompanion data) {
    return Area(
      areaId: data.areaId.present ? data.areaId.value : this.areaId,
      areaName: data.areaName.present ? data.areaName.value : this.areaName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Area(')
          ..write('areaId: $areaId, ')
          ..write('areaName: $areaName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(areaId, areaName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Area &&
          other.areaId == this.areaId &&
          other.areaName == this.areaName);
}

class AreasCompanion extends UpdateCompanion<Area> {
  final Value<int?> areaId;
  final Value<String?> areaName;
  final Value<int> rowid;
  const AreasCompanion({
    this.areaId = const Value.absent(),
    this.areaName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AreasCompanion.insert({
    this.areaId = const Value.absent(),
    this.areaName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<Area> custom({
    Expression<int>? areaId,
    Expression<String>? areaName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (areaId != null) 'area_id': areaId,
      if (areaName != null) 'area_name': areaName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AreasCompanion copyWith({
    Value<int?>? areaId,
    Value<String?>? areaName,
    Value<int>? rowid,
  }) {
    return AreasCompanion(
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (areaId.present) {
      map['area_id'] = Variable<int>(areaId.value);
    }
    if (areaName.present) {
      map['area_name'] = Variable<String>(areaName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AreasCompanion(')
          ..write('areaId: $areaId, ')
          ..write('areaName: $areaName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ComingTable extends Coming with TableInfo<$ComingTable, ComingData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComingTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateWeekMeta = const VerificationMeta(
    'dateWeek',
  );
  @override
  late final GeneratedColumn<String> dateWeek = GeneratedColumn<String>(
    'date_week',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pointMeta = const VerificationMeta('point');
  @override
  late final GeneratedColumn<int> point = GeneratedColumn<int>(
    'point',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mont1Meta = const VerificationMeta('mont1');
  @override
  late final GeneratedColumn<int> mont1 = GeneratedColumn<int>(
    'mont1',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _year1Meta = const VerificationMeta('year1');
  @override
  late final GeneratedColumn<int> year1 = GeneratedColumn<int>(
    'year1',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    dateWeek,
    point,
    mont1,
    year1,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coming';
  @override
  VerificationContext validateIntegrity(
    Insertable<ComingData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('date_week')) {
      context.handle(
        _dateWeekMeta,
        dateWeek.isAcceptableOrUnknown(data['date_week']!, _dateWeekMeta),
      );
    }
    if (data.containsKey('point')) {
      context.handle(
        _pointMeta,
        point.isAcceptableOrUnknown(data['point']!, _pointMeta),
      );
    }
    if (data.containsKey('mont1')) {
      context.handle(
        _mont1Meta,
        mont1.isAcceptableOrUnknown(data['mont1']!, _mont1Meta),
      );
    }
    if (data.containsKey('year1')) {
      context.handle(
        _year1Meta,
        year1.isAcceptableOrUnknown(data['year1']!, _year1Meta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  ComingData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ComingData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      ),
      dateWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_week'],
      ),
      point: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}point'],
      ),
      mont1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mont1'],
      ),
      year1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year1'],
      ),
    );
  }

  @override
  $ComingTable createAlias(String alias) {
    return $ComingTable(attachedDatabase, alias);
  }
}

class ComingData extends DataClass implements Insertable<ComingData> {
  final int? id;
  final int? personId;
  final String? dateWeek;
  final int? point;
  final int? mont1;
  final int? year1;
  const ComingData({
    this.id,
    this.personId,
    this.dateWeek,
    this.point,
    this.mont1,
    this.year1,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<int>(personId);
    }
    if (!nullToAbsent || dateWeek != null) {
      map['date_week'] = Variable<String>(dateWeek);
    }
    if (!nullToAbsent || point != null) {
      map['point'] = Variable<int>(point);
    }
    if (!nullToAbsent || mont1 != null) {
      map['mont1'] = Variable<int>(mont1);
    }
    if (!nullToAbsent || year1 != null) {
      map['year1'] = Variable<int>(year1);
    }
    return map;
  }

  ComingCompanion toCompanion(bool nullToAbsent) {
    return ComingCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      dateWeek: dateWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(dateWeek),
      point: point == null && nullToAbsent
          ? const Value.absent()
          : Value(point),
      mont1: mont1 == null && nullToAbsent
          ? const Value.absent()
          : Value(mont1),
      year1: year1 == null && nullToAbsent
          ? const Value.absent()
          : Value(year1),
    );
  }

  factory ComingData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ComingData(
      id: serializer.fromJson<int?>(json['id']),
      personId: serializer.fromJson<int?>(json['personId']),
      dateWeek: serializer.fromJson<String?>(json['dateWeek']),
      point: serializer.fromJson<int?>(json['point']),
      mont1: serializer.fromJson<int?>(json['mont1']),
      year1: serializer.fromJson<int?>(json['year1']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int?>(id),
      'personId': serializer.toJson<int?>(personId),
      'dateWeek': serializer.toJson<String?>(dateWeek),
      'point': serializer.toJson<int?>(point),
      'mont1': serializer.toJson<int?>(mont1),
      'year1': serializer.toJson<int?>(year1),
    };
  }

  ComingData copyWith({
    Value<int?> id = const Value.absent(),
    Value<int?> personId = const Value.absent(),
    Value<String?> dateWeek = const Value.absent(),
    Value<int?> point = const Value.absent(),
    Value<int?> mont1 = const Value.absent(),
    Value<int?> year1 = const Value.absent(),
  }) => ComingData(
    id: id.present ? id.value : this.id,
    personId: personId.present ? personId.value : this.personId,
    dateWeek: dateWeek.present ? dateWeek.value : this.dateWeek,
    point: point.present ? point.value : this.point,
    mont1: mont1.present ? mont1.value : this.mont1,
    year1: year1.present ? year1.value : this.year1,
  );
  ComingData copyWithCompanion(ComingCompanion data) {
    return ComingData(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      dateWeek: data.dateWeek.present ? data.dateWeek.value : this.dateWeek,
      point: data.point.present ? data.point.value : this.point,
      mont1: data.mont1.present ? data.mont1.value : this.mont1,
      year1: data.year1.present ? data.year1.value : this.year1,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ComingData(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('dateWeek: $dateWeek, ')
          ..write('point: $point, ')
          ..write('mont1: $mont1, ')
          ..write('year1: $year1')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, personId, dateWeek, point, mont1, year1);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ComingData &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.dateWeek == this.dateWeek &&
          other.point == this.point &&
          other.mont1 == this.mont1 &&
          other.year1 == this.year1);
}

class ComingCompanion extends UpdateCompanion<ComingData> {
  final Value<int?> id;
  final Value<int?> personId;
  final Value<String?> dateWeek;
  final Value<int?> point;
  final Value<int?> mont1;
  final Value<int?> year1;
  final Value<int> rowid;
  const ComingCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.dateWeek = const Value.absent(),
    this.point = const Value.absent(),
    this.mont1 = const Value.absent(),
    this.year1 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComingCompanion.insert({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.dateWeek = const Value.absent(),
    this.point = const Value.absent(),
    this.mont1 = const Value.absent(),
    this.year1 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<ComingData> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<String>? dateWeek,
    Expression<int>? point,
    Expression<int>? mont1,
    Expression<int>? year1,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (dateWeek != null) 'date_week': dateWeek,
      if (point != null) 'point': point,
      if (mont1 != null) 'mont1': mont1,
      if (year1 != null) 'year1': year1,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComingCompanion copyWith({
    Value<int?>? id,
    Value<int?>? personId,
    Value<String?>? dateWeek,
    Value<int?>? point,
    Value<int?>? mont1,
    Value<int?>? year1,
    Value<int>? rowid,
  }) {
    return ComingCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      dateWeek: dateWeek ?? this.dateWeek,
      point: point ?? this.point,
      mont1: mont1 ?? this.mont1,
      year1: year1 ?? this.year1,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (dateWeek.present) {
      map['date_week'] = Variable<String>(dateWeek.value);
    }
    if (point.present) {
      map['point'] = Variable<int>(point.value);
    }
    if (mont1.present) {
      map['mont1'] = Variable<int>(mont1.value);
    }
    if (year1.present) {
      map['year1'] = Variable<int>(year1.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComingCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('dateWeek: $dateWeek, ')
          ..write('point: $point, ')
          ..write('mont1: $mont1, ')
          ..write('year1: $year1, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CreditTable extends Credit with TableInfo<$CreditTable, CreditData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreditTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personNameMeta = const VerificationMeta(
    'personName',
  );
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
    'person_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageNameMeta = const VerificationMeta(
    'stageName',
  );
  @override
  late final GeneratedColumn<String> stageName = GeneratedColumn<String>(
    'stage_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaNameMeta = const VerificationMeta(
    'areaName',
  );
  @override
  late final GeneratedColumn<String> areaName = GeneratedColumn<String>(
    'area_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streetMeta = const VerificationMeta('street');
  @override
  late final GeneratedColumn<String> street = GeneratedColumn<String>(
    'street',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
    'mobile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jenderMeta = const VerificationMeta('jender');
  @override
  late final GeneratedColumn<String> jender = GeneratedColumn<String>(
    'jender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<Uint8List> photo = GeneratedColumn<Uint8List>(
    'photo',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parcodeMeta = const VerificationMeta(
    'parcode',
  );
  @override
  late final GeneratedColumn<Uint8List> parcode = GeneratedColumn<Uint8List>(
    'parcode',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    personName,
    stageName,
    areaName,
    street,
    phone,
    mobile,
    day,
    month,
    year,
    jender,
    photo,
    parcode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credit';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreditData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('person_name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['person_name']!, _personNameMeta),
      );
    }
    if (data.containsKey('stage_name')) {
      context.handle(
        _stageNameMeta,
        stageName.isAcceptableOrUnknown(data['stage_name']!, _stageNameMeta),
      );
    }
    if (data.containsKey('area_name')) {
      context.handle(
        _areaNameMeta,
        areaName.isAcceptableOrUnknown(data['area_name']!, _areaNameMeta),
      );
    }
    if (data.containsKey('street')) {
      context.handle(
        _streetMeta,
        street.isAcceptableOrUnknown(data['street']!, _streetMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('mobile')) {
      context.handle(
        _mobileMeta,
        mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta),
      );
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('jender')) {
      context.handle(
        _jenderMeta,
        jender.isAcceptableOrUnknown(data['jender']!, _jenderMeta),
      );
    }
    if (data.containsKey('photo')) {
      context.handle(
        _photoMeta,
        photo.isAcceptableOrUnknown(data['photo']!, _photoMeta),
      );
    }
    if (data.containsKey('parcode')) {
      context.handle(
        _parcodeMeta,
        parcode.isAcceptableOrUnknown(data['parcode']!, _parcodeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  CreditData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      ),
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_name'],
      ),
      stageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage_name'],
      ),
      areaName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_name'],
      ),
      street: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}street'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      mobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mobile'],
      ),
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      ),
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      jender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jender'],
      ),
      photo: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}photo'],
      ),
      parcode: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}parcode'],
      ),
    );
  }

  @override
  $CreditTable createAlias(String alias) {
    return $CreditTable(attachedDatabase, alias);
  }
}

class CreditData extends DataClass implements Insertable<CreditData> {
  final int? id;
  final int? personId;
  final String? personName;
  final String? stageName;
  final String? areaName;
  final String? street;
  final String? phone;
  final String? mobile;
  final int? day;
  final int? month;
  final int? year;
  final String? jender;
  final Uint8List? photo;
  final Uint8List? parcode;
  const CreditData({
    this.id,
    this.personId,
    this.personName,
    this.stageName,
    this.areaName,
    this.street,
    this.phone,
    this.mobile,
    this.day,
    this.month,
    this.year,
    this.jender,
    this.photo,
    this.parcode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<int>(personId);
    }
    if (!nullToAbsent || personName != null) {
      map['person_name'] = Variable<String>(personName);
    }
    if (!nullToAbsent || stageName != null) {
      map['stage_name'] = Variable<String>(stageName);
    }
    if (!nullToAbsent || areaName != null) {
      map['area_name'] = Variable<String>(areaName);
    }
    if (!nullToAbsent || street != null) {
      map['street'] = Variable<String>(street);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || mobile != null) {
      map['mobile'] = Variable<String>(mobile);
    }
    if (!nullToAbsent || day != null) {
      map['day'] = Variable<int>(day);
    }
    if (!nullToAbsent || month != null) {
      map['month'] = Variable<int>(month);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || jender != null) {
      map['jender'] = Variable<String>(jender);
    }
    if (!nullToAbsent || photo != null) {
      map['photo'] = Variable<Uint8List>(photo);
    }
    if (!nullToAbsent || parcode != null) {
      map['parcode'] = Variable<Uint8List>(parcode);
    }
    return map;
  }

  CreditCompanion toCompanion(bool nullToAbsent) {
    return CreditCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      personName: personName == null && nullToAbsent
          ? const Value.absent()
          : Value(personName),
      stageName: stageName == null && nullToAbsent
          ? const Value.absent()
          : Value(stageName),
      areaName: areaName == null && nullToAbsent
          ? const Value.absent()
          : Value(areaName),
      street: street == null && nullToAbsent
          ? const Value.absent()
          : Value(street),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      mobile: mobile == null && nullToAbsent
          ? const Value.absent()
          : Value(mobile),
      day: day == null && nullToAbsent ? const Value.absent() : Value(day),
      month: month == null && nullToAbsent
          ? const Value.absent()
          : Value(month),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      jender: jender == null && nullToAbsent
          ? const Value.absent()
          : Value(jender),
      photo: photo == null && nullToAbsent
          ? const Value.absent()
          : Value(photo),
      parcode: parcode == null && nullToAbsent
          ? const Value.absent()
          : Value(parcode),
    );
  }

  factory CreditData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditData(
      id: serializer.fromJson<int?>(json['id']),
      personId: serializer.fromJson<int?>(json['personId']),
      personName: serializer.fromJson<String?>(json['personName']),
      stageName: serializer.fromJson<String?>(json['stageName']),
      areaName: serializer.fromJson<String?>(json['areaName']),
      street: serializer.fromJson<String?>(json['street']),
      phone: serializer.fromJson<String?>(json['phone']),
      mobile: serializer.fromJson<String?>(json['mobile']),
      day: serializer.fromJson<int?>(json['day']),
      month: serializer.fromJson<int?>(json['month']),
      year: serializer.fromJson<int?>(json['year']),
      jender: serializer.fromJson<String?>(json['jender']),
      photo: serializer.fromJson<Uint8List?>(json['photo']),
      parcode: serializer.fromJson<Uint8List?>(json['parcode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int?>(id),
      'personId': serializer.toJson<int?>(personId),
      'personName': serializer.toJson<String?>(personName),
      'stageName': serializer.toJson<String?>(stageName),
      'areaName': serializer.toJson<String?>(areaName),
      'street': serializer.toJson<String?>(street),
      'phone': serializer.toJson<String?>(phone),
      'mobile': serializer.toJson<String?>(mobile),
      'day': serializer.toJson<int?>(day),
      'month': serializer.toJson<int?>(month),
      'year': serializer.toJson<int?>(year),
      'jender': serializer.toJson<String?>(jender),
      'photo': serializer.toJson<Uint8List?>(photo),
      'parcode': serializer.toJson<Uint8List?>(parcode),
    };
  }

  CreditData copyWith({
    Value<int?> id = const Value.absent(),
    Value<int?> personId = const Value.absent(),
    Value<String?> personName = const Value.absent(),
    Value<String?> stageName = const Value.absent(),
    Value<String?> areaName = const Value.absent(),
    Value<String?> street = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> mobile = const Value.absent(),
    Value<int?> day = const Value.absent(),
    Value<int?> month = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> jender = const Value.absent(),
    Value<Uint8List?> photo = const Value.absent(),
    Value<Uint8List?> parcode = const Value.absent(),
  }) => CreditData(
    id: id.present ? id.value : this.id,
    personId: personId.present ? personId.value : this.personId,
    personName: personName.present ? personName.value : this.personName,
    stageName: stageName.present ? stageName.value : this.stageName,
    areaName: areaName.present ? areaName.value : this.areaName,
    street: street.present ? street.value : this.street,
    phone: phone.present ? phone.value : this.phone,
    mobile: mobile.present ? mobile.value : this.mobile,
    day: day.present ? day.value : this.day,
    month: month.present ? month.value : this.month,
    year: year.present ? year.value : this.year,
    jender: jender.present ? jender.value : this.jender,
    photo: photo.present ? photo.value : this.photo,
    parcode: parcode.present ? parcode.value : this.parcode,
  );
  CreditData copyWithCompanion(CreditCompanion data) {
    return CreditData(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      personName: data.personName.present
          ? data.personName.value
          : this.personName,
      stageName: data.stageName.present ? data.stageName.value : this.stageName,
      areaName: data.areaName.present ? data.areaName.value : this.areaName,
      street: data.street.present ? data.street.value : this.street,
      phone: data.phone.present ? data.phone.value : this.phone,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      day: data.day.present ? data.day.value : this.day,
      month: data.month.present ? data.month.value : this.month,
      year: data.year.present ? data.year.value : this.year,
      jender: data.jender.present ? data.jender.value : this.jender,
      photo: data.photo.present ? data.photo.value : this.photo,
      parcode: data.parcode.present ? data.parcode.value : this.parcode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditData(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('stageName: $stageName, ')
          ..write('areaName: $areaName, ')
          ..write('street: $street, ')
          ..write('phone: $phone, ')
          ..write('mobile: $mobile, ')
          ..write('day: $day, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('jender: $jender, ')
          ..write('photo: $photo, ')
          ..write('parcode: $parcode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    personName,
    stageName,
    areaName,
    street,
    phone,
    mobile,
    day,
    month,
    year,
    jender,
    $driftBlobEquality.hash(photo),
    $driftBlobEquality.hash(parcode),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditData &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.personName == this.personName &&
          other.stageName == this.stageName &&
          other.areaName == this.areaName &&
          other.street == this.street &&
          other.phone == this.phone &&
          other.mobile == this.mobile &&
          other.day == this.day &&
          other.month == this.month &&
          other.year == this.year &&
          other.jender == this.jender &&
          $driftBlobEquality.equals(other.photo, this.photo) &&
          $driftBlobEquality.equals(other.parcode, this.parcode));
}

class CreditCompanion extends UpdateCompanion<CreditData> {
  final Value<int?> id;
  final Value<int?> personId;
  final Value<String?> personName;
  final Value<String?> stageName;
  final Value<String?> areaName;
  final Value<String?> street;
  final Value<String?> phone;
  final Value<String?> mobile;
  final Value<int?> day;
  final Value<int?> month;
  final Value<int?> year;
  final Value<String?> jender;
  final Value<Uint8List?> photo;
  final Value<Uint8List?> parcode;
  final Value<int> rowid;
  const CreditCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.personName = const Value.absent(),
    this.stageName = const Value.absent(),
    this.areaName = const Value.absent(),
    this.street = const Value.absent(),
    this.phone = const Value.absent(),
    this.mobile = const Value.absent(),
    this.day = const Value.absent(),
    this.month = const Value.absent(),
    this.year = const Value.absent(),
    this.jender = const Value.absent(),
    this.photo = const Value.absent(),
    this.parcode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CreditCompanion.insert({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.personName = const Value.absent(),
    this.stageName = const Value.absent(),
    this.areaName = const Value.absent(),
    this.street = const Value.absent(),
    this.phone = const Value.absent(),
    this.mobile = const Value.absent(),
    this.day = const Value.absent(),
    this.month = const Value.absent(),
    this.year = const Value.absent(),
    this.jender = const Value.absent(),
    this.photo = const Value.absent(),
    this.parcode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<CreditData> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<String>? personName,
    Expression<String>? stageName,
    Expression<String>? areaName,
    Expression<String>? street,
    Expression<String>? phone,
    Expression<String>? mobile,
    Expression<int>? day,
    Expression<int>? month,
    Expression<int>? year,
    Expression<String>? jender,
    Expression<Uint8List>? photo,
    Expression<Uint8List>? parcode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (personName != null) 'person_name': personName,
      if (stageName != null) 'stage_name': stageName,
      if (areaName != null) 'area_name': areaName,
      if (street != null) 'street': street,
      if (phone != null) 'phone': phone,
      if (mobile != null) 'mobile': mobile,
      if (day != null) 'day': day,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (jender != null) 'jender': jender,
      if (photo != null) 'photo': photo,
      if (parcode != null) 'parcode': parcode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CreditCompanion copyWith({
    Value<int?>? id,
    Value<int?>? personId,
    Value<String?>? personName,
    Value<String?>? stageName,
    Value<String?>? areaName,
    Value<String?>? street,
    Value<String?>? phone,
    Value<String?>? mobile,
    Value<int?>? day,
    Value<int?>? month,
    Value<int?>? year,
    Value<String?>? jender,
    Value<Uint8List?>? photo,
    Value<Uint8List?>? parcode,
    Value<int>? rowid,
  }) {
    return CreditCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      stageName: stageName ?? this.stageName,
      areaName: areaName ?? this.areaName,
      street: street ?? this.street,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      day: day ?? this.day,
      month: month ?? this.month,
      year: year ?? this.year,
      jender: jender ?? this.jender,
      photo: photo ?? this.photo,
      parcode: parcode ?? this.parcode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (stageName.present) {
      map['stage_name'] = Variable<String>(stageName.value);
    }
    if (areaName.present) {
      map['area_name'] = Variable<String>(areaName.value);
    }
    if (street.present) {
      map['street'] = Variable<String>(street.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (jender.present) {
      map['jender'] = Variable<String>(jender.value);
    }
    if (photo.present) {
      map['photo'] = Variable<Uint8List>(photo.value);
    }
    if (parcode.present) {
      map['parcode'] = Variable<Uint8List>(parcode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreditCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('stageName: $stageName, ')
          ..write('areaName: $areaName, ')
          ..write('street: $street, ')
          ..write('phone: $phone, ')
          ..write('mobile: $mobile, ')
          ..write('day: $day, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('jender: $jender, ')
          ..write('photo: $photo, ')
          ..write('parcode: $parcode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FathersTable extends Fathers with TableInfo<$FathersTable, Father> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FathersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fatherIdMeta = const VerificationMeta(
    'fatherId',
  );
  @override
  late final GeneratedColumn<int> fatherId = GeneratedColumn<int>(
    'father_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatherNameMeta = const VerificationMeta(
    'fatherName',
  );
  @override
  late final GeneratedColumn<String> fatherName = GeneratedColumn<String>(
    'father_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [fatherId, fatherName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fathers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Father> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('father_id')) {
      context.handle(
        _fatherIdMeta,
        fatherId.isAcceptableOrUnknown(data['father_id']!, _fatherIdMeta),
      );
    }
    if (data.containsKey('father_name')) {
      context.handle(
        _fatherNameMeta,
        fatherName.isAcceptableOrUnknown(data['father_name']!, _fatherNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Father map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Father(
      fatherId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}father_id'],
      ),
      fatherName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}father_name'],
      ),
    );
  }

  @override
  $FathersTable createAlias(String alias) {
    return $FathersTable(attachedDatabase, alias);
  }
}

class Father extends DataClass implements Insertable<Father> {
  final int? fatherId;
  final String? fatherName;
  const Father({this.fatherId, this.fatherName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || fatherId != null) {
      map['father_id'] = Variable<int>(fatherId);
    }
    if (!nullToAbsent || fatherName != null) {
      map['father_name'] = Variable<String>(fatherName);
    }
    return map;
  }

  FathersCompanion toCompanion(bool nullToAbsent) {
    return FathersCompanion(
      fatherId: fatherId == null && nullToAbsent
          ? const Value.absent()
          : Value(fatherId),
      fatherName: fatherName == null && nullToAbsent
          ? const Value.absent()
          : Value(fatherName),
    );
  }

  factory Father.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Father(
      fatherId: serializer.fromJson<int?>(json['fatherId']),
      fatherName: serializer.fromJson<String?>(json['fatherName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fatherId': serializer.toJson<int?>(fatherId),
      'fatherName': serializer.toJson<String?>(fatherName),
    };
  }

  Father copyWith({
    Value<int?> fatherId = const Value.absent(),
    Value<String?> fatherName = const Value.absent(),
  }) => Father(
    fatherId: fatherId.present ? fatherId.value : this.fatherId,
    fatherName: fatherName.present ? fatherName.value : this.fatherName,
  );
  Father copyWithCompanion(FathersCompanion data) {
    return Father(
      fatherId: data.fatherId.present ? data.fatherId.value : this.fatherId,
      fatherName: data.fatherName.present
          ? data.fatherName.value
          : this.fatherName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Father(')
          ..write('fatherId: $fatherId, ')
          ..write('fatherName: $fatherName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fatherId, fatherName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Father &&
          other.fatherId == this.fatherId &&
          other.fatherName == this.fatherName);
}

class FathersCompanion extends UpdateCompanion<Father> {
  final Value<int?> fatherId;
  final Value<String?> fatherName;
  final Value<int> rowid;
  const FathersCompanion({
    this.fatherId = const Value.absent(),
    this.fatherName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FathersCompanion.insert({
    this.fatherId = const Value.absent(),
    this.fatherName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<Father> custom({
    Expression<int>? fatherId,
    Expression<String>? fatherName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fatherId != null) 'father_id': fatherId,
      if (fatherName != null) 'father_name': fatherName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FathersCompanion copyWith({
    Value<int?>? fatherId,
    Value<String?>? fatherName,
    Value<int>? rowid,
  }) {
    return FathersCompanion(
      fatherId: fatherId ?? this.fatherId,
      fatherName: fatherName ?? this.fatherName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fatherId.present) {
      map['father_id'] = Variable<int>(fatherId.value);
    }
    if (fatherName.present) {
      map['father_name'] = Variable<String>(fatherName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FathersCompanion(')
          ..write('fatherId: $fatherId, ')
          ..write('fatherName: $fatherName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JenderTable extends Jender with TableInfo<$JenderTable, JenderData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JenderTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _jenderIdMeta = const VerificationMeta(
    'jenderId',
  );
  @override
  late final GeneratedColumn<int> jenderId = GeneratedColumn<int>(
    'jender_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jenderNameMeta = const VerificationMeta(
    'jenderName',
  );
  @override
  late final GeneratedColumn<String> jenderName = GeneratedColumn<String>(
    'jender_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [jenderId, jenderName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jender';
  @override
  VerificationContext validateIntegrity(
    Insertable<JenderData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('jender_id')) {
      context.handle(
        _jenderIdMeta,
        jenderId.isAcceptableOrUnknown(data['jender_id']!, _jenderIdMeta),
      );
    }
    if (data.containsKey('jender_name')) {
      context.handle(
        _jenderNameMeta,
        jenderName.isAcceptableOrUnknown(data['jender_name']!, _jenderNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  JenderData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JenderData(
      jenderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jender_id'],
      ),
      jenderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jender_name'],
      ),
    );
  }

  @override
  $JenderTable createAlias(String alias) {
    return $JenderTable(attachedDatabase, alias);
  }
}

class JenderData extends DataClass implements Insertable<JenderData> {
  final int? jenderId;
  final String? jenderName;
  const JenderData({this.jenderId, this.jenderName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || jenderId != null) {
      map['jender_id'] = Variable<int>(jenderId);
    }
    if (!nullToAbsent || jenderName != null) {
      map['jender_name'] = Variable<String>(jenderName);
    }
    return map;
  }

  JenderCompanion toCompanion(bool nullToAbsent) {
    return JenderCompanion(
      jenderId: jenderId == null && nullToAbsent
          ? const Value.absent()
          : Value(jenderId),
      jenderName: jenderName == null && nullToAbsent
          ? const Value.absent()
          : Value(jenderName),
    );
  }

  factory JenderData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JenderData(
      jenderId: serializer.fromJson<int?>(json['jenderId']),
      jenderName: serializer.fromJson<String?>(json['jenderName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'jenderId': serializer.toJson<int?>(jenderId),
      'jenderName': serializer.toJson<String?>(jenderName),
    };
  }

  JenderData copyWith({
    Value<int?> jenderId = const Value.absent(),
    Value<String?> jenderName = const Value.absent(),
  }) => JenderData(
    jenderId: jenderId.present ? jenderId.value : this.jenderId,
    jenderName: jenderName.present ? jenderName.value : this.jenderName,
  );
  JenderData copyWithCompanion(JenderCompanion data) {
    return JenderData(
      jenderId: data.jenderId.present ? data.jenderId.value : this.jenderId,
      jenderName: data.jenderName.present
          ? data.jenderName.value
          : this.jenderName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JenderData(')
          ..write('jenderId: $jenderId, ')
          ..write('jenderName: $jenderName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(jenderId, jenderName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JenderData &&
          other.jenderId == this.jenderId &&
          other.jenderName == this.jenderName);
}

class JenderCompanion extends UpdateCompanion<JenderData> {
  final Value<int?> jenderId;
  final Value<String?> jenderName;
  final Value<int> rowid;
  const JenderCompanion({
    this.jenderId = const Value.absent(),
    this.jenderName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JenderCompanion.insert({
    this.jenderId = const Value.absent(),
    this.jenderName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<JenderData> custom({
    Expression<int>? jenderId,
    Expression<String>? jenderName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (jenderId != null) 'jender_id': jenderId,
      if (jenderName != null) 'jender_name': jenderName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JenderCompanion copyWith({
    Value<int?>? jenderId,
    Value<String?>? jenderName,
    Value<int>? rowid,
  }) {
    return JenderCompanion(
      jenderId: jenderId ?? this.jenderId,
      jenderName: jenderName ?? this.jenderName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (jenderId.present) {
      map['jender_id'] = Variable<int>(jenderId.value);
    }
    if (jenderName.present) {
      map['jender_name'] = Variable<String>(jenderName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JenderCompanion(')
          ..write('jenderId: $jenderId, ')
          ..write('jenderName: $jenderName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PassTable extends Pass with TableInfo<$PassTable, PassData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PassTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _passIdMeta = const VerificationMeta('passId');
  @override
  late final GeneratedColumn<int> passId = GeneratedColumn<int>(
    'pass_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passWordMeta = const VerificationMeta(
    'passWord',
  );
  @override
  late final GeneratedColumn<String> passWord = GeneratedColumn<String>(
    'pass_word',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personNameMeta = const VerificationMeta(
    'personName',
  );
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
    'person_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [passId, passWord, personName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pass';
  @override
  VerificationContext validateIntegrity(
    Insertable<PassData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pass_id')) {
      context.handle(
        _passIdMeta,
        passId.isAcceptableOrUnknown(data['pass_id']!, _passIdMeta),
      );
    }
    if (data.containsKey('pass_word')) {
      context.handle(
        _passWordMeta,
        passWord.isAcceptableOrUnknown(data['pass_word']!, _passWordMeta),
      );
    }
    if (data.containsKey('person_name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['person_name']!, _personNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  PassData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PassData(
      passId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pass_id'],
      ),
      passWord: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pass_word'],
      ),
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_name'],
      ),
    );
  }

  @override
  $PassTable createAlias(String alias) {
    return $PassTable(attachedDatabase, alias);
  }
}

class PassData extends DataClass implements Insertable<PassData> {
  final int? passId;
  final String? passWord;
  final String? personName;
  const PassData({this.passId, this.passWord, this.personName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || passId != null) {
      map['pass_id'] = Variable<int>(passId);
    }
    if (!nullToAbsent || passWord != null) {
      map['pass_word'] = Variable<String>(passWord);
    }
    if (!nullToAbsent || personName != null) {
      map['person_name'] = Variable<String>(personName);
    }
    return map;
  }

  PassCompanion toCompanion(bool nullToAbsent) {
    return PassCompanion(
      passId: passId == null && nullToAbsent
          ? const Value.absent()
          : Value(passId),
      passWord: passWord == null && nullToAbsent
          ? const Value.absent()
          : Value(passWord),
      personName: personName == null && nullToAbsent
          ? const Value.absent()
          : Value(personName),
    );
  }

  factory PassData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PassData(
      passId: serializer.fromJson<int?>(json['passId']),
      passWord: serializer.fromJson<String?>(json['passWord']),
      personName: serializer.fromJson<String?>(json['personName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'passId': serializer.toJson<int?>(passId),
      'passWord': serializer.toJson<String?>(passWord),
      'personName': serializer.toJson<String?>(personName),
    };
  }

  PassData copyWith({
    Value<int?> passId = const Value.absent(),
    Value<String?> passWord = const Value.absent(),
    Value<String?> personName = const Value.absent(),
  }) => PassData(
    passId: passId.present ? passId.value : this.passId,
    passWord: passWord.present ? passWord.value : this.passWord,
    personName: personName.present ? personName.value : this.personName,
  );
  PassData copyWithCompanion(PassCompanion data) {
    return PassData(
      passId: data.passId.present ? data.passId.value : this.passId,
      passWord: data.passWord.present ? data.passWord.value : this.passWord,
      personName: data.personName.present
          ? data.personName.value
          : this.personName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PassData(')
          ..write('passId: $passId, ')
          ..write('passWord: $passWord, ')
          ..write('personName: $personName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(passId, passWord, personName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PassData &&
          other.passId == this.passId &&
          other.passWord == this.passWord &&
          other.personName == this.personName);
}

class PassCompanion extends UpdateCompanion<PassData> {
  final Value<int?> passId;
  final Value<String?> passWord;
  final Value<String?> personName;
  final Value<int> rowid;
  const PassCompanion({
    this.passId = const Value.absent(),
    this.passWord = const Value.absent(),
    this.personName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PassCompanion.insert({
    this.passId = const Value.absent(),
    this.passWord = const Value.absent(),
    this.personName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<PassData> custom({
    Expression<int>? passId,
    Expression<String>? passWord,
    Expression<String>? personName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (passId != null) 'pass_id': passId,
      if (passWord != null) 'pass_word': passWord,
      if (personName != null) 'person_name': personName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PassCompanion copyWith({
    Value<int?>? passId,
    Value<String?>? passWord,
    Value<String?>? personName,
    Value<int>? rowid,
  }) {
    return PassCompanion(
      passId: passId ?? this.passId,
      passWord: passWord ?? this.passWord,
      personName: personName ?? this.personName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (passId.present) {
      map['pass_id'] = Variable<int>(passId.value);
    }
    if (passWord.present) {
      map['pass_word'] = Variable<String>(passWord.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PassCompanion(')
          ..write('passId: $passId, ')
          ..write('passWord: $passWord, ')
          ..write('personName: $personName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonsTable extends Persons with TableInfo<$PersonsTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personNameMeta = const VerificationMeta(
    'personName',
  );
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
    'person_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageIdMeta = const VerificationMeta(
    'stageId',
  );
  @override
  late final GeneratedColumn<int> stageId = GeneratedColumn<int>(
    'stage_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaIdMeta = const VerificationMeta('areaId');
  @override
  late final GeneratedColumn<int> areaId = GeneratedColumn<int>(
    'area_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streetNameMeta = const VerificationMeta(
    'streetName',
  );
  @override
  late final GeneratedColumn<String> streetName = GeneratedColumn<String>(
    'street_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
    'mobile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jenderNameMeta = const VerificationMeta(
    'jenderName',
  );
  @override
  late final GeneratedColumn<String> jenderName = GeneratedColumn<String>(
    'jender_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatherIdMeta = const VerificationMeta(
    'fatherId',
  );
  @override
  late final GeneratedColumn<int> fatherId = GeneratedColumn<int>(
    'father_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<Uint8List> photo = GeneratedColumn<Uint8List>(
    'photo',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    personId,
    personName,
    stageId,
    areaId,
    streetName,
    phone,
    mobile,
    day,
    month,
    year,
    jenderName,
    fatherId,
    photo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'persons';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('person_name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['person_name']!, _personNameMeta),
      );
    }
    if (data.containsKey('stage_id')) {
      context.handle(
        _stageIdMeta,
        stageId.isAcceptableOrUnknown(data['stage_id']!, _stageIdMeta),
      );
    }
    if (data.containsKey('area_id')) {
      context.handle(
        _areaIdMeta,
        areaId.isAcceptableOrUnknown(data['area_id']!, _areaIdMeta),
      );
    }
    if (data.containsKey('street_name')) {
      context.handle(
        _streetNameMeta,
        streetName.isAcceptableOrUnknown(data['street_name']!, _streetNameMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('mobile')) {
      context.handle(
        _mobileMeta,
        mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta),
      );
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('jender_name')) {
      context.handle(
        _jenderNameMeta,
        jenderName.isAcceptableOrUnknown(data['jender_name']!, _jenderNameMeta),
      );
    }
    if (data.containsKey('father_id')) {
      context.handle(
        _fatherIdMeta,
        fatherId.isAcceptableOrUnknown(data['father_id']!, _fatherIdMeta),
      );
    }
    if (data.containsKey('photo')) {
      context.handle(
        _photoMeta,
        photo.isAcceptableOrUnknown(data['photo']!, _photoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      ),
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_name'],
      ),
      stageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_id'],
      ),
      areaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}area_id'],
      ),
      streetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}street_name'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      mobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mobile'],
      ),
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      ),
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      jenderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jender_name'],
      ),
      fatherId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}father_id'],
      ),
      photo: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}photo'],
      ),
    );
  }

  @override
  $PersonsTable createAlias(String alias) {
    return $PersonsTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final int? personId;
  final String? personName;
  final int? stageId;
  final int? areaId;
  final String? streetName;
  final String? phone;
  final String? mobile;
  final int? day;
  final int? month;
  final int? year;
  final String? jenderName;
  final int? fatherId;
  final Uint8List? photo;
  const Person({
    this.personId,
    this.personName,
    this.stageId,
    this.areaId,
    this.streetName,
    this.phone,
    this.mobile,
    this.day,
    this.month,
    this.year,
    this.jenderName,
    this.fatherId,
    this.photo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<int>(personId);
    }
    if (!nullToAbsent || personName != null) {
      map['person_name'] = Variable<String>(personName);
    }
    if (!nullToAbsent || stageId != null) {
      map['stage_id'] = Variable<int>(stageId);
    }
    if (!nullToAbsent || areaId != null) {
      map['area_id'] = Variable<int>(areaId);
    }
    if (!nullToAbsent || streetName != null) {
      map['street_name'] = Variable<String>(streetName);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || mobile != null) {
      map['mobile'] = Variable<String>(mobile);
    }
    if (!nullToAbsent || day != null) {
      map['day'] = Variable<int>(day);
    }
    if (!nullToAbsent || month != null) {
      map['month'] = Variable<int>(month);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || jenderName != null) {
      map['jender_name'] = Variable<String>(jenderName);
    }
    if (!nullToAbsent || fatherId != null) {
      map['father_id'] = Variable<int>(fatherId);
    }
    if (!nullToAbsent || photo != null) {
      map['photo'] = Variable<Uint8List>(photo);
    }
    return map;
  }

  PersonsCompanion toCompanion(bool nullToAbsent) {
    return PersonsCompanion(
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      personName: personName == null && nullToAbsent
          ? const Value.absent()
          : Value(personName),
      stageId: stageId == null && nullToAbsent
          ? const Value.absent()
          : Value(stageId),
      areaId: areaId == null && nullToAbsent
          ? const Value.absent()
          : Value(areaId),
      streetName: streetName == null && nullToAbsent
          ? const Value.absent()
          : Value(streetName),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      mobile: mobile == null && nullToAbsent
          ? const Value.absent()
          : Value(mobile),
      day: day == null && nullToAbsent ? const Value.absent() : Value(day),
      month: month == null && nullToAbsent
          ? const Value.absent()
          : Value(month),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      jenderName: jenderName == null && nullToAbsent
          ? const Value.absent()
          : Value(jenderName),
      fatherId: fatherId == null && nullToAbsent
          ? const Value.absent()
          : Value(fatherId),
      photo: photo == null && nullToAbsent
          ? const Value.absent()
          : Value(photo),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      personId: serializer.fromJson<int?>(json['personId']),
      personName: serializer.fromJson<String?>(json['personName']),
      stageId: serializer.fromJson<int?>(json['stageId']),
      areaId: serializer.fromJson<int?>(json['areaId']),
      streetName: serializer.fromJson<String?>(json['streetName']),
      phone: serializer.fromJson<String?>(json['phone']),
      mobile: serializer.fromJson<String?>(json['mobile']),
      day: serializer.fromJson<int?>(json['day']),
      month: serializer.fromJson<int?>(json['month']),
      year: serializer.fromJson<int?>(json['year']),
      jenderName: serializer.fromJson<String?>(json['jenderName']),
      fatherId: serializer.fromJson<int?>(json['fatherId']),
      photo: serializer.fromJson<Uint8List?>(json['photo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'personId': serializer.toJson<int?>(personId),
      'personName': serializer.toJson<String?>(personName),
      'stageId': serializer.toJson<int?>(stageId),
      'areaId': serializer.toJson<int?>(areaId),
      'streetName': serializer.toJson<String?>(streetName),
      'phone': serializer.toJson<String?>(phone),
      'mobile': serializer.toJson<String?>(mobile),
      'day': serializer.toJson<int?>(day),
      'month': serializer.toJson<int?>(month),
      'year': serializer.toJson<int?>(year),
      'jenderName': serializer.toJson<String?>(jenderName),
      'fatherId': serializer.toJson<int?>(fatherId),
      'photo': serializer.toJson<Uint8List?>(photo),
    };
  }

  Person copyWith({
    Value<int?> personId = const Value.absent(),
    Value<String?> personName = const Value.absent(),
    Value<int?> stageId = const Value.absent(),
    Value<int?> areaId = const Value.absent(),
    Value<String?> streetName = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> mobile = const Value.absent(),
    Value<int?> day = const Value.absent(),
    Value<int?> month = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> jenderName = const Value.absent(),
    Value<int?> fatherId = const Value.absent(),
    Value<Uint8List?> photo = const Value.absent(),
  }) => Person(
    personId: personId.present ? personId.value : this.personId,
    personName: personName.present ? personName.value : this.personName,
    stageId: stageId.present ? stageId.value : this.stageId,
    areaId: areaId.present ? areaId.value : this.areaId,
    streetName: streetName.present ? streetName.value : this.streetName,
    phone: phone.present ? phone.value : this.phone,
    mobile: mobile.present ? mobile.value : this.mobile,
    day: day.present ? day.value : this.day,
    month: month.present ? month.value : this.month,
    year: year.present ? year.value : this.year,
    jenderName: jenderName.present ? jenderName.value : this.jenderName,
    fatherId: fatherId.present ? fatherId.value : this.fatherId,
    photo: photo.present ? photo.value : this.photo,
  );
  Person copyWithCompanion(PersonsCompanion data) {
    return Person(
      personId: data.personId.present ? data.personId.value : this.personId,
      personName: data.personName.present
          ? data.personName.value
          : this.personName,
      stageId: data.stageId.present ? data.stageId.value : this.stageId,
      areaId: data.areaId.present ? data.areaId.value : this.areaId,
      streetName: data.streetName.present
          ? data.streetName.value
          : this.streetName,
      phone: data.phone.present ? data.phone.value : this.phone,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      day: data.day.present ? data.day.value : this.day,
      month: data.month.present ? data.month.value : this.month,
      year: data.year.present ? data.year.value : this.year,
      jenderName: data.jenderName.present
          ? data.jenderName.value
          : this.jenderName,
      fatherId: data.fatherId.present ? data.fatherId.value : this.fatherId,
      photo: data.photo.present ? data.photo.value : this.photo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('stageId: $stageId, ')
          ..write('areaId: $areaId, ')
          ..write('streetName: $streetName, ')
          ..write('phone: $phone, ')
          ..write('mobile: $mobile, ')
          ..write('day: $day, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('jenderName: $jenderName, ')
          ..write('fatherId: $fatherId, ')
          ..write('photo: $photo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    personId,
    personName,
    stageId,
    areaId,
    streetName,
    phone,
    mobile,
    day,
    month,
    year,
    jenderName,
    fatherId,
    $driftBlobEquality.hash(photo),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.personId == this.personId &&
          other.personName == this.personName &&
          other.stageId == this.stageId &&
          other.areaId == this.areaId &&
          other.streetName == this.streetName &&
          other.phone == this.phone &&
          other.mobile == this.mobile &&
          other.day == this.day &&
          other.month == this.month &&
          other.year == this.year &&
          other.jenderName == this.jenderName &&
          other.fatherId == this.fatherId &&
          $driftBlobEquality.equals(other.photo, this.photo));
}

class PersonsCompanion extends UpdateCompanion<Person> {
  final Value<int?> personId;
  final Value<String?> personName;
  final Value<int?> stageId;
  final Value<int?> areaId;
  final Value<String?> streetName;
  final Value<String?> phone;
  final Value<String?> mobile;
  final Value<int?> day;
  final Value<int?> month;
  final Value<int?> year;
  final Value<String?> jenderName;
  final Value<int?> fatherId;
  final Value<Uint8List?> photo;
  final Value<int> rowid;
  const PersonsCompanion({
    this.personId = const Value.absent(),
    this.personName = const Value.absent(),
    this.stageId = const Value.absent(),
    this.areaId = const Value.absent(),
    this.streetName = const Value.absent(),
    this.phone = const Value.absent(),
    this.mobile = const Value.absent(),
    this.day = const Value.absent(),
    this.month = const Value.absent(),
    this.year = const Value.absent(),
    this.jenderName = const Value.absent(),
    this.fatherId = const Value.absent(),
    this.photo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonsCompanion.insert({
    this.personId = const Value.absent(),
    this.personName = const Value.absent(),
    this.stageId = const Value.absent(),
    this.areaId = const Value.absent(),
    this.streetName = const Value.absent(),
    this.phone = const Value.absent(),
    this.mobile = const Value.absent(),
    this.day = const Value.absent(),
    this.month = const Value.absent(),
    this.year = const Value.absent(),
    this.jenderName = const Value.absent(),
    this.fatherId = const Value.absent(),
    this.photo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<Person> custom({
    Expression<int>? personId,
    Expression<String>? personName,
    Expression<int>? stageId,
    Expression<int>? areaId,
    Expression<String>? streetName,
    Expression<String>? phone,
    Expression<String>? mobile,
    Expression<int>? day,
    Expression<int>? month,
    Expression<int>? year,
    Expression<String>? jenderName,
    Expression<int>? fatherId,
    Expression<Uint8List>? photo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (personId != null) 'person_id': personId,
      if (personName != null) 'person_name': personName,
      if (stageId != null) 'stage_id': stageId,
      if (areaId != null) 'area_id': areaId,
      if (streetName != null) 'street_name': streetName,
      if (phone != null) 'phone': phone,
      if (mobile != null) 'mobile': mobile,
      if (day != null) 'day': day,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (jenderName != null) 'jender_name': jenderName,
      if (fatherId != null) 'father_id': fatherId,
      if (photo != null) 'photo': photo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonsCompanion copyWith({
    Value<int?>? personId,
    Value<String?>? personName,
    Value<int?>? stageId,
    Value<int?>? areaId,
    Value<String?>? streetName,
    Value<String?>? phone,
    Value<String?>? mobile,
    Value<int?>? day,
    Value<int?>? month,
    Value<int?>? year,
    Value<String?>? jenderName,
    Value<int?>? fatherId,
    Value<Uint8List?>? photo,
    Value<int>? rowid,
  }) {
    return PersonsCompanion(
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      stageId: stageId ?? this.stageId,
      areaId: areaId ?? this.areaId,
      streetName: streetName ?? this.streetName,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      day: day ?? this.day,
      month: month ?? this.month,
      year: year ?? this.year,
      jenderName: jenderName ?? this.jenderName,
      fatherId: fatherId ?? this.fatherId,
      photo: photo ?? this.photo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (stageId.present) {
      map['stage_id'] = Variable<int>(stageId.value);
    }
    if (areaId.present) {
      map['area_id'] = Variable<int>(areaId.value);
    }
    if (streetName.present) {
      map['street_name'] = Variable<String>(streetName.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (jenderName.present) {
      map['jender_name'] = Variable<String>(jenderName.value);
    }
    if (fatherId.present) {
      map['father_id'] = Variable<int>(fatherId.value);
    }
    if (photo.present) {
      map['photo'] = Variable<Uint8List>(photo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsCompanion(')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('stageId: $stageId, ')
          ..write('areaId: $areaId, ')
          ..write('streetName: $streetName, ')
          ..write('phone: $phone, ')
          ..write('mobile: $mobile, ')
          ..write('day: $day, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('jenderName: $jenderName, ')
          ..write('fatherId: $fatherId, ')
          ..write('photo: $photo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StagesTable extends Stages with TableInfo<$StagesTable, Stage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stageIdMeta = const VerificationMeta(
    'stageId',
  );
  @override
  late final GeneratedColumn<int> stageId = GeneratedColumn<int>(
    'stage_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageNameMeta = const VerificationMeta(
    'stageName',
  );
  @override
  late final GeneratedColumn<String> stageName = GeneratedColumn<String>(
    'stage_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [stageId, stageName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Stage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('stage_id')) {
      context.handle(
        _stageIdMeta,
        stageId.isAcceptableOrUnknown(data['stage_id']!, _stageIdMeta),
      );
    }
    if (data.containsKey('stage_name')) {
      context.handle(
        _stageNameMeta,
        stageName.isAcceptableOrUnknown(data['stage_name']!, _stageNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Stage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Stage(
      stageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_id'],
      ),
      stageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage_name'],
      ),
    );
  }

  @override
  $StagesTable createAlias(String alias) {
    return $StagesTable(attachedDatabase, alias);
  }
}

class Stage extends DataClass implements Insertable<Stage> {
  final int? stageId;
  final String? stageName;
  const Stage({this.stageId, this.stageName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || stageId != null) {
      map['stage_id'] = Variable<int>(stageId);
    }
    if (!nullToAbsent || stageName != null) {
      map['stage_name'] = Variable<String>(stageName);
    }
    return map;
  }

  StagesCompanion toCompanion(bool nullToAbsent) {
    return StagesCompanion(
      stageId: stageId == null && nullToAbsent
          ? const Value.absent()
          : Value(stageId),
      stageName: stageName == null && nullToAbsent
          ? const Value.absent()
          : Value(stageName),
    );
  }

  factory Stage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Stage(
      stageId: serializer.fromJson<int?>(json['stageId']),
      stageName: serializer.fromJson<String?>(json['stageName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stageId': serializer.toJson<int?>(stageId),
      'stageName': serializer.toJson<String?>(stageName),
    };
  }

  Stage copyWith({
    Value<int?> stageId = const Value.absent(),
    Value<String?> stageName = const Value.absent(),
  }) => Stage(
    stageId: stageId.present ? stageId.value : this.stageId,
    stageName: stageName.present ? stageName.value : this.stageName,
  );
  Stage copyWithCompanion(StagesCompanion data) {
    return Stage(
      stageId: data.stageId.present ? data.stageId.value : this.stageId,
      stageName: data.stageName.present ? data.stageName.value : this.stageName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Stage(')
          ..write('stageId: $stageId, ')
          ..write('stageName: $stageName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(stageId, stageName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stage &&
          other.stageId == this.stageId &&
          other.stageName == this.stageName);
}

class StagesCompanion extends UpdateCompanion<Stage> {
  final Value<int?> stageId;
  final Value<String?> stageName;
  final Value<int> rowid;
  const StagesCompanion({
    this.stageId = const Value.absent(),
    this.stageName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StagesCompanion.insert({
    this.stageId = const Value.absent(),
    this.stageName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<Stage> custom({
    Expression<int>? stageId,
    Expression<String>? stageName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (stageId != null) 'stage_id': stageId,
      if (stageName != null) 'stage_name': stageName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StagesCompanion copyWith({
    Value<int?>? stageId,
    Value<String?>? stageName,
    Value<int>? rowid,
  }) {
    return StagesCompanion(
      stageId: stageId ?? this.stageId,
      stageName: stageName ?? this.stageName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stageId.present) {
      map['stage_id'] = Variable<int>(stageId.value);
    }
    if (stageName.present) {
      map['stage_name'] = Variable<String>(stageName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StagesCompanion(')
          ..write('stageId: $stageId, ')
          ..write('stageName: $stageName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AbsentPersonsTable absentPersons = $AbsentPersonsTable(this);
  late final $AbsentPrintTable absentPrint = $AbsentPrintTable(this);
  late final $AddingTable adding = $AddingTable(this);
  late final $AreasTable areas = $AreasTable(this);
  late final $ComingTable coming = $ComingTable(this);
  late final $CreditTable credit = $CreditTable(this);
  late final $FathersTable fathers = $FathersTable(this);
  late final $JenderTable jender = $JenderTable(this);
  late final $PassTable pass = $PassTable(this);
  late final $PersonsTable persons = $PersonsTable(this);
  late final $StagesTable stages = $StagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    absentPersons,
    absentPrint,
    adding,
    areas,
    coming,
    credit,
    fathers,
    jender,
    pass,
    persons,
    stages,
  ];
}

typedef $$AbsentPersonsTableCreateCompanionBuilder =
    AbsentPersonsCompanion Function({
      Value<int?> id,
      Value<int?> personId,
      Value<String?> personName,
      Value<String?> stage,
      Value<String?> month1,
      Value<String?> first,
      Value<String?> second,
      Value<String?> third,
      Value<String?> forth,
      Value<String?> fife,
      Value<int> rowid,
    });
typedef $$AbsentPersonsTableUpdateCompanionBuilder =
    AbsentPersonsCompanion Function({
      Value<int?> id,
      Value<int?> personId,
      Value<String?> personName,
      Value<String?> stage,
      Value<String?> month1,
      Value<String?> first,
      Value<String?> second,
      Value<String?> third,
      Value<String?> forth,
      Value<String?> fife,
      Value<int> rowid,
    });

class $$AbsentPersonsTableFilterComposer
    extends Composer<_$AppDatabase, $AbsentPersonsTable> {
  $$AbsentPersonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get month1 => $composableBuilder(
    column: $table.month1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get first => $composableBuilder(
    column: $table.first,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get second => $composableBuilder(
    column: $table.second,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get third => $composableBuilder(
    column: $table.third,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get forth => $composableBuilder(
    column: $table.forth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fife => $composableBuilder(
    column: $table.fife,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AbsentPersonsTableOrderingComposer
    extends Composer<_$AppDatabase, $AbsentPersonsTable> {
  $$AbsentPersonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get month1 => $composableBuilder(
    column: $table.month1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get first => $composableBuilder(
    column: $table.first,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get second => $composableBuilder(
    column: $table.second,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get third => $composableBuilder(
    column: $table.third,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forth => $composableBuilder(
    column: $table.forth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fife => $composableBuilder(
    column: $table.fife,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AbsentPersonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AbsentPersonsTable> {
  $$AbsentPersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<String> get month1 =>
      $composableBuilder(column: $table.month1, builder: (column) => column);

  GeneratedColumn<String> get first =>
      $composableBuilder(column: $table.first, builder: (column) => column);

  GeneratedColumn<String> get second =>
      $composableBuilder(column: $table.second, builder: (column) => column);

  GeneratedColumn<String> get third =>
      $composableBuilder(column: $table.third, builder: (column) => column);

  GeneratedColumn<String> get forth =>
      $composableBuilder(column: $table.forth, builder: (column) => column);

  GeneratedColumn<String> get fife =>
      $composableBuilder(column: $table.fife, builder: (column) => column);
}

class $$AbsentPersonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AbsentPersonsTable,
          AbsentPerson,
          $$AbsentPersonsTableFilterComposer,
          $$AbsentPersonsTableOrderingComposer,
          $$AbsentPersonsTableAnnotationComposer,
          $$AbsentPersonsTableCreateCompanionBuilder,
          $$AbsentPersonsTableUpdateCompanionBuilder,
          (
            AbsentPerson,
            BaseReferences<_$AppDatabase, $AbsentPersonsTable, AbsentPerson>,
          ),
          AbsentPerson,
          PrefetchHooks Function()
        > {
  $$AbsentPersonsTableTableManager(_$AppDatabase db, $AbsentPersonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AbsentPersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AbsentPersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AbsentPersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<String?> stage = const Value.absent(),
                Value<String?> month1 = const Value.absent(),
                Value<String?> first = const Value.absent(),
                Value<String?> second = const Value.absent(),
                Value<String?> third = const Value.absent(),
                Value<String?> forth = const Value.absent(),
                Value<String?> fife = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AbsentPersonsCompanion(
                id: id,
                personId: personId,
                personName: personName,
                stage: stage,
                month1: month1,
                first: first,
                second: second,
                third: third,
                forth: forth,
                fife: fife,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<String?> stage = const Value.absent(),
                Value<String?> month1 = const Value.absent(),
                Value<String?> first = const Value.absent(),
                Value<String?> second = const Value.absent(),
                Value<String?> third = const Value.absent(),
                Value<String?> forth = const Value.absent(),
                Value<String?> fife = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AbsentPersonsCompanion.insert(
                id: id,
                personId: personId,
                personName: personName,
                stage: stage,
                month1: month1,
                first: first,
                second: second,
                third: third,
                forth: forth,
                fife: fife,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AbsentPersonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AbsentPersonsTable,
      AbsentPerson,
      $$AbsentPersonsTableFilterComposer,
      $$AbsentPersonsTableOrderingComposer,
      $$AbsentPersonsTableAnnotationComposer,
      $$AbsentPersonsTableCreateCompanionBuilder,
      $$AbsentPersonsTableUpdateCompanionBuilder,
      (
        AbsentPerson,
        BaseReferences<_$AppDatabase, $AbsentPersonsTable, AbsentPerson>,
      ),
      AbsentPerson,
      PrefetchHooks Function()
    >;
typedef $$AbsentPrintTableCreateCompanionBuilder =
    AbsentPrintCompanion Function({
      Value<int?> id,
      Value<int?> personId,
      Value<String?> personName,
      Value<int?> stageId,
      Value<String?> stageName,
      Value<int?> areaId,
      Value<String?> areaName,
      Value<String?> streetName,
      Value<String?> phone,
      Value<String?> mobile,
      Value<String?> dateFrom,
      Value<String?> dateTo,
      Value<int> rowid,
    });
typedef $$AbsentPrintTableUpdateCompanionBuilder =
    AbsentPrintCompanion Function({
      Value<int?> id,
      Value<int?> personId,
      Value<String?> personName,
      Value<int?> stageId,
      Value<String?> stageName,
      Value<int?> areaId,
      Value<String?> areaName,
      Value<String?> streetName,
      Value<String?> phone,
      Value<String?> mobile,
      Value<String?> dateFrom,
      Value<String?> dateTo,
      Value<int> rowid,
    });

class $$AbsentPrintTableFilterComposer
    extends Composer<_$AppDatabase, $AbsentPrintTable> {
  $$AbsentPrintTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stageName => $composableBuilder(
    column: $table.stageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaName => $composableBuilder(
    column: $table.areaName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streetName => $composableBuilder(
    column: $table.streetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateFrom => $composableBuilder(
    column: $table.dateFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateTo => $composableBuilder(
    column: $table.dateTo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AbsentPrintTableOrderingComposer
    extends Composer<_$AppDatabase, $AbsentPrintTable> {
  $$AbsentPrintTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stageName => $composableBuilder(
    column: $table.stageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaName => $composableBuilder(
    column: $table.areaName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streetName => $composableBuilder(
    column: $table.streetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateFrom => $composableBuilder(
    column: $table.dateFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateTo => $composableBuilder(
    column: $table.dateTo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AbsentPrintTableAnnotationComposer
    extends Composer<_$AppDatabase, $AbsentPrintTable> {
  $$AbsentPrintTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stageId =>
      $composableBuilder(column: $table.stageId, builder: (column) => column);

  GeneratedColumn<String> get stageName =>
      $composableBuilder(column: $table.stageName, builder: (column) => column);

  GeneratedColumn<int> get areaId =>
      $composableBuilder(column: $table.areaId, builder: (column) => column);

  GeneratedColumn<String> get areaName =>
      $composableBuilder(column: $table.areaName, builder: (column) => column);

  GeneratedColumn<String> get streetName => $composableBuilder(
    column: $table.streetName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<String> get dateFrom =>
      $composableBuilder(column: $table.dateFrom, builder: (column) => column);

  GeneratedColumn<String> get dateTo =>
      $composableBuilder(column: $table.dateTo, builder: (column) => column);
}

class $$AbsentPrintTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AbsentPrintTable,
          AbsentPrintData,
          $$AbsentPrintTableFilterComposer,
          $$AbsentPrintTableOrderingComposer,
          $$AbsentPrintTableAnnotationComposer,
          $$AbsentPrintTableCreateCompanionBuilder,
          $$AbsentPrintTableUpdateCompanionBuilder,
          (
            AbsentPrintData,
            BaseReferences<_$AppDatabase, $AbsentPrintTable, AbsentPrintData>,
          ),
          AbsentPrintData,
          PrefetchHooks Function()
        > {
  $$AbsentPrintTableTableManager(_$AppDatabase db, $AbsentPrintTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AbsentPrintTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AbsentPrintTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AbsentPrintTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<int?> stageId = const Value.absent(),
                Value<String?> stageName = const Value.absent(),
                Value<int?> areaId = const Value.absent(),
                Value<String?> areaName = const Value.absent(),
                Value<String?> streetName = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<String?> dateFrom = const Value.absent(),
                Value<String?> dateTo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AbsentPrintCompanion(
                id: id,
                personId: personId,
                personName: personName,
                stageId: stageId,
                stageName: stageName,
                areaId: areaId,
                areaName: areaName,
                streetName: streetName,
                phone: phone,
                mobile: mobile,
                dateFrom: dateFrom,
                dateTo: dateTo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<int?> stageId = const Value.absent(),
                Value<String?> stageName = const Value.absent(),
                Value<int?> areaId = const Value.absent(),
                Value<String?> areaName = const Value.absent(),
                Value<String?> streetName = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<String?> dateFrom = const Value.absent(),
                Value<String?> dateTo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AbsentPrintCompanion.insert(
                id: id,
                personId: personId,
                personName: personName,
                stageId: stageId,
                stageName: stageName,
                areaId: areaId,
                areaName: areaName,
                streetName: streetName,
                phone: phone,
                mobile: mobile,
                dateFrom: dateFrom,
                dateTo: dateTo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AbsentPrintTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AbsentPrintTable,
      AbsentPrintData,
      $$AbsentPrintTableFilterComposer,
      $$AbsentPrintTableOrderingComposer,
      $$AbsentPrintTableAnnotationComposer,
      $$AbsentPrintTableCreateCompanionBuilder,
      $$AbsentPrintTableUpdateCompanionBuilder,
      (
        AbsentPrintData,
        BaseReferences<_$AppDatabase, $AbsentPrintTable, AbsentPrintData>,
      ),
      AbsentPrintData,
      PrefetchHooks Function()
    >;
typedef $$AddingTableCreateCompanionBuilder =
    AddingCompanion Function({
      Value<int?> dateId,
      Value<String?> date,
      Value<int> rowid,
    });
typedef $$AddingTableUpdateCompanionBuilder =
    AddingCompanion Function({
      Value<int?> dateId,
      Value<String?> date,
      Value<int> rowid,
    });

class $$AddingTableFilterComposer
    extends Composer<_$AppDatabase, $AddingTable> {
  $$AddingTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get dateId => $composableBuilder(
    column: $table.dateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AddingTableOrderingComposer
    extends Composer<_$AppDatabase, $AddingTable> {
  $$AddingTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get dateId => $composableBuilder(
    column: $table.dateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AddingTableAnnotationComposer
    extends Composer<_$AppDatabase, $AddingTable> {
  $$AddingTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get dateId =>
      $composableBuilder(column: $table.dateId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$AddingTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AddingTable,
          AddingData,
          $$AddingTableFilterComposer,
          $$AddingTableOrderingComposer,
          $$AddingTableAnnotationComposer,
          $$AddingTableCreateCompanionBuilder,
          $$AddingTableUpdateCompanionBuilder,
          (AddingData, BaseReferences<_$AppDatabase, $AddingTable, AddingData>),
          AddingData,
          PrefetchHooks Function()
        > {
  $$AddingTableTableManager(_$AppDatabase db, $AddingTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AddingTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AddingTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AddingTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> dateId = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AddingCompanion(dateId: dateId, date: date, rowid: rowid),
          createCompanionCallback:
              ({
                Value<int?> dateId = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AddingCompanion.insert(
                dateId: dateId,
                date: date,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AddingTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AddingTable,
      AddingData,
      $$AddingTableFilterComposer,
      $$AddingTableOrderingComposer,
      $$AddingTableAnnotationComposer,
      $$AddingTableCreateCompanionBuilder,
      $$AddingTableUpdateCompanionBuilder,
      (AddingData, BaseReferences<_$AppDatabase, $AddingTable, AddingData>),
      AddingData,
      PrefetchHooks Function()
    >;
typedef $$AreasTableCreateCompanionBuilder =
    AreasCompanion Function({
      Value<int?> areaId,
      Value<String?> areaName,
      Value<int> rowid,
    });
typedef $$AreasTableUpdateCompanionBuilder =
    AreasCompanion Function({
      Value<int?> areaId,
      Value<String?> areaName,
      Value<int> rowid,
    });

class $$AreasTableFilterComposer extends Composer<_$AppDatabase, $AreasTable> {
  $$AreasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaName => $composableBuilder(
    column: $table.areaName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AreasTableOrderingComposer
    extends Composer<_$AppDatabase, $AreasTable> {
  $$AreasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaName => $composableBuilder(
    column: $table.areaName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AreasTableAnnotationComposer
    extends Composer<_$AppDatabase, $AreasTable> {
  $$AreasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get areaId =>
      $composableBuilder(column: $table.areaId, builder: (column) => column);

  GeneratedColumn<String> get areaName =>
      $composableBuilder(column: $table.areaName, builder: (column) => column);
}

class $$AreasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AreasTable,
          Area,
          $$AreasTableFilterComposer,
          $$AreasTableOrderingComposer,
          $$AreasTableAnnotationComposer,
          $$AreasTableCreateCompanionBuilder,
          $$AreasTableUpdateCompanionBuilder,
          (Area, BaseReferences<_$AppDatabase, $AreasTable, Area>),
          Area,
          PrefetchHooks Function()
        > {
  $$AreasTableTableManager(_$AppDatabase db, $AreasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AreasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AreasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AreasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> areaId = const Value.absent(),
                Value<String?> areaName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AreasCompanion(
                areaId: areaId,
                areaName: areaName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int?> areaId = const Value.absent(),
                Value<String?> areaName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AreasCompanion.insert(
                areaId: areaId,
                areaName: areaName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AreasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AreasTable,
      Area,
      $$AreasTableFilterComposer,
      $$AreasTableOrderingComposer,
      $$AreasTableAnnotationComposer,
      $$AreasTableCreateCompanionBuilder,
      $$AreasTableUpdateCompanionBuilder,
      (Area, BaseReferences<_$AppDatabase, $AreasTable, Area>),
      Area,
      PrefetchHooks Function()
    >;
typedef $$ComingTableCreateCompanionBuilder =
    ComingCompanion Function({
      Value<int?> id,
      Value<int?> personId,
      Value<String?> dateWeek,
      Value<int?> point,
      Value<int?> mont1,
      Value<int?> year1,
      Value<int> rowid,
    });
typedef $$ComingTableUpdateCompanionBuilder =
    ComingCompanion Function({
      Value<int?> id,
      Value<int?> personId,
      Value<String?> dateWeek,
      Value<int?> point,
      Value<int?> mont1,
      Value<int?> year1,
      Value<int> rowid,
    });

class $$ComingTableFilterComposer
    extends Composer<_$AppDatabase, $ComingTable> {
  $$ComingTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateWeek => $composableBuilder(
    column: $table.dateWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get point => $composableBuilder(
    column: $table.point,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mont1 => $composableBuilder(
    column: $table.mont1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year1 => $composableBuilder(
    column: $table.year1,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ComingTableOrderingComposer
    extends Composer<_$AppDatabase, $ComingTable> {
  $$ComingTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateWeek => $composableBuilder(
    column: $table.dateWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get point => $composableBuilder(
    column: $table.point,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mont1 => $composableBuilder(
    column: $table.mont1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year1 => $composableBuilder(
    column: $table.year1,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ComingTableAnnotationComposer
    extends Composer<_$AppDatabase, $ComingTable> {
  $$ComingTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get dateWeek =>
      $composableBuilder(column: $table.dateWeek, builder: (column) => column);

  GeneratedColumn<int> get point =>
      $composableBuilder(column: $table.point, builder: (column) => column);

  GeneratedColumn<int> get mont1 =>
      $composableBuilder(column: $table.mont1, builder: (column) => column);

  GeneratedColumn<int> get year1 =>
      $composableBuilder(column: $table.year1, builder: (column) => column);
}

class $$ComingTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ComingTable,
          ComingData,
          $$ComingTableFilterComposer,
          $$ComingTableOrderingComposer,
          $$ComingTableAnnotationComposer,
          $$ComingTableCreateCompanionBuilder,
          $$ComingTableUpdateCompanionBuilder,
          (ComingData, BaseReferences<_$AppDatabase, $ComingTable, ComingData>),
          ComingData,
          PrefetchHooks Function()
        > {
  $$ComingTableTableManager(_$AppDatabase db, $ComingTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComingTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComingTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComingTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<String?> dateWeek = const Value.absent(),
                Value<int?> point = const Value.absent(),
                Value<int?> mont1 = const Value.absent(),
                Value<int?> year1 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComingCompanion(
                id: id,
                personId: personId,
                dateWeek: dateWeek,
                point: point,
                mont1: mont1,
                year1: year1,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<String?> dateWeek = const Value.absent(),
                Value<int?> point = const Value.absent(),
                Value<int?> mont1 = const Value.absent(),
                Value<int?> year1 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComingCompanion.insert(
                id: id,
                personId: personId,
                dateWeek: dateWeek,
                point: point,
                mont1: mont1,
                year1: year1,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ComingTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ComingTable,
      ComingData,
      $$ComingTableFilterComposer,
      $$ComingTableOrderingComposer,
      $$ComingTableAnnotationComposer,
      $$ComingTableCreateCompanionBuilder,
      $$ComingTableUpdateCompanionBuilder,
      (ComingData, BaseReferences<_$AppDatabase, $ComingTable, ComingData>),
      ComingData,
      PrefetchHooks Function()
    >;
typedef $$CreditTableCreateCompanionBuilder =
    CreditCompanion Function({
      Value<int?> id,
      Value<int?> personId,
      Value<String?> personName,
      Value<String?> stageName,
      Value<String?> areaName,
      Value<String?> street,
      Value<String?> phone,
      Value<String?> mobile,
      Value<int?> day,
      Value<int?> month,
      Value<int?> year,
      Value<String?> jender,
      Value<Uint8List?> photo,
      Value<Uint8List?> parcode,
      Value<int> rowid,
    });
typedef $$CreditTableUpdateCompanionBuilder =
    CreditCompanion Function({
      Value<int?> id,
      Value<int?> personId,
      Value<String?> personName,
      Value<String?> stageName,
      Value<String?> areaName,
      Value<String?> street,
      Value<String?> phone,
      Value<String?> mobile,
      Value<int?> day,
      Value<int?> month,
      Value<int?> year,
      Value<String?> jender,
      Value<Uint8List?> photo,
      Value<Uint8List?> parcode,
      Value<int> rowid,
    });

class $$CreditTableFilterComposer
    extends Composer<_$AppDatabase, $CreditTable> {
  $$CreditTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stageName => $composableBuilder(
    column: $table.stageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaName => $composableBuilder(
    column: $table.areaName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get street => $composableBuilder(
    column: $table.street,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jender => $composableBuilder(
    column: $table.jender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get parcode => $composableBuilder(
    column: $table.parcode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CreditTableOrderingComposer
    extends Composer<_$AppDatabase, $CreditTable> {
  $$CreditTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stageName => $composableBuilder(
    column: $table.stageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaName => $composableBuilder(
    column: $table.areaName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get street => $composableBuilder(
    column: $table.street,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jender => $composableBuilder(
    column: $table.jender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get parcode => $composableBuilder(
    column: $table.parcode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CreditTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreditTable> {
  $$CreditTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stageName =>
      $composableBuilder(column: $table.stageName, builder: (column) => column);

  GeneratedColumn<String> get areaName =>
      $composableBuilder(column: $table.areaName, builder: (column) => column);

  GeneratedColumn<String> get street =>
      $composableBuilder(column: $table.street, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get jender =>
      $composableBuilder(column: $table.jender, builder: (column) => column);

  GeneratedColumn<Uint8List> get photo =>
      $composableBuilder(column: $table.photo, builder: (column) => column);

  GeneratedColumn<Uint8List> get parcode =>
      $composableBuilder(column: $table.parcode, builder: (column) => column);
}

class $$CreditTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CreditTable,
          CreditData,
          $$CreditTableFilterComposer,
          $$CreditTableOrderingComposer,
          $$CreditTableAnnotationComposer,
          $$CreditTableCreateCompanionBuilder,
          $$CreditTableUpdateCompanionBuilder,
          (CreditData, BaseReferences<_$AppDatabase, $CreditTable, CreditData>),
          CreditData,
          PrefetchHooks Function()
        > {
  $$CreditTableTableManager(_$AppDatabase db, $CreditTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreditTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreditTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreditTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<String?> stageName = const Value.absent(),
                Value<String?> areaName = const Value.absent(),
                Value<String?> street = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<int?> day = const Value.absent(),
                Value<int?> month = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> jender = const Value.absent(),
                Value<Uint8List?> photo = const Value.absent(),
                Value<Uint8List?> parcode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditCompanion(
                id: id,
                personId: personId,
                personName: personName,
                stageName: stageName,
                areaName: areaName,
                street: street,
                phone: phone,
                mobile: mobile,
                day: day,
                month: month,
                year: year,
                jender: jender,
                photo: photo,
                parcode: parcode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int?> id = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<String?> stageName = const Value.absent(),
                Value<String?> areaName = const Value.absent(),
                Value<String?> street = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<int?> day = const Value.absent(),
                Value<int?> month = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> jender = const Value.absent(),
                Value<Uint8List?> photo = const Value.absent(),
                Value<Uint8List?> parcode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditCompanion.insert(
                id: id,
                personId: personId,
                personName: personName,
                stageName: stageName,
                areaName: areaName,
                street: street,
                phone: phone,
                mobile: mobile,
                day: day,
                month: month,
                year: year,
                jender: jender,
                photo: photo,
                parcode: parcode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CreditTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CreditTable,
      CreditData,
      $$CreditTableFilterComposer,
      $$CreditTableOrderingComposer,
      $$CreditTableAnnotationComposer,
      $$CreditTableCreateCompanionBuilder,
      $$CreditTableUpdateCompanionBuilder,
      (CreditData, BaseReferences<_$AppDatabase, $CreditTable, CreditData>),
      CreditData,
      PrefetchHooks Function()
    >;
typedef $$FathersTableCreateCompanionBuilder =
    FathersCompanion Function({
      Value<int?> fatherId,
      Value<String?> fatherName,
      Value<int> rowid,
    });
typedef $$FathersTableUpdateCompanionBuilder =
    FathersCompanion Function({
      Value<int?> fatherId,
      Value<String?> fatherName,
      Value<int> rowid,
    });

class $$FathersTableFilterComposer
    extends Composer<_$AppDatabase, $FathersTable> {
  $$FathersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get fatherId => $composableBuilder(
    column: $table.fatherId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fatherName => $composableBuilder(
    column: $table.fatherName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FathersTableOrderingComposer
    extends Composer<_$AppDatabase, $FathersTable> {
  $$FathersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get fatherId => $composableBuilder(
    column: $table.fatherId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fatherName => $composableBuilder(
    column: $table.fatherName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FathersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FathersTable> {
  $$FathersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get fatherId =>
      $composableBuilder(column: $table.fatherId, builder: (column) => column);

  GeneratedColumn<String> get fatherName => $composableBuilder(
    column: $table.fatherName,
    builder: (column) => column,
  );
}

class $$FathersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FathersTable,
          Father,
          $$FathersTableFilterComposer,
          $$FathersTableOrderingComposer,
          $$FathersTableAnnotationComposer,
          $$FathersTableCreateCompanionBuilder,
          $$FathersTableUpdateCompanionBuilder,
          (Father, BaseReferences<_$AppDatabase, $FathersTable, Father>),
          Father,
          PrefetchHooks Function()
        > {
  $$FathersTableTableManager(_$AppDatabase db, $FathersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FathersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FathersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FathersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> fatherId = const Value.absent(),
                Value<String?> fatherName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FathersCompanion(
                fatherId: fatherId,
                fatherName: fatherName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int?> fatherId = const Value.absent(),
                Value<String?> fatherName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FathersCompanion.insert(
                fatherId: fatherId,
                fatherName: fatherName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FathersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FathersTable,
      Father,
      $$FathersTableFilterComposer,
      $$FathersTableOrderingComposer,
      $$FathersTableAnnotationComposer,
      $$FathersTableCreateCompanionBuilder,
      $$FathersTableUpdateCompanionBuilder,
      (Father, BaseReferences<_$AppDatabase, $FathersTable, Father>),
      Father,
      PrefetchHooks Function()
    >;
typedef $$JenderTableCreateCompanionBuilder =
    JenderCompanion Function({
      Value<int?> jenderId,
      Value<String?> jenderName,
      Value<int> rowid,
    });
typedef $$JenderTableUpdateCompanionBuilder =
    JenderCompanion Function({
      Value<int?> jenderId,
      Value<String?> jenderName,
      Value<int> rowid,
    });

class $$JenderTableFilterComposer
    extends Composer<_$AppDatabase, $JenderTable> {
  $$JenderTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get jenderId => $composableBuilder(
    column: $table.jenderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jenderName => $composableBuilder(
    column: $table.jenderName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JenderTableOrderingComposer
    extends Composer<_$AppDatabase, $JenderTable> {
  $$JenderTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get jenderId => $composableBuilder(
    column: $table.jenderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jenderName => $composableBuilder(
    column: $table.jenderName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JenderTableAnnotationComposer
    extends Composer<_$AppDatabase, $JenderTable> {
  $$JenderTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get jenderId =>
      $composableBuilder(column: $table.jenderId, builder: (column) => column);

  GeneratedColumn<String> get jenderName => $composableBuilder(
    column: $table.jenderName,
    builder: (column) => column,
  );
}

class $$JenderTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JenderTable,
          JenderData,
          $$JenderTableFilterComposer,
          $$JenderTableOrderingComposer,
          $$JenderTableAnnotationComposer,
          $$JenderTableCreateCompanionBuilder,
          $$JenderTableUpdateCompanionBuilder,
          (JenderData, BaseReferences<_$AppDatabase, $JenderTable, JenderData>),
          JenderData,
          PrefetchHooks Function()
        > {
  $$JenderTableTableManager(_$AppDatabase db, $JenderTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JenderTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JenderTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JenderTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> jenderId = const Value.absent(),
                Value<String?> jenderName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JenderCompanion(
                jenderId: jenderId,
                jenderName: jenderName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int?> jenderId = const Value.absent(),
                Value<String?> jenderName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JenderCompanion.insert(
                jenderId: jenderId,
                jenderName: jenderName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JenderTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JenderTable,
      JenderData,
      $$JenderTableFilterComposer,
      $$JenderTableOrderingComposer,
      $$JenderTableAnnotationComposer,
      $$JenderTableCreateCompanionBuilder,
      $$JenderTableUpdateCompanionBuilder,
      (JenderData, BaseReferences<_$AppDatabase, $JenderTable, JenderData>),
      JenderData,
      PrefetchHooks Function()
    >;
typedef $$PassTableCreateCompanionBuilder =
    PassCompanion Function({
      Value<int?> passId,
      Value<String?> passWord,
      Value<String?> personName,
      Value<int> rowid,
    });
typedef $$PassTableUpdateCompanionBuilder =
    PassCompanion Function({
      Value<int?> passId,
      Value<String?> passWord,
      Value<String?> personName,
      Value<int> rowid,
    });

class $$PassTableFilterComposer extends Composer<_$AppDatabase, $PassTable> {
  $$PassTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get passId => $composableBuilder(
    column: $table.passId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passWord => $composableBuilder(
    column: $table.passWord,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PassTableOrderingComposer extends Composer<_$AppDatabase, $PassTable> {
  $$PassTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get passId => $composableBuilder(
    column: $table.passId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passWord => $composableBuilder(
    column: $table.passWord,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PassTableAnnotationComposer
    extends Composer<_$AppDatabase, $PassTable> {
  $$PassTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get passId =>
      $composableBuilder(column: $table.passId, builder: (column) => column);

  GeneratedColumn<String> get passWord =>
      $composableBuilder(column: $table.passWord, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => column,
  );
}

class $$PassTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PassTable,
          PassData,
          $$PassTableFilterComposer,
          $$PassTableOrderingComposer,
          $$PassTableAnnotationComposer,
          $$PassTableCreateCompanionBuilder,
          $$PassTableUpdateCompanionBuilder,
          (PassData, BaseReferences<_$AppDatabase, $PassTable, PassData>),
          PassData,
          PrefetchHooks Function()
        > {
  $$PassTableTableManager(_$AppDatabase db, $PassTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PassTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PassTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PassTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> passId = const Value.absent(),
                Value<String?> passWord = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PassCompanion(
                passId: passId,
                passWord: passWord,
                personName: personName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int?> passId = const Value.absent(),
                Value<String?> passWord = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PassCompanion.insert(
                passId: passId,
                passWord: passWord,
                personName: personName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PassTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PassTable,
      PassData,
      $$PassTableFilterComposer,
      $$PassTableOrderingComposer,
      $$PassTableAnnotationComposer,
      $$PassTableCreateCompanionBuilder,
      $$PassTableUpdateCompanionBuilder,
      (PassData, BaseReferences<_$AppDatabase, $PassTable, PassData>),
      PassData,
      PrefetchHooks Function()
    >;
typedef $$PersonsTableCreateCompanionBuilder =
    PersonsCompanion Function({
      Value<int?> personId,
      Value<String?> personName,
      Value<int?> stageId,
      Value<int?> areaId,
      Value<String?> streetName,
      Value<String?> phone,
      Value<String?> mobile,
      Value<int?> day,
      Value<int?> month,
      Value<int?> year,
      Value<String?> jenderName,
      Value<int?> fatherId,
      Value<Uint8List?> photo,
      Value<int> rowid,
    });
typedef $$PersonsTableUpdateCompanionBuilder =
    PersonsCompanion Function({
      Value<int?> personId,
      Value<String?> personName,
      Value<int?> stageId,
      Value<int?> areaId,
      Value<String?> streetName,
      Value<String?> phone,
      Value<String?> mobile,
      Value<int?> day,
      Value<int?> month,
      Value<int?> year,
      Value<String?> jenderName,
      Value<int?> fatherId,
      Value<Uint8List?> photo,
      Value<int> rowid,
    });

class $$PersonsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streetName => $composableBuilder(
    column: $table.streetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jenderName => $composableBuilder(
    column: $table.jenderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fatherId => $composableBuilder(
    column: $table.fatherId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersonsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get areaId => $composableBuilder(
    column: $table.areaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streetName => $composableBuilder(
    column: $table.streetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jenderName => $composableBuilder(
    column: $table.jenderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fatherId => $composableBuilder(
    column: $table.fatherId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get photo => $composableBuilder(
    column: $table.photo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stageId =>
      $composableBuilder(column: $table.stageId, builder: (column) => column);

  GeneratedColumn<int> get areaId =>
      $composableBuilder(column: $table.areaId, builder: (column) => column);

  GeneratedColumn<String> get streetName => $composableBuilder(
    column: $table.streetName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get jenderName => $composableBuilder(
    column: $table.jenderName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fatherId =>
      $composableBuilder(column: $table.fatherId, builder: (column) => column);

  GeneratedColumn<Uint8List> get photo =>
      $composableBuilder(column: $table.photo, builder: (column) => column);
}

class $$PersonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonsTable,
          Person,
          $$PersonsTableFilterComposer,
          $$PersonsTableOrderingComposer,
          $$PersonsTableAnnotationComposer,
          $$PersonsTableCreateCompanionBuilder,
          $$PersonsTableUpdateCompanionBuilder,
          (Person, BaseReferences<_$AppDatabase, $PersonsTable, Person>),
          Person,
          PrefetchHooks Function()
        > {
  $$PersonsTableTableManager(_$AppDatabase db, $PersonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> personId = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<int?> stageId = const Value.absent(),
                Value<int?> areaId = const Value.absent(),
                Value<String?> streetName = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<int?> day = const Value.absent(),
                Value<int?> month = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> jenderName = const Value.absent(),
                Value<int?> fatherId = const Value.absent(),
                Value<Uint8List?> photo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonsCompanion(
                personId: personId,
                personName: personName,
                stageId: stageId,
                areaId: areaId,
                streetName: streetName,
                phone: phone,
                mobile: mobile,
                day: day,
                month: month,
                year: year,
                jenderName: jenderName,
                fatherId: fatherId,
                photo: photo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int?> personId = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<int?> stageId = const Value.absent(),
                Value<int?> areaId = const Value.absent(),
                Value<String?> streetName = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<int?> day = const Value.absent(),
                Value<int?> month = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> jenderName = const Value.absent(),
                Value<int?> fatherId = const Value.absent(),
                Value<Uint8List?> photo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonsCompanion.insert(
                personId: personId,
                personName: personName,
                stageId: stageId,
                areaId: areaId,
                streetName: streetName,
                phone: phone,
                mobile: mobile,
                day: day,
                month: month,
                year: year,
                jenderName: jenderName,
                fatherId: fatherId,
                photo: photo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonsTable,
      Person,
      $$PersonsTableFilterComposer,
      $$PersonsTableOrderingComposer,
      $$PersonsTableAnnotationComposer,
      $$PersonsTableCreateCompanionBuilder,
      $$PersonsTableUpdateCompanionBuilder,
      (Person, BaseReferences<_$AppDatabase, $PersonsTable, Person>),
      Person,
      PrefetchHooks Function()
    >;
typedef $$StagesTableCreateCompanionBuilder =
    StagesCompanion Function({
      Value<int?> stageId,
      Value<String?> stageName,
      Value<int> rowid,
    });
typedef $$StagesTableUpdateCompanionBuilder =
    StagesCompanion Function({
      Value<int?> stageId,
      Value<String?> stageName,
      Value<int> rowid,
    });

class $$StagesTableFilterComposer
    extends Composer<_$AppDatabase, $StagesTable> {
  $$StagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stageName => $composableBuilder(
    column: $table.stageName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StagesTableOrderingComposer
    extends Composer<_$AppDatabase, $StagesTable> {
  $$StagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get stageId => $composableBuilder(
    column: $table.stageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stageName => $composableBuilder(
    column: $table.stageName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StagesTable> {
  $$StagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get stageId =>
      $composableBuilder(column: $table.stageId, builder: (column) => column);

  GeneratedColumn<String> get stageName =>
      $composableBuilder(column: $table.stageName, builder: (column) => column);
}

class $$StagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StagesTable,
          Stage,
          $$StagesTableFilterComposer,
          $$StagesTableOrderingComposer,
          $$StagesTableAnnotationComposer,
          $$StagesTableCreateCompanionBuilder,
          $$StagesTableUpdateCompanionBuilder,
          (Stage, BaseReferences<_$AppDatabase, $StagesTable, Stage>),
          Stage,
          PrefetchHooks Function()
        > {
  $$StagesTableTableManager(_$AppDatabase db, $StagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> stageId = const Value.absent(),
                Value<String?> stageName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StagesCompanion(
                stageId: stageId,
                stageName: stageName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int?> stageId = const Value.absent(),
                Value<String?> stageName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StagesCompanion.insert(
                stageId: stageId,
                stageName: stageName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StagesTable,
      Stage,
      $$StagesTableFilterComposer,
      $$StagesTableOrderingComposer,
      $$StagesTableAnnotationComposer,
      $$StagesTableCreateCompanionBuilder,
      $$StagesTableUpdateCompanionBuilder,
      (Stage, BaseReferences<_$AppDatabase, $StagesTable, Stage>),
      Stage,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AbsentPersonsTableTableManager get absentPersons =>
      $$AbsentPersonsTableTableManager(_db, _db.absentPersons);
  $$AbsentPrintTableTableManager get absentPrint =>
      $$AbsentPrintTableTableManager(_db, _db.absentPrint);
  $$AddingTableTableManager get adding =>
      $$AddingTableTableManager(_db, _db.adding);
  $$AreasTableTableManager get areas =>
      $$AreasTableTableManager(_db, _db.areas);
  $$ComingTableTableManager get coming =>
      $$ComingTableTableManager(_db, _db.coming);
  $$CreditTableTableManager get credit =>
      $$CreditTableTableManager(_db, _db.credit);
  $$FathersTableTableManager get fathers =>
      $$FathersTableTableManager(_db, _db.fathers);
  $$JenderTableTableManager get jender =>
      $$JenderTableTableManager(_db, _db.jender);
  $$PassTableTableManager get pass => $$PassTableTableManager(_db, _db.pass);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db, _db.persons);
  $$StagesTableTableManager get stages =>
      $$StagesTableTableManager(_db, _db.stages);
}
