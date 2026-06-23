import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/database_provider.dart';

part 'documents_repository.g.dart';

class PersonDocumentDTO {
  final int id;
  final int personId;
  final int fieldId;
  final String fileName;
  final Uint8List fileContent;
  final DateTime createdAt;

  PersonDocumentDTO({
    required this.id,
    required this.personId,
    required this.fieldId,
    required this.fileName,
    required this.fileContent,
    required this.createdAt,
  });

  factory PersonDocumentDTO.fromDb(PersonDocument d) {
    return PersonDocumentDTO(
      id: d.id,
      personId: d.personId,
      fieldId: d.fieldId,
      fileName: d.fileName,
      fileContent: d.fileContent,
      createdAt: d.createdAt,
    );
  }
}

@riverpod
class DocumentsRepository extends _$DocumentsRepository {
  @override
  FutureOr<void> build() {}

  Future<List<PersonDocumentDTO>> fetchDocuments(int personId, int fieldId) async {
    final db = ref.read(appDatabaseProvider);
    final rows = await (db.select(db.personDocuments)
      ..where((t) => t.personId.equals(personId) & t.fieldId.equals(fieldId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    return rows.map((r) => PersonDocumentDTO.fromDb(r)).toList();
  }

  Future<bool> addDocument({
    required int personId,
    required int fieldId,
    required String fileName,
    required Uint8List fileContent,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.into(db.personDocuments).insert(PersonDocumentsCompanion.insert(
        personId: personId,
        fieldId: fieldId,
        fileName: fileName,
        fileContent: fileContent,
      ));
      return true;
    } catch (e) {
      print('Error adding document: $e');
      return false;
    }
  }

  Future<bool> deleteDocument(int id) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await (db.delete(db.personDocuments)..where((t) => t.id.equals(id))).go();
      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  Future<bool> hasDocuments(int personId, int fieldId) async {
    final db = ref.read(appDatabaseProvider);
    final query = db.selectOnly(db.personDocuments)
      ..addColumns([db.personDocuments.id.count()])
      ..where(db.personDocuments.personId.equals(personId) & db.personDocuments.fieldId.equals(fieldId));
    final result = await query.getSingle();
    final count = result.read(db.personDocuments.id.count()) ?? 0;
    return count > 0;
  }
}
