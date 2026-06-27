// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'areas_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AreasRepository)
final areasRepositoryProvider = AreasRepositoryProvider._();

final class AreasRepositoryProvider
    extends $AsyncNotifierProvider<AreasRepository, List<Area>> {
  AreasRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'areasRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$areasRepositoryHash();

  @$internal
  @override
  AreasRepository create() => AreasRepository();
}

String _$areasRepositoryHash() => r'ffd5c1d01b8f1ef96a569ce721ca4bd09b177867';

abstract class _$AreasRepository extends $AsyncNotifier<List<Area>> {
  FutureOr<List<Area>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Area>>, List<Area>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Area>>, List<Area>>,
              AsyncValue<List<Area>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
