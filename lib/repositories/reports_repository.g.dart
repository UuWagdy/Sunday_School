// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(personsReport)
final personsReportProvider = PersonsReportFamily._();

final class PersonsReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PersonReportDTO>>,
          List<PersonReportDTO>,
          FutureOr<List<PersonReportDTO>>
        >
    with
        $FutureModifier<List<PersonReportDTO>>,
        $FutureProvider<List<PersonReportDTO>> {
  PersonsReportProvider._({
    required PersonsReportFamily super.from,
    required ({int? stageId, int? areaId}) super.argument,
  }) : super(
         retry: null,
         name: r'personsReportProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$personsReportHash();

  @override
  String toString() {
    return r'personsReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PersonReportDTO>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PersonReportDTO>> create(Ref ref) {
    final argument = this.argument as ({int? stageId, int? areaId});
    return personsReport(
      ref,
      stageId: argument.stageId,
      areaId: argument.areaId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PersonsReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$personsReportHash() => r'399679fdc80398f522d5427d308e7fd926dc2f95';

final class PersonsReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PersonReportDTO>>,
          ({int? stageId, int? areaId})
        > {
  PersonsReportFamily._()
    : super(
        retry: null,
        name: r'personsReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  PersonsReportProvider call({int? stageId, int? areaId}) =>
      PersonsReportProvider._(
        argument: (stageId: stageId, areaId: areaId),
        from: this,
      );

  @override
  String toString() => r'personsReportProvider';
}

@ProviderFor(attendanceReport)
final attendanceReportProvider = AttendanceReportFamily._();

final class AttendanceReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AttendanceReportDTO>>,
          List<AttendanceReportDTO>,
          FutureOr<List<AttendanceReportDTO>>
        >
    with
        $FutureModifier<List<AttendanceReportDTO>>,
        $FutureProvider<List<AttendanceReportDTO>> {
  AttendanceReportProvider._({
    required AttendanceReportFamily super.from,
    required ({int? month, int? year, String? status}) super.argument,
  }) : super(
         retry: null,
         name: r'attendanceReportProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attendanceReportHash();

  @override
  String toString() {
    return r'attendanceReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<AttendanceReportDTO>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AttendanceReportDTO>> create(Ref ref) {
    final argument = this.argument as ({int? month, int? year, String? status});
    return attendanceReport(
      ref,
      month: argument.month,
      year: argument.year,
      status: argument.status,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AttendanceReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attendanceReportHash() => r'b0fc508fb8426bbd93952ef01f2385b8c73d0174';

final class AttendanceReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<AttendanceReportDTO>>,
          ({int? month, int? year, String? status})
        > {
  AttendanceReportFamily._()
    : super(
        retry: null,
        name: r'attendanceReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  AttendanceReportProvider call({int? month, int? year, String? status}) =>
      AttendanceReportProvider._(
        argument: (month: month, year: year, status: status),
        from: this,
      );

  @override
  String toString() => r'attendanceReportProvider';
}

@ProviderFor(stageStatistics)
final stageStatisticsProvider = StageStatisticsProvider._();

final class StageStatisticsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StageStatDTO>>,
          List<StageStatDTO>,
          FutureOr<List<StageStatDTO>>
        >
    with
        $FutureModifier<List<StageStatDTO>>,
        $FutureProvider<List<StageStatDTO>> {
  StageStatisticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stageStatisticsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stageStatisticsHash();

  @$internal
  @override
  $FutureProviderElement<List<StageStatDTO>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StageStatDTO>> create(Ref ref) {
    return stageStatistics(ref);
  }
}

String _$stageStatisticsHash() => r'1ee58d50b6fda0b1608630ab08990cd227efffda';
