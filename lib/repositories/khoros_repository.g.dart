// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'khoros_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(KhorosRepository)
final khorosRepositoryProvider = KhorosRepositoryProvider._();

final class KhorosRepositoryProvider
    extends $AsyncNotifierProvider<KhorosRepository, List<KhorosModel>> {
  KhorosRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'khorosRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$khorosRepositoryHash();

  @$internal
  @override
  KhorosRepository create() => KhorosRepository();
}

String _$khorosRepositoryHash() => r'78046218baadabe308921a7cd9988530f188b0ed';

abstract class _$KhorosRepository extends $AsyncNotifier<List<KhorosModel>> {
  FutureOr<List<KhorosModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<KhorosModel>>, List<KhorosModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<KhorosModel>>, List<KhorosModel>>,
              AsyncValue<List<KhorosModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
