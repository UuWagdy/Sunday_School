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
    'ID',
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
    'Person_ID',
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
    'Person_Name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
    'Stage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _month1Meta = const VerificationMeta('month1');
  @override
  late final GeneratedColumn<String> month1 = GeneratedColumn<String>(
    'Month_1',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstMeta = const VerificationMeta('first');
  @override
  late final GeneratedColumn<String> first = GeneratedColumn<String>(
    'First',
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
    'Forth',
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
  static const String $name = 'Absent_Persons';
  @override
  VerificationContext validateIntegrity(
    Insertable<AbsentPerson> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ID')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['ID']!, _idMeta));
    }
    if (data.containsKey('Person_ID')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['Person_ID']!, _personIdMeta),
      );
    }
    if (data.containsKey('Person_Name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['Person_Name']!, _personNameMeta),
      );
    }
    if (data.containsKey('Stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['Stage']!, _stageMeta),
      );
    }
    if (data.containsKey('Month_1')) {
      context.handle(
        _month1Meta,
        month1.isAcceptableOrUnknown(data['Month_1']!, _month1Meta),
      );
    }
    if (data.containsKey('First')) {
      context.handle(
        _firstMeta,
        first.isAcceptableOrUnknown(data['First']!, _firstMeta),
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
    if (data.containsKey('Forth')) {
      context.handle(
        _forthMeta,
        forth.isAcceptableOrUnknown(data['Forth']!, _forthMeta),
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
        data['${effectivePrefix}ID'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Person_ID'],
      ),
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Person_Name'],
      ),
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Stage'],
      ),
      month1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Month_1'],
      ),
      first: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}First'],
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
        data['${effectivePrefix}Forth'],
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
      map['ID'] = Variable<int>(id);
    }
    if (!nullToAbsent || personId != null) {
      map['Person_ID'] = Variable<int>(personId);
    }
    if (!nullToAbsent || personName != null) {
      map['Person_Name'] = Variable<String>(personName);
    }
    if (!nullToAbsent || stage != null) {
      map['Stage'] = Variable<String>(stage);
    }
    if (!nullToAbsent || month1 != null) {
      map['Month_1'] = Variable<String>(month1);
    }
    if (!nullToAbsent || first != null) {
      map['First'] = Variable<String>(first);
    }
    if (!nullToAbsent || second != null) {
      map['second'] = Variable<String>(second);
    }
    if (!nullToAbsent || third != null) {
      map['third'] = Variable<String>(third);
    }
    if (!nullToAbsent || forth != null) {
      map['Forth'] = Variable<String>(forth);
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
      if (id != null) 'ID': id,
      if (personId != null) 'Person_ID': personId,
      if (personName != null) 'Person_Name': personName,
      if (stage != null) 'Stage': stage,
      if (month1 != null) 'Month_1': month1,
      if (first != null) 'First': first,
      if (second != null) 'second': second,
      if (third != null) 'third': third,
      if (forth != null) 'Forth': forth,
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
      map['ID'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['Person_ID'] = Variable<int>(personId.value);
    }
    if (personName.present) {
      map['Person_Name'] = Variable<String>(personName.value);
    }
    if (stage.present) {
      map['Stage'] = Variable<String>(stage.value);
    }
    if (month1.present) {
      map['Month_1'] = Variable<String>(month1.value);
    }
    if (first.present) {
      map['First'] = Variable<String>(first.value);
    }
    if (second.present) {
      map['second'] = Variable<String>(second.value);
    }
    if (third.present) {
      map['third'] = Variable<String>(third.value);
    }
    if (forth.present) {
      map['Forth'] = Variable<String>(forth.value);
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
    'ID',
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
    'Person_ID',
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
    'Person_Name',
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
    'Stage_ID',
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
    'Stage_Name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _khorosIdMeta = const VerificationMeta(
    'khorosId',
  );
  @override
  late final GeneratedColumn<int> khorosId = GeneratedColumn<int>(
    'Khoros_ID',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _khorosNameMeta = const VerificationMeta(
    'khorosName',
  );
  @override
  late final GeneratedColumn<String> khorosName = GeneratedColumn<String>(
    'Khoros_Name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaIdMeta = const VerificationMeta('areaId');
  @override
  late final GeneratedColumn<int> areaId = GeneratedColumn<int>(
    'Area_ID',
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
    'Area_Name',
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
    'Street_Name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'Phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
    'Mobile',
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
    'Date_From',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateToMeta = const VerificationMeta('dateTo');
  @override
  late final GeneratedColumn<String> dateTo = GeneratedColumn<String>(
    'Date_To',
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
    khorosId,
    khorosName,
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
  static const String $name = 'Absent_Print';
  @override
  VerificationContext validateIntegrity(
    Insertable<AbsentPrintData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ID')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['ID']!, _idMeta));
    }
    if (data.containsKey('Person_ID')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['Person_ID']!, _personIdMeta),
      );
    }
    if (data.containsKey('Person_Name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['Person_Name']!, _personNameMeta),
      );
    }
    if (data.containsKey('Stage_ID')) {
      context.handle(
        _stageIdMeta,
        stageId.isAcceptableOrUnknown(data['Stage_ID']!, _stageIdMeta),
      );
    }
    if (data.containsKey('Stage_Name')) {
      context.handle(
        _stageNameMeta,
        stageName.isAcceptableOrUnknown(data['Stage_Name']!, _stageNameMeta),
      );
    }
    if (data.containsKey('Khoros_ID')) {
      context.handle(
        _khorosIdMeta,
        khorosId.isAcceptableOrUnknown(data['Khoros_ID']!, _khorosIdMeta),
      );
    }
    if (data.containsKey('Khoros_Name')) {
      context.handle(
        _khorosNameMeta,
        khorosName.isAcceptableOrUnknown(data['Khoros_Name']!, _khorosNameMeta),
      );
    }
    if (data.containsKey('Area_ID')) {
      context.handle(
        _areaIdMeta,
        areaId.isAcceptableOrUnknown(data['Area_ID']!, _areaIdMeta),
      );
    }
    if (data.containsKey('Area_Name')) {
      context.handle(
        _areaNameMeta,
        areaName.isAcceptableOrUnknown(data['Area_Name']!, _areaNameMeta),
      );
    }
    if (data.containsKey('Street_Name')) {
      context.handle(
        _streetNameMeta,
        streetName.isAcceptableOrUnknown(data['Street_Name']!, _streetNameMeta),
      );
    }
    if (data.containsKey('Phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['Phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('Mobile')) {
      context.handle(
        _mobileMeta,
        mobile.isAcceptableOrUnknown(data['Mobile']!, _mobileMeta),
      );
    }
    if (data.containsKey('Date_From')) {
      context.handle(
        _dateFromMeta,
        dateFrom.isAcceptableOrUnknown(data['Date_From']!, _dateFromMeta),
      );
    }
    if (data.containsKey('Date_To')) {
      context.handle(
        _dateToMeta,
        dateTo.isAcceptableOrUnknown(data['Date_To']!, _dateToMeta),
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
        data['${effectivePrefix}ID'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Person_ID'],
      ),
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Person_Name'],
      ),
      stageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Stage_ID'],
      ),
      stageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Stage_Name'],
      ),
      khorosId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Khoros_ID'],
      ),
      khorosName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Khoros_Name'],
      ),
      areaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Area_ID'],
      ),
      areaName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Area_Name'],
      ),
      streetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Street_Name'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Phone'],
      ),
      mobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Mobile'],
      ),
      dateFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Date_From'],
      ),
      dateTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Date_To'],
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
  final int? khorosId;
  final String? khorosName;
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
    this.khorosId,
    this.khorosName,
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
      map['ID'] = Variable<int>(id);
    }
    if (!nullToAbsent || personId != null) {
      map['Person_ID'] = Variable<int>(personId);
    }
    if (!nullToAbsent || personName != null) {
      map['Person_Name'] = Variable<String>(personName);
    }
    if (!nullToAbsent || stageId != null) {
      map['Stage_ID'] = Variable<int>(stageId);
    }
    if (!nullToAbsent || stageName != null) {
      map['Stage_Name'] = Variable<String>(stageName);
    }
    if (!nullToAbsent || khorosId != null) {
      map['Khoros_ID'] = Variable<int>(khorosId);
    }
    if (!nullToAbsent || khorosName != null) {
      map['Khoros_Name'] = Variable<String>(khorosName);
    }
    if (!nullToAbsent || areaId != null) {
      map['Area_ID'] = Variable<int>(areaId);
    }
    if (!nullToAbsent || areaName != null) {
      map['Area_Name'] = Variable<String>(areaName);
    }
    if (!nullToAbsent || streetName != null) {
      map['Street_Name'] = Variable<String>(streetName);
    }
    if (!nullToAbsent || phone != null) {
      map['Phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || mobile != null) {
      map['Mobile'] = Variable<String>(mobile);
    }
    if (!nullToAbsent || dateFrom != null) {
      map['Date_From'] = Variable<String>(dateFrom);
    }
    if (!nullToAbsent || dateTo != null) {
      map['Date_To'] = Variable<String>(dateTo);
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
      khorosId: khorosId == null && nullToAbsent
          ? const Value.absent()
          : Value(khorosId),
      khorosName: khorosName == null && nullToAbsent
          ? const Value.absent()
          : Value(khorosName),
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
      khorosId: serializer.fromJson<int?>(json['khorosId']),
      khorosName: serializer.fromJson<String?>(json['khorosName']),
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
      'khorosId': serializer.toJson<int?>(khorosId),
      'khorosName': serializer.toJson<String?>(khorosName),
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
    Value<int?> khorosId = const Value.absent(),
    Value<String?> khorosName = const Value.absent(),
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
    khorosId: khorosId.present ? khorosId.value : this.khorosId,
    khorosName: khorosName.present ? khorosName.value : this.khorosName,
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
      khorosId: data.khorosId.present ? data.khorosId.value : this.khorosId,
      khorosName: data.khorosName.present
          ? data.khorosName.value
          : this.khorosName,
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
          ..write('khorosId: $khorosId, ')
          ..write('khorosName: $khorosName, ')
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
    khorosId,
    khorosName,
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
          other.khorosId == this.khorosId &&
          other.khorosName == this.khorosName &&
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
  final Value<int?> khorosId;
  final Value<String?> khorosName;
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
    this.khorosId = const Value.absent(),
    this.khorosName = const Value.absent(),
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
    this.khorosId = const Value.absent(),
    this.khorosName = const Value.absent(),
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
    Expression<int>? khorosId,
    Expression<String>? khorosName,
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
      if (id != null) 'ID': id,
      if (personId != null) 'Person_ID': personId,
      if (personName != null) 'Person_Name': personName,
      if (stageId != null) 'Stage_ID': stageId,
      if (stageName != null) 'Stage_Name': stageName,
      if (khorosId != null) 'Khoros_ID': khorosId,
      if (khorosName != null) 'Khoros_Name': khorosName,
      if (areaId != null) 'Area_ID': areaId,
      if (areaName != null) 'Area_Name': areaName,
      if (streetName != null) 'Street_Name': streetName,
      if (phone != null) 'Phone': phone,
      if (mobile != null) 'Mobile': mobile,
      if (dateFrom != null) 'Date_From': dateFrom,
      if (dateTo != null) 'Date_To': dateTo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AbsentPrintCompanion copyWith({
    Value<int?>? id,
    Value<int?>? personId,
    Value<String?>? personName,
    Value<int?>? stageId,
    Value<String?>? stageName,
    Value<int?>? khorosId,
    Value<String?>? khorosName,
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
      khorosId: khorosId ?? this.khorosId,
      khorosName: khorosName ?? this.khorosName,
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
      map['ID'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['Person_ID'] = Variable<int>(personId.value);
    }
    if (personName.present) {
      map['Person_Name'] = Variable<String>(personName.value);
    }
    if (stageId.present) {
      map['Stage_ID'] = Variable<int>(stageId.value);
    }
    if (stageName.present) {
      map['Stage_Name'] = Variable<String>(stageName.value);
    }
    if (khorosId.present) {
      map['Khoros_ID'] = Variable<int>(khorosId.value);
    }
    if (khorosName.present) {
      map['Khoros_Name'] = Variable<String>(khorosName.value);
    }
    if (areaId.present) {
      map['Area_ID'] = Variable<int>(areaId.value);
    }
    if (areaName.present) {
      map['Area_Name'] = Variable<String>(areaName.value);
    }
    if (streetName.present) {
      map['Street_Name'] = Variable<String>(streetName.value);
    }
    if (phone.present) {
      map['Phone'] = Variable<String>(phone.value);
    }
    if (mobile.present) {
      map['Mobile'] = Variable<String>(mobile.value);
    }
    if (dateFrom.present) {
      map['Date_From'] = Variable<String>(dateFrom.value);
    }
    if (dateTo.present) {
      map['Date_To'] = Variable<String>(dateTo.value);
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
          ..write('khorosId: $khorosId, ')
          ..write('khorosName: $khorosName, ')
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
    'Date_ID',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'Date',
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
  static const String $name = 'Adding';
  @override
  VerificationContext validateIntegrity(
    Insertable<AddingData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Date_ID')) {
      context.handle(
        _dateIdMeta,
        dateId.isAcceptableOrUnknown(data['Date_ID']!, _dateIdMeta),
      );
    }
    if (data.containsKey('Date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['Date']!, _dateMeta),
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
        data['${effectivePrefix}Date_ID'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Date'],
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
      map['Date_ID'] = Variable<int>(dateId);
    }
    if (!nullToAbsent || date != null) {
      map['Date'] = Variable<String>(date);
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
      if (dateId != null) 'Date_ID': dateId,
      if (date != null) 'Date': date,
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
      map['Date_ID'] = Variable<int>(dateId.value);
    }
    if (date.present) {
      map['Date'] = Variable<String>(date.value);
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
    'Area_ID',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _areaNameMeta = const VerificationMeta(
    'areaName',
  );
  @override
  late final GeneratedColumn<String> areaName = GeneratedColumn<String>(
    'Area_Name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'Parent_ID',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'Level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _areaPathMeta = const VerificationMeta(
    'areaPath',
  );
  @override
  late final GeneratedColumn<String> areaPath = GeneratedColumn<String>(
    'Area_Path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    areaId,
    areaName,
    parentId,
    level,
    areaPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Area> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Area_ID')) {
      context.handle(
        _areaIdMeta,
        areaId.isAcceptableOrUnknown(data['Area_ID']!, _areaIdMeta),
      );
    }
    if (data.containsKey('Area_Name')) {
      context.handle(
        _areaNameMeta,
        areaName.isAcceptableOrUnknown(data['Area_Name']!, _areaNameMeta),
      );
    }
    if (data.containsKey('Parent_ID')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['Parent_ID']!, _parentIdMeta),
      );
    }
    if (data.containsKey('Level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['Level']!, _levelMeta),
      );
    }
    if (data.containsKey('Area_Path')) {
      context.handle(
        _areaPathMeta,
        areaPath.isAcceptableOrUnknown(data['Area_Path']!, _areaPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {areaId};
  @override
  Area map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Area(
      areaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Area_ID'],
      )!,
      areaName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Area_Name'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Parent_ID'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Level'],
      )!,
      areaPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Area_Path'],
      ),
    );
  }

  @override
  $AreasTable createAlias(String alias) {
    return $AreasTable(attachedDatabase, alias);
  }
}

class Area extends DataClass implements Insertable<Area> {
  final int areaId;
  final String? areaName;
  final int? parentId;
  final int level;
  final String? areaPath;
  const Area({
    required this.areaId,
    this.areaName,
    this.parentId,
    required this.level,
    this.areaPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Area_ID'] = Variable<int>(areaId);
    if (!nullToAbsent || areaName != null) {
      map['Area_Name'] = Variable<String>(areaName);
    }
    if (!nullToAbsent || parentId != null) {
      map['Parent_ID'] = Variable<int>(parentId);
    }
    map['Level'] = Variable<int>(level);
    if (!nullToAbsent || areaPath != null) {
      map['Area_Path'] = Variable<String>(areaPath);
    }
    return map;
  }

  AreasCompanion toCompanion(bool nullToAbsent) {
    return AreasCompanion(
      areaId: Value(areaId),
      areaName: areaName == null && nullToAbsent
          ? const Value.absent()
          : Value(areaName),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      level: Value(level),
      areaPath: areaPath == null && nullToAbsent
          ? const Value.absent()
          : Value(areaPath),
    );
  }

  factory Area.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Area(
      areaId: serializer.fromJson<int>(json['areaId']),
      areaName: serializer.fromJson<String?>(json['areaName']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      level: serializer.fromJson<int>(json['level']),
      areaPath: serializer.fromJson<String?>(json['areaPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'areaId': serializer.toJson<int>(areaId),
      'areaName': serializer.toJson<String?>(areaName),
      'parentId': serializer.toJson<int?>(parentId),
      'level': serializer.toJson<int>(level),
      'areaPath': serializer.toJson<String?>(areaPath),
    };
  }

  Area copyWith({
    int? areaId,
    Value<String?> areaName = const Value.absent(),
    Value<int?> parentId = const Value.absent(),
    int? level,
    Value<String?> areaPath = const Value.absent(),
  }) => Area(
    areaId: areaId ?? this.areaId,
    areaName: areaName.present ? areaName.value : this.areaName,
    parentId: parentId.present ? parentId.value : this.parentId,
    level: level ?? this.level,
    areaPath: areaPath.present ? areaPath.value : this.areaPath,
  );
  Area copyWithCompanion(AreasCompanion data) {
    return Area(
      areaId: data.areaId.present ? data.areaId.value : this.areaId,
      areaName: data.areaName.present ? data.areaName.value : this.areaName,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      level: data.level.present ? data.level.value : this.level,
      areaPath: data.areaPath.present ? data.areaPath.value : this.areaPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Area(')
          ..write('areaId: $areaId, ')
          ..write('areaName: $areaName, ')
          ..write('parentId: $parentId, ')
          ..write('level: $level, ')
          ..write('areaPath: $areaPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(areaId, areaName, parentId, level, areaPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Area &&
          other.areaId == this.areaId &&
          other.areaName == this.areaName &&
          other.parentId == this.parentId &&
          other.level == this.level &&
          other.areaPath == this.areaPath);
}

class AreasCompanion extends UpdateCompanion<Area> {
  final Value<int> areaId;
  final Value<String?> areaName;
  final Value<int?> parentId;
  final Value<int> level;
  final Value<String?> areaPath;
  const AreasCompanion({
    this.areaId = const Value.absent(),
    this.areaName = const Value.absent(),
    this.parentId = const Value.absent(),
    this.level = const Value.absent(),
    this.areaPath = const Value.absent(),
  });
  AreasCompanion.insert({
    this.areaId = const Value.absent(),
    this.areaName = const Value.absent(),
    this.parentId = const Value.absent(),
    this.level = const Value.absent(),
    this.areaPath = const Value.absent(),
  });
  static Insertable<Area> custom({
    Expression<int>? areaId,
    Expression<String>? areaName,
    Expression<int>? parentId,
    Expression<int>? level,
    Expression<String>? areaPath,
  }) {
    return RawValuesInsertable({
      if (areaId != null) 'Area_ID': areaId,
      if (areaName != null) 'Area_Name': areaName,
      if (parentId != null) 'Parent_ID': parentId,
      if (level != null) 'Level': level,
      if (areaPath != null) 'Area_Path': areaPath,
    });
  }

  AreasCompanion copyWith({
    Value<int>? areaId,
    Value<String?>? areaName,
    Value<int?>? parentId,
    Value<int>? level,
    Value<String?>? areaPath,
  }) {
    return AreasCompanion(
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      areaPath: areaPath ?? this.areaPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (areaId.present) {
      map['Area_ID'] = Variable<int>(areaId.value);
    }
    if (areaName.present) {
      map['Area_Name'] = Variable<String>(areaName.value);
    }
    if (parentId.present) {
      map['Parent_ID'] = Variable<int>(parentId.value);
    }
    if (level.present) {
      map['Level'] = Variable<int>(level.value);
    }
    if (areaPath.present) {
      map['Area_Path'] = Variable<String>(areaPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AreasCompanion(')
          ..write('areaId: $areaId, ')
          ..write('areaName: $areaName, ')
          ..write('parentId: $parentId, ')
          ..write('level: $level, ')
          ..write('areaPath: $areaPath')
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
    'Id',
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
    'Person_ID',
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
    'date_Week',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pointMeta = const VerificationMeta('point');
  @override
  late final GeneratedColumn<int> point = GeneratedColumn<int>(
    'Point',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mont1Meta = const VerificationMeta('mont1');
  @override
  late final GeneratedColumn<int> mont1 = GeneratedColumn<int>(
    'Mont_1',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _year1Meta = const VerificationMeta('year1');
  @override
  late final GeneratedColumn<int> year1 = GeneratedColumn<int>(
    'Year_1',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<int> serviceId = GeneratedColumn<int>(
    'Service_ID',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attendTimeMeta = const VerificationMeta(
    'attendTime',
  );
  @override
  late final GeneratedColumn<String> attendTime = GeneratedColumn<String>(
    'Attend_Time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkoutTimeMeta = const VerificationMeta(
    'checkoutTime',
  );
  @override
  late final GeneratedColumn<String> checkoutTime = GeneratedColumn<String>(
    'Checkout_Time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visitedMeta = const VerificationMeta(
    'visited',
  );
  @override
  late final GeneratedColumn<int> visited = GeneratedColumn<int>(
    'Visited',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visitNotesMeta = const VerificationMeta(
    'visitNotes',
  );
  @override
  late final GeneratedColumn<String> visitNotes = GeneratedColumn<String>(
    'Visit_Notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _behaviorMeta = const VerificationMeta(
    'behavior',
  );
  @override
  late final GeneratedColumn<int> behavior = GeneratedColumn<int>(
    'Behavior',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    dateWeek,
    point,
    mont1,
    year1,
    serviceId,
    attendTime,
    checkoutTime,
    visited,
    visitNotes,
    behavior,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Coming';
  @override
  VerificationContext validateIntegrity(
    Insertable<ComingData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['Id']!, _idMeta));
    }
    if (data.containsKey('Person_ID')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['Person_ID']!, _personIdMeta),
      );
    }
    if (data.containsKey('date_Week')) {
      context.handle(
        _dateWeekMeta,
        dateWeek.isAcceptableOrUnknown(data['date_Week']!, _dateWeekMeta),
      );
    }
    if (data.containsKey('Point')) {
      context.handle(
        _pointMeta,
        point.isAcceptableOrUnknown(data['Point']!, _pointMeta),
      );
    }
    if (data.containsKey('Mont_1')) {
      context.handle(
        _mont1Meta,
        mont1.isAcceptableOrUnknown(data['Mont_1']!, _mont1Meta),
      );
    }
    if (data.containsKey('Year_1')) {
      context.handle(
        _year1Meta,
        year1.isAcceptableOrUnknown(data['Year_1']!, _year1Meta),
      );
    }
    if (data.containsKey('Service_ID')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['Service_ID']!, _serviceIdMeta),
      );
    }
    if (data.containsKey('Attend_Time')) {
      context.handle(
        _attendTimeMeta,
        attendTime.isAcceptableOrUnknown(data['Attend_Time']!, _attendTimeMeta),
      );
    }
    if (data.containsKey('Checkout_Time')) {
      context.handle(
        _checkoutTimeMeta,
        checkoutTime.isAcceptableOrUnknown(
          data['Checkout_Time']!,
          _checkoutTimeMeta,
        ),
      );
    }
    if (data.containsKey('Visited')) {
      context.handle(
        _visitedMeta,
        visited.isAcceptableOrUnknown(data['Visited']!, _visitedMeta),
      );
    }
    if (data.containsKey('Visit_Notes')) {
      context.handle(
        _visitNotesMeta,
        visitNotes.isAcceptableOrUnknown(data['Visit_Notes']!, _visitNotesMeta),
      );
    }
    if (data.containsKey('Behavior')) {
      context.handle(
        _behaviorMeta,
        behavior.isAcceptableOrUnknown(data['Behavior']!, _behaviorMeta),
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
        data['${effectivePrefix}Id'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Person_ID'],
      ),
      dateWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_Week'],
      ),
      point: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Point'],
      ),
      mont1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Mont_1'],
      ),
      year1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Year_1'],
      ),
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Service_ID'],
      ),
      attendTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Attend_Time'],
      ),
      checkoutTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Checkout_Time'],
      ),
      visited: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Visited'],
      ),
      visitNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Visit_Notes'],
      ),
      behavior: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Behavior'],
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
  final int? serviceId;
  final String? attendTime;
  final String? checkoutTime;
  final int? visited;
  final String? visitNotes;
  final int? behavior;
  const ComingData({
    this.id,
    this.personId,
    this.dateWeek,
    this.point,
    this.mont1,
    this.year1,
    this.serviceId,
    this.attendTime,
    this.checkoutTime,
    this.visited,
    this.visitNotes,
    this.behavior,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['Id'] = Variable<int>(id);
    }
    if (!nullToAbsent || personId != null) {
      map['Person_ID'] = Variable<int>(personId);
    }
    if (!nullToAbsent || dateWeek != null) {
      map['date_Week'] = Variable<String>(dateWeek);
    }
    if (!nullToAbsent || point != null) {
      map['Point'] = Variable<int>(point);
    }
    if (!nullToAbsent || mont1 != null) {
      map['Mont_1'] = Variable<int>(mont1);
    }
    if (!nullToAbsent || year1 != null) {
      map['Year_1'] = Variable<int>(year1);
    }
    if (!nullToAbsent || serviceId != null) {
      map['Service_ID'] = Variable<int>(serviceId);
    }
    if (!nullToAbsent || attendTime != null) {
      map['Attend_Time'] = Variable<String>(attendTime);
    }
    if (!nullToAbsent || checkoutTime != null) {
      map['Checkout_Time'] = Variable<String>(checkoutTime);
    }
    if (!nullToAbsent || visited != null) {
      map['Visited'] = Variable<int>(visited);
    }
    if (!nullToAbsent || visitNotes != null) {
      map['Visit_Notes'] = Variable<String>(visitNotes);
    }
    if (!nullToAbsent || behavior != null) {
      map['Behavior'] = Variable<int>(behavior);
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
      serviceId: serviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceId),
      attendTime: attendTime == null && nullToAbsent
          ? const Value.absent()
          : Value(attendTime),
      checkoutTime: checkoutTime == null && nullToAbsent
          ? const Value.absent()
          : Value(checkoutTime),
      visited: visited == null && nullToAbsent
          ? const Value.absent()
          : Value(visited),
      visitNotes: visitNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(visitNotes),
      behavior: behavior == null && nullToAbsent
          ? const Value.absent()
          : Value(behavior),
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
      serviceId: serializer.fromJson<int?>(json['serviceId']),
      attendTime: serializer.fromJson<String?>(json['attendTime']),
      checkoutTime: serializer.fromJson<String?>(json['checkoutTime']),
      visited: serializer.fromJson<int?>(json['visited']),
      visitNotes: serializer.fromJson<String?>(json['visitNotes']),
      behavior: serializer.fromJson<int?>(json['behavior']),
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
      'serviceId': serializer.toJson<int?>(serviceId),
      'attendTime': serializer.toJson<String?>(attendTime),
      'checkoutTime': serializer.toJson<String?>(checkoutTime),
      'visited': serializer.toJson<int?>(visited),
      'visitNotes': serializer.toJson<String?>(visitNotes),
      'behavior': serializer.toJson<int?>(behavior),
    };
  }

  ComingData copyWith({
    Value<int?> id = const Value.absent(),
    Value<int?> personId = const Value.absent(),
    Value<String?> dateWeek = const Value.absent(),
    Value<int?> point = const Value.absent(),
    Value<int?> mont1 = const Value.absent(),
    Value<int?> year1 = const Value.absent(),
    Value<int?> serviceId = const Value.absent(),
    Value<String?> attendTime = const Value.absent(),
    Value<String?> checkoutTime = const Value.absent(),
    Value<int?> visited = const Value.absent(),
    Value<String?> visitNotes = const Value.absent(),
    Value<int?> behavior = const Value.absent(),
  }) => ComingData(
    id: id.present ? id.value : this.id,
    personId: personId.present ? personId.value : this.personId,
    dateWeek: dateWeek.present ? dateWeek.value : this.dateWeek,
    point: point.present ? point.value : this.point,
    mont1: mont1.present ? mont1.value : this.mont1,
    year1: year1.present ? year1.value : this.year1,
    serviceId: serviceId.present ? serviceId.value : this.serviceId,
    attendTime: attendTime.present ? attendTime.value : this.attendTime,
    checkoutTime: checkoutTime.present ? checkoutTime.value : this.checkoutTime,
    visited: visited.present ? visited.value : this.visited,
    visitNotes: visitNotes.present ? visitNotes.value : this.visitNotes,
    behavior: behavior.present ? behavior.value : this.behavior,
  );
  ComingData copyWithCompanion(ComingCompanion data) {
    return ComingData(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      dateWeek: data.dateWeek.present ? data.dateWeek.value : this.dateWeek,
      point: data.point.present ? data.point.value : this.point,
      mont1: data.mont1.present ? data.mont1.value : this.mont1,
      year1: data.year1.present ? data.year1.value : this.year1,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      attendTime: data.attendTime.present
          ? data.attendTime.value
          : this.attendTime,
      checkoutTime: data.checkoutTime.present
          ? data.checkoutTime.value
          : this.checkoutTime,
      visited: data.visited.present ? data.visited.value : this.visited,
      visitNotes: data.visitNotes.present
          ? data.visitNotes.value
          : this.visitNotes,
      behavior: data.behavior.present ? data.behavior.value : this.behavior,
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
          ..write('year1: $year1, ')
          ..write('serviceId: $serviceId, ')
          ..write('attendTime: $attendTime, ')
          ..write('checkoutTime: $checkoutTime, ')
          ..write('visited: $visited, ')
          ..write('visitNotes: $visitNotes, ')
          ..write('behavior: $behavior')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    dateWeek,
    point,
    mont1,
    year1,
    serviceId,
    attendTime,
    checkoutTime,
    visited,
    visitNotes,
    behavior,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ComingData &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.dateWeek == this.dateWeek &&
          other.point == this.point &&
          other.mont1 == this.mont1 &&
          other.year1 == this.year1 &&
          other.serviceId == this.serviceId &&
          other.attendTime == this.attendTime &&
          other.checkoutTime == this.checkoutTime &&
          other.visited == this.visited &&
          other.visitNotes == this.visitNotes &&
          other.behavior == this.behavior);
}

class ComingCompanion extends UpdateCompanion<ComingData> {
  final Value<int?> id;
  final Value<int?> personId;
  final Value<String?> dateWeek;
  final Value<int?> point;
  final Value<int?> mont1;
  final Value<int?> year1;
  final Value<int?> serviceId;
  final Value<String?> attendTime;
  final Value<String?> checkoutTime;
  final Value<int?> visited;
  final Value<String?> visitNotes;
  final Value<int?> behavior;
  final Value<int> rowid;
  const ComingCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.dateWeek = const Value.absent(),
    this.point = const Value.absent(),
    this.mont1 = const Value.absent(),
    this.year1 = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.attendTime = const Value.absent(),
    this.checkoutTime = const Value.absent(),
    this.visited = const Value.absent(),
    this.visitNotes = const Value.absent(),
    this.behavior = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComingCompanion.insert({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.dateWeek = const Value.absent(),
    this.point = const Value.absent(),
    this.mont1 = const Value.absent(),
    this.year1 = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.attendTime = const Value.absent(),
    this.checkoutTime = const Value.absent(),
    this.visited = const Value.absent(),
    this.visitNotes = const Value.absent(),
    this.behavior = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<ComingData> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<String>? dateWeek,
    Expression<int>? point,
    Expression<int>? mont1,
    Expression<int>? year1,
    Expression<int>? serviceId,
    Expression<String>? attendTime,
    Expression<String>? checkoutTime,
    Expression<int>? visited,
    Expression<String>? visitNotes,
    Expression<int>? behavior,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'Id': id,
      if (personId != null) 'Person_ID': personId,
      if (dateWeek != null) 'date_Week': dateWeek,
      if (point != null) 'Point': point,
      if (mont1 != null) 'Mont_1': mont1,
      if (year1 != null) 'Year_1': year1,
      if (serviceId != null) 'Service_ID': serviceId,
      if (attendTime != null) 'Attend_Time': attendTime,
      if (checkoutTime != null) 'Checkout_Time': checkoutTime,
      if (visited != null) 'Visited': visited,
      if (visitNotes != null) 'Visit_Notes': visitNotes,
      if (behavior != null) 'Behavior': behavior,
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
    Value<int?>? serviceId,
    Value<String?>? attendTime,
    Value<String?>? checkoutTime,
    Value<int?>? visited,
    Value<String?>? visitNotes,
    Value<int?>? behavior,
    Value<int>? rowid,
  }) {
    return ComingCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      dateWeek: dateWeek ?? this.dateWeek,
      point: point ?? this.point,
      mont1: mont1 ?? this.mont1,
      year1: year1 ?? this.year1,
      serviceId: serviceId ?? this.serviceId,
      attendTime: attendTime ?? this.attendTime,
      checkoutTime: checkoutTime ?? this.checkoutTime,
      visited: visited ?? this.visited,
      visitNotes: visitNotes ?? this.visitNotes,
      behavior: behavior ?? this.behavior,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['Id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['Person_ID'] = Variable<int>(personId.value);
    }
    if (dateWeek.present) {
      map['date_Week'] = Variable<String>(dateWeek.value);
    }
    if (point.present) {
      map['Point'] = Variable<int>(point.value);
    }
    if (mont1.present) {
      map['Mont_1'] = Variable<int>(mont1.value);
    }
    if (year1.present) {
      map['Year_1'] = Variable<int>(year1.value);
    }
    if (serviceId.present) {
      map['Service_ID'] = Variable<int>(serviceId.value);
    }
    if (attendTime.present) {
      map['Attend_Time'] = Variable<String>(attendTime.value);
    }
    if (checkoutTime.present) {
      map['Checkout_Time'] = Variable<String>(checkoutTime.value);
    }
    if (visited.present) {
      map['Visited'] = Variable<int>(visited.value);
    }
    if (visitNotes.present) {
      map['Visit_Notes'] = Variable<String>(visitNotes.value);
    }
    if (behavior.present) {
      map['Behavior'] = Variable<int>(behavior.value);
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
          ..write('serviceId: $serviceId, ')
          ..write('attendTime: $attendTime, ')
          ..write('checkoutTime: $checkoutTime, ')
          ..write('visited: $visited, ')
          ..write('visitNotes: $visitNotes, ')
          ..write('behavior: $behavior, ')
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
    'Id',
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
    'Person_ID',
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
    'Person_Name',
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
    'Stage_Name',
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
    'Area_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streetMeta = const VerificationMeta('street');
  @override
  late final GeneratedColumn<String> street = GeneratedColumn<String>(
    'Street',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'Phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
    'Mobile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'Day',
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
    'Jender',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<Uint8List> photo = GeneratedColumn<Uint8List>(
    'Photo',
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
    'Parcode',
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
  static const String $name = 'Credit';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreditData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['Id']!, _idMeta));
    }
    if (data.containsKey('Person_ID')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['Person_ID']!, _personIdMeta),
      );
    }
    if (data.containsKey('Person_Name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['Person_Name']!, _personNameMeta),
      );
    }
    if (data.containsKey('Stage_Name')) {
      context.handle(
        _stageNameMeta,
        stageName.isAcceptableOrUnknown(data['Stage_Name']!, _stageNameMeta),
      );
    }
    if (data.containsKey('Area_name')) {
      context.handle(
        _areaNameMeta,
        areaName.isAcceptableOrUnknown(data['Area_name']!, _areaNameMeta),
      );
    }
    if (data.containsKey('Street')) {
      context.handle(
        _streetMeta,
        street.isAcceptableOrUnknown(data['Street']!, _streetMeta),
      );
    }
    if (data.containsKey('Phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['Phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('Mobile')) {
      context.handle(
        _mobileMeta,
        mobile.isAcceptableOrUnknown(data['Mobile']!, _mobileMeta),
      );
    }
    if (data.containsKey('Day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['Day']!, _dayMeta),
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
    if (data.containsKey('Jender')) {
      context.handle(
        _jenderMeta,
        jender.isAcceptableOrUnknown(data['Jender']!, _jenderMeta),
      );
    }
    if (data.containsKey('Photo')) {
      context.handle(
        _photoMeta,
        photo.isAcceptableOrUnknown(data['Photo']!, _photoMeta),
      );
    }
    if (data.containsKey('Parcode')) {
      context.handle(
        _parcodeMeta,
        parcode.isAcceptableOrUnknown(data['Parcode']!, _parcodeMeta),
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
        data['${effectivePrefix}Id'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Person_ID'],
      ),
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Person_Name'],
      ),
      stageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Stage_Name'],
      ),
      areaName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Area_name'],
      ),
      street: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Street'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Phone'],
      ),
      mobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Mobile'],
      ),
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Day'],
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
        data['${effectivePrefix}Jender'],
      ),
      photo: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}Photo'],
      ),
      parcode: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}Parcode'],
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
      map['Id'] = Variable<int>(id);
    }
    if (!nullToAbsent || personId != null) {
      map['Person_ID'] = Variable<int>(personId);
    }
    if (!nullToAbsent || personName != null) {
      map['Person_Name'] = Variable<String>(personName);
    }
    if (!nullToAbsent || stageName != null) {
      map['Stage_Name'] = Variable<String>(stageName);
    }
    if (!nullToAbsent || areaName != null) {
      map['Area_name'] = Variable<String>(areaName);
    }
    if (!nullToAbsent || street != null) {
      map['Street'] = Variable<String>(street);
    }
    if (!nullToAbsent || phone != null) {
      map['Phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || mobile != null) {
      map['Mobile'] = Variable<String>(mobile);
    }
    if (!nullToAbsent || day != null) {
      map['Day'] = Variable<int>(day);
    }
    if (!nullToAbsent || month != null) {
      map['month'] = Variable<int>(month);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || jender != null) {
      map['Jender'] = Variable<String>(jender);
    }
    if (!nullToAbsent || photo != null) {
      map['Photo'] = Variable<Uint8List>(photo);
    }
    if (!nullToAbsent || parcode != null) {
      map['Parcode'] = Variable<Uint8List>(parcode);
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
      if (id != null) 'Id': id,
      if (personId != null) 'Person_ID': personId,
      if (personName != null) 'Person_Name': personName,
      if (stageName != null) 'Stage_Name': stageName,
      if (areaName != null) 'Area_name': areaName,
      if (street != null) 'Street': street,
      if (phone != null) 'Phone': phone,
      if (mobile != null) 'Mobile': mobile,
      if (day != null) 'Day': day,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (jender != null) 'Jender': jender,
      if (photo != null) 'Photo': photo,
      if (parcode != null) 'Parcode': parcode,
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
      map['Id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['Person_ID'] = Variable<int>(personId.value);
    }
    if (personName.present) {
      map['Person_Name'] = Variable<String>(personName.value);
    }
    if (stageName.present) {
      map['Stage_Name'] = Variable<String>(stageName.value);
    }
    if (areaName.present) {
      map['Area_name'] = Variable<String>(areaName.value);
    }
    if (street.present) {
      map['Street'] = Variable<String>(street.value);
    }
    if (phone.present) {
      map['Phone'] = Variable<String>(phone.value);
    }
    if (mobile.present) {
      map['Mobile'] = Variable<String>(mobile.value);
    }
    if (day.present) {
      map['Day'] = Variable<int>(day.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (jender.present) {
      map['Jender'] = Variable<String>(jender.value);
    }
    if (photo.present) {
      map['Photo'] = Variable<Uint8List>(photo.value);
    }
    if (parcode.present) {
      map['Parcode'] = Variable<Uint8List>(parcode.value);
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
    'Father_ID',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fatherNameMeta = const VerificationMeta(
    'fatherName',
  );
  @override
  late final GeneratedColumn<String> fatherName = GeneratedColumn<String>(
    'Father_Name',
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
  static const String $name = 'Fathers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Father> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Father_ID')) {
      context.handle(
        _fatherIdMeta,
        fatherId.isAcceptableOrUnknown(data['Father_ID']!, _fatherIdMeta),
      );
    }
    if (data.containsKey('Father_Name')) {
      context.handle(
        _fatherNameMeta,
        fatherName.isAcceptableOrUnknown(data['Father_Name']!, _fatherNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fatherId};
  @override
  Father map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Father(
      fatherId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Father_ID'],
      )!,
      fatherName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Father_Name'],
      ),
    );
  }

  @override
  $FathersTable createAlias(String alias) {
    return $FathersTable(attachedDatabase, alias);
  }
}

class Father extends DataClass implements Insertable<Father> {
  final int fatherId;
  final String? fatherName;
  const Father({required this.fatherId, this.fatherName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Father_ID'] = Variable<int>(fatherId);
    if (!nullToAbsent || fatherName != null) {
      map['Father_Name'] = Variable<String>(fatherName);
    }
    return map;
  }

  FathersCompanion toCompanion(bool nullToAbsent) {
    return FathersCompanion(
      fatherId: Value(fatherId),
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
      fatherId: serializer.fromJson<int>(json['fatherId']),
      fatherName: serializer.fromJson<String?>(json['fatherName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fatherId': serializer.toJson<int>(fatherId),
      'fatherName': serializer.toJson<String?>(fatherName),
    };
  }

  Father copyWith({
    int? fatherId,
    Value<String?> fatherName = const Value.absent(),
  }) => Father(
    fatherId: fatherId ?? this.fatherId,
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
  final Value<int> fatherId;
  final Value<String?> fatherName;
  const FathersCompanion({
    this.fatherId = const Value.absent(),
    this.fatherName = const Value.absent(),
  });
  FathersCompanion.insert({
    this.fatherId = const Value.absent(),
    this.fatherName = const Value.absent(),
  });
  static Insertable<Father> custom({
    Expression<int>? fatherId,
    Expression<String>? fatherName,
  }) {
    return RawValuesInsertable({
      if (fatherId != null) 'Father_ID': fatherId,
      if (fatherName != null) 'Father_Name': fatherName,
    });
  }

  FathersCompanion copyWith({
    Value<int>? fatherId,
    Value<String?>? fatherName,
  }) {
    return FathersCompanion(
      fatherId: fatherId ?? this.fatherId,
      fatherName: fatherName ?? this.fatherName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fatherId.present) {
      map['Father_ID'] = Variable<int>(fatherId.value);
    }
    if (fatherName.present) {
      map['Father_Name'] = Variable<String>(fatherName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FathersCompanion(')
          ..write('fatherId: $fatherId, ')
          ..write('fatherName: $fatherName')
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
    'Jender_ID',
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
    'Jender_Name',
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
  static const String $name = 'Jender';
  @override
  VerificationContext validateIntegrity(
    Insertable<JenderData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Jender_ID')) {
      context.handle(
        _jenderIdMeta,
        jenderId.isAcceptableOrUnknown(data['Jender_ID']!, _jenderIdMeta),
      );
    }
    if (data.containsKey('Jender_Name')) {
      context.handle(
        _jenderNameMeta,
        jenderName.isAcceptableOrUnknown(data['Jender_Name']!, _jenderNameMeta),
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
        data['${effectivePrefix}Jender_ID'],
      ),
      jenderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Jender_Name'],
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
      map['Jender_ID'] = Variable<int>(jenderId);
    }
    if (!nullToAbsent || jenderName != null) {
      map['Jender_Name'] = Variable<String>(jenderName);
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
      if (jenderId != null) 'Jender_ID': jenderId,
      if (jenderName != null) 'Jender_Name': jenderName,
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
      map['Jender_ID'] = Variable<int>(jenderId.value);
    }
    if (jenderName.present) {
      map['Jender_Name'] = Variable<String>(jenderName.value);
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
    'Pass_ID',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _passWordMeta = const VerificationMeta(
    'passWord',
  );
  @override
  late final GeneratedColumn<String> passWord = GeneratedColumn<String>(
    'Pass_Word',
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
    'Person_Name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _canPersonsMeta = const VerificationMeta(
    'canPersons',
  );
  @override
  late final GeneratedColumn<bool> canPersons = GeneratedColumn<bool>(
    'can_persons',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_persons" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canStagesMeta = const VerificationMeta(
    'canStages',
  );
  @override
  late final GeneratedColumn<bool> canStages = GeneratedColumn<bool>(
    'can_stages',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_stages" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canAreasMeta = const VerificationMeta(
    'canAreas',
  );
  @override
  late final GeneratedColumn<bool> canAreas = GeneratedColumn<bool>(
    'can_areas',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_areas" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canFathersMeta = const VerificationMeta(
    'canFathers',
  );
  @override
  late final GeneratedColumn<bool> canFathers = GeneratedColumn<bool>(
    'can_fathers',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_fathers" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canReportsMeta = const VerificationMeta(
    'canReports',
  );
  @override
  late final GeneratedColumn<bool> canReports = GeneratedColumn<bool>(
    'can_reports',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_reports" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canUsersMeta = const VerificationMeta(
    'canUsers',
  );
  @override
  late final GeneratedColumn<bool> canUsers = GeneratedColumn<bool>(
    'can_users',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_users" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canAbsenceMeta = const VerificationMeta(
    'canAbsence',
  );
  @override
  late final GeneratedColumn<bool> canAbsence = GeneratedColumn<bool>(
    'can_absence',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_absence" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canMaintenanceMeta = const VerificationMeta(
    'canMaintenance',
  );
  @override
  late final GeneratedColumn<bool> canMaintenance = GeneratedColumn<bool>(
    'can_maintenance',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_maintenance" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canIdCardMeta = const VerificationMeta(
    'canIdCard',
  );
  @override
  late final GeneratedColumn<bool> canIdCard = GeneratedColumn<bool>(
    'can_id_card',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_id_card" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canTayoMeta = const VerificationMeta(
    'canTayo',
  );
  @override
  late final GeneratedColumn<bool> canTayo = GeneratedColumn<bool>(
    'can_tayo',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_tayo" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canTransferMeta = const VerificationMeta(
    'canTransfer',
  );
  @override
  late final GeneratedColumn<bool> canTransfer = GeneratedColumn<bool>(
    'can_transfer',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_transfer" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canServicesMeta = const VerificationMeta(
    'canServices',
  );
  @override
  late final GeneratedColumn<bool> canServices = GeneratedColumn<bool>(
    'can_services',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_services" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canKhorosMeta = const VerificationMeta(
    'canKhoros',
  );
  @override
  late final GeneratedColumn<bool> canKhoros = GeneratedColumn<bool>(
    'can_khoros',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_khoros" IN (0, 1))',
    ),
  );
  static const VerificationMeta _canBehaviorMeta = const VerificationMeta(
    'canBehavior',
  );
  @override
  late final GeneratedColumn<bool> canBehavior = GeneratedColumn<bool>(
    'can_behavior',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_behavior" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isAdvancedMeta = const VerificationMeta(
    'isAdvanced',
  );
  @override
  late final GeneratedColumn<bool> isAdvanced = GeneratedColumn<bool>(
    'is_advanced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_advanced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    passId,
    passWord,
    personName,
    canPersons,
    canStages,
    canAreas,
    canFathers,
    canReports,
    canUsers,
    canAbsence,
    canMaintenance,
    canIdCard,
    canTayo,
    canTransfer,
    canServices,
    canKhoros,
    canBehavior,
    isAdvanced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Pass';
  @override
  VerificationContext validateIntegrity(
    Insertable<PassData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Pass_ID')) {
      context.handle(
        _passIdMeta,
        passId.isAcceptableOrUnknown(data['Pass_ID']!, _passIdMeta),
      );
    }
    if (data.containsKey('Pass_Word')) {
      context.handle(
        _passWordMeta,
        passWord.isAcceptableOrUnknown(data['Pass_Word']!, _passWordMeta),
      );
    }
    if (data.containsKey('Person_Name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['Person_Name']!, _personNameMeta),
      );
    }
    if (data.containsKey('can_persons')) {
      context.handle(
        _canPersonsMeta,
        canPersons.isAcceptableOrUnknown(data['can_persons']!, _canPersonsMeta),
      );
    }
    if (data.containsKey('can_stages')) {
      context.handle(
        _canStagesMeta,
        canStages.isAcceptableOrUnknown(data['can_stages']!, _canStagesMeta),
      );
    }
    if (data.containsKey('can_areas')) {
      context.handle(
        _canAreasMeta,
        canAreas.isAcceptableOrUnknown(data['can_areas']!, _canAreasMeta),
      );
    }
    if (data.containsKey('can_fathers')) {
      context.handle(
        _canFathersMeta,
        canFathers.isAcceptableOrUnknown(data['can_fathers']!, _canFathersMeta),
      );
    }
    if (data.containsKey('can_reports')) {
      context.handle(
        _canReportsMeta,
        canReports.isAcceptableOrUnknown(data['can_reports']!, _canReportsMeta),
      );
    }
    if (data.containsKey('can_users')) {
      context.handle(
        _canUsersMeta,
        canUsers.isAcceptableOrUnknown(data['can_users']!, _canUsersMeta),
      );
    }
    if (data.containsKey('can_absence')) {
      context.handle(
        _canAbsenceMeta,
        canAbsence.isAcceptableOrUnknown(data['can_absence']!, _canAbsenceMeta),
      );
    }
    if (data.containsKey('can_maintenance')) {
      context.handle(
        _canMaintenanceMeta,
        canMaintenance.isAcceptableOrUnknown(
          data['can_maintenance']!,
          _canMaintenanceMeta,
        ),
      );
    }
    if (data.containsKey('can_id_card')) {
      context.handle(
        _canIdCardMeta,
        canIdCard.isAcceptableOrUnknown(data['can_id_card']!, _canIdCardMeta),
      );
    }
    if (data.containsKey('can_tayo')) {
      context.handle(
        _canTayoMeta,
        canTayo.isAcceptableOrUnknown(data['can_tayo']!, _canTayoMeta),
      );
    }
    if (data.containsKey('can_transfer')) {
      context.handle(
        _canTransferMeta,
        canTransfer.isAcceptableOrUnknown(
          data['can_transfer']!,
          _canTransferMeta,
        ),
      );
    }
    if (data.containsKey('can_services')) {
      context.handle(
        _canServicesMeta,
        canServices.isAcceptableOrUnknown(
          data['can_services']!,
          _canServicesMeta,
        ),
      );
    }
    if (data.containsKey('can_khoros')) {
      context.handle(
        _canKhorosMeta,
        canKhoros.isAcceptableOrUnknown(data['can_khoros']!, _canKhorosMeta),
      );
    }
    if (data.containsKey('can_behavior')) {
      context.handle(
        _canBehaviorMeta,
        canBehavior.isAcceptableOrUnknown(
          data['can_behavior']!,
          _canBehaviorMeta,
        ),
      );
    }
    if (data.containsKey('is_advanced')) {
      context.handle(
        _isAdvancedMeta,
        isAdvanced.isAcceptableOrUnknown(data['is_advanced']!, _isAdvancedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {passId};
  @override
  PassData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PassData(
      passId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Pass_ID'],
      )!,
      passWord: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Pass_Word'],
      ),
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Person_Name'],
      ),
      canPersons: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_persons'],
      ),
      canStages: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_stages'],
      ),
      canAreas: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_areas'],
      ),
      canFathers: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_fathers'],
      ),
      canReports: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_reports'],
      ),
      canUsers: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_users'],
      ),
      canAbsence: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_absence'],
      ),
      canMaintenance: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_maintenance'],
      ),
      canIdCard: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_id_card'],
      ),
      canTayo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_tayo'],
      ),
      canTransfer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_transfer'],
      ),
      canServices: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_services'],
      ),
      canKhoros: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_khoros'],
      ),
      canBehavior: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_behavior'],
      ),
      isAdvanced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_advanced'],
      )!,
    );
  }

  @override
  $PassTable createAlias(String alias) {
    return $PassTable(attachedDatabase, alias);
  }
}

