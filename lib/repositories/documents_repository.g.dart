// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DocumentsRepository)
final documentsRepositoryProvider = DocumentsRepositoryProvider._();

final class DocumentsRepositoryProvider
    extends $AsyncNotifierProvider<DocumentsRepository, void> {
  DocumentsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentsRepositoryHash();

  @$internal
  @override
  DocumentsRepository create() => DocumentsRepository();
}

String _$documentsRepositoryHash() =>
    r'b57c911459274d1e90324e19e3d9c729f82cfd23';

abstract class _$DocumentsRepository extends $AsyncNotifier<void> {
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
