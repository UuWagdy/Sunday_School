// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tayo_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TayoRepository)
final tayoRepositoryProvider = TayoRepositoryProvider._();

final class TayoRepositoryProvider
    extends $AsyncNotifierProvider<TayoRepository, List<TayoCardDTO>> {
  TayoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tayoRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tayoRepositoryHash();

  @$internal
  @override
  TayoRepository create() => TayoRepository();
}

String _$tayoRepositoryHash() => r'5fab2c6c653610be36cc3691ea25d28af495c7ff';

abstract class _$TayoRepository extends $AsyncNotifier<List<TayoCardDTO>> {
  FutureOr<List<TayoCardDTO>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<TayoCardDTO>>, List<TayoCardDTO>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TayoCardDTO>>, List<TayoCardDTO>>,
              AsyncValue<List<TayoCardDTO>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
