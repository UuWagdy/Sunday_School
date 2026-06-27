// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persons_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PersonsRepository)
final personsRepositoryProvider = PersonsRepositoryProvider._();

final class PersonsRepositoryProvider
    extends $AsyncNotifierProvider<PersonsRepository, List<PersonListDTO>> {
  PersonsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personsRepositoryHash();

  @$internal
  @override
  PersonsRepository create() => PersonsRepository();
}

String _$personsRepositoryHash() => r'07abe4f17812a366479d5382886932bfa9997b94';

abstract class _$PersonsRepository extends $AsyncNotifier<List<PersonListDTO>> {
  FutureOr<List<PersonListDTO>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PersonListDTO>>, List<PersonListDTO>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PersonListDTO>>, List<PersonListDTO>>,
              AsyncValue<List<PersonListDTO>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