class PassData extends DataClass implements Insertable<PassData> {
  final int passId;
  final String? passWord;
  final String? personName;
  final bool? canPersons;
  final bool? canStages;
  final bool? canAreas;
  final bool? canFathers;
  final bool? canReports;
  final bool? canUsers;
  final bool? canAbsence;
  final bool? canMaintenance;
  final bool? canIdCard;
  final bool? canTayo;
  final bool? canTransfer;
  final bool? canServices;
  final bool? canKhoros;
  final bool? canBehavior;
  final bool isAdvanced;
  const PassData({
    required this.passId,
    this.passWord,
    this.personName,
    this.canPersons,
    this.canStages,
    this.canAreas,
    this.canFathers,
    this.canReports,
    this.canUsers,
    this.canAbsence,
    this.canMaintenance,
    this.canIdCard,
    this.canTayo,
    this.canTransfer,
    this.canServices,
    this.canKhoros,
    this.canBehavior,
    required this.isAdvanced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Pass_ID'] = Variable<int>(passId);
    if (!nullToAbsent || passWord != null) {
      map['Pass_Word'] = Variable<String>(passWord);
    }
    if (!nullToAbsent || personName != null) {
      map['Person_Name'] = Variable<String>(personName);
    }
    if (!nullToAbsent || canPersons != null) {
      map['can_persons'] = Variable<bool>(canPersons);
    }
    if (!nullToAbsent || canStages != null) {
      map['can_stages'] = Variable<bool>(canStages);
    }
    if (!nullToAbsent || canAreas != null) {
      map['can_areas'] = Variable<bool>(canAreas);
    }
    if (!nullToAbsent || canFathers != null) {
      map['can_fathers'] = Variable<bool>(canFathers);
    }
    if (!nullToAbsent || canReports != null) {
      map['can_reports'] = Variable<bool>(canReports);
    }
    if (!nullToAbsent || canUsers != null) {
      map['can_users'] = Variable<bool>(canUsers);
    }
    if (!nullToAbsent || canAbsence != null) {
      map['can_absence'] = Variable<bool>(canAbsence);
    }
    if (!nullToAbsent || canMaintenance != null) {
      map['can_maintenance'] = Variable<bool>(canMaintenance);
    }
    if (!nullToAbsent || canIdCard != null) {
      map['can_id_card'] = Variable<bool>(canIdCard);
    }
    if (!nullToAbsent || canTayo != null) {
      map['can_tayo'] = Variable<bool>(canTayo);
    }
    if (!nullToAbsent || canTransfer != null) {
      map['can_transfer'] = Variable<bool>(canTransfer);
    }
    if (!nullToAbsent || canServices != null) {
      map['can_services'] = Variable<bool>(canServices);
    }
    if (!nullToAbsent || canKhoros != null) {
      map['can_khoros'] = Variable<bool>(canKhoros);
    }
    if (!nullToAbsent || canBehavior != null) {
      map['can_behavior'] = Variable<bool>(canBehavior);
    }
    map['is_advanced'] = Variable<bool>(isAdvanced);
    return map;
  }

  PassCompanion toCompanion(bool nullToAbsent) {
    return PassCompanion(
      passId: Value(passId),
      passWord: passWord == null && nullToAbsent
          ? const Value.absent()
          : Value(passWord),
      personName: personName == null && nullToAbsent
          ? const Value.absent()
          : Value(personName),
      canPersons: canPersons == null && nullToAbsent
          ? const Value.absent()
          : Value(canPersons),
      canStages: canStages == null && nullToAbsent
          ? const Value.absent()
          : Value(canStages),
      canAreas: canAreas == null && nullToAbsent
          ? const Value.absent()
          : Value(canAreas),
      canFathers: canFathers == null && nullToAbsent
          ? const Value.absent()
          : Value(canFathers),
      canReports: canReports == null && nullToAbsent
          ? const Value.absent()
          : Value(canReports),
      canUsers: canUsers == null && nullToAbsent
          ? const Value.absent()
          : Value(canUsers),
      canAbsence: canAbsence == null && nullToAbsent
          ? const Value.absent()
          : Value(canAbsence),
      canMaintenance: canMaintenance == null && nullToAbsent
          ? const Value.absent()
          : Value(canMaintenance),
      canIdCard: canIdCard == null && nullToAbsent
          ? const Value.absent()
          : Value(canIdCard),
      canTayo: canTayo == null && nullToAbsent
          ? const Value.absent()
          : Value(canTayo),
      canTransfer: canTransfer == null && nullToAbsent
          ? const Value.absent()
          : Value(canTransfer),
      canServices: canServices == null && nullToAbsent
          ? const Value.absent()
          : Value(canServices),
      canKhoros: canKhoros == null && nullToAbsent
          ? const Value.absent()
          : Value(canKhoros),
      canBehavior: canBehavior == null && nullToAbsent
          ? const Value.absent()
          : Value(canBehavior),
      isAdvanced: Value(isAdvanced),
    );
  }

  factory PassData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PassData(
      passId: serializer.fromJson<int>(json['passId']),
      passWord: serializer.fromJson<String?>(json['passWord']),
      personName: serializer.fromJson<String?>(json['personName']),
      canPersons: serializer.fromJson<bool?>(json['canPersons']),
      canStages: serializer.fromJson<bool?>(json['canStages']),
      canAreas: serializer.fromJson<bool?>(json['canAreas']),
      canFathers: serializer.fromJson<bool?>(json['canFathers']),
      canReports: serializer.fromJson<bool?>(json['canReports']),
      canUsers: serializer.fromJson<bool?>(json['canUsers']),
      canAbsence: serializer.fromJson<bool?>(json['canAbsence']),
      canMaintenance: serializer.fromJson<bool?>(json['canMaintenance']),
      canIdCard: serializer.fromJson<bool?>(json['canIdCard']),
      canTayo: serializer.fromJson<bool?>(json['canTayo']),
      canTransfer: serializer.fromJson<bool?>(json['canTransfer']),
      canServices: serializer.fromJson<bool?>(json['canServices']),
      canKhoros: serializer.fromJson<bool?>(json['canKhoros']),
      canBehavior: serializer.fromJson<bool?>(json['canBehavior']),
      isAdvanced: serializer.fromJson<bool>(json['isAdvanced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'passId': serializer.toJson<int>(passId),
      'passWord': serializer.toJson<String?>(passWord),
      'personName': serializer.toJson<String?>(personName),
      'canPersons': serializer.toJson<bool?>(canPersons),
      'canStages': serializer.toJson<bool?>(canStages),
      'canAreas': serializer.toJson<bool?>(canAreas),
      'canFathers': serializer.toJson<bool?>(canFathers),
      'canReports': serializer.toJson<bool?>(canReports),
      'canUsers': serializer.toJson<bool?>(canUsers),
      'canAbsence': serializer.toJson<bool?>(canAbsence),
      'canMaintenance': serializer.toJson<bool?>(canMaintenance),
      'canIdCard': serializer.toJson<bool?>(canIdCard),
      'canTayo': serializer.toJson<bool?>(canTayo),
      'canTransfer': serializer.toJson<bool?>(canTransfer),
      'canServices': serializer.toJson<bool?>(canServices),
      'canKhoros': serializer.toJson<bool?>(canKhoros),
      'canBehavior': serializer.toJson<bool?>(canBehavior),
      'isAdvanced': serializer.toJson<bool>(isAdvanced),
    };
  }

  PassData copyWith({
    int? passId,
    Value<String?> passWord = const Value.absent(),
    Value<String?> personName = const Value.absent(),
    Value<bool?> canPersons = const Value.absent(),
    Value<bool?> canStages = const Value.absent(),
    Value<bool?> canAreas = const Value.absent(),
    Value<bool?> canFathers = const Value.absent(),
    Value<bool?> canReports = const Value.absent(),
    Value<bool?> canUsers = const Value.absent(),
    Value<bool?> canAbsence = const Value.absent(),
    Value<bool?> canMaintenance = const Value.absent(),
    Value<bool?> canIdCard = const Value.absent(),
    Value<bool?> canTayo = const Value.absent(),
    Value<bool?> canTransfer = const Value.absent(),
    Value<bool?> canServices = const Value.absent(),
    Value<bool?> canKhoros = const Value.absent(),
    Value<bool?> canBehavior = const Value.absent(),
    bool? isAdvanced,
  }) => PassData(
    passId: passId ?? this.passId,
    passWord: passWord.present ? passWord.value : this.passWord,
    personName: personName.present ? personName.value : this.personName,
    canPersons: canPersons.present ? canPersons.value : this.canPersons,
    canStages: canStages.present ? canStages.value : this.canStages,
    canAreas: canAreas.present ? canAreas.value : this.canAreas,
    canFathers: canFathers.present ? canFathers.value : this.canFathers,
    canReports: canReports.present ? canReports.value : this.canReports,
    canUsers: canUsers.present ? canUsers.value : this.canUsers,
    canAbsence: canAbsence.present ? canAbsence.value : this.canAbsence,
    canMaintenance: canMaintenance.present
        ? canMaintenance.value
        : this.canMaintenance,
    canIdCard: canIdCard.present ? canIdCard.value : this.canIdCard,
    canTayo: canTayo.present ? canTayo.value : this.canTayo,
    canTransfer: canTransfer.present ? canTransfer.value : this.canTransfer,
    canServices: canServices.present ? canServices.value : this.canServices,
    canKhoros: canKhoros.present ? canKhoros.value : this.canKhoros,
    canBehavior: canBehavior.present ? canBehavior.value : this.canBehavior,
    isAdvanced: isAdvanced ?? this.isAdvanced,
  );
  PassData copyWithCompanion(PassCompanion data) {
    return PassData(
      passId: data.passId.present ? data.passId.value : this.passId,
      passWord: data.passWord.present ? data.passWord.value : this.passWord,
      personName: data.personName.present
          ? data.personName.value
          : this.personName,
      canPersons: data.canPersons.present
          ? data.canPersons.value
          : this.canPersons,
      canStages: data.canStages.present ? data.canStages.value : this.canStages,
      canAreas: data.canAreas.present ? data.canAreas.value : this.canAreas,
      canFathers: data.canFathers.present
          ? data.canFathers.value
          : this.canFathers,
      canReports: data.canReports.present
          ? data.canReports.value
          : this.canReports,
      canUsers: data.canUsers.present ? data.canUsers.value : this.canUsers,
      canAbsence: data.canAbsence.present
          ? data.canAbsence.value
          : this.canAbsence,
      canMaintenance: data.canMaintenance.present
          ? data.canMaintenance.value
          : this.canMaintenance,
      canIdCard: data.canIdCard.present ? data.canIdCard.value : this.canIdCard,
      canTayo: data.canTayo.present ? data.canTayo.value : this.canTayo,
      canTransfer: data.canTransfer.present
          ? data.canTransfer.value
          : this.canTransfer,
      canServices: data.canServices.present
          ? data.canServices.value
          : this.canServices,
      canKhoros: data.canKhoros.present ? data.canKhoros.value : this.canKhoros,
      canBehavior: data.canBehavior.present
          ? data.canBehavior.value
          : this.canBehavior,
      isAdvanced: data.isAdvanced.present
          ? data.isAdvanced.value
          : this.isAdvanced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PassData(')
          ..write('passId: $passId, ')
          ..write('passWord: $passWord, ')
          ..write('personName: $personName, ')
          ..write('canPersons: $canPersons, ')
          ..write('canStages: $canStages, ')
          ..write('canAreas: $canAreas, ')
          ..write('canFathers: $canFathers, ')
          ..write('canReports: $canReports, ')
          ..write('canUsers: $canUsers, ')
          ..write('canAbsence: $canAbsence, ')
          ..write('canMaintenance: $canMaintenance, ')
          ..write('canIdCard: $canIdCard, ')
          ..write('canTayo: $canTayo, ')
          ..write('canTransfer: $canTransfer, ')
          ..write('canServices: $canServices, ')
          ..write('canKhoros: $canKhoros, ')
          ..write('canBehavior: $canBehavior, ')
          ..write('isAdvanced: $isAdvanced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    passId,
    passWord,
    personName,
    canPersons,
    canStages,
    canAreas,
    canFathers,
    canReports,
    canUsers,
    canAbsence,
    canMaintenance,
    canIdCard,
    canTayo,
    canTransfer,
    canServices,
    canKhoros,
    canBehavior,
    isAdvanced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PassData &&
          other.passId == this.passId &&
          other.passWord == this.passWord &&
          other.personName == this.personName &&
          other.canPersons == this.canPersons &&
          other.canStages == this.canStages &&
          other.canAreas == this.canAreas &&
          other.canFathers == this.canFathers &&
          other.canReports == this.canReports &&
          other.canUsers == this.canUsers &&
          other.canAbsence == this.canAbsence &&
          other.canMaintenance == this.canMaintenance &&
          other.canIdCard == this.canIdCard &&
          other.canTayo == this.canTayo &&
          other.canTransfer == this.canTransfer &&
          other.canServices == this.canServices &&
          other.canKhoros == this.canKhoros &&
          other.canBehavior == this.canBehavior &&
          other.isAdvanced == this.isAdvanced);
}

class PassCompanion extends UpdateCompanion<PassData> {
  final Value<int> passId;
  final Value<String?> passWord;
  final Value<String?> personName;
  final Value<bool?> canPersons;
  final Value<bool?> canStages;
  final Value<bool?> canAreas;
  final Value<bool?> canFathers;
  final Value<bool?> canReports;
  final Value<bool?> canUsers;
  final Value<bool?> canAbsence;
  final Value<bool?> canMaintenance;
  final Value<bool?> canIdCard;
  final Value<bool?> canTayo;
  final Value<bool?> canTransfer;
  final Value<bool?> canServices;
  final Value<bool?> canKhoros;
  final Value<bool?> canBehavior;
  final Value<bool> isAdvanced;
  const PassCompanion({
    this.passId = const Value.absent(),
    this.passWord = const Value.absent(),
    this.personName = const Value.absent(),
    this.canPersons = const Value.absent(),
    this.canStages = const Value.absent(),
    this.canAreas = const Value.absent(),
    this.canFathers = const Value.absent(),
    this.canReports = const Value.absent(),
    this.canUsers = const Value.absent(),
    this.canAbsence = const Value.absent(),
    this.canMaintenance = const Value.absent(),
    this.canIdCard = const Value.absent(),
    this.canTayo = const Value.absent(),
    this.canTransfer = const Value.absent(),
    this.canServices = const Value.absent(),
    this.canKhoros = const Value.absent(),
    this.canBehavior = const Value.absent(),
    this.isAdvanced = const Value.absent(),
  });
  PassCompanion.insert({
    this.passId = const Value.absent(),
    this.passWord = const Value.absent(),
    this.personName = const Value.absent(),
    this.canPersons = const Value.absent(),
    this.canStages = const Value.absent(),
    this.canAreas = const Value.absent(),
    this.canFathers = const Value.absent(),
    this.canReports = const Value.absent(),
    this.canUsers = const Value.absent(),
    this.canAbsence = const Value.absent(),
    this.canMaintenance = const Value.absent(),
    this.canIdCard = const Value.absent(),
    this.canTayo = const Value.absent(),
    this.canTransfer = const Value.absent(),
    this.canServices = const Value.absent(),
    this.canKhoros = const Value.absent(),
    this.canBehavior = const Value.absent(),
    this.isAdvanced = const Value.absent(),
  });
  static Insertable<PassData> custom({
    Expression<int>? passId,
    Expression<String>? passWord,
    Expression<String>? personName,
    Expression<bool>? canPersons,
    Expression<bool>? canStages,
    Expression<bool>? canAreas,
    Expression<bool>? canFathers,
    Expression<bool>? canReports,
    Expression<bool>? canUsers,
    Expression<bool>? canAbsence,
    Expression<bool>? canMaintenance,
    Expression<bool>? canIdCard,
    Expression<bool>? canTayo,
    Expression<bool>? canTransfer,
    Expression<bool>? canServices,
    Expression<bool>? canKhoros,
    Expression<bool>? canBehavior,
    Expression<bool>? isAdvanced,
  }) {
    return RawValuesInsertable({
      if (passId != null) 'Pass_ID': passId,
      if (passWord != null) 'Pass_Word': passWord,
      if (personName != null) 'Person_Name': personName,
      if (canPersons != null) 'can_persons': canPersons,
      if (canStages != null) 'can_stages': canStages,
      if (canAreas != null) 'can_areas': canAreas,
      if (canFathers != null) 'can_fathers': canFathers,
      if (canReports != null) 'can_reports': canReports,
      if (canUsers != null) 'can_users': canUsers,
      if (canAbsence != null) 'can_absence': canAbsence,
      if (canMaintenance != null) 'can_maintenance': canMaintenance,
      if (canIdCard != null) 'can_id_card': canIdCard,
      if (canTayo != null) 'can_tayo': canTayo,
      if (canTransfer != null) 'can_transfer': canTransfer,
      if (canServices != null) 'can_services': canServices,
      if (canKhoros != null) 'can_khoros': canKhoros,
      if (canBehavior != null) 'can_behavior': canBehavior,
      if (isAdvanced != null) 'is_advanced': isAdvanced,
    });
  }

  PassCompanion copyWith({
    Value<int>? passId,
    Value<String?>? passWord,
    Value<String?>? personName,
    Value<bool?>? canPersons,
    Value<bool?>? canStages,
    Value<bool?>? canAreas,
    Value<bool?>? canFathers,
    Value<bool?>? canReports,
    Value<bool?>? canUsers,
    Value<bool?>? canAbsence,
    Value<bool?>? canMaintenance,
    Value<bool?>? canIdCard,
    Value<bool?>? canTayo,
    Value<bool?>? canTransfer,
    Value<bool?>? canServices,
    Value<bool?>? canKhoros,
    Value<bool?>? canBehavior,
    Value<bool>? isAdvanced,
  }) {
    return PassCompanion(
      passId: passId ?? this.passId,
      passWord: passWord ?? this.passWord,
      personName: personName ?? this.personName,
      canPersons: canPersons ?? this.canPersons,
      canStages: canStages ?? this.canStages,
      canAreas: canAreas ?? this.canAreas,
      canFathers: canFathers ?? this.canFathers,
      canReports: canReports ?? this.canReports,
      canUsers: canUsers ?? this.canUsers,
      canAbsence: canAbsence ?? this.canAbsence,
      canMaintenance: canMaintenance ?? this.canMaintenance,
      canIdCard: canIdCard ?? this.canIdCard,
      canTayo: canTayo ?? this.canTayo,
      canTransfer: canTransfer ?? this.canTransfer,
      canServices: canServices ?? this.canServices,
      canKhoros: canKhoros ?? this.canKhoros,
      canBehavior: canBehavior ?? this.canBehavior,
      isAdvanced: isAdvanced ?? this.isAdvanced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (passId.present) {
      map['Pass_ID'] = Variable<int>(passId.value);
    }
    if (passWord.present) {
      map['Pass_Word'] = Variable<String>(passWord.value);
    }
    if (personName.present) {
      map['Person_Name'] = Variable<String>(personName.value);
    }
    if (canPersons.present) {
      map['can_persons'] = Variable<bool>(canPersons.value);
    }
    if (canStages.present) {
      map['can_stages'] = Variable<bool>(canStages.value);
    }
    if (canAreas.present) {
      map['can_areas'] = Variable<bool>(canAreas.value);
    }
    if (canFathers.present) {
      map['can_fathers'] = Variable<bool>(canFathers.value);
    }
    if (canReports.present) {
      map['can_reports'] = Variable<bool>(canReports.value);
    }
    if (canUsers.present) {
      map['can_users'] = Variable<bool>(canUsers.value);
    }
    if (canAbsence.present) {
      map['can_absence'] = Variable<bool>(canAbsence.value);
    }
    if (canMaintenance.present) {
      map['can_maintenance'] = Variable<bool>(canMaintenance.value);
    }
    if (canIdCard.present) {
      map['can_id_card'] = Variable<bool>(canIdCard.value);
    }
    if (canTayo.present) {
      map['can_tayo'] = Variable<bool>(canTayo.value);
    }
    if (canTransfer.present) {
      map['can_transfer'] = Variable<bool>(canTransfer.value);
    }
    if (canServices.present) {
      map['can_services'] = Variable<bool>(canServices.value);
    }
    if (canKhoros.present) {
      map['can_khoros'] = Variable<bool>(canKhoros.value);
    }
    if (canBehavior.present) {
      map['can_behavior'] = Variable<bool>(canBehavior.value);
    }
    if (isAdvanced.present) {
      map['is_advanced'] = Variable<bool>(isAdvanced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PassCompanion(')
          ..write('passId: $passId, ')
          ..write('passWord: $passWord, ')
          ..write('personName: $personName, ')
          ..write('canPersons: $canPersons, ')
          ..write('canStages: $canStages, ')
          ..write('canAreas: $canAreas, ')
          ..write('canFathers: $canFathers, ')
          ..write('canReports: $canReports, ')
          ..write('canUsers: $canUsers, ')
          ..write('canAbsence: $canAbsence, ')
          ..write('canMaintenance: $canMaintenance, ')
          ..write('canIdCard: $canIdCard, ')
          ..write('canTayo: $canTayo, ')
          ..write('canTransfer: $canTransfer, ')
          ..write('canServices: $canServices, ')
          ..write('canKhoros: $canKhoros, ')
          ..write('canBehavior: $canBehavior, ')
          ..write('isAdvanced: $isAdvanced')
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
    'Person_ID',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _personNameMeta = const VerificationMeta(
    'personName',
  );
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
    'Person_Name',
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
    'Stage_ID',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _khorosIdMeta = const VerificationMeta(
    'khorosId',
  );
  @override
  late final GeneratedColumn<int> khorosId = GeneratedColumn<int>(
    'Khoros_ID',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaIdMeta = const VerificationMeta('areaId');
  @override
  late final GeneratedColumn<int> areaId = GeneratedColumn<int>(
    'Area_ID',
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
    'Street_Name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'Phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
    'Mobile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'Day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'Month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'Year',
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
    'Jender_Name',
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
    'Father_ID',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoMeta = const VerificationMeta('photo');
  @override
  late final GeneratedColumn<Uint8List> photo = GeneratedColumn<Uint8List>(
    'Photo',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rohotMeta = const VerificationMeta('rohot');
  @override
  late final GeneratedColumn<String> rohot = GeneratedColumn<String>(
    'Rohot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leaderMeta = const VerificationMeta('leader');
  @override
  late final GeneratedColumn<String> leader = GeneratedColumn<String>(
    'Leader',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    personId,
    personName,
    stageId,
    khorosId,
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
    rohot,
    leader,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Persons';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Person_ID')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['Person_ID']!, _personIdMeta),
      );
    }
    if (data.containsKey('Person_Name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['Person_Name']!, _personNameMeta),
      );
    }
    if (data.containsKey('Stage_ID')) {
      context.handle(
        _stageIdMeta,
        stageId.isAcceptableOrUnknown(data['Stage_ID']!, _stageIdMeta),
      );
    }
    if (data.containsKey('Khoros_ID')) {
      context.handle(
        _khorosIdMeta,
        khorosId.isAcceptableOrUnknown(data['Khoros_ID']!, _khorosIdMeta),
      );
    }
    if (data.containsKey('Area_ID')) {
      context.handle(
        _areaIdMeta,
        areaId.isAcceptableOrUnknown(data['Area_ID']!, _areaIdMeta),
      );
    }
    if (data.containsKey('Street_Name')) {
      context.handle(
        _streetNameMeta,
        streetName.isAcceptableOrUnknown(data['Street_Name']!, _streetNameMeta),
      );
    }
    if (data.containsKey('Phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['Phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('Mobile')) {
      context.handle(
        _mobileMeta,
        mobile.isAcceptableOrUnknown(data['Mobile']!, _mobileMeta),
      );
    }
    if (data.containsKey('Day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['Day']!, _dayMeta),
      );
    }
    if (data.containsKey('Month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['Month']!, _monthMeta),
      );
    }
    if (data.containsKey('Year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['Year']!, _yearMeta),
      );
    }
    if (data.containsKey('Jender_Name')) {
      context.handle(
        _jenderNameMeta,
        jenderName.isAcceptableOrUnknown(data['Jender_Name']!, _jenderNameMeta),
      );
    }
    if (data.containsKey('Father_ID')) {
      context.handle(
        _fatherIdMeta,
        fatherId.isAcceptableOrUnknown(data['Father_ID']!, _fatherIdMeta),
      );
    }
    if (data.containsKey('Photo')) {
      context.handle(
        _photoMeta,
        photo.isAcceptableOrUnknown(data['Photo']!, _photoMeta),
      );
    }
    if (data.containsKey('Rohot')) {
      context.handle(
        _rohotMeta,
        rohot.isAcceptableOrUnknown(data['Rohot']!, _rohotMeta),
      );
    }
    if (data.containsKey('Leader')) {
      context.handle(
        _leaderMeta,
        leader.isAcceptableOrUnknown(data['Leader']!, _leaderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {personId};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Person_ID'],
      )!,
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Person_Name'],
      ),
      stageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Stage_ID'],
      ),
      khorosId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Khoros_ID'],
      ),
      areaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Area_ID'],
      ),
      streetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Street_Name'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Phone'],
      ),
      mobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Mobile'],
      ),
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Day'],
      ),
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Month'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Year'],
      ),
      jenderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Jender_Name'],
      ),
      fatherId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Father_ID'],
      ),
      photo: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}Photo'],
      ),
      rohot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Rohot'],
      ),
      leader: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Leader'],
      ),
    );
  }

  @override
  $PersonsTable createAlias(String alias) {
    return $PersonsTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final int personId;
  final String? personName;
  final int? stageId;
  final int? khorosId;
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
  final String? rohot;
  final String? leader;
  const Person({
    required this.personId,
    this.personName,
    this.stageId,
    this.khorosId,
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
    this.rohot,
    this.leader,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Person_ID'] = Variable<int>(personId);
    if (!nullToAbsent || personName != null) {
      map['Person_Name'] = Variable<String>(personName);
    }
    if (!nullToAbsent || stageId != null) {
      map['Stage_ID'] = Variable<int>(stageId);
    }
    if (!nullToAbsent || khorosId != null) {
      map['Khoros_ID'] = Variable<int>(khorosId);
    }
    if (!nullToAbsent || areaId != null) {
      map['Area_ID'] = Variable<int>(areaId);
    }
    if (!nullToAbsent || streetName != null) {
      map['Street_Name'] = Variable<String>(streetName);
    }
    if (!nullToAbsent || phone != null) {
      map['Phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || mobile != null) {
      map['Mobile'] = Variable<String>(mobile);
    }
    if (!nullToAbsent || day != null) {
      map['Day'] = Variable<int>(day);
    }
    if (!nullToAbsent || month != null) {
      map['Month'] = Variable<int>(month);
    }
    if (!nullToAbsent || year != null) {
      map['Year'] = Variable<int>(year);
    }
    if (!nullToAbsent || jenderName != null) {
      map['Jender_Name'] = Variable<String>(jenderName);
    }
    if (!nullToAbsent || fatherId != null) {
      map['Father_ID'] = Variable<int>(fatherId);
    }
    if (!nullToAbsent || photo != null) {
      map['Photo'] = Variable<Uint8List>(photo);
    }
    if (!nullToAbsent || rohot != null) {
      map['Rohot'] = Variable<String>(rohot);
    }
    if (!nullToAbsent || leader != null) {
      map['Leader'] = Variable<String>(leader);
    }
    return map;
  }

  PersonsCompanion toCompanion(bool nullToAbsent) {
    return PersonsCompanion(
      personId: Value(personId),
      personName: personName == null && nullToAbsent
          ? const Value.absent()
          : Value(personName),
      stageId: stageId == null && nullToAbsent
          ? const Value.absent()
          : Value(stageId),
      khorosId: khorosId == null && nullToAbsent
          ? const Value.absent()
          : Value(khorosId),
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
      rohot: rohot == null && nullToAbsent
          ? const Value.absent()
          : Value(rohot),
      leader: leader == null && nullToAbsent
          ? const Value.absent()
          : Value(leader),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      personId: serializer.fromJson<int>(json['personId']),
      personName: serializer.fromJson<String?>(json['personName']),
      stageId: serializer.fromJson<int?>(json['stageId']),
      khorosId: serializer.fromJson<int?>(json['khorosId']),
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
      rohot: serializer.fromJson<String?>(json['rohot']),
      leader: serializer.fromJson<String?>(json['leader']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'personId': serializer.toJson<int>(personId),
      'personName': serializer.toJson<String?>(personName),
      'stageId': serializer.toJson<int?>(stageId),
      'khorosId': serializer.toJson<int?>(khorosId),
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
      'rohot': serializer.toJson<String?>(rohot),
      'leader': serializer.toJson<String?>(leader),
    };
  }

  Person copyWith({
    int? personId,
    Value<String?> personName = const Value.absent(),
    Value<int?> stageId = const Value.absent(),
    Value<int?> khorosId = const Value.absent(),
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
    Value<String?> rohot = const Value.absent(),
    Value<String?> leader = const Value.absent(),
  }) => Person(
    personId: personId ?? this.personId,
    personName: personName.present ? personName.value : this.personName,
    stageId: stageId.present ? stageId.value : this.stageId,
    khorosId: khorosId.present ? khorosId.value : this.khorosId,
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
    rohot: rohot.present ? rohot.value : this.rohot,
    leader: leader.present ? leader.value : this.leader,
  );
  Person copyWithCompanion(PersonsCompanion data) {
    return Person(
      personId: data.personId.present ? data.personId.value : this.personId,
      personName: data.personName.present
          ? data.personName.value
          : this.personName,
      stageId: data.stageId.present ? data.stageId.value : this.stageId,
      khorosId: data.khorosId.present ? data.khorosId.value : this.khorosId,
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
      rohot: data.rohot.present ? data.rohot.value : this.rohot,
      leader: data.leader.present ? data.leader.value : this.leader,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('stageId: $stageId, ')
          ..write('khorosId: $khorosId, ')
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
          ..write('rohot: $rohot, ')
          ..write('leader: $leader')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    personId,
    personName,
    stageId,
    khorosId,
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
    rohot,
    leader,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.personId == this.personId &&
          other.personName == this.personName &&
          other.stageId == this.stageId &&
          other.khorosId == this.khorosId &&
          other.areaId == this.areaId &&
          other.streetName == this.streetName &&
          other.phone == this.phone &&
          other.mobile == this.mobile &&
          other.day == this.day &&
          other.month == this.month &&
          other.year == this.year &&
          other.jenderName == this.jenderName &&
          other.fatherId == this.fatherId &&
          $driftBlobEquality.equals(other.photo, this.photo) &&
          other.rohot == this.rohot &&
          other.leader == this.leader);
}

class PersonsCompanion extends UpdateCompanion<Person> {
  final Value<int> personId;
  final Value<String?> personName;
  final Value<int?> stageId;
  final Value<int?> khorosId;
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
  final Value<String?> rohot;
  final Value<String?> leader;
  const PersonsCompanion({
    this.personId = const Value.absent(),
    this.personName = const Value.absent(),
    this.stageId = const Value.absent(),
    this.khorosId = const Value.absent(),
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
    this.rohot = const Value.absent(),
    this.leader = const Value.absent(),
  });
  PersonsCompanion.insert({
    this.personId = const Value.absent(),
    this.personName = const Value.absent(),
    this.stageId = const Value.absent(),
    this.khorosId = const Value.absent(),
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
    this.rohot = const Value.absent(),
    this.leader = const Value.absent(),
  });
  static Insertable<Person> custom({
    Expression<int>? personId,
    Expression<String>? personName,
    Expression<int>? stageId,
    Expression<int>? khorosId,
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
    Expression<String>? rohot,
    Expression<String>? leader,
  }) {
    return RawValuesInsertable({
      if (personId != null) 'Person_ID': personId,
      if (personName != null) 'Person_Name': personName,
      if (stageId != null) 'Stage_ID': stageId,
      if (khorosId != null) 'Khoros_ID': khorosId,
      if (areaId != null) 'Area_ID': areaId,
      if (streetName != null) 'Street_Name': streetName,
      if (phone != null) 'Phone': phone,
      if (mobile != null) 'Mobile': mobile,
      if (day != null) 'Day': day,
      if (month != null) 'Month': month,
      if (year != null) 'Year': year,
      if (jenderName != null) 'Jender_Name': jenderName,
      if (fatherId != null) 'Father_ID': fatherId,
      if (photo != null) 'Photo': photo,
      if (rohot != null) 'Rohot': rohot,
      if (leader != null) 'Leader': leader,
    });
  }

  PersonsCompanion copyWith({
    Value<int>? personId,
    Value<String?>? personName,
    Value<int?>? stageId,
    Value<int?>? khorosId,
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
    Value<String?>? rohot,
    Value<String?>? leader,
  }) {
    return PersonsCompanion(
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      stageId: stageId ?? this.stageId,
      khorosId: khorosId ?? this.khorosId,
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
      rohot: rohot ?? this.rohot,
      leader: leader ?? this.leader,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (personId.present) {
      map['Person_ID'] = Variable<int>(personId.value);
    }
    if (personName.present) {
      map['Person_Name'] = Variable<String>(personName.value);
    }
    if (stageId.present) {
      map['Stage_ID'] = Variable<int>(stageId.value);
    }
    if (khorosId.present) {
      map['Khoros_ID'] = Variable<int>(khorosId.value);
    }
    if (areaId.present) {
      map['Area_ID'] = Variable<int>(areaId.value);
    }
    if (streetName.present) {
      map['Street_Name'] = Variable<String>(streetName.value);
    }
    if (phone.present) {
      map['Phone'] = Variable<String>(phone.value);
    }
    if (mobile.present) {
      map['Mobile'] = Variable<String>(mobile.value);
    }
    if (day.present) {
      map['Day'] = Variable<int>(day.value);
    }
    if (month.present) {
      map['Month'] = Variable<int>(month.value);
    }
    if (year.present) {
      map['Year'] = Variable<int>(year.value);
    }
    if (jenderName.present) {
      map['Jender_Name'] = Variable<String>(jenderName.value);
    }
    if (fatherId.present) {
      map['Father_ID'] = Variable<int>(fatherId.value);
    }
    if (photo.present) {
      map['Photo'] = Variable<Uint8List>(photo.value);
    }
    if (rohot.present) {
      map['Rohot'] = Variable<String>(rohot.value);
    }
    if (leader.present) {
      map['Leader'] = Variable<String>(leader.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsCompanion(')
          ..write('personId: $personId, ')
          ..write('personName: $personName, ')
          ..write('stageId: $stageId, ')
          ..write('khorosId: $khorosId, ')
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
          ..write('rohot: $rohot, ')
          ..write('leader: $leader')
          ..write(')'))
        .toString();
  }
}

class $ServicesTable extends Services
    with TableInfo<$ServicesTable, ServiceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<int> serviceId = GeneratedColumn<int>(
    'Service_ID',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serviceNameMeta = const VerificationMeta(
    'serviceName',
  );
  @override
  late final GeneratedColumn<String> serviceName = GeneratedColumn<String>(
    'Service_Name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'Day_Of_Week',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'Hour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'Minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endHourMeta = const VerificationMeta(
    'endHour',
  );
  @override
  late final GeneratedColumn<int> endHour = GeneratedColumn<int>(
    'End_Hour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endMinuteMeta = const VerificationMeta(
    'endMinute',
  );
  @override
  late final GeneratedColumn<int> endMinute = GeneratedColumn<int>(
    'End_Minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoMeta = const VerificationMeta('logo');
  @override
  late final GeneratedColumn<Uint8List> logo = GeneratedColumn<Uint8List>(
    'Logo',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    serviceId,
    serviceName,
    dayOfWeek,
    hour,
    minute,
    endHour,
    endMinute,
    logo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Services';
  @override
  VerificationContext validateIntegrity(
    Insertable<ServiceData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Service_ID')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['Service_ID']!, _serviceIdMeta),
      );
    }
    if (data.containsKey('Service_Name')) {
      context.handle(
        _serviceNameMeta,
        serviceName.isAcceptableOrUnknown(
          data['Service_Name']!,
          _serviceNameMeta,
        ),
      );
    }
    if (data.containsKey('Day_Of_Week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['Day_Of_Week']!, _dayOfWeekMeta),
      );
    }
    if (data.containsKey('Hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['Hour']!, _hourMeta),
      );
    }
    if (data.containsKey('Minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['Minute']!, _minuteMeta),
      );
    }
    if (data.containsKey('End_Hour')) {
      context.handle(
        _endHourMeta,
        endHour.isAcceptableOrUnknown(data['End_Hour']!, _endHourMeta),
      );
    }
    if (data.containsKey('End_Minute')) {
      context.handle(
        _endMinuteMeta,
        endMinute.isAcceptableOrUnknown(data['End_Minute']!, _endMinuteMeta),
      );
    }
    if (data.containsKey('Logo')) {
      context.handle(
        _logoMeta,
        logo.isAcceptableOrUnknown(data['Logo']!, _logoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {serviceId};
  @override
  ServiceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServiceData(
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Service_ID'],
      )!,
      serviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Service_Name'],
      ),
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Day_Of_Week'],
      ),
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Hour'],
      ),
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Minute'],
      ),
      endHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}End_Hour'],
      ),
      endMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}End_Minute'],
      ),
      logo: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}Logo'],
      ),
    );
  }

  @override
  $ServicesTable createAlias(String alias) {
    return $ServicesTable(attachedDatabase, alias);
  }
}

