// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fields_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FieldsRepository)
final fieldsRepositoryProvider = FieldsRepositoryProvider._();

final class FieldsRepositoryProvider
    extends $AsyncNotifierProvider<FieldsRepository, List<FieldConfigDTO>> {
  FieldsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fieldsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fieldsRepositoryHash();

  @$internal
  @override
  FieldsRepository create() => FieldsRepository();
}

String _$fieldsRepositoryHash() => r'52b581320174fc551847d05ef63f8cbd58ab07ca';

abstract class _$FieldsRepository extends $AsyncNotifier<List<FieldConfigDTO>> {
  FutureOr<List<FieldConfigDTO>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<FieldConfigDTO>>, List<FieldConfigDTO>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<FieldConfigDTO>>,
                List<FieldConfigDTO>
              >,
              AsyncValue<List<FieldConfigDTO>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
