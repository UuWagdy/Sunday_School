import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../services/auth_service.dart';
import '../database/database.dart';
import '../database/database_provider.dart';

part 'family_repository.g.dart';

class RelativeDTO {
  final int id;
  final int personId;
  final int relatedPersonId;
  final String relatedPersonName;
  final String category;
  final String relationshipCode;
  final String? customLabel;
  final String? gender;

  RelativeDTO({
    required this.id,
    required this.personId,
    required this.relatedPersonId,
    required this.relatedPersonName,
    required this.category,
    required this.relationshipCode,
    this.customLabel,
    this.gender,
  });
}

@riverpod
class FamilyRepository extends _$FamilyRepository {
  @override
  FutureOr<List<RelativeDTO>> build(int personId, {String? search, int? limit, int? offset}) async {
    return _fetchRelatives(personId, search: search, limit: limit, offset: offset);
  }

  Future<List<RelativeDTO>> _fetchRelatives(int personId, {String? search, int? limit, int? offset}) async {
    final db = ref.read(appDatabaseProvider);
    
    final query = db.select(db.familyRelationships).join([
      drift.leftOuterJoin(db.persons, db.persons.personId.equalsExp(db.familyRelationships.relatedPersonId)),
    ])..where(db.familyRelationships.personId.equals(personId));

    final user = ref.read(authServiceProvider).value;
    final filters = user?.visibilityFilters ?? {};
    await _applyVisibilityFilters(query, db, filters);

    if (search != null && search.isNotEmpty) {
      final s = '%$search%';
      query.where(db.persons.personName.like(s));
    }

    if (limit != null) {
      query.limit(limit, offset: offset);
    }

    final results = await query.get();

    return results.map((row) {
      final relationship = row.readTable(db.familyRelationships);
      final person = row.readTable(db.persons);

      return RelativeDTO(
        id: relationship.id,
        personId: relationship.personId,
        relatedPersonId: relationship.relatedPersonId,
        relatedPersonName: person.personName ?? 'Unknown',
        category: relationship.category,
        relationshipCode: relationship.relationshipCode,
        customLabel: relationship.customLabel,
        gender: person.jenderName,
      );
    }).toList();
  }

  Future<void> _applyVisibilityFilters(drift.JoinedSelectStatement query, AppDatabase db, Map<String, List<int>> filters) async {
    final user = ref.read(authServiceProvider).value;
    if (user != null && user.canPersons) return;
    if (filters.isEmpty) return;

    for (final type in filters.keys) {
      final values = filters[type]!;
      switch (type) {
        case 'stage':
          if (values.isNotEmpty) query.where(db.persons.stageId.isIn(values));
          break;
        case 'khoros':
          if (values.isNotEmpty) query.where(db.persons.khorosId.isIn(values));
          break;
        case 'area':
          if (values.isNotEmpty) {
            final allDescendants = <int>{};
            for (final areaId in values) {
              allDescendants.addAll(await db.getAreaAndDescendantIds(areaId));
            }
            query.where(db.persons.areaId.isIn(allDescendants.toList()));
          }
          break;
        case 'gender':
          if (values.isNotEmpty) {
            final genderStrs = values.map((v) => v == 1 ? 'ذكر' : 'أنثى').toList();
            query.where(db.persons.jenderName.isIn(genderStrs));
          }
          break;
      }
    }
  }

  Future<bool> addRelationship({
    required int personId,
    required int relatedPersonId,
    required String category,
    required String relationshipCode,
    String? customLabel,
    String? initiatorCustomLabel,
  }) async {
    final db = ref.read(appDatabaseProvider);
    try {
      await db.transaction(() async {
        final initiator = await (db.select(db.persons)..where((t) => t.personId.equals(personId))).getSingle();
        final target = await (db.select(db.persons)..where((t) => t.personId.equals(relatedPersonId))).getSingle();
        
        final initiatorGender = initiator.jenderName;
        final targetGender = target.jenderName;

        if (relationshipCode == 'OTHER') {
          await db.into(db.familyRelationships).insert(FamilyRelationshipsCompanion.insert(
            personId: personId,
            relatedPersonId: relatedPersonId,
            category: category,
            relationshipCode: 'OTHER',
            customLabel: drift.Value(customLabel),
          ));
          await db.into(db.familyRelationships).insert(FamilyRelationshipsCompanion.insert(
            personId: relatedPersonId,
            relatedPersonId: personId,
            category: category,
            relationshipCode: 'OTHER',
            customLabel: drift.Value(initiatorCustomLabel),
          ));
        } else {
          final codes = _getBidirectionalCodes(relationshipCode, initiatorGender, targetGender);
          if (codes != null) {
            await db.into(db.familyRelationships).insert(FamilyRelationshipsCompanion.insert(
              personId: personId,
              relatedPersonId: relatedPersonId,
              category: category,
              relationshipCode: codes.targetLabel,
              customLabel: drift.Value(customLabel),
            ));
            await db.into(db.familyRelationships).insert(FamilyRelationshipsCompanion.insert(
              personId: relatedPersonId,
              relatedPersonId: personId,
              category: category,
              relationshipCode: codes.initiatorLabel,
              customLabel: drift.Value(initiatorCustomLabel), // Added initiatorCustomLabel here
            ));
          }
        }
      });
      
      ref.invalidateSelf();
      ref.invalidate(familyRepositoryProvider(relatedPersonId));
      return true;
    } catch (e) {
      return false;
    }
  }

