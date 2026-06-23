// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_comparison_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PeriodComparisonRepository)
final periodComparisonRepositoryProvider =
    PeriodComparisonRepositoryProvider._();

final class PeriodComparisonRepositoryProvider
    extends $AsyncNotifierProvider<PeriodComparisonRepository, void> {
  PeriodComparisonRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'periodComparisonRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$periodComparisonRepositoryHash();

  @$internal
  @override
  PeriodComparisonRepository create() => PeriodComparisonRepository();
}

String _$periodComparisonRepositoryHash() =>
    r'81013a06d894b0e76e736d48d0bb13bad7903373';

abstract class _$PeriodComparisonRepository extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
