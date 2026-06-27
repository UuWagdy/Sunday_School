// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stages_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StagesRepository)
final stagesRepositoryProvider = StagesRepositoryProvider._();

final class StagesRepositoryProvider
    extends $AsyncNotifierProvider<StagesRepository, List<StageModel>> {
  StagesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stagesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stagesRepositoryHash();

  @$internal
  @override
  StagesRepository create() => StagesRepository();
}

String _$stagesRepositoryHash() => r'117cd0c1a8332c5647e907014d42634e83d42f7e';

abstract class _$StagesRepository extends $AsyncNotifier<List<StageModel>> {
  FutureOr<List<StageModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<StageModel>>, List<StageModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<StageModel>>, List<StageModel>>,
              AsyncValue<List<StageModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