class ServiceData extends DataClass implements Insertable<ServiceData> {
  final int serviceId;
  final String? serviceName;
  final int? dayOfWeek;
  final int? hour;
  final int? minute;
  final int? endHour;
  final int? endMinute;
  final Uint8List? logo;
  const ServiceData({
    required this.serviceId,
    this.serviceName,
    this.dayOfWeek,
    this.hour,
    this.minute,
    this.endHour,
    this.endMinute,
    this.logo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Service_ID'] = Variable<int>(serviceId);
    if (!nullToAbsent || serviceName != null) {
      map['Service_Name'] = Variable<String>(serviceName);
    }
    if (!nullToAbsent || dayOfWeek != null) {
      map['Day_Of_Week'] = Variable<int>(dayOfWeek);
    }
    if (!nullToAbsent || hour != null) {
      map['Hour'] = Variable<int>(hour);
    }
    if (!nullToAbsent || minute != null) {
      map['Minute'] = Variable<int>(minute);
    }
    if (!nullToAbsent || endHour != null) {
      map['End_Hour'] = Variable<int>(endHour);
    }
    if (!nullToAbsent || endMinute != null) {
      map['End_Minute'] = Variable<int>(endMinute);
    }
    if (!nullToAbsent || logo != null) {
      map['Logo'] = Variable<Uint8List>(logo);
    }
    return map;
  }

  ServicesCompanion toCompanion(bool nullToAbsent) {
    return ServicesCompanion(
      serviceId: Value(serviceId),
      serviceName: serviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceName),
      dayOfWeek: dayOfWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfWeek),
      hour: hour == null && nullToAbsent ? const Value.absent() : Value(hour),
      minute: minute == null && nullToAbsent
          ? const Value.absent()
          : Value(minute),
      endHour: endHour == null && nullToAbsent
          ? const Value.absent()
          : Value(endHour),
      endMinute: endMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(endMinute),
      logo: logo == null && nullToAbsent ? const Value.absent() : Value(logo),
    );
  }

  factory ServiceData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServiceData(
      serviceId: serializer.fromJson<int>(json['serviceId']),
      serviceName: serializer.fromJson<String?>(json['serviceName']),
      dayOfWeek: serializer.fromJson<int?>(json['dayOfWeek']),
      hour: serializer.fromJson<int?>(json['hour']),
      minute: serializer.fromJson<int?>(json['minute']),
      endHour: serializer.fromJson<int?>(json['endHour']),
      endMinute: serializer.fromJson<int?>(json['endMinute']),
      logo: serializer.fromJson<Uint8List?>(json['logo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serviceId': serializer.toJson<int>(serviceId),
      'serviceName': serializer.toJson<String?>(serviceName),
      'dayOfWeek': serializer.toJson<int?>(dayOfWeek),
      'hour': serializer.toJson<int?>(hour),
      'minute': serializer.toJson<int?>(minute),
      'endHour': serializer.toJson<int?>(endHour),
      'endMinute': serializer.toJson<int?>(endMinute),
      'logo': serializer.toJson<Uint8List?>(logo),
    };
  }

  ServiceData copyWith({
    int? serviceId,
    Value<String?> serviceName = const Value.absent(),
    Value<int?> dayOfWeek = const Value.absent(),
    Value<int?> hour = const Value.absent(),
    Value<int?> minute = const Value.absent(),
    Value<int?> endHour = const Value.absent(),
    Value<int?> endMinute = const Value.absent(),
    Value<Uint8List?> logo = const Value.absent(),
  }) => ServiceData(
    serviceId: serviceId ?? this.serviceId,
    serviceName: serviceName.present ? serviceName.value : this.serviceName,
    dayOfWeek: dayOfWeek.present ? dayOfWeek.value : this.dayOfWeek,
    hour: hour.present ? hour.value : this.hour,
    minute: minute.present ? minute.value : this.minute,
    endHour: endHour.present ? endHour.value : this.endHour,
    endMinute: endMinute.present ? endMinute.value : this.endMinute,
    logo: logo.present ? logo.value : this.logo,
  );
  ServiceData copyWithCompanion(ServicesCompanion data) {
    return ServiceData(
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      serviceName: data.serviceName.present
          ? data.serviceName.value
          : this.serviceName,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      endHour: data.endHour.present ? data.endHour.value : this.endHour,
      endMinute: data.endMinute.present ? data.endMinute.value : this.endMinute,
      logo: data.logo.present ? data.logo.value : this.logo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServiceData(')
          ..write('serviceId: $serviceId, ')
          ..write('serviceName: $serviceName, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('endHour: $endHour, ')
          ..write('endMinute: $endMinute, ')
          ..write('logo: $logo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    serviceId,
    serviceName,
    dayOfWeek,
    hour,
    minute,
    endHour,
    endMinute,
    $driftBlobEquality.hash(logo),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServiceData &&
          other.serviceId == this.serviceId &&
          other.serviceName == this.serviceName &&
          other.dayOfWeek == this.dayOfWeek &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.endHour == this.endHour &&
          other.endMinute == this.endMinute &&
          $driftBlobEquality.equals(other.logo, this.logo));
}

class ServicesCompanion extends UpdateCompanion<ServiceData> {
  final Value<int> serviceId;
  final Value<String?> serviceName;
  final Value<int?> dayOfWeek;
  final Value<int?> hour;
  final Value<int?> minute;
  final Value<int?> endHour;
  final Value<int?> endMinute;
  final Value<Uint8List?> logo;
  const ServicesCompanion({
    this.serviceId = const Value.absent(),
    this.serviceName = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.endHour = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.logo = const Value.absent(),
  });
  ServicesCompanion.insert({
    this.serviceId = const Value.absent(),
    this.serviceName = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.endHour = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.logo = const Value.absent(),
  });
  static Insertable<ServiceData> custom({
    Expression<int>? serviceId,
    Expression<String>? serviceName,
    Expression<int>? dayOfWeek,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<int>? endHour,
    Expression<int>? endMinute,
    Expression<Uint8List>? logo,
  }) {
    return RawValuesInsertable({
      if (serviceId != null) 'Service_ID': serviceId,
      if (serviceName != null) 'Service_Name': serviceName,
      if (dayOfWeek != null) 'Day_Of_Week': dayOfWeek,
      if (hour != null) 'Hour': hour,
      if (minute != null) 'Minute': minute,
      if (endHour != null) 'End_Hour': endHour,
      if (endMinute != null) 'End_Minute': endMinute,
      if (logo != null) 'Logo': logo,
    });
  }

  ServicesCompanion copyWith({
    Value<int>? serviceId,
    Value<String?>? serviceName,
    Value<int?>? dayOfWeek,
    Value<int?>? hour,
    Value<int?>? minute,
    Value<int?>? endHour,
    Value<int?>? endMinute,
    Value<Uint8List?>? logo,
  }) {
    return ServicesCompanion(
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      logo: logo ?? this.logo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serviceId.present) {
      map['Service_ID'] = Variable<int>(serviceId.value);
    }
    if (serviceName.present) {
      map['Service_Name'] = Variable<String>(serviceName.value);
    }
    if (dayOfWeek.present) {
      map['Day_Of_Week'] = Variable<int>(dayOfWeek.value);
    }
    if (hour.present) {
      map['Hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['Minute'] = Variable<int>(minute.value);
    }
    if (endHour.present) {
      map['End_Hour'] = Variable<int>(endHour.value);
    }
    if (endMinute.present) {
      map['End_Minute'] = Variable<int>(endMinute.value);
    }
    if (logo.present) {
      map['Logo'] = Variable<Uint8List>(logo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServicesCompanion(')
          ..write('serviceId: $serviceId, ')
          ..write('serviceName: $serviceName, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('endHour: $endHour, ')
          ..write('endMinute: $endMinute, ')
          ..write('logo: $logo')
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
    'Stage_ID',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _stageNameMeta = const VerificationMeta(
    'stageName',
  );
  @override
  late final GeneratedColumn<String> stageName = GeneratedColumn<String>(
    'Stage_Name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<int> serviceId = GeneratedColumn<int>(
    'Service_ID',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Services (Service_ID) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _nextStageIdMeta = const VerificationMeta(
    'nextStageId',
  );
  @override
  late final GeneratedColumn<int> nextStageId = GeneratedColumn<int>(
    'Next_Stage_ID',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Stages (Stage_ID) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    stageId,
    stageName,
    serviceId,
    nextStageId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Stages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Stage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Stage_ID')) {
      context.handle(
        _stageIdMeta,
        stageId.isAcceptableOrUnknown(data['Stage_ID']!, _stageIdMeta),
      );
    }
    if (data.containsKey('Stage_Name')) {
      context.handle(
        _stageNameMeta,
        stageName.isAcceptableOrUnknown(data['Stage_Name']!, _stageNameMeta),
      );
    }
    if (data.containsKey('Service_ID')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['Service_ID']!, _serviceIdMeta),
      );
    }
    if (data.containsKey('Next_Stage_ID')) {
      context.handle(
        _nextStageIdMeta,
        nextStageId.isAcceptableOrUnknown(
          data['Next_Stage_ID']!,
          _nextStageIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stageId};
  @override
  Stage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Stage(
      stageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Stage_ID'],
      )!,
      stageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Stage_Name'],
      ),
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Service_ID'],
      ),
      nextStageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Next_Stage_ID'],
      ),
    );
  }

  @override
  $StagesTable createAlias(String alias) {
    return $StagesTable(attachedDatabase, alias);
  }
}

class Stage extends DataClass implements Insertable<Stage> {
  final int stageId;
  final String? stageName;
  final int? serviceId;
  final int? nextStageId;
  const Stage({
    required this.stageId,
    this.stageName,
    this.serviceId,
    this.nextStageId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Stage_ID'] = Variable<int>(stageId);
    if (!nullToAbsent || stageName != null) {
      map['Stage_Name'] = Variable<String>(stageName);
    }
    if (!nullToAbsent || serviceId != null) {
      map['Service_ID'] = Variable<int>(serviceId);
    }
    if (!nullToAbsent || nextStageId != null) {
      map['Next_Stage_ID'] = Variable<int>(nextStageId);
    }
    return map;
  }

  StagesCompanion toCompanion(bool nullToAbsent) {
    return StagesCompanion(
      stageId: Value(stageId),
      stageName: stageName == null && nullToAbsent
          ? const Value.absent()
          : Value(stageName),
      serviceId: serviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceId),
      nextStageId: nextStageId == null && nullToAbsent
          ? const Value.absent()
          : Value(nextStageId),
    );
  }

  factory Stage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Stage(
      stageId: serializer.fromJson<int>(json['stageId']),
      stageName: serializer.fromJson<String?>(json['stageName']),
      serviceId: serializer.fromJson<int?>(json['serviceId']),
      nextStageId: serializer.fromJson<int?>(json['nextStageId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stageId': serializer.toJson<int>(stageId),
      'stageName': serializer.toJson<String?>(stageName),
      'serviceId': serializer.toJson<int?>(serviceId),
      'nextStageId': serializer.toJson<int?>(nextStageId),
    };
  }

  Stage copyWith({
    int? stageId,
    Value<String?> stageName = const Value.absent(),
    Value<int?> serviceId = const Value.absent(),
    Value<int?> nextStageId = const Value.absent(),
  }) => Stage(
    stageId: stageId ?? this.stageId,
    stageName: stageName.present ? stageName.value : this.stageName,
    serviceId: serviceId.present ? serviceId.value : this.serviceId,
    nextStageId: nextStageId.present ? nextStageId.value : this.nextStageId,
  );
  Stage copyWithCompanion(StagesCompanion data) {
    return Stage(
      stageId: data.stageId.present ? data.stageId.value : this.stageId,
      stageName: data.stageName.present ? data.stageName.value : this.stageName,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
      nextStageId: data.nextStageId.present
          ? data.nextStageId.value
          : this.nextStageId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Stage(')
          ..write('stageId: $stageId, ')
          ..write('stageName: $stageName, ')
          ..write('serviceId: $serviceId, ')
          ..write('nextStageId: $nextStageId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(stageId, stageName, serviceId, nextStageId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stage &&
          other.stageId == this.stageId &&
          other.stageName == this.stageName &&
          other.serviceId == this.serviceId &&
          other.nextStageId == this.nextStageId);
}

class StagesCompanion extends UpdateCompanion<Stage> {
  final Value<int> stageId;
  final Value<String?> stageName;
  final Value<int?> serviceId;
  final Value<int?> nextStageId;
  const StagesCompanion({
    this.stageId = const Value.absent(),
    this.stageName = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.nextStageId = const Value.absent(),
  });
  StagesCompanion.insert({
    this.stageId = const Value.absent(),
    this.stageName = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.nextStageId = const Value.absent(),
  });
  static Insertable<Stage> custom({
    Expression<int>? stageId,
    Expression<String>? stageName,
    Expression<int>? serviceId,
    Expression<int>? nextStageId,
  }) {
    return RawValuesInsertable({
      if (stageId != null) 'Stage_ID': stageId,
      if (stageName != null) 'Stage_Name': stageName,
      if (serviceId != null) 'Service_ID': serviceId,
      if (nextStageId != null) 'Next_Stage_ID': nextStageId,
    });
  }

  StagesCompanion copyWith({
    Value<int>? stageId,
    Value<String?>? stageName,
    Value<int?>? serviceId,
    Value<int?>? nextStageId,
  }) {
    return StagesCompanion(
      stageId: stageId ?? this.stageId,
      stageName: stageName ?? this.stageName,
      serviceId: serviceId ?? this.serviceId,
      nextStageId: nextStageId ?? this.nextStageId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stageId.present) {
      map['Stage_ID'] = Variable<int>(stageId.value);
    }
    if (stageName.present) {
      map['Stage_Name'] = Variable<String>(stageName.value);
    }
    if (serviceId.present) {
      map['Service_ID'] = Variable<int>(serviceId.value);
    }
    if (nextStageId.present) {
      map['Next_Stage_ID'] = Variable<int>(nextStageId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StagesCompanion(')
          ..write('stageId: $stageId, ')
          ..write('stageName: $stageName, ')
          ..write('serviceId: $serviceId, ')
          ..write('nextStageId: $nextStageId')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingKeyMeta = const VerificationMeta(
    'settingKey',
  );
  @override
  late final GeneratedColumn<String> settingKey = GeneratedColumn<String>(
    'Setting_Key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingValueMeta = const VerificationMeta(
    'settingValue',
  );
  @override
  late final GeneratedColumn<String> settingValue = GeneratedColumn<String>(
    'Setting_Value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [settingKey, settingValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Setting_Key')) {
      context.handle(
        _settingKeyMeta,
        settingKey.isAcceptableOrUnknown(data['Setting_Key']!, _settingKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_settingKeyMeta);
    }
    if (data.containsKey('Setting_Value')) {
      context.handle(
        _settingValueMeta,
        settingValue.isAcceptableOrUnknown(
          data['Setting_Value']!,
          _settingValueMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingKey};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      settingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Setting_Key'],
      )!,
      settingValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Setting_Value'],
      ),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String settingKey;
  final String? settingValue;
  const Setting({required this.settingKey, this.settingValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Setting_Key'] = Variable<String>(settingKey);
    if (!nullToAbsent || settingValue != null) {
      map['Setting_Value'] = Variable<String>(settingValue);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      settingKey: Value(settingKey),
      settingValue: settingValue == null && nullToAbsent
          ? const Value.absent()
          : Value(settingValue),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      settingKey: serializer.fromJson<String>(json['settingKey']),
      settingValue: serializer.fromJson<String?>(json['settingValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'settingKey': serializer.toJson<String>(settingKey),
      'settingValue': serializer.toJson<String?>(settingValue),
    };
  }

  Setting copyWith({
    String? settingKey,
    Value<String?> settingValue = const Value.absent(),
  }) => Setting(
    settingKey: settingKey ?? this.settingKey,
    settingValue: settingValue.present ? settingValue.value : this.settingValue,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      settingKey: data.settingKey.present
          ? data.settingKey.value
          : this.settingKey,
      settingValue: data.settingValue.present
          ? data.settingValue.value
          : this.settingValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('settingKey: $settingKey, ')
          ..write('settingValue: $settingValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingKey, settingValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.settingKey == this.settingKey &&
          other.settingValue == this.settingValue);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> settingKey;
  final Value<String?> settingValue;
  final Value<int> rowid;
  const SettingsCompanion({
    this.settingKey = const Value.absent(),
    this.settingValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String settingKey,
    this.settingValue = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : settingKey = Value(settingKey);
  static Insertable<Setting> custom({
    Expression<String>? settingKey,
    Expression<String>? settingValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (settingKey != null) 'Setting_Key': settingKey,
      if (settingValue != null) 'Setting_Value': settingValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? settingKey,
    Value<String?>? settingValue,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      settingKey: settingKey ?? this.settingKey,
      settingValue: settingValue ?? this.settingValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingKey.present) {
      map['Setting_Key'] = Variable<String>(settingKey.value);
    }
    if (settingValue.present) {
      map['Setting_Value'] = Variable<String>(settingValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('settingKey: $settingKey, ')
          ..write('settingValue: $settingValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TayoCardsTable extends TayoCards
    with TableInfo<$TayoCardsTable, TayoCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TayoCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'Card_ID',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cardNameMeta = const VerificationMeta(
    'cardName',
  );
  @override
  late final GeneratedColumn<String> cardName = GeneratedColumn<String>(
    'Card_Name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardPointsMeta = const VerificationMeta(
    'cardPoints',
  );
  @override
  late final GeneratedColumn<int> cardPoints = GeneratedColumn<int>(
    'Card_Points',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardImageMeta = const VerificationMeta(
    'cardImage',
  );
  @override
  late final GeneratedColumn<Uint8List> cardImage = GeneratedColumn<Uint8List>(
    'Card_Image',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cardId,
    cardName,
    cardPoints,
    cardImage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Tayo_Cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<TayoCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Card_ID')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['Card_ID']!, _cardIdMeta),
      );
    }
    if (data.containsKey('Card_Name')) {
      context.handle(
        _cardNameMeta,
        cardName.isAcceptableOrUnknown(data['Card_Name']!, _cardNameMeta),
      );
    }
    if (data.containsKey('Card_Points')) {
      context.handle(
        _cardPointsMeta,
        cardPoints.isAcceptableOrUnknown(data['Card_Points']!, _cardPointsMeta),
      );
    }
    if (data.containsKey('Card_Image')) {
      context.handle(
        _cardImageMeta,
        cardImage.isAcceptableOrUnknown(data['Card_Image']!, _cardImageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cardId};
  @override
  TayoCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TayoCard(
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Card_ID'],
      )!,
      cardName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Card_Name'],
      ),
      cardPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Card_Points'],
      ),
      cardImage: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}Card_Image'],
      ),
    );
  }

  @override
  $TayoCardsTable createAlias(String alias) {
    return $TayoCardsTable(attachedDatabase, alias);
  }
}

class TayoCard extends DataClass implements Insertable<TayoCard> {
  final int cardId;
  final String? cardName;
  final int? cardPoints;
  final Uint8List? cardImage;
  const TayoCard({
    required this.cardId,
    this.cardName,
    this.cardPoints,
    this.cardImage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Card_ID'] = Variable<int>(cardId);
    if (!nullToAbsent || cardName != null) {
      map['Card_Name'] = Variable<String>(cardName);
    }
    if (!nullToAbsent || cardPoints != null) {
      map['Card_Points'] = Variable<int>(cardPoints);
    }
    if (!nullToAbsent || cardImage != null) {
      map['Card_Image'] = Variable<Uint8List>(cardImage);
    }
    return map;
  }

  TayoCardsCompanion toCompanion(bool nullToAbsent) {
    return TayoCardsCompanion(
      cardId: Value(cardId),
      cardName: cardName == null && nullToAbsent
          ? const Value.absent()
          : Value(cardName),
      cardPoints: cardPoints == null && nullToAbsent
          ? const Value.absent()
          : Value(cardPoints),
      cardImage: cardImage == null && nullToAbsent
          ? const Value.absent()
          : Value(cardImage),
    );
  }

  factory TayoCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TayoCard(
      cardId: serializer.fromJson<int>(json['cardId']),
      cardName: serializer.fromJson<String?>(json['cardName']),
      cardPoints: serializer.fromJson<int?>(json['cardPoints']),
      cardImage: serializer.fromJson<Uint8List?>(json['cardImage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cardId': serializer.toJson<int>(cardId),
      'cardName': serializer.toJson<String?>(cardName),
      'cardPoints': serializer.toJson<int?>(cardPoints),
      'cardImage': serializer.toJson<Uint8List?>(cardImage),
    };
  }

  TayoCard copyWith({
    int? cardId,
    Value<String?> cardName = const Value.absent(),
    Value<int?> cardPoints = const Value.absent(),
    Value<Uint8List?> cardImage = const Value.absent(),
  }) => TayoCard(
    cardId: cardId ?? this.cardId,
    cardName: cardName.present ? cardName.value : this.cardName,
    cardPoints: cardPoints.present ? cardPoints.value : this.cardPoints,
    cardImage: cardImage.present ? cardImage.value : this.cardImage,
  );
  TayoCard copyWithCompanion(TayoCardsCompanion data) {
    return TayoCard(
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      cardName: data.cardName.present ? data.cardName.value : this.cardName,
      cardPoints: data.cardPoints.present
          ? data.cardPoints.value
          : this.cardPoints,
      cardImage: data.cardImage.present ? data.cardImage.value : this.cardImage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TayoCard(')
          ..write('cardId: $cardId, ')
          ..write('cardName: $cardName, ')
          ..write('cardPoints: $cardPoints, ')
          ..write('cardImage: $cardImage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cardId,
    cardName,
    cardPoints,
    $driftBlobEquality.hash(cardImage),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TayoCard &&
          other.cardId == this.cardId &&
          other.cardName == this.cardName &&
          other.cardPoints == this.cardPoints &&
          $driftBlobEquality.equals(other.cardImage, this.cardImage));
}

class TayoCardsCompanion extends UpdateCompanion<TayoCard> {
  final Value<int> cardId;
  final Value<String?> cardName;
  final Value<int?> cardPoints;
  final Value<Uint8List?> cardImage;
  const TayoCardsCompanion({
    this.cardId = const Value.absent(),
    this.cardName = const Value.absent(),
    this.cardPoints = const Value.absent(),
    this.cardImage = const Value.absent(),
  });
  TayoCardsCompanion.insert({
    this.cardId = const Value.absent(),
    this.cardName = const Value.absent(),
    this.cardPoints = const Value.absent(),
    this.cardImage = const Value.absent(),
  });
  static Insertable<TayoCard> custom({
    Expression<int>? cardId,
    Expression<String>? cardName,
    Expression<int>? cardPoints,
    Expression<Uint8List>? cardImage,
  }) {
    return RawValuesInsertable({
      if (cardId != null) 'Card_ID': cardId,
      if (cardName != null) 'Card_Name': cardName,
      if (cardPoints != null) 'Card_Points': cardPoints,
      if (cardImage != null) 'Card_Image': cardImage,
    });
  }

  TayoCardsCompanion copyWith({
    Value<int>? cardId,
    Value<String?>? cardName,
    Value<int?>? cardPoints,
    Value<Uint8List?>? cardImage,
  }) {
    return TayoCardsCompanion(
      cardId: cardId ?? this.cardId,
      cardName: cardName ?? this.cardName,
      cardPoints: cardPoints ?? this.cardPoints,
      cardImage: cardImage ?? this.cardImage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cardId.present) {
      map['Card_ID'] = Variable<int>(cardId.value);
    }
    if (cardName.present) {
      map['Card_Name'] = Variable<String>(cardName.value);
    }
    if (cardPoints.present) {
      map['Card_Points'] = Variable<int>(cardPoints.value);
    }
    if (cardImage.present) {
      map['Card_Image'] = Variable<Uint8List>(cardImage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TayoCardsCompanion(')
          ..write('cardId: $cardId, ')
          ..write('cardName: $cardName, ')
          ..write('cardPoints: $cardPoints, ')
          ..write('cardImage: $cardImage')
          ..write(')'))
        .toString();
  }
}

class $PersonTayoPointsTable extends PersonTayoPoints
    with TableInfo<$PersonTayoPointsTable, PersonTayoPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonTayoPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'ID',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'Person_ID',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'Card_ID',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'Points',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _awardDateMeta = const VerificationMeta(
    'awardDate',
  );
  @override
  late final GeneratedColumn<String> awardDate = GeneratedColumn<String>(
    'Award_Date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAttendanceMeta = const VerificationMeta(
    'isAttendance',
  );
  @override
  late final GeneratedColumn<bool> isAttendance = GeneratedColumn<bool>(
    'Is_Attendance',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("Is_Attendance" IN (0, 1))',
    ),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'Notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<int> serviceId = GeneratedColumn<int>(
    'Service_ID',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    cardId,
    points,
    awardDate,
    isAttendance,
    notes,
    serviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Person_Tayo_Points';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonTayoPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ID')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['ID']!, _idMeta));
    }
    if (data.containsKey('Person_ID')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['Person_ID']!, _personIdMeta),
      );
    }
    if (data.containsKey('Card_ID')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['Card_ID']!, _cardIdMeta),
      );
    }
    if (data.containsKey('Points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['Points']!, _pointsMeta),
      );
    }
    if (data.containsKey('Award_Date')) {
      context.handle(
        _awardDateMeta,
        awardDate.isAcceptableOrUnknown(data['Award_Date']!, _awardDateMeta),
      );
    }
    if (data.containsKey('Is_Attendance')) {
      context.handle(
        _isAttendanceMeta,
        isAttendance.isAcceptableOrUnknown(
          data['Is_Attendance']!,
          _isAttendanceMeta,
        ),
      );
    }
    if (data.containsKey('Notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['Notes']!, _notesMeta),
      );
    }
    if (data.containsKey('Service_ID')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['Service_ID']!, _serviceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonTayoPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonTayoPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ID'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Person_ID'],
      ),
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Card_ID'],
      ),
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Points'],
      ),
      awardDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Award_Date'],
      ),
      isAttendance: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}Is_Attendance'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Notes'],
      ),
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Service_ID'],
      ),
    );
  }

  @override
  $PersonTayoPointsTable createAlias(String alias) {
    return $PersonTayoPointsTable(attachedDatabase, alias);
  }
}

class PersonTayoPoint extends DataClass implements Insertable<PersonTayoPoint> {
  final int id;
  final int? personId;
  final int? cardId;
  final int? points;
  final String? awardDate;
  final bool? isAttendance;
  final String? notes;
  final int? serviceId;
  const PersonTayoPoint({
    required this.id,
    this.personId,
    this.cardId,
    this.points,
    this.awardDate,
    this.isAttendance,
    this.notes,
    this.serviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ID'] = Variable<int>(id);
    if (!nullToAbsent || personId != null) {
      map['Person_ID'] = Variable<int>(personId);
    }
    if (!nullToAbsent || cardId != null) {
      map['Card_ID'] = Variable<int>(cardId);
    }
    if (!nullToAbsent || points != null) {
      map['Points'] = Variable<int>(points);
    }
    if (!nullToAbsent || awardDate != null) {
      map['Award_Date'] = Variable<String>(awardDate);
    }
    if (!nullToAbsent || isAttendance != null) {
      map['Is_Attendance'] = Variable<bool>(isAttendance);
    }
    if (!nullToAbsent || notes != null) {
      map['Notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || serviceId != null) {
      map['Service_ID'] = Variable<int>(serviceId);
    }
    return map;
  }

  PersonTayoPointsCompanion toCompanion(bool nullToAbsent) {
    return PersonTayoPointsCompanion(
      id: Value(id),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      cardId: cardId == null && nullToAbsent
          ? const Value.absent()
          : Value(cardId),
      points: points == null && nullToAbsent
          ? const Value.absent()
          : Value(points),
      awardDate: awardDate == null && nullToAbsent
          ? const Value.absent()
          : Value(awardDate),
      isAttendance: isAttendance == null && nullToAbsent
          ? const Value.absent()
          : Value(isAttendance),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      serviceId: serviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceId),
    );
  }

  factory PersonTayoPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonTayoPoint(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int?>(json['personId']),
      cardId: serializer.fromJson<int?>(json['cardId']),
      points: serializer.fromJson<int?>(json['points']),
      awardDate: serializer.fromJson<String?>(json['awardDate']),
      isAttendance: serializer.fromJson<bool?>(json['isAttendance']),
      notes: serializer.fromJson<String?>(json['notes']),
      serviceId: serializer.fromJson<int?>(json['serviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int?>(personId),
      'cardId': serializer.toJson<int?>(cardId),
      'points': serializer.toJson<int?>(points),
      'awardDate': serializer.toJson<String?>(awardDate),
      'isAttendance': serializer.toJson<bool?>(isAttendance),
      'notes': serializer.toJson<String?>(notes),
      'serviceId': serializer.toJson<int?>(serviceId),
    };
  }

  PersonTayoPoint copyWith({
    int? id,
    Value<int?> personId = const Value.absent(),
    Value<int?> cardId = const Value.absent(),
    Value<int?> points = const Value.absent(),
    Value<String?> awardDate = const Value.absent(),
    Value<bool?> isAttendance = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> serviceId = const Value.absent(),
  }) => PersonTayoPoint(
    id: id ?? this.id,
    personId: personId.present ? personId.value : this.personId,
    cardId: cardId.present ? cardId.value : this.cardId,
    points: points.present ? points.value : this.points,
    awardDate: awardDate.present ? awardDate.value : this.awardDate,
    isAttendance: isAttendance.present ? isAttendance.value : this.isAttendance,
    notes: notes.present ? notes.value : this.notes,
    serviceId: serviceId.present ? serviceId.value : this.serviceId,
  );
  PersonTayoPoint copyWithCompanion(PersonTayoPointsCompanion data) {
    return PersonTayoPoint(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      points: data.points.present ? data.points.value : this.points,
      awardDate: data.awardDate.present ? data.awardDate.value : this.awardDate,
      isAttendance: data.isAttendance.present
          ? data.isAttendance.value
          : this.isAttendance,
      notes: data.notes.present ? data.notes.value : this.notes,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonTayoPoint(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('cardId: $cardId, ')
          ..write('points: $points, ')
          ..write('awardDate: $awardDate, ')
          ..write('isAttendance: $isAttendance, ')
          ..write('notes: $notes, ')
          ..write('serviceId: $serviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    cardId,
    points,
    awardDate,
    isAttendance,
    notes,
    serviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonTayoPoint &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.cardId == this.cardId &&
          other.points == this.points &&
          other.awardDate == this.awardDate &&
          other.isAttendance == this.isAttendance &&
          other.notes == this.notes &&
          other.serviceId == this.serviceId);
}

class PersonTayoPointsCompanion extends UpdateCompanion<PersonTayoPoint> {
  final Value<int> id;
  final Value<int?> personId;
  final Value<int?> cardId;
  final Value<int?> points;
  final Value<String?> awardDate;
  final Value<bool?> isAttendance;
  final Value<String?> notes;
  final Value<int?> serviceId;
  const PersonTayoPointsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.points = const Value.absent(),
    this.awardDate = const Value.absent(),
    this.isAttendance = const Value.absent(),
    this.notes = const Value.absent(),
    this.serviceId = const Value.absent(),
  });
  PersonTayoPointsCompanion.insert({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.points = const Value.absent(),
    this.awardDate = const Value.absent(),
    this.isAttendance = const Value.absent(),
    this.notes = const Value.absent(),
    this.serviceId = const Value.absent(),
  });
  static Insertable<PersonTayoPoint> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<int>? cardId,
    Expression<int>? points,
    Expression<String>? awardDate,
    Expression<bool>? isAttendance,
    Expression<String>? notes,
    Expression<int>? serviceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'ID': id,
      if (personId != null) 'Person_ID': personId,
      if (cardId != null) 'Card_ID': cardId,
      if (points != null) 'Points': points,
      if (awardDate != null) 'Award_Date': awardDate,
      if (isAttendance != null) 'Is_Attendance': isAttendance,
      if (notes != null) 'Notes': notes,
      if (serviceId != null) 'Service_ID': serviceId,
    });
  }

  PersonTayoPointsCompanion copyWith({
    Value<int>? id,
    Value<int?>? personId,
    Value<int?>? cardId,
    Value<int?>? points,
    Value<String?>? awardDate,
    Value<bool?>? isAttendance,
    Value<String?>? notes,
    Value<int?>? serviceId,
  }) {
    return PersonTayoPointsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      cardId: cardId ?? this.cardId,
      points: points ?? this.points,
      awardDate: awardDate ?? this.awardDate,
      isAttendance: isAttendance ?? this.isAttendance,
      notes: notes ?? this.notes,
      serviceId: serviceId ?? this.serviceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['ID'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['Person_ID'] = Variable<int>(personId.value);
    }
    if (cardId.present) {
      map['Card_ID'] = Variable<int>(cardId.value);
    }
    if (points.present) {
      map['Points'] = Variable<int>(points.value);
    }
    if (awardDate.present) {
      map['Award_Date'] = Variable<String>(awardDate.value);
    }
    if (isAttendance.present) {
      map['Is_Attendance'] = Variable<bool>(isAttendance.value);
    }
    if (notes.present) {
      map['Notes'] = Variable<String>(notes.value);
    }
    if (serviceId.present) {
      map['Service_ID'] = Variable<int>(serviceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonTayoPointsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('cardId: $cardId, ')
          ..write('points: $points, ')
          ..write('awardDate: $awardDate, ')
          ..write('isAttendance: $isAttendance, ')
          ..write('notes: $notes, ')
          ..write('serviceId: $serviceId')
          ..write(')'))
        .toString();
  }
}

class $KhorosesTable extends Khoroses with TableInfo<$KhorosesTable, Khorose> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KhorosesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _khorosIdMeta = const VerificationMeta(
    'khorosId',
  );
  @override
  late final GeneratedColumn<int> khorosId = GeneratedColumn<int>(
    'Khoros_ID',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _khorosNameMeta = const VerificationMeta(
    'khorosName',
  );
  @override
  late final GeneratedColumn<String> khorosName = GeneratedColumn<String>(
    'Khoros_Name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoMeta = const VerificationMeta('logo');
  @override
  late final GeneratedColumn<Uint8List> logo = GeneratedColumn<Uint8List>(
    'Logo',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<int> serviceId = GeneratedColumn<int>(
    'Service_ID',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Services (Service_ID) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [khorosId, khorosName, logo, serviceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Khoroses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Khorose> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Khoros_ID')) {
      context.handle(
        _khorosIdMeta,
        khorosId.isAcceptableOrUnknown(data['Khoros_ID']!, _khorosIdMeta),
      );
    }
    if (data.containsKey('Khoros_Name')) {
      context.handle(
        _khorosNameMeta,
        khorosName.isAcceptableOrUnknown(data['Khoros_Name']!, _khorosNameMeta),
      );
    }
    if (data.containsKey('Logo')) {
      context.handle(
        _logoMeta,
        logo.isAcceptableOrUnknown(data['Logo']!, _logoMeta),
      );
    }
    if (data.containsKey('Service_ID')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['Service_ID']!, _serviceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {khorosId};
  @override
  Khorose map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Khorose(
      khorosId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Khoros_ID'],
      )!,
      khorosName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Khoros_Name'],
      ),
      logo: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}Logo'],
      ),
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Service_ID'],
      ),
    );
  }

  @override
  $KhorosesTable createAlias(String alias) {
    return $KhorosesTable(attachedDatabase, alias);
  }
}

class Khorose extends DataClass implements Insertable<Khorose> {
  final int khorosId;
  final String? khorosName;
  final Uint8List? logo;
  final int? serviceId;
  const Khorose({
    required this.khorosId,
    this.khorosName,
    this.logo,
    this.serviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Khoros_ID'] = Variable<int>(khorosId);
    if (!nullToAbsent || khorosName != null) {
      map['Khoros_Name'] = Variable<String>(khorosName);
    }
    if (!nullToAbsent || logo != null) {
      map['Logo'] = Variable<Uint8List>(logo);
    }
    if (!nullToAbsent || serviceId != null) {
      map['Service_ID'] = Variable<int>(serviceId);
    }
    return map;
  }

  KhorosesCompanion toCompanion(bool nullToAbsent) {
    return KhorosesCompanion(
      khorosId: Value(khorosId),
      khorosName: khorosName == null && nullToAbsent
          ? const Value.absent()
          : Value(khorosName),
      logo: logo == null && nullToAbsent ? const Value.absent() : Value(logo),
      serviceId: serviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceId),
    );
  }

  factory Khorose.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Khorose(
      khorosId: serializer.fromJson<int>(json['khorosId']),
      khorosName: serializer.fromJson<String?>(json['khorosName']),
      logo: serializer.fromJson<Uint8List?>(json['logo']),
      serviceId: serializer.fromJson<int?>(json['serviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'khorosId': serializer.toJson<int>(khorosId),
      'khorosName': serializer.toJson<String?>(khorosName),
      'logo': serializer.toJson<Uint8List?>(logo),
      'serviceId': serializer.toJson<int?>(serviceId),
    };
  }

  Khorose copyWith({
    int? khorosId,
    Value<String?> khorosName = const Value.absent(),
    Value<Uint8List?> logo = const Value.absent(),
    Value<int?> serviceId = const Value.absent(),
  }) => Khorose(
    khorosId: khorosId ?? this.khorosId,
    khorosName: khorosName.present ? khorosName.value : this.khorosName,
    logo: logo.present ? logo.value : this.logo,
    serviceId: serviceId.present ? serviceId.value : this.serviceId,
  );
  Khorose copyWithCompanion(KhorosesCompanion data) {
    return Khorose(
      khorosId: data.khorosId.present ? data.khorosId.value : this.khorosId,
      khorosName: data.khorosName.present
          ? data.khorosName.value
          : this.khorosName,
      logo: data.logo.present ? data.logo.value : this.logo,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Khorose(')
          ..write('khorosId: $khorosId, ')
          ..write('khorosName: $khorosName, ')
          ..write('logo: $logo, ')
          ..write('serviceId: $serviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    khorosId,
    khorosName,
    $driftBlobEquality.hash(logo),
    serviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Khorose &&
          other.khorosId == this.khorosId &&
          other.khorosName == this.khorosName &&
          $driftBlobEquality.equals(other.logo, this.logo) &&
          other.serviceId == this.serviceId);
}

class KhorosesCompanion extends UpdateCompanion<Khorose> {
  final Value<int> khorosId;
  final Value<String?> khorosName;
  final Value<Uint8List?> logo;
  final Value<int?> serviceId;
  const KhorosesCompanion({
    this.khorosId = const Value.absent(),
    this.khorosName = const Value.absent(),
    this.logo = const Value.absent(),
    this.serviceId = const Value.absent(),
  });
  KhorosesCompanion.insert({
    this.khorosId = const Value.absent(),
    this.khorosName = const Value.absent(),
    this.logo = const Value.absent(),
    this.serviceId = const Value.absent(),
  });
  static Insertable<Khorose> custom({
    Expression<int>? khorosId,
    Expression<String>? khorosName,
    Expression<Uint8List>? logo,
    Expression<int>? serviceId,
  }) {
    return RawValuesInsertable({
      if (khorosId != null) 'Khoros_ID': khorosId,
      if (khorosName != null) 'Khoros_Name': khorosName,
      if (logo != null) 'Logo': logo,
      if (serviceId != null) 'Service_ID': serviceId,
    });
  }

  KhorosesCompanion copyWith({
    Value<int>? khorosId,
    Value<String?>? khorosName,
    Value<Uint8List?>? logo,
    Value<int?>? serviceId,
  }) {
    return KhorosesCompanion(
      khorosId: khorosId ?? this.khorosId,
      khorosName: khorosName ?? this.khorosName,
      logo: logo ?? this.logo,
      serviceId: serviceId ?? this.serviceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (khorosId.present) {
      map['Khoros_ID'] = Variable<int>(khorosId.value);
    }
    if (khorosName.present) {
      map['Khoros_Name'] = Variable<String>(khorosName.value);
    }
    if (logo.present) {
      map['Logo'] = Variable<Uint8List>(logo.value);
    }
    if (serviceId.present) {
      map['Service_ID'] = Variable<int>(serviceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KhorosesCompanion(')
          ..write('khorosId: $khorosId, ')
          ..write('khorosName: $khorosName, ')
          ..write('logo: $logo, ')
          ..write('serviceId: $serviceId')
          ..write(')'))
        .toString();
  }
}

class $KhorosServicesTable extends KhorosServices
    with TableInfo<$KhorosServicesTable, KhorosService> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KhorosServicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _khorosIdMeta = const VerificationMeta(
    'khorosId',
  );
  @override
  late final GeneratedColumn<int> khorosId = GeneratedColumn<int>(
    'Khoros_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Khoroses (Khoros_ID) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<int> serviceId = GeneratedColumn<int>(
    'Service_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Services (Service_ID) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [khorosId, serviceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Khoros_Services';
  @override
  VerificationContext validateIntegrity(
    Insertable<KhorosService> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Khoros_ID')) {
      context.handle(
        _khorosIdMeta,
        khorosId.isAcceptableOrUnknown(data['Khoros_ID']!, _khorosIdMeta),
      );
    } else if (isInserting) {
      context.missing(_khorosIdMeta);
    }
    if (data.containsKey('Service_ID')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['Service_ID']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {khorosId, serviceId};
  @override
  KhorosService map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KhorosService(
      khorosId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Khoros_ID'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Service_ID'],
      )!,
    );
  }

  @override
  $KhorosServicesTable createAlias(String alias) {
    return $KhorosServicesTable(attachedDatabase, alias);
  }
}

class KhorosService extends DataClass implements Insertable<KhorosService> {
  final int khorosId;
  final int serviceId;
  const KhorosService({required this.khorosId, required this.serviceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Khoros_ID'] = Variable<int>(khorosId);
    map['Service_ID'] = Variable<int>(serviceId);
    return map;
  }

  KhorosServicesCompanion toCompanion(bool nullToAbsent) {
    return KhorosServicesCompanion(
      khorosId: Value(khorosId),
      serviceId: Value(serviceId),
    );
  }

  factory KhorosService.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KhorosService(
      khorosId: serializer.fromJson<int>(json['khorosId']),
      serviceId: serializer.fromJson<int>(json['serviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'khorosId': serializer.toJson<int>(khorosId),
      'serviceId': serializer.toJson<int>(serviceId),
    };
  }

  KhorosService copyWith({int? khorosId, int? serviceId}) => KhorosService(
    khorosId: khorosId ?? this.khorosId,
    serviceId: serviceId ?? this.serviceId,
  );
  KhorosService copyWithCompanion(KhorosServicesCompanion data) {
    return KhorosService(
      khorosId: data.khorosId.present ? data.khorosId.value : this.khorosId,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KhorosService(')
          ..write('khorosId: $khorosId, ')
          ..write('serviceId: $serviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(khorosId, serviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KhorosService &&
          other.khorosId == this.khorosId &&
          other.serviceId == this.serviceId);
}

class KhorosServicesCompanion extends UpdateCompanion<KhorosService> {
  final Value<int> khorosId;
  final Value<int> serviceId;
  final Value<int> rowid;
  const KhorosServicesCompanion({
    this.khorosId = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KhorosServicesCompanion.insert({
    required int khorosId,
    required int serviceId,
    this.rowid = const Value.absent(),
  }) : khorosId = Value(khorosId),
       serviceId = Value(serviceId);
  static Insertable<KhorosService> custom({
    Expression<int>? khorosId,
    Expression<int>? serviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (khorosId != null) 'Khoros_ID': khorosId,
      if (serviceId != null) 'Service_ID': serviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KhorosServicesCompanion copyWith({
    Value<int>? khorosId,
    Value<int>? serviceId,
    Value<int>? rowid,
  }) {
    return KhorosServicesCompanion(
      khorosId: khorosId ?? this.khorosId,
      serviceId: serviceId ?? this.serviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (khorosId.present) {
      map['Khoros_ID'] = Variable<int>(khorosId.value);
    }
    if (serviceId.present) {
      map['Service_ID'] = Variable<int>(serviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KhorosServicesCompanion(')
          ..write('khorosId: $khorosId, ')
          ..write('serviceId: $serviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StageServicesTable extends StageServices
    with TableInfo<$StageServicesTable, StageService> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StageServicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stageIdMeta = const VerificationMeta(
    'stageId',
  );
  @override
  late final GeneratedColumn<int> stageId = GeneratedColumn<int>(
    'Stage_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Stages (Stage_ID) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<int> serviceId = GeneratedColumn<int>(
    'Service_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Services (Service_ID) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [stageId, serviceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Stage_Services';
  @override
  VerificationContext validateIntegrity(
    Insertable<StageService> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Stage_ID')) {
      context.handle(
        _stageIdMeta,
        stageId.isAcceptableOrUnknown(data['Stage_ID']!, _stageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stageIdMeta);
    }
    if (data.containsKey('Service_ID')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['Service_ID']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stageId, serviceId};
  @override
  StageService map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StageService(
      stageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Stage_ID'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Service_ID'],
      )!,
    );
  }

  @override
  $StageServicesTable createAlias(String alias) {
    return $StageServicesTable(attachedDatabase, alias);
  }
}

class StageService extends DataClass implements Insertable<StageService> {
  final int stageId;
  final int serviceId;
  const StageService({required this.stageId, required this.serviceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Stage_ID'] = Variable<int>(stageId);
    map['Service_ID'] = Variable<int>(serviceId);
    return map;
  }

  StageServicesCompanion toCompanion(bool nullToAbsent) {
    return StageServicesCompanion(
      stageId: Value(stageId),
      serviceId: Value(serviceId),
    );
  }

  factory StageService.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StageService(
      stageId: serializer.fromJson<int>(json['stageId']),
      serviceId: serializer.fromJson<int>(json['serviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stageId': serializer.toJson<int>(stageId),
      'serviceId': serializer.toJson<int>(serviceId),
    };
  }

  StageService copyWith({int? stageId, int? serviceId}) => StageService(
    stageId: stageId ?? this.stageId,
    serviceId: serviceId ?? this.serviceId,
  );
  StageService copyWithCompanion(StageServicesCompanion data) {
    return StageService(
      stageId: data.stageId.present ? data.stageId.value : this.stageId,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StageService(')
          ..write('stageId: $stageId, ')
          ..write('serviceId: $serviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(stageId, serviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StageService &&
          other.stageId == this.stageId &&
          other.serviceId == this.serviceId);
}

class StageServicesCompanion extends UpdateCompanion<StageService> {
  final Value<int> stageId;
  final Value<int> serviceId;
  final Value<int> rowid;
  const StageServicesCompanion({
    this.stageId = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StageServicesCompanion.insert({
    required int stageId,
    required int serviceId,
    this.rowid = const Value.absent(),
  }) : stageId = Value(stageId),
       serviceId = Value(serviceId);
  static Insertable<StageService> custom({
    Expression<int>? stageId,
    Expression<int>? serviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (stageId != null) 'Stage_ID': stageId,
      if (serviceId != null) 'Service_ID': serviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StageServicesCompanion copyWith({
    Value<int>? stageId,
    Value<int>? serviceId,
    Value<int>? rowid,
  }) {
    return StageServicesCompanion(
      stageId: stageId ?? this.stageId,
      serviceId: serviceId ?? this.serviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stageId.present) {
      map['Stage_ID'] = Variable<int>(stageId.value);
    }
    if (serviceId.present) {
      map['Service_ID'] = Variable<int>(serviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StageServicesCompanion(')
          ..write('stageId: $stageId, ')
          ..write('serviceId: $serviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonServicesTable extends PersonServices
    with TableInfo<$PersonServicesTable, PersonService> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonServicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'Person_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Persons (Person_ID) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _serviceIdMeta = const VerificationMeta(
    'serviceId',
  );
  @override
  late final GeneratedColumn<int> serviceId = GeneratedColumn<int>(
    'Service_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Services (Service_ID) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [personId, serviceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Person_Services';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonService> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Person_ID')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['Person_ID']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('Service_ID')) {
      context.handle(
        _serviceIdMeta,
        serviceId.isAcceptableOrUnknown(data['Service_ID']!, _serviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {personId, serviceId};
  @override
  PersonService map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonService(
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Person_ID'],
      )!,
      serviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Service_ID'],
      )!,
    );
  }

  @override
  $PersonServicesTable createAlias(String alias) {
    return $PersonServicesTable(attachedDatabase, alias);
  }
}

class PersonService extends DataClass implements Insertable<PersonService> {
  final int personId;
  final int serviceId;
  const PersonService({required this.personId, required this.serviceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Person_ID'] = Variable<int>(personId);
    map['Service_ID'] = Variable<int>(serviceId);
    return map;
  }

  PersonServicesCompanion toCompanion(bool nullToAbsent) {
    return PersonServicesCompanion(
      personId: Value(personId),
      serviceId: Value(serviceId),
    );
  }

  factory PersonService.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonService(
      personId: serializer.fromJson<int>(json['personId']),
      serviceId: serializer.fromJson<int>(json['serviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'personId': serializer.toJson<int>(personId),
      'serviceId': serializer.toJson<int>(serviceId),
    };
  }

  PersonService copyWith({int? personId, int? serviceId}) => PersonService(
    personId: personId ?? this.personId,
    serviceId: serviceId ?? this.serviceId,
  );
  PersonService copyWithCompanion(PersonServicesCompanion data) {
    return PersonService(
      personId: data.personId.present ? data.personId.value : this.personId,
      serviceId: data.serviceId.present ? data.serviceId.value : this.serviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonService(')
          ..write('personId: $personId, ')
          ..write('serviceId: $serviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(personId, serviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonService &&
          other.personId == this.personId &&
          other.serviceId == this.serviceId);
}

class PersonServicesCompanion extends UpdateCompanion<PersonService> {
  final Value<int> personId;
  final Value<int> serviceId;
  final Value<int> rowid;
  const PersonServicesCompanion({
    this.personId = const Value.absent(),
    this.serviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonServicesCompanion.insert({
    required int personId,
    required int serviceId,
    this.rowid = const Value.absent(),
  }) : personId = Value(personId),
       serviceId = Value(serviceId);
  static Insertable<PersonService> custom({
    Expression<int>? personId,
    Expression<int>? serviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (personId != null) 'Person_ID': personId,
      if (serviceId != null) 'Service_ID': serviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonServicesCompanion copyWith({
    Value<int>? personId,
    Value<int>? serviceId,
    Value<int>? rowid,
  }) {
    return PersonServicesCompanion(
      personId: personId ?? this.personId,
      serviceId: serviceId ?? this.serviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (personId.present) {
      map['Person_ID'] = Variable<int>(personId.value);
    }
    if (serviceId.present) {
      map['Service_ID'] = Variable<int>(serviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonServicesCompanion(')
          ..write('personId: $personId, ')
          ..write('serviceId: $serviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPermissionsExtTable extends UserPermissionsExt
    with TableInfo<$UserPermissionsExtTable, UserPermissionsExtData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPermissionsExtTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'User_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Pass (Pass_ID) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _featureKeyMeta = const VerificationMeta(
    'featureKey',
  );
  @override
  late final GeneratedColumn<String> featureKey = GeneratedColumn<String>(
    'Feature_Key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canAddMeta = const VerificationMeta('canAdd');
  @override
  late final GeneratedColumn<bool> canAdd = GeneratedColumn<bool>(
    'can_add',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_add" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _canEditMeta = const VerificationMeta(
    'canEdit',
  );
  @override
  late final GeneratedColumn<bool> canEdit = GeneratedColumn<bool>(
    'can_edit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_edit" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _canDeleteMeta = const VerificationMeta(
    'canDelete',
  );
  @override
  late final GeneratedColumn<bool> canDelete = GeneratedColumn<bool>(
    'can_delete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_delete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    featureKey,
    canAdd,
    canEdit,
    canDelete,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'User_Permissions_Ext';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPermissionsExtData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('User_ID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['User_ID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('Feature_Key')) {
      context.handle(
        _featureKeyMeta,
        featureKey.isAcceptableOrUnknown(data['Feature_Key']!, _featureKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_featureKeyMeta);
    }
    if (data.containsKey('can_add')) {
      context.handle(
        _canAddMeta,
        canAdd.isAcceptableOrUnknown(data['can_add']!, _canAddMeta),
      );
    }
    if (data.containsKey('can_edit')) {
      context.handle(
        _canEditMeta,
        canEdit.isAcceptableOrUnknown(data['can_edit']!, _canEditMeta),
      );
    }
    if (data.containsKey('can_delete')) {
      context.handle(
        _canDeleteMeta,
        canDelete.isAcceptableOrUnknown(data['can_delete']!, _canDeleteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, featureKey};
  @override
  UserPermissionsExtData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPermissionsExtData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}User_ID'],
      )!,
      featureKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Feature_Key'],
      )!,
      canAdd: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_add'],
      )!,
      canEdit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_edit'],
      )!,
      canDelete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_delete'],
      )!,
    );
  }

  @override
  $UserPermissionsExtTable createAlias(String alias) {
    return $UserPermissionsExtTable(attachedDatabase, alias);
  }
}

class UserPermissionsExtData extends DataClass
    implements Insertable<UserPermissionsExtData> {
  final int userId;
  final String featureKey;
  final bool canAdd;
  final bool canEdit;
  final bool canDelete;
  const UserPermissionsExtData({
    required this.userId,
    required this.featureKey,
    required this.canAdd,
    required this.canEdit,
    required this.canDelete,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['User_ID'] = Variable<int>(userId);
    map['Feature_Key'] = Variable<String>(featureKey);
    map['can_add'] = Variable<bool>(canAdd);
    map['can_edit'] = Variable<bool>(canEdit);
    map['can_delete'] = Variable<bool>(canDelete);
    return map;
  }

  UserPermissionsExtCompanion toCompanion(bool nullToAbsent) {
    return UserPermissionsExtCompanion(
      userId: Value(userId),
      featureKey: Value(featureKey),
      canAdd: Value(canAdd),
      canEdit: Value(canEdit),
      canDelete: Value(canDelete),
    );
  }

  factory UserPermissionsExtData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPermissionsExtData(
      userId: serializer.fromJson<int>(json['userId']),
      featureKey: serializer.fromJson<String>(json['featureKey']),
      canAdd: serializer.fromJson<bool>(json['canAdd']),
      canEdit: serializer.fromJson<bool>(json['canEdit']),
      canDelete: serializer.fromJson<bool>(json['canDelete']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'featureKey': serializer.toJson<String>(featureKey),
      'canAdd': serializer.toJson<bool>(canAdd),
      'canEdit': serializer.toJson<bool>(canEdit),
      'canDelete': serializer.toJson<bool>(canDelete),
    };
  }

  UserPermissionsExtData copyWith({
    int? userId,
    String? featureKey,
    bool? canAdd,
    bool? canEdit,
    bool? canDelete,
  }) => UserPermissionsExtData(
    userId: userId ?? this.userId,
    featureKey: featureKey ?? this.featureKey,
    canAdd: canAdd ?? this.canAdd,
    canEdit: canEdit ?? this.canEdit,
    canDelete: canDelete ?? this.canDelete,
  );
  UserPermissionsExtData copyWithCompanion(UserPermissionsExtCompanion data) {
    return UserPermissionsExtData(
      userId: data.userId.present ? data.userId.value : this.userId,
      featureKey: data.featureKey.present
          ? data.featureKey.value
          : this.featureKey,
      canAdd: data.canAdd.present ? data.canAdd.value : this.canAdd,
      canEdit: data.canEdit.present ? data.canEdit.value : this.canEdit,
      canDelete: data.canDelete.present ? data.canDelete.value : this.canDelete,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPermissionsExtData(')
          ..write('userId: $userId, ')
          ..write('featureKey: $featureKey, ')
          ..write('canAdd: $canAdd, ')
          ..write('canEdit: $canEdit, ')
          ..write('canDelete: $canDelete')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, featureKey, canAdd, canEdit, canDelete);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPermissionsExtData &&
          other.userId == this.userId &&
          other.featureKey == this.featureKey &&
          other.canAdd == this.canAdd &&
          other.canEdit == this.canEdit &&
          other.canDelete == this.canDelete);
}

class UserPermissionsExtCompanion
    extends UpdateCompanion<UserPermissionsExtData> {
  final Value<int> userId;
  final Value<String> featureKey;
  final Value<bool> canAdd;
  final Value<bool> canEdit;
  final Value<bool> canDelete;
  final Value<int> rowid;
  const UserPermissionsExtCompanion({
    this.userId = const Value.absent(),
    this.featureKey = const Value.absent(),
    this.canAdd = const Value.absent(),
    this.canEdit = const Value.absent(),
    this.canDelete = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserPermissionsExtCompanion.insert({
    required int userId,
    required String featureKey,
    this.canAdd = const Value.absent(),
    this.canEdit = const Value.absent(),
    this.canDelete = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       featureKey = Value(featureKey);
  static Insertable<UserPermissionsExtData> custom({
    Expression<int>? userId,
    Expression<String>? featureKey,
    Expression<bool>? canAdd,
    Expression<bool>? canEdit,
    Expression<bool>? canDelete,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'User_ID': userId,
      if (featureKey != null) 'Feature_Key': featureKey,
      if (canAdd != null) 'can_add': canAdd,
      if (canEdit != null) 'can_edit': canEdit,
      if (canDelete != null) 'can_delete': canDelete,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserPermissionsExtCompanion copyWith({
    Value<int>? userId,
    Value<String>? featureKey,
    Value<bool>? canAdd,
    Value<bool>? canEdit,
    Value<bool>? canDelete,
    Value<int>? rowid,
  }) {
    return UserPermissionsExtCompanion(
      userId: userId ?? this.userId,
      featureKey: featureKey ?? this.featureKey,
      canAdd: canAdd ?? this.canAdd,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['User_ID'] = Variable<int>(userId.value);
    }
    if (featureKey.present) {
      map['Feature_Key'] = Variable<String>(featureKey.value);
    }
    if (canAdd.present) {
      map['can_add'] = Variable<bool>(canAdd.value);
    }
    if (canEdit.present) {
      map['can_edit'] = Variable<bool>(canEdit.value);
    }
    if (canDelete.present) {
      map['can_delete'] = Variable<bool>(canDelete.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPermissionsExtCompanion(')
          ..write('userId: $userId, ')
          ..write('featureKey: $featureKey, ')
          ..write('canAdd: $canAdd, ')
          ..write('canEdit: $canEdit, ')
          ..write('canDelete: $canDelete, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserVisibilityFiltersTable extends UserVisibilityFilters
    with TableInfo<$UserVisibilityFiltersTable, UserVisibilityFilter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserVisibilityFiltersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'User_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Pass (Pass_ID) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _filterTypeMeta = const VerificationMeta(
    'filterType',
  );
  @override
  late final GeneratedColumn<String> filterType = GeneratedColumn<String>(
    'Filter_Type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueIdMeta = const VerificationMeta(
    'valueId',
  );
  @override
  late final GeneratedColumn<int> valueId = GeneratedColumn<int>(
    'Value_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, filterType, valueId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'User_Visibility_Filters';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserVisibilityFilter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('User_ID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['User_ID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('Filter_Type')) {
      context.handle(
        _filterTypeMeta,
        filterType.isAcceptableOrUnknown(data['Filter_Type']!, _filterTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_filterTypeMeta);
    }
    if (data.containsKey('Value_ID')) {
      context.handle(
        _valueIdMeta,
        valueId.isAcceptableOrUnknown(data['Value_ID']!, _valueIdMeta),
      );
    } else if (isInserting) {
      context.missing(_valueIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, filterType, valueId};
  @override
  UserVisibilityFilter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserVisibilityFilter(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}User_ID'],
      )!,
      filterType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Filter_Type'],
      )!,
      valueId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Value_ID'],
      )!,
    );
  }

  @override
  $UserVisibilityFiltersTable createAlias(String alias) {
    return $UserVisibilityFiltersTable(attachedDatabase, alias);
  }
}

class UserVisibilityFilter extends DataClass
    implements Insertable<UserVisibilityFilter> {
  final int userId;
  final String filterType;
  final int valueId;
  const UserVisibilityFilter({
    required this.userId,
    required this.filterType,
    required this.valueId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['User_ID'] = Variable<int>(userId);
    map['Filter_Type'] = Variable<String>(filterType);
    map['Value_ID'] = Variable<int>(valueId);
    return map;
  }

  UserVisibilityFiltersCompanion toCompanion(bool nullToAbsent) {
    return UserVisibilityFiltersCompanion(
      userId: Value(userId),
      filterType: Value(filterType),
      valueId: Value(valueId),
    );
  }

  factory UserVisibilityFilter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserVisibilityFilter(
      userId: serializer.fromJson<int>(json['userId']),
      filterType: serializer.fromJson<String>(json['filterType']),
      valueId: serializer.fromJson<int>(json['valueId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'filterType': serializer.toJson<String>(filterType),
      'valueId': serializer.toJson<int>(valueId),
    };
  }

  UserVisibilityFilter copyWith({
    int? userId,
    String? filterType,
    int? valueId,
  }) => UserVisibilityFilter(
    userId: userId ?? this.userId,
    filterType: filterType ?? this.filterType,
    valueId: valueId ?? this.valueId,
  );
  UserVisibilityFilter copyWithCompanion(UserVisibilityFiltersCompanion data) {
    return UserVisibilityFilter(
      userId: data.userId.present ? data.userId.value : this.userId,
      filterType: data.filterType.present
          ? data.filterType.value
          : this.filterType,
      valueId: data.valueId.present ? data.valueId.value : this.valueId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserVisibilityFilter(')
          ..write('userId: $userId, ')
          ..write('filterType: $filterType, ')
          ..write('valueId: $valueId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, filterType, valueId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserVisibilityFilter &&
          other.userId == this.userId &&
          other.filterType == this.filterType &&
          other.valueId == this.valueId);
}

class UserVisibilityFiltersCompanion
    extends UpdateCompanion<UserVisibilityFilter> {
  final Value<int> userId;
  final Value<String> filterType;
  final Value<int> valueId;
  final Value<int> rowid;
  const UserVisibilityFiltersCompanion({
    this.userId = const Value.absent(),
    this.filterType = const Value.absent(),
    this.valueId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserVisibilityFiltersCompanion.insert({
    required int userId,
    required String filterType,
    required int valueId,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       filterType = Value(filterType),
       valueId = Value(valueId);
  static Insertable<UserVisibilityFilter> custom({
    Expression<int>? userId,
    Expression<String>? filterType,
    Expression<int>? valueId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'User_ID': userId,
      if (filterType != null) 'Filter_Type': filterType,
      if (valueId != null) 'Value_ID': valueId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserVisibilityFiltersCompanion copyWith({
    Value<int>? userId,
    Value<String>? filterType,
    Value<int>? valueId,
    Value<int>? rowid,
  }) {
    return UserVisibilityFiltersCompanion(
      userId: userId ?? this.userId,
      filterType: filterType ?? this.filterType,
      valueId: valueId ?? this.valueId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['User_ID'] = Variable<int>(userId.value);
    }
    if (filterType.present) {
      map['Filter_Type'] = Variable<String>(filterType.value);
    }
    if (valueId.present) {
      map['Value_ID'] = Variable<int>(valueId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserVisibilityFiltersCompanion(')
          ..write('userId: $userId, ')
          ..write('filterType: $filterType, ')
          ..write('valueId: $valueId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomFieldDefinitionsTable extends CustomFieldDefinitions
    with TableInfo<$CustomFieldDefinitionsTable, CustomFieldDefinition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomFieldDefinitionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fieldKeyMeta = const VerificationMeta(
    'fieldKey',
  );
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
    'Field_Key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'Name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'Type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsMeta = const VerificationMeta(
    'options',
  );
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
    'Options',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fieldOrderMeta = const VerificationMeta(
    'fieldOrder',
  );
  @override
  late final GeneratedColumn<int> fieldOrder = GeneratedColumn<int>(
    'Field_Order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isVisibleMeta = const VerificationMeta(
    'isVisible',
  );
  @override
  late final GeneratedColumn<bool> isVisible = GeneratedColumn<bool>(
    'Is_Visible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("Is_Visible" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isFilterMeta = const VerificationMeta(
    'isFilter',
  );
  @override
  late final GeneratedColumn<bool> isFilter = GeneratedColumn<bool>(
    'Is_Filter',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("Is_Filter" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fieldKey,
    name,
    type,
    options,
    fieldOrder,
    isVisible,
    isFilter,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_field_definitions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomFieldDefinition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('Field_Key')) {
      context.handle(
        _fieldKeyMeta,
        fieldKey.isAcceptableOrUnknown(data['Field_Key']!, _fieldKeyMeta),
      );
    }
    if (data.containsKey('Name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['Name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('Type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['Type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('Options')) {
      context.handle(
        _optionsMeta,
        options.isAcceptableOrUnknown(data['Options']!, _optionsMeta),
      );
    }
    if (data.containsKey('Field_Order')) {
      context.handle(
        _fieldOrderMeta,
        fieldOrder.isAcceptableOrUnknown(data['Field_Order']!, _fieldOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldOrderMeta);
    }
    if (data.containsKey('Is_Visible')) {
      context.handle(
        _isVisibleMeta,
        isVisible.isAcceptableOrUnknown(data['Is_Visible']!, _isVisibleMeta),
      );
    }
    if (data.containsKey('Is_Filter')) {
      context.handle(
        _isFilterMeta,
        isFilter.isAcceptableOrUnknown(data['Is_Filter']!, _isFilterMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomFieldDefinition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomFieldDefinition(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Field_Key'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Type'],
      )!,
      options: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Options'],
      ),
      fieldOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Field_Order'],
      )!,
      isVisible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}Is_Visible'],
      )!,
      isFilter: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}Is_Filter'],
      )!,
    );
  }

  @override
  $CustomFieldDefinitionsTable createAlias(String alias) {
    return $CustomFieldDefinitionsTable(attachedDatabase, alias);
  }
}

class CustomFieldDefinition extends DataClass
    implements Insertable<CustomFieldDefinition> {
  final int id;
  final String? fieldKey;
  final String name;
  final String type;
  final String? options;
  final int fieldOrder;
  final bool isVisible;
  final bool isFilter;
  const CustomFieldDefinition({
    required this.id,
    this.fieldKey,
    required this.name,
    required this.type,
    this.options,
    required this.fieldOrder,
    required this.isVisible,
    required this.isFilter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || fieldKey != null) {
      map['Field_Key'] = Variable<String>(fieldKey);
    }
    map['Name'] = Variable<String>(name);
    map['Type'] = Variable<String>(type);
    if (!nullToAbsent || options != null) {
      map['Options'] = Variable<String>(options);
    }
    map['Field_Order'] = Variable<int>(fieldOrder);
    map['Is_Visible'] = Variable<bool>(isVisible);
    map['Is_Filter'] = Variable<bool>(isFilter);
    return map;
  }

  CustomFieldDefinitionsCompanion toCompanion(bool nullToAbsent) {
    return CustomFieldDefinitionsCompanion(
      id: Value(id),
      fieldKey: fieldKey == null && nullToAbsent
          ? const Value.absent()
          : Value(fieldKey),
      name: Value(name),
      type: Value(type),
      options: options == null && nullToAbsent
          ? const Value.absent()
          : Value(options),
      fieldOrder: Value(fieldOrder),
      isVisible: Value(isVisible),
      isFilter: Value(isFilter),
    );
  }

  factory CustomFieldDefinition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomFieldDefinition(
      id: serializer.fromJson<int>(json['id']),
      fieldKey: serializer.fromJson<String?>(json['fieldKey']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      options: serializer.fromJson<String?>(json['options']),
      fieldOrder: serializer.fromJson<int>(json['fieldOrder']),
      isVisible: serializer.fromJson<bool>(json['isVisible']),
      isFilter: serializer.fromJson<bool>(json['isFilter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fieldKey': serializer.toJson<String?>(fieldKey),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'options': serializer.toJson<String?>(options),
      'fieldOrder': serializer.toJson<int>(fieldOrder),
      'isVisible': serializer.toJson<bool>(isVisible),
      'isFilter': serializer.toJson<bool>(isFilter),
    };
  }

  CustomFieldDefinition copyWith({
    int? id,
    Value<String?> fieldKey = const Value.absent(),
    String? name,
    String? type,
    Value<String?> options = const Value.absent(),
    int? fieldOrder,
    bool? isVisible,
    bool? isFilter,
  }) => CustomFieldDefinition(
    id: id ?? this.id,
    fieldKey: fieldKey.present ? fieldKey.value : this.fieldKey,
    name: name ?? this.name,
    type: type ?? this.type,
    options: options.present ? options.value : this.options,
    fieldOrder: fieldOrder ?? this.fieldOrder,
    isVisible: isVisible ?? this.isVisible,
    isFilter: isFilter ?? this.isFilter,
  );
  CustomFieldDefinition copyWithCompanion(
    CustomFieldDefinitionsCompanion data,
  ) {
    return CustomFieldDefinition(
      id: data.id.present ? data.id.value : this.id,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      options: data.options.present ? data.options.value : this.options,
      fieldOrder: data.fieldOrder.present
          ? data.fieldOrder.value
          : this.fieldOrder,
      isVisible: data.isVisible.present ? data.isVisible.value : this.isVisible,
      isFilter: data.isFilter.present ? data.isFilter.value : this.isFilter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomFieldDefinition(')
          ..write('id: $id, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('options: $options, ')
          ..write('fieldOrder: $fieldOrder, ')
          ..write('isVisible: $isVisible, ')
          ..write('isFilter: $isFilter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fieldKey,
    name,
    type,
    options,
    fieldOrder,
    isVisible,
    isFilter,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomFieldDefinition &&
          other.id == this.id &&
          other.fieldKey == this.fieldKey &&
          other.name == this.name &&
          other.type == this.type &&
          other.options == this.options &&
          other.fieldOrder == this.fieldOrder &&
          other.isVisible == this.isVisible &&
          other.isFilter == this.isFilter);
}

class CustomFieldDefinitionsCompanion
    extends UpdateCompanion<CustomFieldDefinition> {
  final Value<int> id;
  final Value<String?> fieldKey;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> options;
  final Value<int> fieldOrder;
  final Value<bool> isVisible;
  final Value<bool> isFilter;
  const CustomFieldDefinitionsCompanion({
    this.id = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.options = const Value.absent(),
    this.fieldOrder = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.isFilter = const Value.absent(),
  });
  CustomFieldDefinitionsCompanion.insert({
    this.id = const Value.absent(),
    this.fieldKey = const Value.absent(),
    required String name,
    required String type,
    this.options = const Value.absent(),
    required int fieldOrder,
    this.isVisible = const Value.absent(),
    this.isFilter = const Value.absent(),
  }) : name = Value(name),
       type = Value(type),
       fieldOrder = Value(fieldOrder);
  static Insertable<CustomFieldDefinition> custom({
    Expression<int>? id,
    Expression<String>? fieldKey,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? options,
    Expression<int>? fieldOrder,
    Expression<bool>? isVisible,
    Expression<bool>? isFilter,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fieldKey != null) 'Field_Key': fieldKey,
      if (name != null) 'Name': name,
      if (type != null) 'Type': type,
      if (options != null) 'Options': options,
      if (fieldOrder != null) 'Field_Order': fieldOrder,
      if (isVisible != null) 'Is_Visible': isVisible,
      if (isFilter != null) 'Is_Filter': isFilter,
    });
  }

  CustomFieldDefinitionsCompanion copyWith({
    Value<int>? id,
    Value<String?>? fieldKey,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? options,
    Value<int>? fieldOrder,
    Value<bool>? isVisible,
    Value<bool>? isFilter,
  }) {
    return CustomFieldDefinitionsCompanion(
      id: id ?? this.id,
      fieldKey: fieldKey ?? this.fieldKey,
      name: name ?? this.name,
      type: type ?? this.type,
      options: options ?? this.options,
      fieldOrder: fieldOrder ?? this.fieldOrder,
      isVisible: isVisible ?? this.isVisible,
      isFilter: isFilter ?? this.isFilter,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fieldKey.present) {
      map['Field_Key'] = Variable<String>(fieldKey.value);
    }
    if (name.present) {
      map['Name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['Type'] = Variable<String>(type.value);
    }
    if (options.present) {
      map['Options'] = Variable<String>(options.value);
    }
    if (fieldOrder.present) {
      map['Field_Order'] = Variable<int>(fieldOrder.value);
    }
    if (isVisible.present) {
      map['Is_Visible'] = Variable<bool>(isVisible.value);
    }
    if (isFilter.present) {
      map['Is_Filter'] = Variable<bool>(isFilter.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomFieldDefinitionsCompanion(')
          ..write('id: $id, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('options: $options, ')
          ..write('fieldOrder: $fieldOrder, ')
          ..write('isVisible: $isVisible, ')
          ..write('isFilter: $isFilter')
          ..write(')'))
        .toString();
  }
}

class $PersonCustomFieldValuesTable extends PersonCustomFieldValues
    with TableInfo<$PersonCustomFieldValuesTable, PersonCustomFieldValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonCustomFieldValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'Person_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Persons (Person_ID) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fieldIdMeta = const VerificationMeta(
    'fieldId',
  );
  @override
  late final GeneratedColumn<int> fieldId = GeneratedColumn<int>(
    'Field_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES custom_field_definitions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'Value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [personId, fieldId, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'person_custom_field_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonCustomFieldValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Person_ID')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['Person_ID']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('Field_ID')) {
      context.handle(
        _fieldIdMeta,
        fieldId.isAcceptableOrUnknown(data['Field_ID']!, _fieldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldIdMeta);
    }
    if (data.containsKey('Value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['Value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {personId, fieldId};
  @override
  PersonCustomFieldValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonCustomFieldValue(
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Person_ID'],
      )!,
      fieldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Field_ID'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Value'],
      ),
    );
  }

  @override
  $PersonCustomFieldValuesTable createAlias(String alias) {
    return $PersonCustomFieldValuesTable(attachedDatabase, alias);
  }
}

class PersonCustomFieldValue extends DataClass
    implements Insertable<PersonCustomFieldValue> {
  final int personId;
  final int fieldId;
  final String? value;
  const PersonCustomFieldValue({
    required this.personId,
    required this.fieldId,
    this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Person_ID'] = Variable<int>(personId);
    map['Field_ID'] = Variable<int>(fieldId);
    if (!nullToAbsent || value != null) {
      map['Value'] = Variable<String>(value);
    }
    return map;
  }

  PersonCustomFieldValuesCompanion toCompanion(bool nullToAbsent) {
    return PersonCustomFieldValuesCompanion(
      personId: Value(personId),
      fieldId: Value(fieldId),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory PersonCustomFieldValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonCustomFieldValue(
      personId: serializer.fromJson<int>(json['personId']),
      fieldId: serializer.fromJson<int>(json['fieldId']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'personId': serializer.toJson<int>(personId),
      'fieldId': serializer.toJson<int>(fieldId),
      'value': serializer.toJson<String?>(value),
    };
  }

  PersonCustomFieldValue copyWith({
    int? personId,
    int? fieldId,
    Value<String?> value = const Value.absent(),
  }) => PersonCustomFieldValue(
    personId: personId ?? this.personId,
    fieldId: fieldId ?? this.fieldId,
    value: value.present ? value.value : this.value,
  );
  PersonCustomFieldValue copyWithCompanion(
    PersonCustomFieldValuesCompanion data,
  ) {
    return PersonCustomFieldValue(
      personId: data.personId.present ? data.personId.value : this.personId,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonCustomFieldValue(')
          ..write('personId: $personId, ')
          ..write('fieldId: $fieldId, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(personId, fieldId, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonCustomFieldValue &&
          other.personId == this.personId &&
          other.fieldId == this.fieldId &&
          other.value == this.value);
}

class PersonCustomFieldValuesCompanion
    extends UpdateCompanion<PersonCustomFieldValue> {
  final Value<int> personId;
  final Value<int> fieldId;
  final Value<String?> value;
  final Value<int> rowid;
  const PersonCustomFieldValuesCompanion({
    this.personId = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonCustomFieldValuesCompanion.insert({
    required int personId,
    required int fieldId,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : personId = Value(personId),
       fieldId = Value(fieldId);
  static Insertable<PersonCustomFieldValue> custom({
    Expression<int>? personId,
    Expression<int>? fieldId,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (personId != null) 'Person_ID': personId,
      if (fieldId != null) 'Field_ID': fieldId,
      if (value != null) 'Value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonCustomFieldValuesCompanion copyWith({
    Value<int>? personId,
    Value<int>? fieldId,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return PersonCustomFieldValuesCompanion(
      personId: personId ?? this.personId,
      fieldId: fieldId ?? this.fieldId,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (personId.present) {
      map['Person_ID'] = Variable<int>(personId.value);
    }
    if (fieldId.present) {
      map['Field_ID'] = Variable<int>(fieldId.value);
    }
    if (value.present) {
      map['Value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonCustomFieldValuesCompanion(')
          ..write('personId: $personId, ')
          ..write('fieldId: $fieldId, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonDocumentsTable extends PersonDocuments
    with TableInfo<$PersonDocumentsTable, PersonDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'Person_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Persons (Person_ID) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fieldIdMeta = const VerificationMeta(
    'fieldId',
  );
  @override
  late final GeneratedColumn<int> fieldId = GeneratedColumn<int>(
    'Field_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES custom_field_definitions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'File_Name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileContentMeta = const VerificationMeta(
    'fileContent',
  );
  @override
  late final GeneratedColumn<Uint8List> fileContent =
      GeneratedColumn<Uint8List>(
        'File_Content',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'Created_At',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    fieldId,
    fileName,
    fileContent,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'person_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('Person_ID')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['Person_ID']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('Field_ID')) {
      context.handle(
        _fieldIdMeta,
        fieldId.isAcceptableOrUnknown(data['Field_ID']!, _fieldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldIdMeta);
    }
    if (data.containsKey('File_Name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['File_Name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('File_Content')) {
      context.handle(
        _fileContentMeta,
        fileContent.isAcceptableOrUnknown(
          data['File_Content']!,
          _fileContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileContentMeta);
    }
    if (data.containsKey('Created_At')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['Created_At']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonDocument(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Person_ID'],
      )!,
      fieldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Field_ID'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}File_Name'],
      )!,
      fileContent: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}File_Content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}Created_At'],
      )!,
    );
  }

  @override
  $PersonDocumentsTable createAlias(String alias) {
    return $PersonDocumentsTable(attachedDatabase, alias);
  }
}

class PersonDocument extends DataClass implements Insertable<PersonDocument> {
  final int id;
  final int personId;
  final int fieldId;
  final String fileName;
  final Uint8List fileContent;
  final DateTime createdAt;
  const PersonDocument({
    required this.id,
    required this.personId,
    required this.fieldId,
    required this.fileName,
    required this.fileContent,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['Person_ID'] = Variable<int>(personId);
    map['Field_ID'] = Variable<int>(fieldId);
    map['File_Name'] = Variable<String>(fileName);
    map['File_Content'] = Variable<Uint8List>(fileContent);
    map['Created_At'] = Variable<DateTime>(createdAt);
    return map;
  }

  PersonDocumentsCompanion toCompanion(bool nullToAbsent) {
    return PersonDocumentsCompanion(
      id: Value(id),
      personId: Value(personId),
      fieldId: Value(fieldId),
      fileName: Value(fileName),
      fileContent: Value(fileContent),
      createdAt: Value(createdAt),
    );
  }

  factory PersonDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonDocument(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int>(json['personId']),
      fieldId: serializer.fromJson<int>(json['fieldId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      fileContent: serializer.fromJson<Uint8List>(json['fileContent']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int>(personId),
      'fieldId': serializer.toJson<int>(fieldId),
      'fileName': serializer.toJson<String>(fileName),
      'fileContent': serializer.toJson<Uint8List>(fileContent),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PersonDocument copyWith({
    int? id,
    int? personId,
    int? fieldId,
    String? fileName,
    Uint8List? fileContent,
    DateTime? createdAt,
  }) => PersonDocument(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    fieldId: fieldId ?? this.fieldId,
    fileName: fileName ?? this.fileName,
    fileContent: fileContent ?? this.fileContent,
    createdAt: createdAt ?? this.createdAt,
  );
  PersonDocument copyWithCompanion(PersonDocumentsCompanion data) {
    return PersonDocument(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileContent: data.fileContent.present
          ? data.fileContent.value
          : this.fileContent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonDocument(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('fieldId: $fieldId, ')
          ..write('fileName: $fileName, ')
          ..write('fileContent: $fileContent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    fieldId,
    fileName,
    $driftBlobEquality.hash(fileContent),
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonDocument &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.fieldId == this.fieldId &&
          other.fileName == this.fileName &&
          $driftBlobEquality.equals(other.fileContent, this.fileContent) &&
          other.createdAt == this.createdAt);
}

class PersonDocumentsCompanion extends UpdateCompanion<PersonDocument> {
  final Value<int> id;
  final Value<int> personId;
  final Value<int> fieldId;
  final Value<String> fileName;
  final Value<Uint8List> fileContent;
  final Value<DateTime> createdAt;
  const PersonDocumentsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileContent = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PersonDocumentsCompanion.insert({
    this.id = const Value.absent(),
    required int personId,
    required int fieldId,
    required String fileName,
    required Uint8List fileContent,
    this.createdAt = const Value.absent(),
  }) : personId = Value(personId),
       fieldId = Value(fieldId),
       fileName = Value(fileName),
       fileContent = Value(fileContent);
  static Insertable<PersonDocument> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<int>? fieldId,
    Expression<String>? fileName,
    Expression<Uint8List>? fileContent,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'Person_ID': personId,
      if (fieldId != null) 'Field_ID': fieldId,
      if (fileName != null) 'File_Name': fileName,
      if (fileContent != null) 'File_Content': fileContent,
      if (createdAt != null) 'Created_At': createdAt,
    });
  }

  PersonDocumentsCompanion copyWith({
    Value<int>? id,
    Value<int>? personId,
    Value<int>? fieldId,
    Value<String>? fileName,
    Value<Uint8List>? fileContent,
    Value<DateTime>? createdAt,
  }) {
    return PersonDocumentsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      fieldId: fieldId ?? this.fieldId,
      fileName: fileName ?? this.fileName,
      fileContent: fileContent ?? this.fileContent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['Person_ID'] = Variable<int>(personId.value);
    }
    if (fieldId.present) {
      map['Field_ID'] = Variable<int>(fieldId.value);
    }
    if (fileName.present) {
      map['File_Name'] = Variable<String>(fileName.value);
    }
    if (fileContent.present) {
      map['File_Content'] = Variable<Uint8List>(fileContent.value);
    }
    if (createdAt.present) {
      map['Created_At'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('fieldId: $fieldId, ')
          ..write('fileName: $fileName, ')
          ..write('fileContent: $fileContent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FamilyRelationshipsTable extends FamilyRelationships
    with TableInfo<$FamilyRelationshipsTable, FamilyRelationship> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyRelationshipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'ID',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'Person_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Persons (Person_ID) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _relatedPersonIdMeta = const VerificationMeta(
    'relatedPersonId',
  );
  @override
  late final GeneratedColumn<int> relatedPersonId = GeneratedColumn<int>(
    'Related_Person_ID',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES Persons (Person_ID) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'Category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relationshipCodeMeta = const VerificationMeta(
    'relationshipCode',
  );
  @override
  late final GeneratedColumn<String> relationshipCode = GeneratedColumn<String>(
    'Relationship_Code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customLabelMeta = const VerificationMeta(
    'customLabel',
  );
  @override
  late final GeneratedColumn<String> customLabel = GeneratedColumn<String>(
    'Custom_Label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'Created_At',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    relatedPersonId,
    category,
    relationshipCode,
    customLabel,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Family_Relationships';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyRelationship> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ID')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['ID']!, _idMeta));
    }
    if (data.containsKey('Person_ID')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['Person_ID']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('Related_Person_ID')) {
      context.handle(
        _relatedPersonIdMeta,
        relatedPersonId.isAcceptableOrUnknown(
          data['Related_Person_ID']!,
          _relatedPersonIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relatedPersonIdMeta);
    }
    if (data.containsKey('Category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['Category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('Relationship_Code')) {
      context.handle(
        _relationshipCodeMeta,
        relationshipCode.isAcceptableOrUnknown(
          data['Relationship_Code']!,
          _relationshipCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relationshipCodeMeta);
    }
    if (data.containsKey('Custom_Label')) {
      context.handle(
        _customLabelMeta,
        customLabel.isAcceptableOrUnknown(
          data['Custom_Label']!,
          _customLabelMeta,
        ),
      );
    }
    if (data.containsKey('Created_At')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['Created_At']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyRelationship map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyRelationship(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ID'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Person_ID'],
      )!,
      relatedPersonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Related_Person_ID'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Category'],
      )!,
      relationshipCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Relationship_Code'],
      )!,
      customLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Custom_Label'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}Created_At'],
      )!,
    );
  }

  @override
  $FamilyRelationshipsTable createAlias(String alias) {
    return $FamilyRelationshipsTable(attachedDatabase, alias);
  }
}

class FamilyRelationship extends DataClass
    implements Insertable<FamilyRelationship> {
  final int id;
  final int personId;
  final int relatedPersonId;
  final String category;
  final String relationshipCode;
  final String? customLabel;
  final DateTime createdAt;
  const FamilyRelationship({
    required this.id,
    required this.personId,
    required this.relatedPersonId,
    required this.category,
    required this.relationshipCode,
    this.customLabel,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ID'] = Variable<int>(id);
    map['Person_ID'] = Variable<int>(personId);
    map['Related_Person_ID'] = Variable<int>(relatedPersonId);
    map['Category'] = Variable<String>(category);
    map['Relationship_Code'] = Variable<String>(relationshipCode);
    if (!nullToAbsent || customLabel != null) {
      map['Custom_Label'] = Variable<String>(customLabel);
    }
    map['Created_At'] = Variable<DateTime>(createdAt);
    return map;
  }

  FamilyRelationshipsCompanion toCompanion(bool nullToAbsent) {
    return FamilyRelationshipsCompanion(
      id: Value(id),
      personId: Value(personId),
      relatedPersonId: Value(relatedPersonId),
      category: Value(category),
      relationshipCode: Value(relationshipCode),
      customLabel: customLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(customLabel),
      createdAt: Value(createdAt),
    );
  }

  factory FamilyRelationship.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyRelationship(
      id: serializer.fromJson<int>(json['id']),
      personId: serializer.fromJson<int>(json['personId']),
      relatedPersonId: serializer.fromJson<int>(json['relatedPersonId']),
      category: serializer.fromJson<String>(json['category']),
      relationshipCode: serializer.fromJson<String>(json['relationshipCode']),
      customLabel: serializer.fromJson<String?>(json['customLabel']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'personId': serializer.toJson<int>(personId),
      'relatedPersonId': serializer.toJson<int>(relatedPersonId),
      'category': serializer.toJson<String>(category),
      'relationshipCode': serializer.toJson<String>(relationshipCode),
      'customLabel': serializer.toJson<String?>(customLabel),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FamilyRelationship copyWith({
    int? id,
    int? personId,
    int? relatedPersonId,
    String? category,
    String? relationshipCode,
    Value<String?> customLabel = const Value.absent(),
    DateTime? createdAt,
  }) => FamilyRelationship(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    relatedPersonId: relatedPersonId ?? this.relatedPersonId,
    category: category ?? this.category,
    relationshipCode: relationshipCode ?? this.relationshipCode,
    customLabel: customLabel.present ? customLabel.value : this.customLabel,
    createdAt: createdAt ?? this.createdAt,
  );
  FamilyRelationship copyWithCompanion(FamilyRelationshipsCompanion data) {
    return FamilyRelationship(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      relatedPersonId: data.relatedPersonId.present
          ? data.relatedPersonId.value
          : this.relatedPersonId,
      category: data.category.present ? data.category.value : this.category,
      relationshipCode: data.relationshipCode.present
          ? data.relationshipCode.value
          : this.relationshipCode,
      customLabel: data.customLabel.present
          ? data.customLabel.value
          : this.customLabel,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyRelationship(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('relatedPersonId: $relatedPersonId, ')
          ..write('category: $category, ')
          ..write('relationshipCode: $relationshipCode, ')
          ..write('customLabel: $customLabel, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    relatedPersonId,
    category,
    relationshipCode,
    customLabel,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyRelationship &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.relatedPersonId == this.relatedPersonId &&
          other.category == this.category &&
          other.relationshipCode == this.relationshipCode &&
          other.customLabel == this.customLabel &&
          other.createdAt == this.createdAt);
}

class FamilyRelationshipsCompanion extends UpdateCompanion<FamilyRelationship> {
  final Value<int> id;
  final Value<int> personId;
  final Value<int> relatedPersonId;
  final Value<String> category;
  final Value<String> relationshipCode;
  final Value<String?> customLabel;
  final Value<DateTime> createdAt;
  const FamilyRelationshipsCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.relatedPersonId = const Value.absent(),
    this.category = const Value.absent(),
    this.relationshipCode = const Value.absent(),
    this.customLabel = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FamilyRelationshipsCompanion.insert({
    this.id = const Value.absent(),
    required int personId,
    required int relatedPersonId,
    required String category,
    required String relationshipCode,
    this.customLabel = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : personId = Value(personId),
       relatedPersonId = Value(relatedPersonId),
       category = Value(category),
       relationshipCode = Value(relationshipCode);
  static Insertable<FamilyRelationship> custom({
    Expression<int>? id,
    Expression<int>? personId,
    Expression<int>? relatedPersonId,
    Expression<String>? category,
    Expression<String>? relationshipCode,
    Expression<String>? customLabel,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'ID': id,
      if (personId != null) 'Person_ID': personId,
      if (relatedPersonId != null) 'Related_Person_ID': relatedPersonId,
      if (category != null) 'Category': category,
      if (relationshipCode != null) 'Relationship_Code': relationshipCode,
      if (customLabel != null) 'Custom_Label': customLabel,
      if (createdAt != null) 'Created_At': createdAt,
    });
  }

  FamilyRelationshipsCompanion copyWith({
    Value<int>? id,
    Value<int>? personId,
    Value<int>? relatedPersonId,
    Value<String>? category,
    Value<String>? relationshipCode,
    Value<String?>? customLabel,
    Value<DateTime>? createdAt,
  }) {
    return FamilyRelationshipsCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      relatedPersonId: relatedPersonId ?? this.relatedPersonId,
      category: category ?? this.category,
      relationshipCode: relationshipCode ?? this.relationshipCode,
      customLabel: customLabel ?? this.customLabel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['ID'] = Variable<int>(id.value);
    }
    if (personId.present) {
      map['Person_ID'] = Variable<int>(personId.value);
    }
    if (relatedPersonId.present) {
      map['Related_Person_ID'] = Variable<int>(relatedPersonId.value);
    }
    if (category.present) {
      map['Category'] = Variable<String>(category.value);
    }
    if (relationshipCode.present) {
      map['Relationship_Code'] = Variable<String>(relationshipCode.value);
    }
    if (customLabel.present) {
      map['Custom_Label'] = Variable<String>(customLabel.value);
    }
    if (createdAt.present) {
      map['Created_At'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyRelationshipsCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('relatedPersonId: $relatedPersonId, ')
          ..write('category: $category, ')
          ..write('relationshipCode: $relationshipCode, ')
          ..write('customLabel: $customLabel, ')
          ..write('createdAt: $createdAt')
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
  late final $ServicesTable services = $ServicesTable(this);
  late final $StagesTable stages = $StagesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $TayoCardsTable tayoCards = $TayoCardsTable(this);
  late final $PersonTayoPointsTable personTayoPoints = $PersonTayoPointsTable(
    this,
  );
  late final $KhorosesTable khoroses = $KhorosesTable(this);
  late final $KhorosServicesTable khorosServices = $KhorosServicesTable(this);
  late final $StageServicesTable stageServices = $StageServicesTable(this);
  late final $PersonServicesTable personServices = $PersonServicesTable(this);
  late final $UserPermissionsExtTable userPermissionsExt =
      $UserPermissionsExtTable(this);
  late final $UserVisibilityFiltersTable userVisibilityFilters =
      $UserVisibilityFiltersTable(this);
  late final $CustomFieldDefinitionsTable customFieldDefinitions =
      $CustomFieldDefinitionsTable(this);
  late final $PersonCustomFieldValuesTable personCustomFieldValues =
      $PersonCustomFieldValuesTable(this);
  late final $PersonDocumentsTable personDocuments = $PersonDocumentsTable(
    this,
  );
  late final $FamilyRelationshipsTable familyRelationships =
      $FamilyRelationshipsTable(this);
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
    services,
    stages,
    settings,
    tayoCards,
    personTayoPoints,
    khoroses,
    khorosServices,
    stageServices,
    personServices,
    userPermissionsExt,
    userVisibilityFilters,
    customFieldDefinitions,
    personCustomFieldValues,
    personDocuments,
    familyRelationships,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Services',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('Stages', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Stages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('Stages', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Services',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('Khoroses', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Khoroses',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('Khoros_Services', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Services',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('Khoros_Services', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Stages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('Stage_Services', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Services',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('Stage_Services', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Persons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('Person_Services', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Services',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('Person_Services', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Pass',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('User_Permissions_Ext', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Pass',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('User_Visibility_Filters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Persons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('person_custom_field_values', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'custom_field_definitions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('person_custom_field_values', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Persons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('person_documents', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'custom_field_definitions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('person_documents', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Persons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('Family_Relationships', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'Persons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('Family_Relationships', kind: UpdateKind.delete)],
    ),
  ]);
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
      Value<int?> khorosId,
      Value<String?> khorosName,
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
      Value<int?> khorosId,
      Value<String?> khorosName,
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

  ColumnFilters<int> get khorosId => $composableBuilder(
    column: $table.khorosId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get khorosName => $composableBuilder(
    column: $table.khorosName,
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

  ColumnOrderings<int> get khorosId => $composableBuilder(
    column: $table.khorosId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get khorosName => $composableBuilder(
    column: $table.khorosName,
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

  GeneratedColumn<int> get khorosId =>
      $composableBuilder(column: $table.khorosId, builder: (column) => column);

  GeneratedColumn<String> get khorosName => $composableBuilder(
    column: $table.khorosName,
    builder: (column) => column,
  );

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
                Value<int?> khorosId = const Value.absent(),
                Value<String?> khorosName = const Value.absent(),
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
                khorosId: khorosId,
                khorosName: khorosName,
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
                Value<int?> khorosId = const Value.absent(),
                Value<String?> khorosName = const Value.absent(),
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
                khorosId: khorosId,
                khorosName: khorosName,
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
      Value<int> areaId,
      Value<String?> areaName,
      Value<int?> parentId,
      Value<int> level,
      Value<String?> areaPath,
    });
typedef $$AreasTableUpdateCompanionBuilder =
    AreasCompanion Function({
      Value<int> areaId,
      Value<String?> areaName,
      Value<int?> parentId,
      Value<int> level,
      Value<String?> areaPath,
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

  ColumnFilters<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaPath => $composableBuilder(
    column: $table.areaPath,
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

  ColumnOrderings<int> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaPath => $composableBuilder(
    column: $table.areaPath,
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

  GeneratedColumn<int> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get areaPath =>
      $composableBuilder(column: $table.areaPath, builder: (column) => column);
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
                Value<int> areaId = const Value.absent(),
                Value<String?> areaName = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String?> areaPath = const Value.absent(),
              }) => AreasCompanion(
                areaId: areaId,
                areaName: areaName,
                parentId: parentId,
                level: level,
                areaPath: areaPath,
              ),
          createCompanionCallback:
              ({
                Value<int> areaId = const Value.absent(),
                Value<String?> areaName = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String?> areaPath = const Value.absent(),
              }) => AreasCompanion.insert(
                areaId: areaId,
                areaName: areaName,
                parentId: parentId,
                level: level,
                areaPath: areaPath,
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
      Value<int?> serviceId,
      Value<String?> attendTime,
      Value<String?> checkoutTime,
      Value<int?> visited,
      Value<String?> visitNotes,
      Value<int?> behavior,
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
      Value<int?> serviceId,
      Value<String?> attendTime,
      Value<String?> checkoutTime,
      Value<int?> visited,
      Value<String?> visitNotes,
      Value<int?> behavior,
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

  ColumnFilters<int> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attendTime => $composableBuilder(
    column: $table.attendTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkoutTime => $composableBuilder(
    column: $table.checkoutTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get visited => $composableBuilder(
    column: $table.visited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitNotes => $composableBuilder(
    column: $table.visitNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get behavior => $composableBuilder(
    column: $table.behavior,
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

  ColumnOrderings<int> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attendTime => $composableBuilder(
    column: $table.attendTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkoutTime => $composableBuilder(
    column: $table.checkoutTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get visited => $composableBuilder(
    column: $table.visited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitNotes => $composableBuilder(
    column: $table.visitNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get behavior => $composableBuilder(
    column: $table.behavior,
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

  GeneratedColumn<int> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get attendTime => $composableBuilder(
    column: $table.attendTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checkoutTime => $composableBuilder(
    column: $table.checkoutTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get visited =>
      $composableBuilder(column: $table.visited, builder: (column) => column);

  GeneratedColumn<String> get visitNotes => $composableBuilder(
    column: $table.visitNotes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get behavior =>
      $composableBuilder(column: $table.behavior, builder: (column) => column);
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
                Value<int?> serviceId = const Value.absent(),
                Value<String?> attendTime = const Value.absent(),
                Value<String?> checkoutTime = const Value.absent(),
                Value<int?> visited = const Value.absent(),
                Value<String?> visitNotes = const Value.absent(),
                Value<int?> behavior = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComingCompanion(
                id: id,
                personId: personId,
                dateWeek: dateWeek,
                point: point,
                mont1: mont1,
                year1: year1,
                serviceId: serviceId,
                attendTime: attendTime,
                checkoutTime: checkoutTime,
                visited: visited,
                visitNotes: visitNotes,
                behavior: behavior,
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
                Value<int?> serviceId = const Value.absent(),
                Value<String?> attendTime = const Value.absent(),
                Value<String?> checkoutTime = const Value.absent(),
                Value<int?> visited = const Value.absent(),
                Value<String?> visitNotes = const Value.absent(),
                Value<int?> behavior = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComingCompanion.insert(
                id: id,
                personId: personId,
                dateWeek: dateWeek,
                point: point,
                mont1: mont1,
                year1: year1,
                serviceId: serviceId,
                attendTime: attendTime,
                checkoutTime: checkoutTime,
                visited: visited,
                visitNotes: visitNotes,
                behavior: behavior,
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
    FathersCompanion Function({Value<int> fatherId, Value<String?> fatherName});
typedef $$FathersTableUpdateCompanionBuilder =
    FathersCompanion Function({Value<int> fatherId, Value<String?> fatherName});

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
                Value<int> fatherId = const Value.absent(),
                Value<String?> fatherName = const Value.absent(),
              }) =>
                  FathersCompanion(fatherId: fatherId, fatherName: fatherName),
          createCompanionCallback:
              ({
                Value<int> fatherId = const Value.absent(),
                Value<String?> fatherName = const Value.absent(),
              }) => FathersCompanion.insert(
                fatherId: fatherId,
                fatherName: fatherName,
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
      Value<int> passId,
      Value<String?> passWord,
      Value<String?> personName,
      Value<bool?> canPersons,
      Value<bool?> canStages,
      Value<bool?> canAreas,
      Value<bool?> canFathers,
      Value<bool?> canReports,
      Value<bool?> canUsers,
      Value<bool?> canAbsence,
      Value<bool?> canMaintenance,
      Value<bool?> canIdCard,
      Value<bool?> canTayo,
      Value<bool?> canTransfer,
      Value<bool?> canServices,
      Value<bool?> canKhoros,
      Value<bool?> canBehavior,
      Value<bool> isAdvanced,
    });
typedef $$PassTableUpdateCompanionBuilder =
    PassCompanion Function({
      Value<int> passId,
      Value<String?> passWord,
      Value<String?> personName,
      Value<bool?> canPersons,
      Value<bool?> canStages,
      Value<bool?> canAreas,
      Value<bool?> canFathers,
      Value<bool?> canReports,
      Value<bool?> canUsers,
      Value<bool?> canAbsence,
      Value<bool?> canMaintenance,
      Value<bool?> canIdCard,
      Value<bool?> canTayo,
      Value<bool?> canTransfer,
      Value<bool?> canServices,
      Value<bool?> canKhoros,
      Value<bool?> canBehavior,
      Value<bool> isAdvanced,
    });

final class $$PassTableReferences
    extends BaseReferences<_$AppDatabase, $PassTable, PassData> {
  $$PassTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $UserPermissionsExtTable,
    List<UserPermissionsExtData>
  >
  _userPermissionsExtRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.userPermissionsExt,
        aliasName: $_aliasNameGenerator(
          db.pass.passId,
          db.userPermissionsExt.userId,
        ),
      );

  $$UserPermissionsExtTableProcessedTableManager get userPermissionsExtRefs {
    final manager = $$UserPermissionsExtTableTableManager(
      $_db,
      $_db.userPermissionsExt,
    ).filter((f) => f.userId.passId.sqlEquals($_itemColumn<int>('Pass_ID')!));

    final cache = $_typedResult.readTableOrNull(
      _userPermissionsExtRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $UserVisibilityFiltersTable,
    List<UserVisibilityFilter>
  >
  _userVisibilityFiltersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.userVisibilityFilters,
        aliasName: $_aliasNameGenerator(
          db.pass.passId,
          db.userVisibilityFilters.userId,
        ),
      );

  $$UserVisibilityFiltersTableProcessedTableManager
  get userVisibilityFiltersRefs {
    final manager = $$UserVisibilityFiltersTableTableManager(
      $_db,
      $_db.userVisibilityFilters,
    ).filter((f) => f.userId.passId.sqlEquals($_itemColumn<int>('Pass_ID')!));

    final cache = $_typedResult.readTableOrNull(
      _userVisibilityFiltersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<bool> get canPersons => $composableBuilder(
    column: $table.canPersons,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canStages => $composableBuilder(
    column: $table.canStages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canAreas => $composableBuilder(
    column: $table.canAreas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canFathers => $composableBuilder(
    column: $table.canFathers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canReports => $composableBuilder(
    column: $table.canReports,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canUsers => $composableBuilder(
    column: $table.canUsers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canAbsence => $composableBuilder(
    column: $table.canAbsence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canMaintenance => $composableBuilder(
    column: $table.canMaintenance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canIdCard => $composableBuilder(
    column: $table.canIdCard,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canTayo => $composableBuilder(
    column: $table.canTayo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canTransfer => $composableBuilder(
    column: $table.canTransfer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canServices => $composableBuilder(
    column: $table.canServices,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canKhoros => $composableBuilder(
    column: $table.canKhoros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canBehavior => $composableBuilder(
    column: $table.canBehavior,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdvanced => $composableBuilder(
    column: $table.isAdvanced,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> userPermissionsExtRefs(
    Expression<bool> Function($$UserPermissionsExtTableFilterComposer f) f,
  ) {
    final $$UserPermissionsExtTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passId,
      referencedTable: $db.userPermissionsExt,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPermissionsExtTableFilterComposer(
            $db: $db,
            $table: $db.userPermissionsExt,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userVisibilityFiltersRefs(
    Expression<bool> Function($$UserVisibilityFiltersTableFilterComposer f) f,
  ) {
    final $$UserVisibilityFiltersTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.passId,
          referencedTable: $db.userVisibilityFilters,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserVisibilityFiltersTableFilterComposer(
                $db: $db,
                $table: $db.userVisibilityFilters,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
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

  ColumnOrderings<bool> get canPersons => $composableBuilder(
    column: $table.canPersons,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canStages => $composableBuilder(
    column: $table.canStages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canAreas => $composableBuilder(
    column: $table.canAreas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canFathers => $composableBuilder(
    column: $table.canFathers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canReports => $composableBuilder(
    column: $table.canReports,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canUsers => $composableBuilder(
    column: $table.canUsers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canAbsence => $composableBuilder(
    column: $table.canAbsence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canMaintenance => $composableBuilder(
    column: $table.canMaintenance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canIdCard => $composableBuilder(
    column: $table.canIdCard,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canTayo => $composableBuilder(
    column: $table.canTayo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canTransfer => $composableBuilder(
    column: $table.canTransfer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canServices => $composableBuilder(
    column: $table.canServices,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canKhoros => $composableBuilder(
    column: $table.canKhoros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canBehavior => $composableBuilder(
    column: $table.canBehavior,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdvanced => $composableBuilder(
    column: $table.isAdvanced,
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

  GeneratedColumn<bool> get canPersons => $composableBuilder(
    column: $table.canPersons,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get canStages =>
      $composableBuilder(column: $table.canStages, builder: (column) => column);

  GeneratedColumn<bool> get canAreas =>
      $composableBuilder(column: $table.canAreas, builder: (column) => column);

  GeneratedColumn<bool> get canFathers => $composableBuilder(
    column: $table.canFathers,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get canReports => $composableBuilder(
    column: $table.canReports,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get canUsers =>
      $composableBuilder(column: $table.canUsers, builder: (column) => column);

  GeneratedColumn<bool> get canAbsence => $composableBuilder(
    column: $table.canAbsence,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get canMaintenance => $composableBuilder(
    column: $table.canMaintenance,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get canIdCard =>
      $composableBuilder(column: $table.canIdCard, builder: (column) => column);

  GeneratedColumn<bool> get canTayo =>
      $composableBuilder(column: $table.canTayo, builder: (column) => column);

  GeneratedColumn<bool> get canTransfer => $composableBuilder(
    column: $table.canTransfer,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get canServices => $composableBuilder(
    column: $table.canServices,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get canKhoros =>
      $composableBuilder(column: $table.canKhoros, builder: (column) => column);

  GeneratedColumn<bool> get canBehavior => $composableBuilder(
    column: $table.canBehavior,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAdvanced => $composableBuilder(
    column: $table.isAdvanced,
    builder: (column) => column,
  );

  Expression<T> userPermissionsExtRefs<T extends Object>(
    Expression<T> Function($$UserPermissionsExtTableAnnotationComposer a) f,
  ) {
    final $$UserPermissionsExtTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.passId,
          referencedTable: $db.userPermissionsExt,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserPermissionsExtTableAnnotationComposer(
                $db: $db,
                $table: $db.userPermissionsExt,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> userVisibilityFiltersRefs<T extends Object>(
    Expression<T> Function($$UserVisibilityFiltersTableAnnotationComposer a) f,
  ) {
    final $$UserVisibilityFiltersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.passId,
          referencedTable: $db.userVisibilityFilters,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserVisibilityFiltersTableAnnotationComposer(
                $db: $db,
                $table: $db.userVisibilityFilters,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
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
          (PassData, $$PassTableReferences),
          PassData,
          PrefetchHooks Function({
            bool userPermissionsExtRefs,
            bool userVisibilityFiltersRefs,
          })
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
                Value<int> passId = const Value.absent(),
                Value<String?> passWord = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<bool?> canPersons = const Value.absent(),
                Value<bool?> canStages = const Value.absent(),
                Value<bool?> canAreas = const Value.absent(),
                Value<bool?> canFathers = const Value.absent(),
                Value<bool?> canReports = const Value.absent(),
                Value<bool?> canUsers = const Value.absent(),
                Value<bool?> canAbsence = const Value.absent(),
                Value<bool?> canMaintenance = const Value.absent(),
                Value<bool?> canIdCard = const Value.absent(),
                Value<bool?> canTayo = const Value.absent(),
                Value<bool?> canTransfer = const Value.absent(),
                Value<bool?> canServices = const Value.absent(),
                Value<bool?> canKhoros = const Value.absent(),
                Value<bool?> canBehavior = const Value.absent(),
                Value<bool> isAdvanced = const Value.absent(),
              }) => PassCompanion(
                passId: passId,
                passWord: passWord,
                personName: personName,
                canPersons: canPersons,
                canStages: canStages,
                canAreas: canAreas,
                canFathers: canFathers,
                canReports: canReports,
                canUsers: canUsers,
                canAbsence: canAbsence,
                canMaintenance: canMaintenance,
                canIdCard: canIdCard,
                canTayo: canTayo,
                canTransfer: canTransfer,
                canServices: canServices,
                canKhoros: canKhoros,
                canBehavior: canBehavior,
                isAdvanced: isAdvanced,
              ),
          createCompanionCallback:
              ({
                Value<int> passId = const Value.absent(),
                Value<String?> passWord = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<bool?> canPersons = const Value.absent(),
                Value<bool?> canStages = const Value.absent(),
                Value<bool?> canAreas = const Value.absent(),
                Value<bool?> canFathers = const Value.absent(),
                Value<bool?> canReports = const Value.absent(),
                Value<bool?> canUsers = const Value.absent(),
                Value<bool?> canAbsence = const Value.absent(),
                Value<bool?> canMaintenance = const Value.absent(),
                Value<bool?> canIdCard = const Value.absent(),
                Value<bool?> canTayo = const Value.absent(),
                Value<bool?> canTransfer = const Value.absent(),
                Value<bool?> canServices = const Value.absent(),
                Value<bool?> canKhoros = const Value.absent(),
                Value<bool?> canBehavior = const Value.absent(),
                Value<bool> isAdvanced = const Value.absent(),
              }) => PassCompanion.insert(
                passId: passId,
                passWord: passWord,
                personName: personName,
                canPersons: canPersons,
                canStages: canStages,
                canAreas: canAreas,
                canFathers: canFathers,
                canReports: canReports,
                canUsers: canUsers,
                canAbsence: canAbsence,
                canMaintenance: canMaintenance,
                canIdCard: canIdCard,
                canTayo: canTayo,
                canTransfer: canTransfer,
                canServices: canServices,
                canKhoros: canKhoros,
                canBehavior: canBehavior,
                isAdvanced: isAdvanced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PassTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                userPermissionsExtRefs = false,
                userVisibilityFiltersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (userPermissionsExtRefs) db.userPermissionsExt,
                    if (userVisibilityFiltersRefs) db.userVisibilityFilters,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (userPermissionsExtRefs)
                        await $_getPrefetchedData<
                          PassData,
                          $PassTable,
                          UserPermissionsExtData
                        >(
                          currentTable: table,
                          referencedTable: $$PassTableReferences
                              ._userPermissionsExtRefsTable(db),
                          managerFromTypedResult: (p0) => $$PassTableReferences(
                            db,
                            table,
                            p0,
                          ).userPermissionsExtRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.passId,
                              ),
                          typedResults: items,
                        ),
                      if (userVisibilityFiltersRefs)
                        await $_getPrefetchedData<
                          PassData,
                          $PassTable,
                          UserVisibilityFilter
                        >(
                          currentTable: table,
                          referencedTable: $$PassTableReferences
                              ._userVisibilityFiltersRefsTable(db),
                          managerFromTypedResult: (p0) => $$PassTableReferences(
                            db,
                            table,
                            p0,
                          ).userVisibilityFiltersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.passId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (PassData, $$PassTableReferences),
      PassData,
      PrefetchHooks Function({
        bool userPermissionsExtRefs,
        bool userVisibilityFiltersRefs,
      })
    >;
typedef $$PersonsTableCreateCompanionBuilder =
    PersonsCompanion Function({
      Value<int> personId,
      Value<String?> personName,
      Value<int?> stageId,
      Value<int?> khorosId,
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
      Value<String?> rohot,
      Value<String?> leader,
    });
typedef $$PersonsTableUpdateCompanionBuilder =
    PersonsCompanion Function({
      Value<int> personId,
      Value<String?> personName,
      Value<int?> stageId,
      Value<int?> khorosId,
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
      Value<String?> rohot,
      Value<String?> leader,
    });

final class $$PersonsTableReferences
    extends BaseReferences<_$AppDatabase, $PersonsTable, Person> {
  $$PersonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PersonServicesTable, List<PersonService>>
  _personServicesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.personServices,
    aliasName: $_aliasNameGenerator(
      db.persons.personId,
      db.personServices.personId,
    ),
  );

  $$PersonServicesTableProcessedTableManager get personServicesRefs {
    final manager = $$PersonServicesTableTableManager($_db, $_db.personServices)
        .filter(
          (f) => f.personId.personId.sqlEquals($_itemColumn<int>('Person_ID')!),
        );

    final cache = $_typedResult.readTableOrNull(_personServicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PersonCustomFieldValuesTable,
    List<PersonCustomFieldValue>
  >
  _personCustomFieldValuesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.personCustomFieldValues,
        aliasName: $_aliasNameGenerator(
          db.persons.personId,
          db.personCustomFieldValues.personId,
        ),
      );

  $$PersonCustomFieldValuesTableProcessedTableManager
  get personCustomFieldValuesRefs {
    final manager =
        $$PersonCustomFieldValuesTableTableManager(
          $_db,
          $_db.personCustomFieldValues,
        ).filter(
          (f) => f.personId.personId.sqlEquals($_itemColumn<int>('Person_ID')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _personCustomFieldValuesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PersonDocumentsTable, List<PersonDocument>>
  _personDocumentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.personDocuments,
    aliasName: $_aliasNameGenerator(
      db.persons.personId,
      db.personDocuments.personId,
    ),
  );

  $$PersonDocumentsTableProcessedTableManager get personDocumentsRefs {
    final manager =
        $$PersonDocumentsTableTableManager($_db, $_db.personDocuments).filter(
          (f) => f.personId.personId.sqlEquals($_itemColumn<int>('Person_ID')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _personDocumentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $FamilyRelationshipsTable,
    List<FamilyRelationship>
  >
  _personRelationshipsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.familyRelationships,
    aliasName: $_aliasNameGenerator(
      db.persons.personId,
      db.familyRelationships.personId,
    ),
  );

  $$FamilyRelationshipsTableProcessedTableManager get personRelationships {
    final manager =
        $$FamilyRelationshipsTableTableManager(
          $_db,
          $_db.familyRelationships,
        ).filter(
          (f) => f.personId.personId.sqlEquals($_itemColumn<int>('Person_ID')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _personRelationshipsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $FamilyRelationshipsTable,
    List<FamilyRelationship>
  >
  _relatedPersonRelationshipsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.familyRelationships,
        aliasName: $_aliasNameGenerator(
          db.persons.personId,
          db.familyRelationships.relatedPersonId,
        ),
      );

  $$FamilyRelationshipsTableProcessedTableManager
  get relatedPersonRelationships {
    final manager =
        $$FamilyRelationshipsTableTableManager(
          $_db,
          $_db.familyRelationships,
        ).filter(
          (f) => f.relatedPersonId.personId.sqlEquals(
            $_itemColumn<int>('Person_ID')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _relatedPersonRelationshipsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<int> get khorosId => $composableBuilder(
    column: $table.khorosId,
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

  ColumnFilters<String> get rohot => $composableBuilder(
    column: $table.rohot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get leader => $composableBuilder(
    column: $table.leader,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> personServicesRefs(
    Expression<bool> Function($$PersonServicesTableFilterComposer f) f,
  ) {
    final $$PersonServicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.personServices,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonServicesTableFilterComposer(
            $db: $db,
            $table: $db.personServices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> personCustomFieldValuesRefs(
    Expression<bool> Function($$PersonCustomFieldValuesTableFilterComposer f) f,
  ) {
    final $$PersonCustomFieldValuesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.personId,
          referencedTable: $db.personCustomFieldValues,
          getReferencedColumn: (t) => t.personId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonCustomFieldValuesTableFilterComposer(
                $db: $db,
                $table: $db.personCustomFieldValues,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> personDocumentsRefs(
    Expression<bool> Function($$PersonDocumentsTableFilterComposer f) f,
  ) {
    final $$PersonDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.personDocuments,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.personDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> personRelationships(
    Expression<bool> Function($$FamilyRelationshipsTableFilterComposer f) f,
  ) {
    final $$FamilyRelationshipsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.familyRelationships,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyRelationshipsTableFilterComposer(
            $db: $db,
            $table: $db.familyRelationships,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> relatedPersonRelationships(
    Expression<bool> Function($$FamilyRelationshipsTableFilterComposer f) f,
  ) {
    final $$FamilyRelationshipsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.familyRelationships,
      getReferencedColumn: (t) => t.relatedPersonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyRelationshipsTableFilterComposer(
            $db: $db,
            $table: $db.familyRelationships,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<int> get khorosId => $composableBuilder(
    column: $table.khorosId,
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

  ColumnOrderings<String> get rohot => $composableBuilder(
    column: $table.rohot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get leader => $composableBuilder(
    column: $table.leader,
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

  GeneratedColumn<int> get khorosId =>
      $composableBuilder(column: $table.khorosId, builder: (column) => column);

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

  GeneratedColumn<String> get rohot =>
      $composableBuilder(column: $table.rohot, builder: (column) => column);

  GeneratedColumn<String> get leader =>
      $composableBuilder(column: $table.leader, builder: (column) => column);

  Expression<T> personServicesRefs<T extends Object>(
    Expression<T> Function($$PersonServicesTableAnnotationComposer a) f,
  ) {
    final $$PersonServicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.personServices,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonServicesTableAnnotationComposer(
            $db: $db,
            $table: $db.personServices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> personCustomFieldValuesRefs<T extends Object>(
    Expression<T> Function($$PersonCustomFieldValuesTableAnnotationComposer a)
    f,
  ) {
    final $$PersonCustomFieldValuesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.personId,
          referencedTable: $db.personCustomFieldValues,
          getReferencedColumn: (t) => t.personId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonCustomFieldValuesTableAnnotationComposer(
                $db: $db,
                $table: $db.personCustomFieldValues,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> personDocumentsRefs<T extends Object>(
    Expression<T> Function($$PersonDocumentsTableAnnotationComposer a) f,
  ) {
    final $$PersonDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.personDocuments,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.personDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> personRelationships<T extends Object>(
    Expression<T> Function($$FamilyRelationshipsTableAnnotationComposer a) f,
  ) {
    final $$FamilyRelationshipsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.personId,
          referencedTable: $db.familyRelationships,
          getReferencedColumn: (t) => t.personId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FamilyRelationshipsTableAnnotationComposer(
                $db: $db,
                $table: $db.familyRelationships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> relatedPersonRelationships<T extends Object>(
    Expression<T> Function($$FamilyRelationshipsTableAnnotationComposer a) f,
  ) {
    final $$FamilyRelationshipsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.personId,
          referencedTable: $db.familyRelationships,
          getReferencedColumn: (t) => t.relatedPersonId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FamilyRelationshipsTableAnnotationComposer(
                $db: $db,
                $table: $db.familyRelationships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
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
          (Person, $$PersonsTableReferences),
          Person,
          PrefetchHooks Function({
            bool personServicesRefs,
            bool personCustomFieldValuesRefs,
            bool personDocumentsRefs,
            bool personRelationships,
            bool relatedPersonRelationships,
          })
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
                Value<int> personId = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<int?> stageId = const Value.absent(),
                Value<int?> khorosId = const Value.absent(),
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
                Value<String?> rohot = const Value.absent(),
                Value<String?> leader = const Value.absent(),
              }) => PersonsCompanion(
                personId: personId,
                personName: personName,
                stageId: stageId,
                khorosId: khorosId,
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
                rohot: rohot,
                leader: leader,
              ),
          createCompanionCallback:
              ({
                Value<int> personId = const Value.absent(),
                Value<String?> personName = const Value.absent(),
                Value<int?> stageId = const Value.absent(),
                Value<int?> khorosId = const Value.absent(),
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
                Value<String?> rohot = const Value.absent(),
                Value<String?> leader = const Value.absent(),
              }) => PersonsCompanion.insert(
                personId: personId,
                personName: personName,
                stageId: stageId,
                khorosId: khorosId,
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
                rohot: rohot,
                leader: leader,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                personServicesRefs = false,
                personCustomFieldValuesRefs = false,
                personDocumentsRefs = false,
                personRelationships = false,
                relatedPersonRelationships = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (personServicesRefs) db.personServices,
                    if (personCustomFieldValuesRefs) db.personCustomFieldValues,
                    if (personDocumentsRefs) db.personDocuments,
                    if (personRelationships) db.familyRelationships,
                    if (relatedPersonRelationships) db.familyRelationships,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (personServicesRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PersonsTable,
                          PersonService
                        >(
                          currentTable: table,
                          referencedTable: $$PersonsTableReferences
                              ._personServicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).personServicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.personId,
                              ),
                          typedResults: items,
                        ),
                      if (personCustomFieldValuesRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PersonsTable,
                          PersonCustomFieldValue
                        >(
                          currentTable: table,
                          referencedTable: $$PersonsTableReferences
                              ._personCustomFieldValuesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).personCustomFieldValuesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.personId,
                              ),
                          typedResults: items,
                        ),
                      if (personDocumentsRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PersonsTable,
                          PersonDocument
                        >(
                          currentTable: table,
                          referencedTable: $$PersonsTableReferences
                              ._personDocumentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).personDocumentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.personId,
                              ),
                          typedResults: items,
                        ),
                      if (personRelationships)
                        await $_getPrefetchedData<
                          Person,
                          $PersonsTable,
                          FamilyRelationship
                        >(
                          currentTable: table,
                          referencedTable: $$PersonsTableReferences
                              ._personRelationshipsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).personRelationships,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.personId,
                              ),
                          typedResults: items,
                        ),
                      if (relatedPersonRelationships)
                        await $_getPrefetchedData<
                          Person,
                          $PersonsTable,
                          FamilyRelationship
                        >(
                          currentTable: table,
                          referencedTable: $$PersonsTableReferences
                              ._relatedPersonRelationshipsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).relatedPersonRelationships,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.relatedPersonId == item.personId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (Person, $$PersonsTableReferences),
      Person,
      PrefetchHooks Function({
        bool personServicesRefs,
        bool personCustomFieldValuesRefs,
        bool personDocumentsRefs,
        bool personRelationships,
        bool relatedPersonRelationships,
      })
    >;
typedef $$ServicesTableCreateCompanionBuilder =
    ServicesCompanion Function({
      Value<int> serviceId,
      Value<String?> serviceName,
      Value<int?> dayOfWeek,
      Value<int?> hour,
      Value<int?> minute,
      Value<int?> endHour,
      Value<int?> endMinute,
      Value<Uint8List?> logo,
    });
typedef $$ServicesTableUpdateCompanionBuilder =
    ServicesCompanion Function({
      Value<int> serviceId,
      Value<String?> serviceName,
      Value<int?> dayOfWeek,
      Value<int?> hour,
      Value<int?> minute,
      Value<int?> endHour,
      Value<int?> endMinute,
      Value<Uint8List?> logo,
    });

final class $$ServicesTableReferences
    extends BaseReferences<_$AppDatabase, $ServicesTable, ServiceData> {
  $$ServicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StagesTable, List<Stage>> _stagesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.stages,
    aliasName: $_aliasNameGenerator(db.services.serviceId, db.stages.serviceId),
  );

  $$StagesTableProcessedTableManager get stagesRefs {
    final manager = $$StagesTableTableManager($_db, $_db.stages).filter(
      (f) => f.serviceId.serviceId.sqlEquals($_itemColumn<int>('Service_ID')!),
    );

    final cache = $_typedResult.readTableOrNull(_stagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$KhorosesTable, List<Khorose>> _khorosesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.khoroses,
    aliasName: $_aliasNameGenerator(
      db.services.serviceId,
      db.khoroses.serviceId,
    ),
  );

  $$KhorosesTableProcessedTableManager get khorosesRefs {
    final manager = $$KhorosesTableTableManager($_db, $_db.khoroses).filter(
      (f) => f.serviceId.serviceId.sqlEquals($_itemColumn<int>('Service_ID')!),
    );

    final cache = $_typedResult.readTableOrNull(_khorosesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$KhorosServicesTable, List<KhorosService>>
  _khorosServicesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.khorosServices,
    aliasName: $_aliasNameGenerator(
      db.services.serviceId,
      db.khorosServices.serviceId,
    ),
  );

  $$KhorosServicesTableProcessedTableManager get khorosServicesRefs {
    final manager = $$KhorosServicesTableTableManager($_db, $_db.khorosServices)
        .filter(
          (f) =>
              f.serviceId.serviceId.sqlEquals($_itemColumn<int>('Service_ID')!),
        );

    final cache = $_typedResult.readTableOrNull(_khorosServicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StageServicesTable, List<StageService>>
  _stageServicesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stageServices,
    aliasName: $_aliasNameGenerator(
      db.services.serviceId,
      db.stageServices.serviceId,
    ),
  );

  $$StageServicesTableProcessedTableManager get stageServicesRefs {
    final manager = $$StageServicesTableTableManager($_db, $_db.stageServices)
        .filter(
          (f) =>
              f.serviceId.serviceId.sqlEquals($_itemColumn<int>('Service_ID')!),
        );

    final cache = $_typedResult.readTableOrNull(_stageServicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PersonServicesTable, List<PersonService>>
  _personServicesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.personServices,
    aliasName: $_aliasNameGenerator(
      db.services.serviceId,
      db.personServices.serviceId,
    ),
  );

  $$PersonServicesTableProcessedTableManager get personServicesRefs {
    final manager = $$PersonServicesTableTableManager($_db, $_db.personServices)
        .filter(
          (f) =>
              f.serviceId.serviceId.sqlEquals($_itemColumn<int>('Service_ID')!),
        );

    final cache = $_typedResult.readTableOrNull(_personServicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ServicesTableFilterComposer
    extends Composer<_$AppDatabase, $ServicesTable> {
  $$ServicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceName => $composableBuilder(
    column: $table.serviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endHour => $composableBuilder(
    column: $table.endHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> stagesRefs(
    Expression<bool> Function($$StagesTableFilterComposer f) f,
  ) {
    final $$StagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.stages,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StagesTableFilterComposer(
            $db: $db,
            $table: $db.stages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> khorosesRefs(
    Expression<bool> Function($$KhorosesTableFilterComposer f) f,
  ) {
    final $$KhorosesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.khoroses,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KhorosesTableFilterComposer(
            $db: $db,
            $table: $db.khoroses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> khorosServicesRefs(
    Expression<bool> Function($$KhorosServicesTableFilterComposer f) f,
  ) {
    final $$KhorosServicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.khorosServices,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KhorosServicesTableFilterComposer(
            $db: $db,
            $table: $db.khorosServices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> stageServicesRefs(
    Expression<bool> Function($$StageServicesTableFilterComposer f) f,
  ) {
    final $$StageServicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.stageServices,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageServicesTableFilterComposer(
            $db: $db,
            $table: $db.stageServices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> personServicesRefs(
    Expression<bool> Function($$PersonServicesTableFilterComposer f) f,
  ) {
    final $$PersonServicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.personServices,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonServicesTableFilterComposer(
            $db: $db,
            $table: $db.personServices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ServicesTableOrderingComposer
    extends Composer<_$AppDatabase, $ServicesTable> {
  $$ServicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceName => $composableBuilder(
    column: $table.serviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endHour => $composableBuilder(
    column: $table.endHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ServicesTable> {
  $$ServicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);

  GeneratedColumn<String> get serviceName => $composableBuilder(
    column: $table.serviceName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<int> get endHour =>
      $composableBuilder(column: $table.endHour, builder: (column) => column);

  GeneratedColumn<int> get endMinute =>
      $composableBuilder(column: $table.endMinute, builder: (column) => column);

  GeneratedColumn<Uint8List> get logo =>
      $composableBuilder(column: $table.logo, builder: (column) => column);

  Expression<T> stagesRefs<T extends Object>(
    Expression<T> Function($$StagesTableAnnotationComposer a) f,
  ) {
    final $$StagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.stages,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StagesTableAnnotationComposer(
            $db: $db,
            $table: $db.stages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> khorosesRefs<T extends Object>(
    Expression<T> Function($$KhorosesTableAnnotationComposer a) f,
  ) {
    final $$KhorosesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.khoroses,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KhorosesTableAnnotationComposer(
            $db: $db,
            $table: $db.khoroses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> khorosServicesRefs<T extends Object>(
    Expression<T> Function($$KhorosServicesTableAnnotationComposer a) f,
  ) {
    final $$KhorosServicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.khorosServices,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KhorosServicesTableAnnotationComposer(
            $db: $db,
            $table: $db.khorosServices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> stageServicesRefs<T extends Object>(
    Expression<T> Function($$StageServicesTableAnnotationComposer a) f,
  ) {
    final $$StageServicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.stageServices,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageServicesTableAnnotationComposer(
            $db: $db,
            $table: $db.stageServices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> personServicesRefs<T extends Object>(
    Expression<T> Function($$PersonServicesTableAnnotationComposer a) f,
  ) {
    final $$PersonServicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.personServices,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonServicesTableAnnotationComposer(
            $db: $db,
            $table: $db.personServices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ServicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ServicesTable,
          ServiceData,
          $$ServicesTableFilterComposer,
          $$ServicesTableOrderingComposer,
          $$ServicesTableAnnotationComposer,
          $$ServicesTableCreateCompanionBuilder,
          $$ServicesTableUpdateCompanionBuilder,
          (ServiceData, $$ServicesTableReferences),
          ServiceData,
          PrefetchHooks Function({
            bool stagesRefs,
            bool khorosesRefs,
            bool khorosServicesRefs,
            bool stageServicesRefs,
            bool personServicesRefs,
          })
        > {
  $$ServicesTableTableManager(_$AppDatabase db, $ServicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> serviceId = const Value.absent(),
                Value<String?> serviceName = const Value.absent(),
                Value<int?> dayOfWeek = const Value.absent(),
                Value<int?> hour = const Value.absent(),
                Value<int?> minute = const Value.absent(),
                Value<int?> endHour = const Value.absent(),
                Value<int?> endMinute = const Value.absent(),
                Value<Uint8List?> logo = const Value.absent(),
              }) => ServicesCompanion(
                serviceId: serviceId,
                serviceName: serviceName,
                dayOfWeek: dayOfWeek,
                hour: hour,
                minute: minute,
                endHour: endHour,
                endMinute: endMinute,
                logo: logo,
              ),
          createCompanionCallback:
              ({
                Value<int> serviceId = const Value.absent(),
                Value<String?> serviceName = const Value.absent(),
                Value<int?> dayOfWeek = const Value.absent(),
                Value<int?> hour = const Value.absent(),
                Value<int?> minute = const Value.absent(),
                Value<int?> endHour = const Value.absent(),
                Value<int?> endMinute = const Value.absent(),
                Value<Uint8List?> logo = const Value.absent(),
              }) => ServicesCompanion.insert(
                serviceId: serviceId,
                serviceName: serviceName,
                dayOfWeek: dayOfWeek,
                hour: hour,
                minute: minute,
                endHour: endHour,
                endMinute: endMinute,
                logo: logo,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ServicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                stagesRefs = false,
                khorosesRefs = false,
                khorosServicesRefs = false,
                stageServicesRefs = false,
                personServicesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (stagesRefs) db.stages,
                    if (khorosesRefs) db.khoroses,
                    if (khorosServicesRefs) db.khorosServices,
                    if (stageServicesRefs) db.stageServices,
                    if (personServicesRefs) db.personServices,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (stagesRefs)
                        await $_getPrefetchedData<
                          ServiceData,
                          $ServicesTable,
                          Stage
                        >(
                          currentTable: table,
                          referencedTable: $$ServicesTableReferences
                              ._stagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ServicesTableReferences(
                                db,
                                table,
                                p0,
                              ).stagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.serviceId == item.serviceId,
                              ),
                          typedResults: items,
                        ),
                      if (khorosesRefs)
                        await $_getPrefetchedData<
                          ServiceData,
                          $ServicesTable,
                          Khorose
                        >(
                          currentTable: table,
                          referencedTable: $$ServicesTableReferences
                              ._khorosesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ServicesTableReferences(
                                db,
                                table,
                                p0,
                              ).khorosesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.serviceId == item.serviceId,
                              ),
                          typedResults: items,
                        ),
                      if (khorosServicesRefs)
                        await $_getPrefetchedData<
                          ServiceData,
                          $ServicesTable,
                          KhorosService
                        >(
                          currentTable: table,
                          referencedTable: $$ServicesTableReferences
                              ._khorosServicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ServicesTableReferences(
                                db,
                                table,
                                p0,
                              ).khorosServicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.serviceId == item.serviceId,
                              ),
                          typedResults: items,
                        ),
                      if (stageServicesRefs)
                        await $_getPrefetchedData<
                          ServiceData,
                          $ServicesTable,
                          StageService
                        >(
                          currentTable: table,
                          referencedTable: $$ServicesTableReferences
                              ._stageServicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ServicesTableReferences(
                                db,
                                table,
                                p0,
                              ).stageServicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.serviceId == item.serviceId,
                              ),
                          typedResults: items,
                        ),
                      if (personServicesRefs)
                        await $_getPrefetchedData<
                          ServiceData,
                          $ServicesTable,
                          PersonService
                        >(
                          currentTable: table,
                          referencedTable: $$ServicesTableReferences
                              ._personServicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ServicesTableReferences(
                                db,
                                table,
                                p0,
                              ).personServicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.serviceId == item.serviceId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ServicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ServicesTable,
      ServiceData,
      $$ServicesTableFilterComposer,
      $$ServicesTableOrderingComposer,
      $$ServicesTableAnnotationComposer,
      $$ServicesTableCreateCompanionBuilder,
      $$ServicesTableUpdateCompanionBuilder,
      (ServiceData, $$ServicesTableReferences),
      ServiceData,
      PrefetchHooks Function({
        bool stagesRefs,
        bool khorosesRefs,
        bool khorosServicesRefs,
        bool stageServicesRefs,
        bool personServicesRefs,
      })
    >;
typedef $$StagesTableCreateCompanionBuilder =
    StagesCompanion Function({
      Value<int> stageId,
      Value<String?> stageName,
      Value<int?> serviceId,
      Value<int?> nextStageId,
    });
typedef $$StagesTableUpdateCompanionBuilder =
    StagesCompanion Function({
      Value<int> stageId,
      Value<String?> stageName,
      Value<int?> serviceId,
      Value<int?> nextStageId,
    });

final class $$StagesTableReferences
    extends BaseReferences<_$AppDatabase, $StagesTable, Stage> {
  $$StagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ServicesTable _serviceIdTable(_$AppDatabase db) =>
      db.services.createAlias(
        $_aliasNameGenerator(db.stages.serviceId, db.services.serviceId),
      );

  $$ServicesTableProcessedTableManager? get serviceId {
    final $_column = $_itemColumn<int>('Service_ID');
    if ($_column == null) return null;
    final manager = $$ServicesTableTableManager(
      $_db,
      $_db.services,
    ).filter((f) => f.serviceId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_serviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StagesTable _nextStageIdTable(_$AppDatabase db) =>
      db.stages.createAlias(
        $_aliasNameGenerator(db.stages.nextStageId, db.stages.stageId),
      );

  $$StagesTableProcessedTableManager? get nextStageId {
    final $_column = $_itemColumn<int>('Next_Stage_ID');
    if ($_column == null) return null;
    final manager = $$StagesTableTableManager(
      $_db,
      $_db.stages,
    ).filter((f) => f.stageId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nextStageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StageServicesTable, List<StageService>>
  _stageServicesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stageServices,
    aliasName: $_aliasNameGenerator(
      db.stages.stageId,
      db.stageServices.stageId,
    ),
  );

  $$StageServicesTableProcessedTableManager get stageServicesRefs {
    final manager = $$StageServicesTableTableManager($_db, $_db.stageServices)
        .filter(
          (f) => f.stageId.stageId.sqlEquals($_itemColumn<int>('Stage_ID')!),
        );

    final cache = $_typedResult.readTableOrNull(_stageServicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  $$ServicesTableFilterComposer get serviceId {
    final $$ServicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableFilterComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StagesTableFilterComposer get nextStageId {
    final $$StagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nextStageId,
      referencedTable: $db.stages,
      getReferencedColumn: (t) => t.stageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StagesTableFilterComposer(
            $db: $db,
            $table: $db.stages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> stageServicesRefs(
    Expression<bool> Function($$StageServicesTableFilterComposer f) f,
  ) {
    final $$StageServicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageId,
      referencedTable: $db.stageServices,
      getReferencedColumn: (t) => t.stageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageServicesTableFilterComposer(
            $db: $db,
            $table: $db.stageServices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  $$ServicesTableOrderingComposer get serviceId {
    final $$ServicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableOrderingComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StagesTableOrderingComposer get nextStageId {
    final $$StagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nextStageId,
      referencedTable: $db.stages,
      getReferencedColumn: (t) => t.stageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StagesTableOrderingComposer(
            $db: $db,
            $table: $db.stages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$ServicesTableAnnotationComposer get serviceId {
    final $$ServicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableAnnotationComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StagesTableAnnotationComposer get nextStageId {
    final $$StagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nextStageId,
      referencedTable: $db.stages,
      getReferencedColumn: (t) => t.stageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StagesTableAnnotationComposer(
            $db: $db,
            $table: $db.stages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> stageServicesRefs<T extends Object>(
    Expression<T> Function($$StageServicesTableAnnotationComposer a) f,
  ) {
    final $$StageServicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageId,
      referencedTable: $db.stageServices,
      getReferencedColumn: (t) => t.stageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StageServicesTableAnnotationComposer(
            $db: $db,
            $table: $db.stageServices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (Stage, $$StagesTableReferences),
          Stage,
          PrefetchHooks Function({
            bool serviceId,
            bool nextStageId,
            bool stageServicesRefs,
          })
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
                Value<int> stageId = const Value.absent(),
                Value<String?> stageName = const Value.absent(),
                Value<int?> serviceId = const Value.absent(),
                Value<int?> nextStageId = const Value.absent(),
              }) => StagesCompanion(
                stageId: stageId,
                stageName: stageName,
                serviceId: serviceId,
                nextStageId: nextStageId,
              ),
          createCompanionCallback:
              ({
                Value<int> stageId = const Value.absent(),
                Value<String?> stageName = const Value.absent(),
                Value<int?> serviceId = const Value.absent(),
                Value<int?> nextStageId = const Value.absent(),
              }) => StagesCompanion.insert(
                stageId: stageId,
                stageName: stageName,
                serviceId: serviceId,
                nextStageId: nextStageId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$StagesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                serviceId = false,
                nextStageId = false,
                stageServicesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (stageServicesRefs) db.stageServices,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (serviceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.serviceId,
                                    referencedTable: $$StagesTableReferences
                                        ._serviceIdTable(db),
                                    referencedColumn: $$StagesTableReferences
                                        ._serviceIdTable(db)
                                        .serviceId,
                                  )
                                  as T;
                        }
                        if (nextStageId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.nextStageId,
                                    referencedTable: $$StagesTableReferences
                                        ._nextStageIdTable(db),
                                    referencedColumn: $$StagesTableReferences
                                        ._nextStageIdTable(db)
                                        .stageId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (stageServicesRefs)
                        await $_getPrefetchedData<
                          Stage,
                          $StagesTable,
                          StageService
                        >(
                          currentTable: table,
                          referencedTable: $$StagesTableReferences
                              ._stageServicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StagesTableReferences(
                                db,
                                table,
                                p0,
                              ).stageServicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.stageId == item.stageId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (Stage, $$StagesTableReferences),
      Stage,
      PrefetchHooks Function({
        bool serviceId,
        bool nextStageId,
        bool stageServicesRefs,
      })
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String settingKey,
      Value<String?> settingValue,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> settingKey,
      Value<String?> settingValue,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> settingKey = const Value.absent(),
                Value<String?> settingValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                settingKey: settingKey,
                settingValue: settingValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String settingKey,
                Value<String?> settingValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                settingKey: settingKey,
                settingValue: settingValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$TayoCardsTableCreateCompanionBuilder =
    TayoCardsCompanion Function({
      Value<int> cardId,
      Value<String?> cardName,
      Value<int?> cardPoints,
      Value<Uint8List?> cardImage,
    });
typedef $$TayoCardsTableUpdateCompanionBuilder =
    TayoCardsCompanion Function({
      Value<int> cardId,
      Value<String?> cardName,
      Value<int?> cardPoints,
      Value<Uint8List?> cardImage,
    });

class $$TayoCardsTableFilterComposer
    extends Composer<_$AppDatabase, $TayoCardsTable> {
  $$TayoCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardName => $composableBuilder(
    column: $table.cardName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardPoints => $composableBuilder(
    column: $table.cardPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get cardImage => $composableBuilder(
    column: $table.cardImage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TayoCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $TayoCardsTable> {
  $$TayoCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardName => $composableBuilder(
    column: $table.cardName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardPoints => $composableBuilder(
    column: $table.cardPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get cardImage => $composableBuilder(
    column: $table.cardImage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TayoCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TayoCardsTable> {
  $$TayoCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get cardName =>
      $composableBuilder(column: $table.cardName, builder: (column) => column);

  GeneratedColumn<int> get cardPoints => $composableBuilder(
    column: $table.cardPoints,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get cardImage =>
      $composableBuilder(column: $table.cardImage, builder: (column) => column);
}

class $$TayoCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TayoCardsTable,
          TayoCard,
          $$TayoCardsTableFilterComposer,
          $$TayoCardsTableOrderingComposer,
          $$TayoCardsTableAnnotationComposer,
          $$TayoCardsTableCreateCompanionBuilder,
          $$TayoCardsTableUpdateCompanionBuilder,
          (TayoCard, BaseReferences<_$AppDatabase, $TayoCardsTable, TayoCard>),
          TayoCard,
          PrefetchHooks Function()
        > {
  $$TayoCardsTableTableManager(_$AppDatabase db, $TayoCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TayoCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TayoCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TayoCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> cardId = const Value.absent(),
                Value<String?> cardName = const Value.absent(),
                Value<int?> cardPoints = const Value.absent(),
                Value<Uint8List?> cardImage = const Value.absent(),
              }) => TayoCardsCompanion(
                cardId: cardId,
                cardName: cardName,
                cardPoints: cardPoints,
                cardImage: cardImage,
              ),
          createCompanionCallback:
              ({
                Value<int> cardId = const Value.absent(),
                Value<String?> cardName = const Value.absent(),
                Value<int?> cardPoints = const Value.absent(),
                Value<Uint8List?> cardImage = const Value.absent(),
              }) => TayoCardsCompanion.insert(
                cardId: cardId,
                cardName: cardName,
                cardPoints: cardPoints,
                cardImage: cardImage,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TayoCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TayoCardsTable,
      TayoCard,
      $$TayoCardsTableFilterComposer,
      $$TayoCardsTableOrderingComposer,
      $$TayoCardsTableAnnotationComposer,
      $$TayoCardsTableCreateCompanionBuilder,
      $$TayoCardsTableUpdateCompanionBuilder,
      (TayoCard, BaseReferences<_$AppDatabase, $TayoCardsTable, TayoCard>),
      TayoCard,
      PrefetchHooks Function()
    >;
typedef $$PersonTayoPointsTableCreateCompanionBuilder =
    PersonTayoPointsCompanion Function({
      Value<int> id,
      Value<int?> personId,
      Value<int?> cardId,
      Value<int?> points,
      Value<String?> awardDate,
      Value<bool?> isAttendance,
      Value<String?> notes,
      Value<int?> serviceId,
    });
typedef $$PersonTayoPointsTableUpdateCompanionBuilder =
    PersonTayoPointsCompanion Function({
      Value<int> id,
      Value<int?> personId,
      Value<int?> cardId,
      Value<int?> points,
      Value<String?> awardDate,
      Value<bool?> isAttendance,
      Value<String?> notes,
      Value<int?> serviceId,
    });

class $$PersonTayoPointsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonTayoPointsTable> {
  $$PersonTayoPointsTableFilterComposer({
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

  ColumnFilters<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get awardDate => $composableBuilder(
    column: $table.awardDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAttendance => $composableBuilder(
    column: $table.isAttendance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersonTayoPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonTayoPointsTable> {
  $$PersonTayoPointsTableOrderingComposer({
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

  ColumnOrderings<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get awardDate => $composableBuilder(
    column: $table.awardDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAttendance => $composableBuilder(
    column: $table.isAttendance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceId => $composableBuilder(
    column: $table.serviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonTayoPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonTayoPointsTable> {
  $$PersonTayoPointsTableAnnotationComposer({
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

  GeneratedColumn<int> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<String> get awardDate =>
      $composableBuilder(column: $table.awardDate, builder: (column) => column);

  GeneratedColumn<bool> get isAttendance => $composableBuilder(
    column: $table.isAttendance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get serviceId =>
      $composableBuilder(column: $table.serviceId, builder: (column) => column);
}

class $$PersonTayoPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonTayoPointsTable,
          PersonTayoPoint,
          $$PersonTayoPointsTableFilterComposer,
          $$PersonTayoPointsTableOrderingComposer,
          $$PersonTayoPointsTableAnnotationComposer,
          $$PersonTayoPointsTableCreateCompanionBuilder,
          $$PersonTayoPointsTableUpdateCompanionBuilder,
          (
            PersonTayoPoint,
            BaseReferences<
              _$AppDatabase,
              $PersonTayoPointsTable,
              PersonTayoPoint
            >,
          ),
          PersonTayoPoint,
          PrefetchHooks Function()
        > {
  $$PersonTayoPointsTableTableManager(
    _$AppDatabase db,
    $PersonTayoPointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonTayoPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonTayoPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonTayoPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<int?> cardId = const Value.absent(),
                Value<int?> points = const Value.absent(),
                Value<String?> awardDate = const Value.absent(),
                Value<bool?> isAttendance = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> serviceId = const Value.absent(),
              }) => PersonTayoPointsCompanion(
                id: id,
                personId: personId,
                cardId: cardId,
                points: points,
                awardDate: awardDate,
                isAttendance: isAttendance,
                notes: notes,
                serviceId: serviceId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<int?> cardId = const Value.absent(),
                Value<int?> points = const Value.absent(),
                Value<String?> awardDate = const Value.absent(),
                Value<bool?> isAttendance = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> serviceId = const Value.absent(),
              }) => PersonTayoPointsCompanion.insert(
                id: id,
                personId: personId,
                cardId: cardId,
                points: points,
                awardDate: awardDate,
                isAttendance: isAttendance,
                notes: notes,
                serviceId: serviceId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersonTayoPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonTayoPointsTable,
      PersonTayoPoint,
      $$PersonTayoPointsTableFilterComposer,
      $$PersonTayoPointsTableOrderingComposer,
      $$PersonTayoPointsTableAnnotationComposer,
      $$PersonTayoPointsTableCreateCompanionBuilder,
      $$PersonTayoPointsTableUpdateCompanionBuilder,
      (
        PersonTayoPoint,
        BaseReferences<_$AppDatabase, $PersonTayoPointsTable, PersonTayoPoint>,
      ),
      PersonTayoPoint,
      PrefetchHooks Function()
    >;
typedef $$KhorosesTableCreateCompanionBuilder =
    KhorosesCompanion Function({
      Value<int> khorosId,
      Value<String?> khorosName,
      Value<Uint8List?> logo,
      Value<int?> serviceId,
    });
typedef $$KhorosesTableUpdateCompanionBuilder =
    KhorosesCompanion Function({
      Value<int> khorosId,
      Value<String?> khorosName,
      Value<Uint8List?> logo,
      Value<int?> serviceId,
    });

final class $$KhorosesTableReferences
    extends BaseReferences<_$AppDatabase, $KhorosesTable, Khorose> {
  $$KhorosesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ServicesTable _serviceIdTable(_$AppDatabase db) =>
      db.services.createAlias(
        $_aliasNameGenerator(db.khoroses.serviceId, db.services.serviceId),
      );

  $$ServicesTableProcessedTableManager? get serviceId {
    final $_column = $_itemColumn<int>('Service_ID');
    if ($_column == null) return null;
    final manager = $$ServicesTableTableManager(
      $_db,
      $_db.services,
    ).filter((f) => f.serviceId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_serviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$KhorosServicesTable, List<KhorosService>>
  _khorosServicesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.khorosServices,
    aliasName: $_aliasNameGenerator(
      db.khoroses.khorosId,
      db.khorosServices.khorosId,
    ),
  );

  $$KhorosServicesTableProcessedTableManager get khorosServicesRefs {
    final manager = $$KhorosServicesTableTableManager($_db, $_db.khorosServices)
        .filter(
          (f) => f.khorosId.khorosId.sqlEquals($_itemColumn<int>('Khoros_ID')!),
        );

    final cache = $_typedResult.readTableOrNull(_khorosServicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KhorosesTableFilterComposer
    extends Composer<_$AppDatabase, $KhorosesTable> {
  $$KhorosesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get khorosId => $composableBuilder(
    column: $table.khorosId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get khorosName => $composableBuilder(
    column: $table.khorosName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnFilters(column),
  );

  $$ServicesTableFilterComposer get serviceId {
    final $$ServicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableFilterComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> khorosServicesRefs(
    Expression<bool> Function($$KhorosServicesTableFilterComposer f) f,
  ) {
    final $$KhorosServicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.khorosId,
      referencedTable: $db.khorosServices,
      getReferencedColumn: (t) => t.khorosId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KhorosServicesTableFilterComposer(
            $db: $db,
            $table: $db.khorosServices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KhorosesTableOrderingComposer
    extends Composer<_$AppDatabase, $KhorosesTable> {
  $$KhorosesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get khorosId => $composableBuilder(
    column: $table.khorosId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get khorosName => $composableBuilder(
    column: $table.khorosName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnOrderings(column),
  );

  $$ServicesTableOrderingComposer get serviceId {
    final $$ServicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableOrderingComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KhorosesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KhorosesTable> {
  $$KhorosesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get khorosId =>
      $composableBuilder(column: $table.khorosId, builder: (column) => column);

  GeneratedColumn<String> get khorosName => $composableBuilder(
    column: $table.khorosName,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get logo =>
      $composableBuilder(column: $table.logo, builder: (column) => column);

  $$ServicesTableAnnotationComposer get serviceId {
    final $$ServicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableAnnotationComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> khorosServicesRefs<T extends Object>(
    Expression<T> Function($$KhorosServicesTableAnnotationComposer a) f,
  ) {
    final $$KhorosServicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.khorosId,
      referencedTable: $db.khorosServices,
      getReferencedColumn: (t) => t.khorosId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KhorosServicesTableAnnotationComposer(
            $db: $db,
            $table: $db.khorosServices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KhorosesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KhorosesTable,
          Khorose,
          $$KhorosesTableFilterComposer,
          $$KhorosesTableOrderingComposer,
          $$KhorosesTableAnnotationComposer,
          $$KhorosesTableCreateCompanionBuilder,
          $$KhorosesTableUpdateCompanionBuilder,
          (Khorose, $$KhorosesTableReferences),
          Khorose,
          PrefetchHooks Function({bool serviceId, bool khorosServicesRefs})
        > {
  $$KhorosesTableTableManager(_$AppDatabase db, $KhorosesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KhorosesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KhorosesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KhorosesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> khorosId = const Value.absent(),
                Value<String?> khorosName = const Value.absent(),
                Value<Uint8List?> logo = const Value.absent(),
                Value<int?> serviceId = const Value.absent(),
              }) => KhorosesCompanion(
                khorosId: khorosId,
                khorosName: khorosName,
                logo: logo,
                serviceId: serviceId,
              ),
          createCompanionCallback:
              ({
                Value<int> khorosId = const Value.absent(),
                Value<String?> khorosName = const Value.absent(),
                Value<Uint8List?> logo = const Value.absent(),
                Value<int?> serviceId = const Value.absent(),
              }) => KhorosesCompanion.insert(
                khorosId: khorosId,
                khorosName: khorosName,
                logo: logo,
                serviceId: serviceId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$KhorosesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({serviceId = false, khorosServicesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (khorosServicesRefs) db.khorosServices,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (serviceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.serviceId,
                                    referencedTable: $$KhorosesTableReferences
                                        ._serviceIdTable(db),
                                    referencedColumn: $$KhorosesTableReferences
                                        ._serviceIdTable(db)
                                        .serviceId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (khorosServicesRefs)
                        await $_getPrefetchedData<
                          Khorose,
                          $KhorosesTable,
                          KhorosService
                        >(
                          currentTable: table,
                          referencedTable: $$KhorosesTableReferences
                              ._khorosServicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$KhorosesTableReferences(
                                db,
                                table,
                                p0,
                              ).khorosServicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.khorosId == item.khorosId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$KhorosesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KhorosesTable,
      Khorose,
      $$KhorosesTableFilterComposer,
      $$KhorosesTableOrderingComposer,
      $$KhorosesTableAnnotationComposer,
      $$KhorosesTableCreateCompanionBuilder,
      $$KhorosesTableUpdateCompanionBuilder,
      (Khorose, $$KhorosesTableReferences),
      Khorose,
      PrefetchHooks Function({bool serviceId, bool khorosServicesRefs})
    >;
typedef $$KhorosServicesTableCreateCompanionBuilder =
    KhorosServicesCompanion Function({
      required int khorosId,
      required int serviceId,
      Value<int> rowid,
    });
typedef $$KhorosServicesTableUpdateCompanionBuilder =
    KhorosServicesCompanion Function({
      Value<int> khorosId,
      Value<int> serviceId,
      Value<int> rowid,
    });

final class $$KhorosServicesTableReferences
    extends BaseReferences<_$AppDatabase, $KhorosServicesTable, KhorosService> {
  $$KhorosServicesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $KhorosesTable _khorosIdTable(_$AppDatabase db) =>
      db.khoroses.createAlias(
        $_aliasNameGenerator(db.khorosServices.khorosId, db.khoroses.khorosId),
      );

  $$KhorosesTableProcessedTableManager get khorosId {
    final $_column = $_itemColumn<int>('Khoros_ID')!;

    final manager = $$KhorosesTableTableManager(
      $_db,
      $_db.khoroses,
    ).filter((f) => f.khorosId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_khorosIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ServicesTable _serviceIdTable(_$AppDatabase db) =>
      db.services.createAlias(
        $_aliasNameGenerator(
          db.khorosServices.serviceId,
          db.services.serviceId,
        ),
      );

  $$ServicesTableProcessedTableManager get serviceId {
    final $_column = $_itemColumn<int>('Service_ID')!;

    final manager = $$ServicesTableTableManager(
      $_db,
      $_db.services,
    ).filter((f) => f.serviceId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_serviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$KhorosServicesTableFilterComposer
    extends Composer<_$AppDatabase, $KhorosServicesTable> {
  $$KhorosServicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$KhorosesTableFilterComposer get khorosId {
    final $$KhorosesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.khorosId,
      referencedTable: $db.khoroses,
      getReferencedColumn: (t) => t.khorosId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KhorosesTableFilterComposer(
            $db: $db,
            $table: $db.khoroses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServicesTableFilterComposer get serviceId {
    final $$ServicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableFilterComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KhorosServicesTableOrderingComposer
    extends Composer<_$AppDatabase, $KhorosServicesTable> {
  $$KhorosServicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$KhorosesTableOrderingComposer get khorosId {
    final $$KhorosesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.khorosId,
      referencedTable: $db.khoroses,
      getReferencedColumn: (t) => t.khorosId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KhorosesTableOrderingComposer(
            $db: $db,
            $table: $db.khoroses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServicesTableOrderingComposer get serviceId {
    final $$ServicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableOrderingComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KhorosServicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KhorosServicesTable> {
  $$KhorosServicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$KhorosesTableAnnotationComposer get khorosId {
    final $$KhorosesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.khorosId,
      referencedTable: $db.khoroses,
      getReferencedColumn: (t) => t.khorosId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KhorosesTableAnnotationComposer(
            $db: $db,
            $table: $db.khoroses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServicesTableAnnotationComposer get serviceId {
    final $$ServicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableAnnotationComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KhorosServicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KhorosServicesTable,
          KhorosService,
          $$KhorosServicesTableFilterComposer,
          $$KhorosServicesTableOrderingComposer,
          $$KhorosServicesTableAnnotationComposer,
          $$KhorosServicesTableCreateCompanionBuilder,
          $$KhorosServicesTableUpdateCompanionBuilder,
          (KhorosService, $$KhorosServicesTableReferences),
          KhorosService,
          PrefetchHooks Function({bool khorosId, bool serviceId})
        > {
  $$KhorosServicesTableTableManager(
    _$AppDatabase db,
    $KhorosServicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KhorosServicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KhorosServicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KhorosServicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> khorosId = const Value.absent(),
                Value<int> serviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KhorosServicesCompanion(
                khorosId: khorosId,
                serviceId: serviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int khorosId,
                required int serviceId,
                Value<int> rowid = const Value.absent(),
              }) => KhorosServicesCompanion.insert(
                khorosId: khorosId,
                serviceId: serviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$KhorosServicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({khorosId = false, serviceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (khorosId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.khorosId,
                                referencedTable: $$KhorosServicesTableReferences
                                    ._khorosIdTable(db),
                                referencedColumn:
                                    $$KhorosServicesTableReferences
                                        ._khorosIdTable(db)
                                        .khorosId,
                              )
                              as T;
                    }
                    if (serviceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.serviceId,
                                referencedTable: $$KhorosServicesTableReferences
                                    ._serviceIdTable(db),
                                referencedColumn:
                                    $$KhorosServicesTableReferences
                                        ._serviceIdTable(db)
                                        .serviceId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$KhorosServicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KhorosServicesTable,
      KhorosService,
      $$KhorosServicesTableFilterComposer,
      $$KhorosServicesTableOrderingComposer,
      $$KhorosServicesTableAnnotationComposer,
      $$KhorosServicesTableCreateCompanionBuilder,
      $$KhorosServicesTableUpdateCompanionBuilder,
      (KhorosService, $$KhorosServicesTableReferences),
      KhorosService,
      PrefetchHooks Function({bool khorosId, bool serviceId})
    >;
typedef $$StageServicesTableCreateCompanionBuilder =
    StageServicesCompanion Function({
      required int stageId,
      required int serviceId,
      Value<int> rowid,
    });
typedef $$StageServicesTableUpdateCompanionBuilder =
    StageServicesCompanion Function({
      Value<int> stageId,
      Value<int> serviceId,
      Value<int> rowid,
    });

final class $$StageServicesTableReferences
    extends BaseReferences<_$AppDatabase, $StageServicesTable, StageService> {
  $$StageServicesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StagesTable _stageIdTable(_$AppDatabase db) => db.stages.createAlias(
    $_aliasNameGenerator(db.stageServices.stageId, db.stages.stageId),
  );

  $$StagesTableProcessedTableManager get stageId {
    final $_column = $_itemColumn<int>('Stage_ID')!;

    final manager = $$StagesTableTableManager(
      $_db,
      $_db.stages,
    ).filter((f) => f.stageId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ServicesTable _serviceIdTable(_$AppDatabase db) =>
      db.services.createAlias(
        $_aliasNameGenerator(db.stageServices.serviceId, db.services.serviceId),
      );

  $$ServicesTableProcessedTableManager get serviceId {
    final $_column = $_itemColumn<int>('Service_ID')!;

    final manager = $$ServicesTableTableManager(
      $_db,
      $_db.services,
    ).filter((f) => f.serviceId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_serviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StageServicesTableFilterComposer
    extends Composer<_$AppDatabase, $StageServicesTable> {
  $$StageServicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$StagesTableFilterComposer get stageId {
    final $$StagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageId,
      referencedTable: $db.stages,
      getReferencedColumn: (t) => t.stageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StagesTableFilterComposer(
            $db: $db,
            $table: $db.stages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServicesTableFilterComposer get serviceId {
    final $$ServicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableFilterComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StageServicesTableOrderingComposer
    extends Composer<_$AppDatabase, $StageServicesTable> {
  $$StageServicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$StagesTableOrderingComposer get stageId {
    final $$StagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageId,
      referencedTable: $db.stages,
      getReferencedColumn: (t) => t.stageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StagesTableOrderingComposer(
            $db: $db,
            $table: $db.stages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServicesTableOrderingComposer get serviceId {
    final $$ServicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableOrderingComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StageServicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StageServicesTable> {
  $$StageServicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$StagesTableAnnotationComposer get stageId {
    final $$StagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stageId,
      referencedTable: $db.stages,
      getReferencedColumn: (t) => t.stageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StagesTableAnnotationComposer(
            $db: $db,
            $table: $db.stages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServicesTableAnnotationComposer get serviceId {
    final $$ServicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableAnnotationComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StageServicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StageServicesTable,
          StageService,
          $$StageServicesTableFilterComposer,
          $$StageServicesTableOrderingComposer,
          $$StageServicesTableAnnotationComposer,
          $$StageServicesTableCreateCompanionBuilder,
          $$StageServicesTableUpdateCompanionBuilder,
          (StageService, $$StageServicesTableReferences),
          StageService,
          PrefetchHooks Function({bool stageId, bool serviceId})
        > {
  $$StageServicesTableTableManager(_$AppDatabase db, $StageServicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StageServicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StageServicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StageServicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> stageId = const Value.absent(),
                Value<int> serviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StageServicesCompanion(
                stageId: stageId,
                serviceId: serviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int stageId,
                required int serviceId,
                Value<int> rowid = const Value.absent(),
              }) => StageServicesCompanion.insert(
                stageId: stageId,
                serviceId: serviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StageServicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({stageId = false, serviceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (stageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.stageId,
                                referencedTable: $$StageServicesTableReferences
                                    ._stageIdTable(db),
                                referencedColumn: $$StageServicesTableReferences
                                    ._stageIdTable(db)
                                    .stageId,
                              )
                              as T;
                    }
                    if (serviceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.serviceId,
                                referencedTable: $$StageServicesTableReferences
                                    ._serviceIdTable(db),
                                referencedColumn: $$StageServicesTableReferences
                                    ._serviceIdTable(db)
                                    .serviceId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StageServicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StageServicesTable,
      StageService,
      $$StageServicesTableFilterComposer,
      $$StageServicesTableOrderingComposer,
      $$StageServicesTableAnnotationComposer,
      $$StageServicesTableCreateCompanionBuilder,
      $$StageServicesTableUpdateCompanionBuilder,
      (StageService, $$StageServicesTableReferences),
      StageService,
      PrefetchHooks Function({bool stageId, bool serviceId})
    >;
typedef $$PersonServicesTableCreateCompanionBuilder =
    PersonServicesCompanion Function({
      required int personId,
      required int serviceId,
      Value<int> rowid,
    });
typedef $$PersonServicesTableUpdateCompanionBuilder =
    PersonServicesCompanion Function({
      Value<int> personId,
      Value<int> serviceId,
      Value<int> rowid,
    });

final class $$PersonServicesTableReferences
    extends BaseReferences<_$AppDatabase, $PersonServicesTable, PersonService> {
  $$PersonServicesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PersonsTable _personIdTable(_$AppDatabase db) =>
      db.persons.createAlias(
        $_aliasNameGenerator(db.personServices.personId, db.persons.personId),
      );

  $$PersonsTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('Person_ID')!;

    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.personId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ServicesTable _serviceIdTable(_$AppDatabase db) =>
      db.services.createAlias(
        $_aliasNameGenerator(
          db.personServices.serviceId,
          db.services.serviceId,
        ),
      );

  $$ServicesTableProcessedTableManager get serviceId {
    final $_column = $_itemColumn<int>('Service_ID')!;

    final manager = $$ServicesTableTableManager(
      $_db,
      $_db.services,
    ).filter((f) => f.serviceId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_serviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PersonServicesTableFilterComposer
    extends Composer<_$AppDatabase, $PersonServicesTable> {
  $$PersonServicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServicesTableFilterComposer get serviceId {
    final $$ServicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableFilterComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonServicesTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonServicesTable> {
  $$PersonServicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServicesTableOrderingComposer get serviceId {
    final $$ServicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableOrderingComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonServicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonServicesTable> {
  $$PersonServicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ServicesTableAnnotationComposer get serviceId {
    final $$ServicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serviceId,
      referencedTable: $db.services,
      getReferencedColumn: (t) => t.serviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServicesTableAnnotationComposer(
            $db: $db,
            $table: $db.services,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonServicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonServicesTable,
          PersonService,
          $$PersonServicesTableFilterComposer,
          $$PersonServicesTableOrderingComposer,
          $$PersonServicesTableAnnotationComposer,
          $$PersonServicesTableCreateCompanionBuilder,
          $$PersonServicesTableUpdateCompanionBuilder,
          (PersonService, $$PersonServicesTableReferences),
          PersonService,
          PrefetchHooks Function({bool personId, bool serviceId})
        > {
  $$PersonServicesTableTableManager(
    _$AppDatabase db,
    $PersonServicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonServicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonServicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonServicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> personId = const Value.absent(),
                Value<int> serviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonServicesCompanion(
                personId: personId,
                serviceId: serviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int personId,
                required int serviceId,
                Value<int> rowid = const Value.absent(),
              }) => PersonServicesCompanion.insert(
                personId: personId,
                serviceId: serviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonServicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false, serviceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$PersonServicesTableReferences
                                    ._personIdTable(db),
                                referencedColumn:
                                    $$PersonServicesTableReferences
                                        ._personIdTable(db)
                                        .personId,
                              )
                              as T;
                    }
                    if (serviceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.serviceId,
                                referencedTable: $$PersonServicesTableReferences
                                    ._serviceIdTable(db),
                                referencedColumn:
                                    $$PersonServicesTableReferences
                                        ._serviceIdTable(db)
                                        .serviceId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PersonServicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonServicesTable,
      PersonService,
      $$PersonServicesTableFilterComposer,
      $$PersonServicesTableOrderingComposer,
      $$PersonServicesTableAnnotationComposer,
      $$PersonServicesTableCreateCompanionBuilder,
      $$PersonServicesTableUpdateCompanionBuilder,
      (PersonService, $$PersonServicesTableReferences),
      PersonService,
      PrefetchHooks Function({bool personId, bool serviceId})
    >;
typedef $$UserPermissionsExtTableCreateCompanionBuilder =
    UserPermissionsExtCompanion Function({
      required int userId,
      required String featureKey,
      Value<bool> canAdd,
      Value<bool> canEdit,
      Value<bool> canDelete,
      Value<int> rowid,
    });
typedef $$UserPermissionsExtTableUpdateCompanionBuilder =
    UserPermissionsExtCompanion Function({
      Value<int> userId,
      Value<String> featureKey,
      Value<bool> canAdd,
      Value<bool> canEdit,
      Value<bool> canDelete,
      Value<int> rowid,
    });

final class $$UserPermissionsExtTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $UserPermissionsExtTable,
          UserPermissionsExtData
        > {
  $$UserPermissionsExtTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PassTable _userIdTable(_$AppDatabase db) => db.pass.createAlias(
    $_aliasNameGenerator(db.userPermissionsExt.userId, db.pass.passId),
  );

  $$PassTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('User_ID')!;

    final manager = $$PassTableTableManager(
      $_db,
      $_db.pass,
    ).filter((f) => f.passId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserPermissionsExtTableFilterComposer
    extends Composer<_$AppDatabase, $UserPermissionsExtTable> {
  $$UserPermissionsExtTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get featureKey => $composableBuilder(
    column: $table.featureKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canAdd => $composableBuilder(
    column: $table.canAdd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canEdit => $composableBuilder(
    column: $table.canEdit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canDelete => $composableBuilder(
    column: $table.canDelete,
    builder: (column) => ColumnFilters(column),
  );

  $$PassTableFilterComposer get userId {
    final $$PassTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.pass,
      getReferencedColumn: (t) => t.passId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassTableFilterComposer(
            $db: $db,
            $table: $db.pass,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPermissionsExtTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPermissionsExtTable> {
  $$UserPermissionsExtTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get featureKey => $composableBuilder(
    column: $table.featureKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canAdd => $composableBuilder(
    column: $table.canAdd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canEdit => $composableBuilder(
    column: $table.canEdit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canDelete => $composableBuilder(
    column: $table.canDelete,
    builder: (column) => ColumnOrderings(column),
  );

  $$PassTableOrderingComposer get userId {
    final $$PassTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.pass,
      getReferencedColumn: (t) => t.passId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassTableOrderingComposer(
            $db: $db,
            $table: $db.pass,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPermissionsExtTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPermissionsExtTable> {
  $$UserPermissionsExtTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get featureKey => $composableBuilder(
    column: $table.featureKey,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get canAdd =>
      $composableBuilder(column: $table.canAdd, builder: (column) => column);

  GeneratedColumn<bool> get canEdit =>
      $composableBuilder(column: $table.canEdit, builder: (column) => column);

  GeneratedColumn<bool> get canDelete =>
      $composableBuilder(column: $table.canDelete, builder: (column) => column);

  $$PassTableAnnotationComposer get userId {
    final $$PassTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.pass,
      getReferencedColumn: (t) => t.passId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassTableAnnotationComposer(
            $db: $db,
            $table: $db.pass,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPermissionsExtTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserPermissionsExtTable,
          UserPermissionsExtData,
          $$UserPermissionsExtTableFilterComposer,
          $$UserPermissionsExtTableOrderingComposer,
          $$UserPermissionsExtTableAnnotationComposer,
          $$UserPermissionsExtTableCreateCompanionBuilder,
          $$UserPermissionsExtTableUpdateCompanionBuilder,
          (UserPermissionsExtData, $$UserPermissionsExtTableReferences),
          UserPermissionsExtData,
          PrefetchHooks Function({bool userId})
        > {
  $$UserPermissionsExtTableTableManager(
    _$AppDatabase db,
    $UserPermissionsExtTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPermissionsExtTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPermissionsExtTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserPermissionsExtTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<String> featureKey = const Value.absent(),
                Value<bool> canAdd = const Value.absent(),
                Value<bool> canEdit = const Value.absent(),
                Value<bool> canDelete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPermissionsExtCompanion(
                userId: userId,
                featureKey: featureKey,
                canAdd: canAdd,
                canEdit: canEdit,
                canDelete: canDelete,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int userId,
                required String featureKey,
                Value<bool> canAdd = const Value.absent(),
                Value<bool> canEdit = const Value.absent(),
                Value<bool> canDelete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPermissionsExtCompanion.insert(
                userId: userId,
                featureKey: featureKey,
                canAdd: canAdd,
                canEdit: canEdit,
                canDelete: canDelete,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserPermissionsExtTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable:
                                    $$UserPermissionsExtTableReferences
                                        ._userIdTable(db),
                                referencedColumn:
                                    $$UserPermissionsExtTableReferences
                                        ._userIdTable(db)
                                        .passId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserPermissionsExtTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserPermissionsExtTable,
      UserPermissionsExtData,
      $$UserPermissionsExtTableFilterComposer,
      $$UserPermissionsExtTableOrderingComposer,
      $$UserPermissionsExtTableAnnotationComposer,
      $$UserPermissionsExtTableCreateCompanionBuilder,
      $$UserPermissionsExtTableUpdateCompanionBuilder,
      (UserPermissionsExtData, $$UserPermissionsExtTableReferences),
      UserPermissionsExtData,
      PrefetchHooks Function({bool userId})
    >;
typedef $$UserVisibilityFiltersTableCreateCompanionBuilder =
    UserVisibilityFiltersCompanion Function({
      required int userId,
      required String filterType,
      required int valueId,
      Value<int> rowid,
    });
typedef $$UserVisibilityFiltersTableUpdateCompanionBuilder =
    UserVisibilityFiltersCompanion Function({
      Value<int> userId,
      Value<String> filterType,
      Value<int> valueId,
      Value<int> rowid,
    });

final class $$UserVisibilityFiltersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $UserVisibilityFiltersTable,
          UserVisibilityFilter
        > {
  $$UserVisibilityFiltersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PassTable _userIdTable(_$AppDatabase db) => db.pass.createAlias(
    $_aliasNameGenerator(db.userVisibilityFilters.userId, db.pass.passId),
  );

  $$PassTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('User_ID')!;

    final manager = $$PassTableTableManager(
      $_db,
      $_db.pass,
    ).filter((f) => f.passId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserVisibilityFiltersTableFilterComposer
    extends Composer<_$AppDatabase, $UserVisibilityFiltersTable> {
  $$UserVisibilityFiltersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get filterType => $composableBuilder(
    column: $table.filterType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valueId => $composableBuilder(
    column: $table.valueId,
    builder: (column) => ColumnFilters(column),
  );

  $$PassTableFilterComposer get userId {
    final $$PassTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.pass,
      getReferencedColumn: (t) => t.passId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassTableFilterComposer(
            $db: $db,
            $table: $db.pass,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserVisibilityFiltersTableOrderingComposer
    extends Composer<_$AppDatabase, $UserVisibilityFiltersTable> {
  $$UserVisibilityFiltersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get filterType => $composableBuilder(
    column: $table.filterType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valueId => $composableBuilder(
    column: $table.valueId,
    builder: (column) => ColumnOrderings(column),
  );

  $$PassTableOrderingComposer get userId {
    final $$PassTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.pass,
      getReferencedColumn: (t) => t.passId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassTableOrderingComposer(
            $db: $db,
            $table: $db.pass,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserVisibilityFiltersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserVisibilityFiltersTable> {
  $$UserVisibilityFiltersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get filterType => $composableBuilder(
    column: $table.filterType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get valueId =>
      $composableBuilder(column: $table.valueId, builder: (column) => column);

  $$PassTableAnnotationComposer get userId {
    final $$PassTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.pass,
      getReferencedColumn: (t) => t.passId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassTableAnnotationComposer(
            $db: $db,
            $table: $db.pass,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserVisibilityFiltersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserVisibilityFiltersTable,
          UserVisibilityFilter,
          $$UserVisibilityFiltersTableFilterComposer,
          $$UserVisibilityFiltersTableOrderingComposer,
          $$UserVisibilityFiltersTableAnnotationComposer,
          $$UserVisibilityFiltersTableCreateCompanionBuilder,
          $$UserVisibilityFiltersTableUpdateCompanionBuilder,
          (UserVisibilityFilter, $$UserVisibilityFiltersTableReferences),
          UserVisibilityFilter,
          PrefetchHooks Function({bool userId})
        > {
  $$UserVisibilityFiltersTableTableManager(
    _$AppDatabase db,
    $UserVisibilityFiltersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserVisibilityFiltersTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$UserVisibilityFiltersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserVisibilityFiltersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<String> filterType = const Value.absent(),
                Value<int> valueId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserVisibilityFiltersCompanion(
                userId: userId,
                filterType: filterType,
                valueId: valueId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int userId,
                required String filterType,
                required int valueId,
                Value<int> rowid = const Value.absent(),
              }) => UserVisibilityFiltersCompanion.insert(
                userId: userId,
                filterType: filterType,
                valueId: valueId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserVisibilityFiltersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable:
                                    $$UserVisibilityFiltersTableReferences
                                        ._userIdTable(db),
                                referencedColumn:
                                    $$UserVisibilityFiltersTableReferences
                                        ._userIdTable(db)
                                        .passId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserVisibilityFiltersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserVisibilityFiltersTable,
      UserVisibilityFilter,
      $$UserVisibilityFiltersTableFilterComposer,
      $$UserVisibilityFiltersTableOrderingComposer,
      $$UserVisibilityFiltersTableAnnotationComposer,
      $$UserVisibilityFiltersTableCreateCompanionBuilder,
      $$UserVisibilityFiltersTableUpdateCompanionBuilder,
      (UserVisibilityFilter, $$UserVisibilityFiltersTableReferences),
      UserVisibilityFilter,
      PrefetchHooks Function({bool userId})
    >;
typedef $$CustomFieldDefinitionsTableCreateCompanionBuilder =
    CustomFieldDefinitionsCompanion Function({
      Value<int> id,
      Value<String?> fieldKey,
      required String name,
      required String type,
      Value<String?> options,
      required int fieldOrder,
      Value<bool> isVisible,
      Value<bool> isFilter,
    });
typedef $$CustomFieldDefinitionsTableUpdateCompanionBuilder =
    CustomFieldDefinitionsCompanion Function({
      Value<int> id,
      Value<String?> fieldKey,
      Value<String> name,
      Value<String> type,
      Value<String?> options,
      Value<int> fieldOrder,
      Value<bool> isVisible,
      Value<bool> isFilter,
    });

final class $$CustomFieldDefinitionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomFieldDefinitionsTable,
          CustomFieldDefinition
        > {
  $$CustomFieldDefinitionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $PersonCustomFieldValuesTable,
    List<PersonCustomFieldValue>
  >
  _personCustomFieldValuesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.personCustomFieldValues,
        aliasName: $_aliasNameGenerator(
          db.customFieldDefinitions.id,
          db.personCustomFieldValues.fieldId,
        ),
      );

  $$PersonCustomFieldValuesTableProcessedTableManager
  get personCustomFieldValuesRefs {
    final manager = $$PersonCustomFieldValuesTableTableManager(
      $_db,
      $_db.personCustomFieldValues,
    ).filter((f) => f.fieldId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _personCustomFieldValuesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PersonDocumentsTable, List<PersonDocument>>
  _personDocumentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.personDocuments,
    aliasName: $_aliasNameGenerator(
      db.customFieldDefinitions.id,
      db.personDocuments.fieldId,
    ),
  );

  $$PersonDocumentsTableProcessedTableManager get personDocumentsRefs {
    final manager = $$PersonDocumentsTableTableManager(
      $_db,
      $_db.personDocuments,
    ).filter((f) => f.fieldId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _personDocumentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomFieldDefinitionsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomFieldDefinitionsTable> {
  $$CustomFieldDefinitionsTableFilterComposer({
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

  ColumnFilters<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fieldOrder => $composableBuilder(
    column: $table.fieldOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFilter => $composableBuilder(
    column: $table.isFilter,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> personCustomFieldValuesRefs(
    Expression<bool> Function($$PersonCustomFieldValuesTableFilterComposer f) f,
  ) {
    final $$PersonCustomFieldValuesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.personCustomFieldValues,
          getReferencedColumn: (t) => t.fieldId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonCustomFieldValuesTableFilterComposer(
                $db: $db,
                $table: $db.personCustomFieldValues,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> personDocumentsRefs(
    Expression<bool> Function($$PersonDocumentsTableFilterComposer f) f,
  ) {
    final $$PersonDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personDocuments,
      getReferencedColumn: (t) => t.fieldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.personDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomFieldDefinitionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomFieldDefinitionsTable> {
  $$CustomFieldDefinitionsTableOrderingComposer({
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

  ColumnOrderings<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fieldOrder => $composableBuilder(
    column: $table.fieldOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVisible => $composableBuilder(
    column: $table.isVisible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFilter => $composableBuilder(
    column: $table.isFilter,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomFieldDefinitionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomFieldDefinitionsTable> {
  $$CustomFieldDefinitionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fieldKey =>
      $composableBuilder(column: $table.fieldKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);

  GeneratedColumn<int> get fieldOrder => $composableBuilder(
    column: $table.fieldOrder,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isVisible =>
      $composableBuilder(column: $table.isVisible, builder: (column) => column);

  GeneratedColumn<bool> get isFilter =>
      $composableBuilder(column: $table.isFilter, builder: (column) => column);

  Expression<T> personCustomFieldValuesRefs<T extends Object>(
    Expression<T> Function($$PersonCustomFieldValuesTableAnnotationComposer a)
    f,
  ) {
    final $$PersonCustomFieldValuesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.personCustomFieldValues,
          getReferencedColumn: (t) => t.fieldId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PersonCustomFieldValuesTableAnnotationComposer(
                $db: $db,
                $table: $db.personCustomFieldValues,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> personDocumentsRefs<T extends Object>(
    Expression<T> Function($$PersonDocumentsTableAnnotationComposer a) f,
  ) {
    final $$PersonDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personDocuments,
      getReferencedColumn: (t) => t.fieldId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.personDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomFieldDefinitionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomFieldDefinitionsTable,
          CustomFieldDefinition,
          $$CustomFieldDefinitionsTableFilterComposer,
          $$CustomFieldDefinitionsTableOrderingComposer,
          $$CustomFieldDefinitionsTableAnnotationComposer,
          $$CustomFieldDefinitionsTableCreateCompanionBuilder,
          $$CustomFieldDefinitionsTableUpdateCompanionBuilder,
          (CustomFieldDefinition, $$CustomFieldDefinitionsTableReferences),
          CustomFieldDefinition,
          PrefetchHooks Function({
            bool personCustomFieldValuesRefs,
            bool personDocumentsRefs,
          })
        > {
  $$CustomFieldDefinitionsTableTableManager(
    _$AppDatabase db,
    $CustomFieldDefinitionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomFieldDefinitionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CustomFieldDefinitionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CustomFieldDefinitionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> fieldKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> options = const Value.absent(),
                Value<int> fieldOrder = const Value.absent(),
                Value<bool> isVisible = const Value.absent(),
                Value<bool> isFilter = const Value.absent(),
              }) => CustomFieldDefinitionsCompanion(
                id: id,
                fieldKey: fieldKey,
                name: name,
                type: type,
                options: options,
                fieldOrder: fieldOrder,
                isVisible: isVisible,
                isFilter: isFilter,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> fieldKey = const Value.absent(),
                required String name,
                required String type,
                Value<String?> options = const Value.absent(),
                required int fieldOrder,
                Value<bool> isVisible = const Value.absent(),
                Value<bool> isFilter = const Value.absent(),
              }) => CustomFieldDefinitionsCompanion.insert(
                id: id,
                fieldKey: fieldKey,
                name: name,
                type: type,
                options: options,
                fieldOrder: fieldOrder,
                isVisible: isVisible,
                isFilter: isFilter,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomFieldDefinitionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                personCustomFieldValuesRefs = false,
                personDocumentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (personCustomFieldValuesRefs) db.personCustomFieldValues,
                    if (personDocumentsRefs) db.personDocuments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (personCustomFieldValuesRefs)
                        await $_getPrefetchedData<
                          CustomFieldDefinition,
                          $CustomFieldDefinitionsTable,
                          PersonCustomFieldValue
                        >(
                          currentTable: table,
                          referencedTable:
                              $$CustomFieldDefinitionsTableReferences
                                  ._personCustomFieldValuesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomFieldDefinitionsTableReferences(
                                db,
                                table,
                                p0,
                              ).personCustomFieldValuesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fieldId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (personDocumentsRefs)
                        await $_getPrefetchedData<
                          CustomFieldDefinition,
                          $CustomFieldDefinitionsTable,
                          PersonDocument
                        >(
                          currentTable: table,
                          referencedTable:
                              $$CustomFieldDefinitionsTableReferences
                                  ._personDocumentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CustomFieldDefinitionsTableReferences(
                                db,
                                table,
                                p0,
                              ).personDocumentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fieldId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CustomFieldDefinitionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomFieldDefinitionsTable,
      CustomFieldDefinition,
      $$CustomFieldDefinitionsTableFilterComposer,
      $$CustomFieldDefinitionsTableOrderingComposer,
      $$CustomFieldDefinitionsTableAnnotationComposer,
      $$CustomFieldDefinitionsTableCreateCompanionBuilder,
      $$CustomFieldDefinitionsTableUpdateCompanionBuilder,
      (CustomFieldDefinition, $$CustomFieldDefinitionsTableReferences),
      CustomFieldDefinition,
      PrefetchHooks Function({
        bool personCustomFieldValuesRefs,
        bool personDocumentsRefs,
      })
    >;
typedef $$PersonCustomFieldValuesTableCreateCompanionBuilder =
    PersonCustomFieldValuesCompanion Function({
      required int personId,
      required int fieldId,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$PersonCustomFieldValuesTableUpdateCompanionBuilder =
    PersonCustomFieldValuesCompanion Function({
      Value<int> personId,
      Value<int> fieldId,
      Value<String?> value,
      Value<int> rowid,
    });

final class $$PersonCustomFieldValuesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PersonCustomFieldValuesTable,
          PersonCustomFieldValue
        > {
  $$PersonCustomFieldValuesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PersonsTable _personIdTable(_$AppDatabase db) =>
      db.persons.createAlias(
        $_aliasNameGenerator(
          db.personCustomFieldValues.personId,
          db.persons.personId,
        ),
      );

  $$PersonsTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('Person_ID')!;

    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.personId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CustomFieldDefinitionsTable _fieldIdTable(_$AppDatabase db) =>
      db.customFieldDefinitions.createAlias(
        $_aliasNameGenerator(
          db.personCustomFieldValues.fieldId,
          db.customFieldDefinitions.id,
        ),
      );

  $$CustomFieldDefinitionsTableProcessedTableManager get fieldId {
    final $_column = $_itemColumn<int>('Field_ID')!;

    final manager = $$CustomFieldDefinitionsTableTableManager(
      $_db,
      $_db.customFieldDefinitions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fieldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PersonCustomFieldValuesTableFilterComposer
    extends Composer<_$AppDatabase, $PersonCustomFieldValuesTable> {
  $$PersonCustomFieldValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomFieldDefinitionsTableFilterComposer get fieldId {
    final $$CustomFieldDefinitionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.fieldId,
          referencedTable: $db.customFieldDefinitions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomFieldDefinitionsTableFilterComposer(
                $db: $db,
                $table: $db.customFieldDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PersonCustomFieldValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonCustomFieldValuesTable> {
  $$PersonCustomFieldValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomFieldDefinitionsTableOrderingComposer get fieldId {
    final $$CustomFieldDefinitionsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.fieldId,
          referencedTable: $db.customFieldDefinitions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomFieldDefinitionsTableOrderingComposer(
                $db: $db,
                $table: $db.customFieldDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PersonCustomFieldValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonCustomFieldValuesTable> {
  $$PersonCustomFieldValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomFieldDefinitionsTableAnnotationComposer get fieldId {
    final $$CustomFieldDefinitionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.fieldId,
          referencedTable: $db.customFieldDefinitions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomFieldDefinitionsTableAnnotationComposer(
                $db: $db,
                $table: $db.customFieldDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PersonCustomFieldValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonCustomFieldValuesTable,
          PersonCustomFieldValue,
          $$PersonCustomFieldValuesTableFilterComposer,
          $$PersonCustomFieldValuesTableOrderingComposer,
          $$PersonCustomFieldValuesTableAnnotationComposer,
          $$PersonCustomFieldValuesTableCreateCompanionBuilder,
          $$PersonCustomFieldValuesTableUpdateCompanionBuilder,
          (PersonCustomFieldValue, $$PersonCustomFieldValuesTableReferences),
          PersonCustomFieldValue,
          PrefetchHooks Function({bool personId, bool fieldId})
        > {
  $$PersonCustomFieldValuesTableTableManager(
    _$AppDatabase db,
    $PersonCustomFieldValuesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonCustomFieldValuesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PersonCustomFieldValuesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PersonCustomFieldValuesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> personId = const Value.absent(),
                Value<int> fieldId = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonCustomFieldValuesCompanion(
                personId: personId,
                fieldId: fieldId,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int personId,
                required int fieldId,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonCustomFieldValuesCompanion.insert(
                personId: personId,
                fieldId: fieldId,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonCustomFieldValuesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false, fieldId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable:
                                    $$PersonCustomFieldValuesTableReferences
                                        ._personIdTable(db),
                                referencedColumn:
                                    $$PersonCustomFieldValuesTableReferences
                                        ._personIdTable(db)
                                        .personId,
                              )
                              as T;
                    }
                    if (fieldId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.fieldId,
                                referencedTable:
                                    $$PersonCustomFieldValuesTableReferences
                                        ._fieldIdTable(db),
                                referencedColumn:
                                    $$PersonCustomFieldValuesTableReferences
                                        ._fieldIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PersonCustomFieldValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonCustomFieldValuesTable,
      PersonCustomFieldValue,
      $$PersonCustomFieldValuesTableFilterComposer,
      $$PersonCustomFieldValuesTableOrderingComposer,
      $$PersonCustomFieldValuesTableAnnotationComposer,
      $$PersonCustomFieldValuesTableCreateCompanionBuilder,
      $$PersonCustomFieldValuesTableUpdateCompanionBuilder,
      (PersonCustomFieldValue, $$PersonCustomFieldValuesTableReferences),
      PersonCustomFieldValue,
      PrefetchHooks Function({bool personId, bool fieldId})
    >;
typedef $$PersonDocumentsTableCreateCompanionBuilder =
    PersonDocumentsCompanion Function({
      Value<int> id,
      required int personId,
      required int fieldId,
      required String fileName,
      required Uint8List fileContent,
      Value<DateTime> createdAt,
    });
typedef $$PersonDocumentsTableUpdateCompanionBuilder =
    PersonDocumentsCompanion Function({
      Value<int> id,
      Value<int> personId,
      Value<int> fieldId,
      Value<String> fileName,
      Value<Uint8List> fileContent,
      Value<DateTime> createdAt,
    });

final class $$PersonDocumentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PersonDocumentsTable, PersonDocument> {
  $$PersonDocumentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PersonsTable _personIdTable(_$AppDatabase db) =>
      db.persons.createAlias(
        $_aliasNameGenerator(db.personDocuments.personId, db.persons.personId),
      );

  $$PersonsTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('Person_ID')!;

    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.personId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CustomFieldDefinitionsTable _fieldIdTable(_$AppDatabase db) =>
      db.customFieldDefinitions.createAlias(
        $_aliasNameGenerator(
          db.personDocuments.fieldId,
          db.customFieldDefinitions.id,
        ),
      );

  $$CustomFieldDefinitionsTableProcessedTableManager get fieldId {
    final $_column = $_itemColumn<int>('Field_ID')!;

    final manager = $$CustomFieldDefinitionsTableTableManager(
      $_db,
      $_db.customFieldDefinitions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fieldIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PersonDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonDocumentsTable> {
  $$PersonDocumentsTableFilterComposer({
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

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get fileContent => $composableBuilder(
    column: $table.fileContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomFieldDefinitionsTableFilterComposer get fieldId {
    final $$CustomFieldDefinitionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.fieldId,
          referencedTable: $db.customFieldDefinitions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomFieldDefinitionsTableFilterComposer(
                $db: $db,
                $table: $db.customFieldDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PersonDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonDocumentsTable> {
  $$PersonDocumentsTableOrderingComposer({
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

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get fileContent => $composableBuilder(
    column: $table.fileContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomFieldDefinitionsTableOrderingComposer get fieldId {
    final $$CustomFieldDefinitionsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.fieldId,
          referencedTable: $db.customFieldDefinitions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomFieldDefinitionsTableOrderingComposer(
                $db: $db,
                $table: $db.customFieldDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PersonDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonDocumentsTable> {
  $$PersonDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<Uint8List> get fileContent => $composableBuilder(
    column: $table.fileContent,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CustomFieldDefinitionsTableAnnotationComposer get fieldId {
    final $$CustomFieldDefinitionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.fieldId,
          referencedTable: $db.customFieldDefinitions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CustomFieldDefinitionsTableAnnotationComposer(
                $db: $db,
                $table: $db.customFieldDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PersonDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonDocumentsTable,
          PersonDocument,
          $$PersonDocumentsTableFilterComposer,
          $$PersonDocumentsTableOrderingComposer,
          $$PersonDocumentsTableAnnotationComposer,
          $$PersonDocumentsTableCreateCompanionBuilder,
          $$PersonDocumentsTableUpdateCompanionBuilder,
          (PersonDocument, $$PersonDocumentsTableReferences),
          PersonDocument,
          PrefetchHooks Function({bool personId, bool fieldId})
        > {
  $$PersonDocumentsTableTableManager(
    _$AppDatabase db,
    $PersonDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> personId = const Value.absent(),
                Value<int> fieldId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<Uint8List> fileContent = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PersonDocumentsCompanion(
                id: id,
                personId: personId,
                fieldId: fieldId,
                fileName: fileName,
                fileContent: fileContent,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int personId,
                required int fieldId,
                required String fileName,
                required Uint8List fileContent,
                Value<DateTime> createdAt = const Value.absent(),
              }) => PersonDocumentsCompanion.insert(
                id: id,
                personId: personId,
                fieldId: fieldId,
                fileName: fileName,
                fileContent: fileContent,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonDocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false, fieldId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable:
                                    $$PersonDocumentsTableReferences
                                        ._personIdTable(db),
                                referencedColumn:
                                    $$PersonDocumentsTableReferences
                                        ._personIdTable(db)
                                        .personId,
                              )
                              as T;
                    }
                    if (fieldId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.fieldId,
                                referencedTable:
                                    $$PersonDocumentsTableReferences
                                        ._fieldIdTable(db),
                                referencedColumn:
                                    $$PersonDocumentsTableReferences
                                        ._fieldIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PersonDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonDocumentsTable,
      PersonDocument,
      $$PersonDocumentsTableFilterComposer,
      $$PersonDocumentsTableOrderingComposer,
      $$PersonDocumentsTableAnnotationComposer,
      $$PersonDocumentsTableCreateCompanionBuilder,
      $$PersonDocumentsTableUpdateCompanionBuilder,
      (PersonDocument, $$PersonDocumentsTableReferences),
      PersonDocument,
      PrefetchHooks Function({bool personId, bool fieldId})
    >;
typedef $$FamilyRelationshipsTableCreateCompanionBuilder =
    FamilyRelationshipsCompanion Function({
      Value<int> id,
      required int personId,
      required int relatedPersonId,
      required String category,
      required String relationshipCode,
      Value<String?> customLabel,
      Value<DateTime> createdAt,
    });
typedef $$FamilyRelationshipsTableUpdateCompanionBuilder =
    FamilyRelationshipsCompanion Function({
      Value<int> id,
      Value<int> personId,
      Value<int> relatedPersonId,
      Value<String> category,
      Value<String> relationshipCode,
      Value<String?> customLabel,
      Value<DateTime> createdAt,
    });

final class $$FamilyRelationshipsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FamilyRelationshipsTable,
          FamilyRelationship
        > {
  $$FamilyRelationshipsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PersonsTable _personIdTable(_$AppDatabase db) =>
      db.persons.createAlias(
        $_aliasNameGenerator(
          db.familyRelationships.personId,
          db.persons.personId,
        ),
      );

  $$PersonsTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('Person_ID')!;

    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.personId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PersonsTable _relatedPersonIdTable(_$AppDatabase db) =>
      db.persons.createAlias(
        $_aliasNameGenerator(
          db.familyRelationships.relatedPersonId,
          db.persons.personId,
        ),
      );

  $$PersonsTableProcessedTableManager get relatedPersonId {
    final $_column = $_itemColumn<int>('Related_Person_ID')!;

    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.personId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_relatedPersonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FamilyRelationshipsTableFilterComposer
    extends Composer<_$AppDatabase, $FamilyRelationshipsTable> {
  $$FamilyRelationshipsTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationshipCode => $composableBuilder(
    column: $table.relationshipCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customLabel => $composableBuilder(
    column: $table.customLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableFilterComposer get relatedPersonId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relatedPersonId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FamilyRelationshipsTableOrderingComposer
    extends Composer<_$AppDatabase, $FamilyRelationshipsTable> {
  $$FamilyRelationshipsTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationshipCode => $composableBuilder(
    column: $table.relationshipCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customLabel => $composableBuilder(
    column: $table.customLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableOrderingComposer get relatedPersonId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relatedPersonId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FamilyRelationshipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FamilyRelationshipsTable> {
  $$FamilyRelationshipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get relationshipCode => $composableBuilder(
    column: $table.relationshipCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customLabel => $composableBuilder(
    column: $table.customLabel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableAnnotationComposer get relatedPersonId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.relatedPersonId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FamilyRelationshipsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FamilyRelationshipsTable,
          FamilyRelationship,
          $$FamilyRelationshipsTableFilterComposer,
          $$FamilyRelationshipsTableOrderingComposer,
          $$FamilyRelationshipsTableAnnotationComposer,
          $$FamilyRelationshipsTableCreateCompanionBuilder,
          $$FamilyRelationshipsTableUpdateCompanionBuilder,
          (FamilyRelationship, $$FamilyRelationshipsTableReferences),
          FamilyRelationship,
          PrefetchHooks Function({bool personId, bool relatedPersonId})
        > {
  $$FamilyRelationshipsTableTableManager(
    _$AppDatabase db,
    $FamilyRelationshipsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyRelationshipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyRelationshipsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FamilyRelationshipsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> personId = const Value.absent(),
                Value<int> relatedPersonId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> relationshipCode = const Value.absent(),
                Value<String?> customLabel = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FamilyRelationshipsCompanion(
                id: id,
                personId: personId,
                relatedPersonId: relatedPersonId,
                category: category,
                relationshipCode: relationshipCode,
                customLabel: customLabel,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int personId,
                required int relatedPersonId,
                required String category,
                required String relationshipCode,
                Value<String?> customLabel = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FamilyRelationshipsCompanion.insert(
                id: id,
                personId: personId,
                relatedPersonId: relatedPersonId,
                category: category,
                relationshipCode: relationshipCode,
                customLabel: customLabel,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FamilyRelationshipsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false, relatedPersonId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable:
                                    $$FamilyRelationshipsTableReferences
                                        ._personIdTable(db),
                                referencedColumn:
                                    $$FamilyRelationshipsTableReferences
                                        ._personIdTable(db)
                                        .personId,
                              )
                              as T;
                    }
                    if (relatedPersonId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.relatedPersonId,
                                referencedTable:
                                    $$FamilyRelationshipsTableReferences
                                        ._relatedPersonIdTable(db),
                                referencedColumn:
                                    $$FamilyRelationshipsTableReferences
                                        ._relatedPersonIdTable(db)
                                        .personId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FamilyRelationshipsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FamilyRelationshipsTable,
      FamilyRelationship,
      $$FamilyRelationshipsTableFilterComposer,
      $$FamilyRelationshipsTableOrderingComposer,
      $$FamilyRelationshipsTableAnnotationComposer,
      $$FamilyRelationshipsTableCreateCompanionBuilder,
      $$FamilyRelationshipsTableUpdateCompanionBuilder,
      (FamilyRelationship, $$FamilyRelationshipsTableReferences),
      FamilyRelationship,
      PrefetchHooks Function({bool personId, bool relatedPersonId})
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
  $$ServicesTableTableManager get services =>
      $$ServicesTableTableManager(_db, _db.services);
  $$StagesTableTableManager get stages =>
      $$StagesTableTableManager(_db, _db.stages);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$TayoCardsTableTableManager get tayoCards =>
      $$TayoCardsTableTableManager(_db, _db.tayoCards);
  $$PersonTayoPointsTableTableManager get personTayoPoints =>
      $$PersonTayoPointsTableTableManager(_db, _db.personTayoPoints);
  $$KhorosesTableTableManager get khoroses =>
      $$KhorosesTableTableManager(_db, _db.khoroses);
  $$KhorosServicesTableTableManager get khorosServices =>
      $$KhorosServicesTableTableManager(_db, _db.khorosServices);
  $$StageServicesTableTableManager get stageServices =>
      $$StageServicesTableTableManager(_db, _db.stageServices);
  $$PersonServicesTableTableManager get personServices =>
      $$PersonServicesTableTableManager(_db, _db.personServices);
  $$UserPermissionsExtTableTableManager get userPermissionsExt =>
      $$UserPermissionsExtTableTableManager(_db, _db.userPermissionsExt);
  $$UserVisibilityFiltersTableTableManager get userVisibilityFilters =>
      $$UserVisibilityFiltersTableTableManager(_db, _db.userVisibilityFilters);
  $$CustomFieldDefinitionsTableTableManager get customFieldDefinitions =>
      $$CustomFieldDefinitionsTableTableManager(
        _db,
        _db.customFieldDefinitions,
      );
  $$PersonCustomFieldValuesTableTableManager get personCustomFieldValues =>
      $$PersonCustomFieldValuesTableTableManager(
        _db,
        _db.personCustomFieldValues,
      );
  $$PersonDocumentsTableTableManager get personDocuments =>
      $$PersonDocumentsTableTableManager(_db, _db.personDocuments);
  $$FamilyRelationshipsTableTableManager get familyRelationships =>
      $$FamilyRelationshipsTableTableManager(_db, _db.familyRelationships);
}
