// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AttendanceRepository)
final attendanceRepositoryProvider = AttendanceRepositoryProvider._();

final class AttendanceRepositoryProvider
    extends $AsyncNotifierProvider<AttendanceRepository, List<AttendanceDTO>> {
  AttendanceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attendanceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attendanceRepositoryHash();

  @$internal
  @override
  AttendanceRepository create() => AttendanceRepository();
}

String _$attendanceRepositoryHash() =>
    r'520e9a53af700dd97a869bc6181e769ef9bd7171';

abstract class _$AttendanceRepository
    extends $AsyncNotifier<List<AttendanceDTO>> {
  FutureOr<List<AttendanceDTO>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<AttendanceDTO>>, List<AttendanceDTO>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AttendanceDTO>>, List<AttendanceDTO>>,
              AsyncValue<List<AttendanceDTO>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
