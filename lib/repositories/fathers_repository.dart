import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../services/auth_service.dart';
import '../database/database.dart';
import '../database/database_provider.dart';

part 'fathers_repository.g.dart';

class FatherModel {
  final int id;
  final String name;

  FatherModel({required this.id, required this.name});
}

@riverpod
class FathersRepository extends _$FathersRepository {
  @override
  FutureOr<List<FatherModel>> build() async {
    return _fetch();
  }

  Future<List<FatherModel>> _fetch() async {
    final db = ref.read(appDatabaseProvider);
    final query = db.select(db.fathers);
    
    // Apply visibility filters
    final user = ref.read(authServiceProvider).value;
    if (user != null && user.isAdvanced) {
      final allowedIds = user.visibilityFilters['father'];
      if (allowedIds != null) {
        if (allowedIds.isEmpty) {
          query.where((t) => t.fatherId.isNull() & t.fatherId.isNotNull());
        } else {
          query.where((t) => t.fatherId.isIn(allowedIds));
        }
      }
    }

    final rows = await query.get();
    return rows.map((r) => FatherModel(
      id: r.fatherId ?? 0,
      name: r.fatherName ?? '',
    )).toList();
  }

  Future<bool> addFather(String name) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.into(db.fathers).insert(FathersCompanion.insert(
        fatherName: drift.Value(name),
      ));
      ref.invalidateSelf();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateFather(int id, String name) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await (db.update(db.fathers)..where((t) => t.fatherId.equals(id))).write(
        FathersCompanion(fatherName: drift.Value(name)),
      );
      ref.invalidateSelf();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteFather(int id) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await (db.delete(db.fathers)..where((t) => t.fatherId.equals(id))).go();
      ref.invalidateSelf();
      return true;
    } catch (e) {
      return false;
    }
  }
}
