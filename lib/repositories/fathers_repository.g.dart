// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fathers_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FathersRepository)
final fathersRepositoryProvider = FathersRepositoryProvider._();

final class FathersRepositoryProvider
    extends $AsyncNotifierProvider<FathersRepository, List<FatherModel>> {
  FathersRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fathersRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fathersRepositoryHash();

  @$internal
  @override
  FathersRepository create() => FathersRepository();
}

String _$fathersRepositoryHash() => r'fd10421fa1d46b127950e187d4ec575263ecd1b0';

abstract class _$FathersRepository extends $AsyncNotifier<List<FatherModel>> {
  FutureOr<List<FatherModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<FatherModel>>, List<FatherModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<FatherModel>>, List<FatherModel>>,
              AsyncValue<List<FatherModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
