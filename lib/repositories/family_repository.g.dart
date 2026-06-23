// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FamilyRepository)
final familyRepositoryProvider = FamilyRepositoryFamily._();

final class FamilyRepositoryProvider
    extends $AsyncNotifierProvider<FamilyRepository, List<RelativeDTO>> {
  FamilyRepositoryProvider._({
    required FamilyRepositoryFamily super.from,
    required (int, {String? search, int? limit, int? offset}) super.argument,
  }) : super(
         retry: null,
         name: r'familyRepositoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$familyRepositoryHash();

  @override
  String toString() {
    return r'familyRepositoryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  FamilyRepository create() => FamilyRepository();

  @override
  bool operator ==(Object other) {
    return other is FamilyRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$familyRepositoryHash() => r'53316fae65fc67d492e091cee1cdfbf3f3e7bf4f';

final class FamilyRepositoryFamily extends $Family
    with
        $ClassFamilyOverride<
          FamilyRepository,
          AsyncValue<List<RelativeDTO>>,
          List<RelativeDTO>,
          FutureOr<List<RelativeDTO>>,
          (int, {String? search, int? limit, int? offset})
        > {
  FamilyRepositoryFamily._()
    : super(
        retry: null,
        name: r'familyRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FamilyRepositoryProvider call(
    int personId, {
    String? search,
    int? limit,
    int? offset,
  }) => FamilyRepositoryProvider._(
    argument: (personId, search: search, limit: limit, offset: offset),
    from: this,
  );

  @override
  String toString() => r'familyRepositoryProvider';
}

abstract class _$FamilyRepository extends $AsyncNotifier<List<RelativeDTO>> {
  late final _$args =
      ref.$arg as (int, {String? search, int? limit, int? offset});
  int get personId => _$args.$1;
  String? get search => _$args.search;
  int? get limit => _$args.limit;
  int? get offset => _$args.offset;

  FutureOr<List<RelativeDTO>> build(
    int personId, {
    String? search,
    int? limit,
    int? offset,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<RelativeDTO>>, List<RelativeDTO>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<RelativeDTO>>, List<RelativeDTO>>,
              AsyncValue<List<RelativeDTO>>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        _$args.$1,
        search: _$args.search,
        limit: _$args.limit,
        offset: _$args.offset,
      ),
    );
  }
}
