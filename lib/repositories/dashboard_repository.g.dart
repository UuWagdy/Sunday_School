// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(generalAttendanceTrend)
final generalAttendanceTrendProvider = GeneralAttendanceTrendFamily._();

final class GeneralAttendanceTrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AttendanceTrendData>>,
          List<AttendanceTrendData>,
          FutureOr<List<AttendanceTrendData>>
        >
    with
        $FutureModifier<List<AttendanceTrendData>>,
        $FutureProvider<List<AttendanceTrendData>> {
  GeneralAttendanceTrendProvider._({
    required GeneralAttendanceTrendFamily super.from,
    required ({
      String groupBy,
      int? filterYear,
      int? filterMonth,
      int? serviceId,
      String? status,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'generalAttendanceTrendProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$generalAttendanceTrendHash();

  @override
  String toString() {
    return r'generalAttendanceTrendProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<AttendanceTrendData>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AttendanceTrendData>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String groupBy,
              int? filterYear,
              int? filterMonth,
              int? serviceId,
              String? status,
            });
    return generalAttendanceTrend(
      ref,
      groupBy: argument.groupBy,
      filterYear: argument.filterYear,
      filterMonth: argument.filterMonth,
      serviceId: argument.serviceId,
      status: argument.status,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GeneralAttendanceTrendProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$generalAttendanceTrendHash() =>
    r'b35f0ee2f5a710ef90de7beb38f62acf8eeff63a';

final class GeneralAttendanceTrendFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<AttendanceTrendData>>,
          ({
            String groupBy,
            int? filterYear,
            int? filterMonth,
            int? serviceId,
            String? status,
          })
        > {
  GeneralAttendanceTrendFamily._()
    : super(
        retry: null,
        name: r'generalAttendanceTrendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  GeneralAttendanceTrendProvider call({
    required String groupBy,
    int? filterYear,
    int? filterMonth,
    int? serviceId,
    String? status,
  }) => GeneralAttendanceTrendProvider._(
    argument: (
      groupBy: groupBy,
      filterYear: filterYear,
      filterMonth: filterMonth,
      serviceId: serviceId,
      status: status,
    ),
    from: this,
  );

  @override
  String toString() => r'generalAttendanceTrendProvider';
}

@ProviderFor(individualAttendanceTrend)
final individualAttendanceTrendProvider = IndividualAttendanceTrendFamily._();

final class IndividualAttendanceTrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AttendanceTrendData>>,
          List<AttendanceTrendData>,
          FutureOr<List<AttendanceTrendData>>
        >
    with
        $FutureModifier<List<AttendanceTrendData>>,
        $FutureProvider<List<AttendanceTrendData>> {
  IndividualAttendanceTrendProvider._({
    required IndividualAttendanceTrendFamily super.from,
    required ({
      int personId,
      String groupBy,
      int? filterYear,
      int? filterMonth,
      int? serviceId,
      String? status,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'individualAttendanceTrendProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$individualAttendanceTrendHash();

  @override
  String toString() {
    return r'individualAttendanceTrendProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<AttendanceTrendData>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AttendanceTrendData>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              int personId,
              String groupBy,
              int? filterYear,
              int? filterMonth,
              int? serviceId,
              String? status,
            });
    return individualAttendanceTrend(
      ref,
      personId: argument.personId,
      groupBy: argument.groupBy,
      filterYear: argument.filterYear,
      filterMonth: argument.filterMonth,
      serviceId: argument.serviceId,
      status: argument.status,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IndividualAttendanceTrendProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$individualAttendanceTrendHash() =>
    r'be4c8d65a1d6f3d3550cc963c7e77046108ad3b4';

final class IndividualAttendanceTrendFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<AttendanceTrendData>>,
          ({
            int personId,
            String groupBy,
            int? filterYear,
            int? filterMonth,
            int? serviceId,
            String? status,
          })
        > {
  IndividualAttendanceTrendFamily._()
    : super(
        retry: null,
        name: r'individualAttendanceTrendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  IndividualAttendanceTrendProvider call({
    required int personId,
    required String groupBy,
    int? filterYear,
    int? filterMonth,
    int? serviceId,
    String? status,
  }) => IndividualAttendanceTrendProvider._(
    argument: (
      personId: personId,
      groupBy: groupBy,
      filterYear: filterYear,
      filterMonth: filterMonth,
      serviceId: serviceId,
      status: status,
    ),
    from: this,
  );

  @override
  String toString() => r'individualAttendanceTrendProvider';
}

@ProviderFor(demographicAreas)
final demographicAreasProvider = DemographicAreasProvider._();

final class DemographicAreasProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DemographicStatData>>,
          List<DemographicStatData>,
          FutureOr<List<DemographicStatData>>
        >
    with
        $FutureModifier<List<DemographicStatData>>,
        $FutureProvider<List<DemographicStatData>> {
  DemographicAreasProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demographicAreasProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demographicAreasHash();

  @$internal
  @override
  $FutureProviderElement<List<DemographicStatData>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DemographicStatData>> create(Ref ref) {
    return demographicAreas(ref);
  }
}

String _$demographicAreasHash() => r'55fa9a848f59c2344e314a855cfe637514f754a1';

@ProviderFor(demographicStages)
final demographicStagesProvider = DemographicStagesProvider._();

final class DemographicStagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DemographicStatData>>,
          List<DemographicStatData>,
          FutureOr<List<DemographicStatData>>
        >
    with
        $FutureModifier<List<DemographicStatData>>,
        $FutureProvider<List<DemographicStatData>> {
  DemographicStagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demographicStagesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demographicStagesHash();

  @$internal
  @override
  $FutureProviderElement<List<DemographicStatData>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DemographicStatData>> create(Ref ref) {
    return demographicStages(ref);
  }
}

String _$demographicStagesHash() => r'6073d4cd9f938b138123c4c29b1230562478e857';

@ProviderFor(demographicFathers)
final demographicFathersProvider = DemographicFathersProvider._();

final class DemographicFathersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DemographicStatData>>,
          List<DemographicStatData>,
          FutureOr<List<DemographicStatData>>
        >
    with
        $FutureModifier<List<DemographicStatData>>,
        $FutureProvider<List<DemographicStatData>> {
  DemographicFathersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demographicFathersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demographicFathersHash();

  @$internal
  @override
  $FutureProviderElement<List<DemographicStatData>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DemographicStatData>> create(Ref ref) {
    return demographicFathers(ref);
  }
}

String _$demographicFathersHash() =>
    r'35b2ea31b30247d2703788cb6b94be8c9727e8af';

@ProviderFor(demographicGender)
final demographicGenderProvider = DemographicGenderProvider._();

final class DemographicGenderProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DemographicStatData>>,
          List<DemographicStatData>,
          FutureOr<List<DemographicStatData>>
        >
    with
        $FutureModifier<List<DemographicStatData>>,
        $FutureProvider<List<DemographicStatData>> {
  DemographicGenderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demographicGenderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demographicGenderHash();

  @$internal
  @override
  $FutureProviderElement<List<DemographicStatData>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DemographicStatData>> create(Ref ref) {
    return demographicGender(ref);
  }
}

String _$demographicGenderHash() => r'886496fb4739eeeaffff08fee82a6a2af98e5eeb';

@ProviderFor(demographicFirstNames)
final demographicFirstNamesProvider = DemographicFirstNamesProvider._();

final class DemographicFirstNamesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DemographicStatData>>,
          List<DemographicStatData>,
          FutureOr<List<DemographicStatData>>
        >
    with
        $FutureModifier<List<DemographicStatData>>,
        $FutureProvider<List<DemographicStatData>> {
  DemographicFirstNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demographicFirstNamesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demographicFirstNamesHash();

  @$internal
  @override
  $FutureProviderElement<List<DemographicStatData>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DemographicStatData>> create(Ref ref) {
    return demographicFirstNames(ref);
  }
}

String _$demographicFirstNamesHash() =>
    r'8c37f21ee68815e727294240e469eb80991555a7';

@ProviderFor(attendanceRankings)
final attendanceRankingsProvider = AttendanceRankingsFamily._();

final class AttendanceRankingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DemographicStatData>>,
          List<DemographicStatData>,
          FutureOr<List<DemographicStatData>>
        >
    with
        $FutureModifier<List<DemographicStatData>>,
        $FutureProvider<List<DemographicStatData>> {
  AttendanceRankingsProvider._({
    required AttendanceRankingsFamily super.from,
    required ({
      int? stageId,
      int? areaId,
      int? fatherId,
      DateTime? dateFrom,
      DateTime? dateTo,
      int? serviceId,
      String sortCriteria,
      int? limit,
      int? offset,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'attendanceRankingsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attendanceRankingsHash();

  @override
  String toString() {
    return r'attendanceRankingsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<DemographicStatData>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DemographicStatData>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              int? stageId,
              int? areaId,
              int? fatherId,
              DateTime? dateFrom,
              DateTime? dateTo,
              int? serviceId,
              String sortCriteria,
              int? limit,
              int? offset,
            });
    return attendanceRankings(
      ref,
      stageId: argument.stageId,
      areaId: argument.areaId,
      fatherId: argument.fatherId,
      dateFrom: argument.dateFrom,
      dateTo: argument.dateTo,
      serviceId: argument.serviceId,
      sortCriteria: argument.sortCriteria,
      limit: argument.limit,
      offset: argument.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AttendanceRankingsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attendanceRankingsHash() =>
    r'a67c76da9d180527b21e71a5ca6b181328d55a73';

final class AttendanceRankingsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<DemographicStatData>>,
          ({
            int? stageId,
            int? areaId,
            int? fatherId,
            DateTime? dateFrom,
            DateTime? dateTo,
            int? serviceId,
            String sortCriteria,
            int? limit,
            int? offset,
          })
        > {
  AttendanceRankingsFamily._()
    : super(
        retry: null,
        name: r'attendanceRankingsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  AttendanceRankingsProvider call({
    int? stageId,
    int? areaId,
    int? fatherId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? serviceId,
    required String sortCriteria,
    int? limit,
    int? offset,
  }) => AttendanceRankingsProvider._(
    argument: (
      stageId: stageId,
      areaId: areaId,
      fatherId: fatherId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      serviceId: serviceId,
      sortCriteria: sortCriteria,
      limit: limit,
      offset: offset,
    ),
    from: this,
  );

  @override
  String toString() => r'attendanceRankingsProvider';
}
