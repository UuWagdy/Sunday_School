// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ServicesRepository)
final servicesRepositoryProvider = ServicesRepositoryProvider._();

final class ServicesRepositoryProvider
    extends $AsyncNotifierProvider<ServicesRepository, List<ServiceDTO>> {
  ServicesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'servicesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$servicesRepositoryHash();

  @$internal
  @override
  ServicesRepository create() => ServicesRepository();
}

String _$servicesRepositoryHash() =>
    r'49507b65c4da3a13905b805b212aa2b03e369d7f';

abstract class _$ServicesRepository extends $AsyncNotifier<List<ServiceDTO>> {
  FutureOr<List<ServiceDTO>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ServiceDTO>>, List<ServiceDTO>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ServiceDTO>>, List<ServiceDTO>>,
              AsyncValue<List<ServiceDTO>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