  ({String initiatorLabel, String targetLabel})? _getBidirectionalCodes(String selection, String? initGender, String? targetGender) {
    bool targetMale = targetGender == 'ذكر';
    
    switch (selection) {
      case 'SON':
      case 'DAUGHTER':
        // A is Son/Daughter. 
        // B sees A as: selection (Son/Daughter)
        // A sees B as: Father/Mother (based on B's gender)
        return (
          initiatorLabel: selection,
          targetLabel: targetMale ? 'FATHER' : 'MOTHER'
        );
      case 'FATHER':
      case 'MOTHER':
        // A is Father/Mother.
        // B sees A as: selection
        // A sees B as: Son/Daughter (based on B's gender)
        return (
          initiatorLabel: selection,
          targetLabel: targetMale ? 'SON' : 'DAUGHTER'
        );
      case 'BROTHER':
      case 'SISTER':
        return (
          initiatorLabel: selection,
          targetLabel: targetMale ? 'BROTHER' : 'SISTER'
        );
      case 'HUSBAND':
      case 'WIFE':
        return (
          initiatorLabel: selection,
          targetLabel: targetMale ? 'HUSBAND' : 'WIFE'
        );
      case 'UNCLE_PATERNAL':
      case 'AUNT_PATERNAL':
        // A is Am/Amma.
        // B sees A as: selection
        // A sees B as: Ibn Akh / Bint Akh (based on B's gender)
        return (
          initiatorLabel: selection,
          targetLabel: targetMale ? 'NEPHEW_PATERNAL' : 'NIECE_PATERNAL'
        );
      case 'UNCLE_MATERNAL':
      case 'AUNT_MATERNAL':
        // A is Khal/Khala.
        // A sees B as: Ibn Okht / Bint Okht
        return (
          initiatorLabel: selection,
          targetLabel: targetMale ? 'NEPHEW_MATERNAL' : 'NIECE_MATERNAL'
        );
      case 'NEPHEW_PATERNAL':
      case 'NIECE_PATERNAL':
        // A is Ibn Akh / Bint Akh.
        // A sees B as: Am / Amma
        return (
          initiatorLabel: selection,
          targetLabel: targetMale ? 'UNCLE_PATERNAL' : 'AUNT_PATERNAL'
        );
      case 'NEPHEW_MATERNAL':
      case 'NIECE_MATERNAL':
        return (
          initiatorLabel: selection,
          targetLabel: targetMale ? 'UNCLE_MATERNAL' : 'AUNT_MATERNAL'
        );
      case 'COUSIN_PATERNAL':
      case 'COUSIN_PATERNAL_F':
        return (
          initiatorLabel: selection,
          targetLabel: targetMale ? 'COUSIN_PATERNAL' : 'COUSIN_PATERNAL_F'
        );
      case 'COUSIN_AMMA':
      case 'COUSIN_AMMA_F':
        // A is Ibn Amma.
        // A sees B as: Ibn Khal / Bint Khal
        return (
          initiatorLabel: selection,
          targetLabel: targetMale ? 'COUSIN_MATERNAL' : 'COUSIN_MATERNAL_F'
        );
      case 'COUSIN_MATERNAL':
      case 'COUSIN_MATERNAL_F':
        // A is Ibn Khal.
        // A sees B as: Ibn Amma / Bint Amma
        return (
          initiatorLabel: selection,
          targetLabel: targetMale ? 'COUSIN_AMMA' : 'COUSIN_AMMA_F'
        );
      case 'COUSIN_KHALA':
      case 'COUSIN_KHALA_F':
        return (
          initiatorLabel: selection,
          targetLabel: targetMale ? 'COUSIN_KHALA' : 'COUSIN_KHALA_F'
        );
      default:
        return null;
    }
  }

  Future<bool> deleteRelationship(int id) async {
    final db = ref.read(appDatabaseProvider);
    try {
      final rel = await (db.select(db.familyRelationships)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (rel == null) return false;

      await db.transaction(() async {
        await (db.delete(db.familyRelationships)..where((t) => t.personId.equals(rel.personId) & t.relatedPersonId.equals(rel.relatedPersonId))).go();
        await (db.delete(db.familyRelationships)
          ..where((t) => t.personId.equals(rel.relatedPersonId) & t.relatedPersonId.equals(rel.personId))).go();
      });

      ref.invalidateSelf();
      ref.invalidate(familyRepositoryProvider(rel.relatedPersonId));
      return true;
    } catch (e) {
      return false;
    }
  }
}
