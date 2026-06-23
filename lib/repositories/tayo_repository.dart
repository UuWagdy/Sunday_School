import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../database/database.dart';
import '../database/database_provider.dart';

part 'tayo_repository.g.dart';

// ─── DTOs ──────────────────────────────────────────────

class TayoCardDTO {
  final int cardId;
  final String cardName;
  final int cardPoints;
  final Uint8List? cardImage;

  TayoCardDTO({
    required this.cardId,
    required this.cardName,
    required this.cardPoints,
    this.cardImage,
  });
}

class PersonPointsDTO {
  final int personId;
  final String personName;
  final String? stageName;
  final String? areaName;
  final int totalPoints;
  final int tayoPoints;
  final int attendancePoints;
  final Map<String, int> cardPoints;

  PersonPointsDTO({
    required this.personId,
    required this.personName,
    this.stageName,
    this.areaName,
    required this.totalPoints,
    required this.tayoPoints,
    required this.attendancePoints,
    required this.cardPoints,
  });
}

class PointLogDTO {
  final int id;
  final int personId;
  final String personName;
  final String? cardName;
  final int points;
  final String date;
  final bool isAttendance;
  final String? notes;

  PointLogDTO({
    required this.id,
    required this.personId,
    required this.personName,
    this.cardName,
    required this.points,
    required this.date,
    required this.isAttendance,
    this.notes,
  });
}

// ─── Repository ────────────────────────────────────────

@riverpod
class TayoRepository extends _$TayoRepository {
  @override
  FutureOr<List<TayoCardDTO>> build() async {
    return getCards();
  }

  // ── Card CRUD ──

  Future<List<TayoCardDTO>> getCards() async {
    final db = ref.read(appDatabaseProvider);
    final rows = await db.select(db.tayoCards).get();
    return rows
        .map((r) => TayoCardDTO(
              cardId: r.cardId,
              cardName: r.cardName ?? '',
              cardPoints: r.cardPoints ?? 0,
              cardImage: r.cardImage,
            ))
        .toList();
  }

  Future<void> addCard({
    required String name,
    required int points,
    Uint8List? image,
  }) async {
    final db = ref.read(appDatabaseProvider);
    await db.into(db.tayoCards).insert(TayoCardsCompanion(
          cardName: drift.Value(name),
          cardPoints: drift.Value(points),
          cardImage: image != null ? drift.Value(image) : const drift.Value.absent(),
        ));
    ref.invalidateSelf();
  }

  Future<void> updateCard({
    required int cardId,
    required String name,
    required int points,
    Uint8List? image,
    bool clearImage = false,
  }) async {
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.tayoCards)..where((t) => t.cardId.equals(cardId))).write(
      TayoCardsCompanion(
        cardName: drift.Value(name),
        cardPoints: drift.Value(points),
        cardImage: clearImage ? const drift.Value(null) : (image != null ? drift.Value(image) : const drift.Value.absent()),
      ),
    );
    ref.invalidateSelf();
  }

  Future<void> deleteCard(int cardId) async {
    final db = ref.read(appDatabaseProvider);
    await (db.delete(db.tayoCards)..where((t) => t.cardId.equals(cardId))).go();
    // Also remove associated point logs
    await (db.delete(db.personTayoPoints)..where((t) => t.cardId.equals(cardId))).go();
    ref.invalidateSelf();
  }

  // ── Points ──

  Future<String?> addPointsToPerson({
    required int personId,
    required int cardId,
    required int points,
    required String date,
    bool isAttendance = false,
    String? notes,
    int? serviceId,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.into(db.personTayoPoints).insert(PersonTayoPointsCompanion(
            personId: drift.Value(personId),
            cardId: drift.Value(cardId),
            points: drift.Value(points),
            awardDate: drift.Value(date),
            isAttendance: drift.Value(isAttendance),
            notes: notes != null ? drift.Value(notes) : const drift.Value.absent(),
            serviceId: serviceId != null ? drift.Value(serviceId) : const drift.Value.absent(),
          ));
      return null;
    } catch (e) {
      return 'خطأ: $e';
    }
  }

  Future<int> getPersonTotalPoints(int personId) async {
    final db = ref.read(appDatabaseProvider);
    final sumExpr = db.personTayoPoints.points.sum();
    final query = db.selectOnly(db.personTayoPoints)
      ..addColumns([sumExpr])
      ..where(db.personTayoPoints.personId.equals(personId));
    final row = await query.getSingle();
    return row.read(sumExpr) ?? 0;
  }

  Future<void> deletePointLog(int logId) async {
    final db = ref.read(appDatabaseProvider);
    await (db.delete(db.personTayoPoints)..where((t) => t.id.equals(logId))).go();
  }

  Future<void> updatePointLog({
    required int logId,
    required String date,
    int? cardId,
    int? points,
    String? notes,
    bool clearNotes = false,
  }) async {
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.personTayoPoints)..where((t) => t.id.equals(logId))).write(
      PersonTayoPointsCompanion(
        awardDate: drift.Value(date),
        cardId: drift.Value(cardId ?? 0), // 0 means extra points without card
        points: points != null ? drift.Value(points) : const drift.Value.absent(),
        notes: clearNotes ? const drift.Value(null) : (notes != null ? drift.Value(notes) : const drift.Value.absent()),
      ),
    );
  }

  // ── Reports ──

  Future<List<PersonPointsDTO>> getPointsReport({
    int? stageId,
    int? areaId,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool ascending = false,
    bool includeAttendance = false,
    List<int>? attendanceServiceIds,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final fmt = DateFormat('yyyy-MM-dd');

    // 1. Fetch Tayo Points Map and Card Breakdown
    final tayoQuery = db.select(db.personTayoPoints).join([
      drift.leftOuterJoin(db.tayoCards, db.tayoCards.cardId.equalsExp(db.personTayoPoints.cardId)),
    ]);
    if (dateFrom != null) tayoQuery.where(db.personTayoPoints.awardDate.isBiggerOrEqualValue(fmt.format(dateFrom)));
    if (dateTo != null) tayoQuery.where(db.personTayoPoints.awardDate.isSmallerOrEqualValue(fmt.format(dateTo)));
    final tayoRows = await tayoQuery.get();
    
    final tayoMap = <int, int>{};
    final cardBreakdownMap = <int, Map<String, int>>{};

    for (var r in tayoRows) {
      final pt = r.readTable(db.personTayoPoints);
      final card = r.readTableOrNull(db.tayoCards);
      
      final pId = pt.personId;
      if (pId == null) continue;
      
      final pts = pt.points ?? 0;
      final cName = card?.cardName ?? 'نقاط إضافية';

      tayoMap[pId] = (tayoMap[pId] ?? 0) + pts;
      cardBreakdownMap[pId] ??= {};
      cardBreakdownMap[pId]![cName] = (cardBreakdownMap[pId]![cName] ?? 0) + pts;
    }

    // 2. Fetch Attendance Map (optionally filtered by service)
    final attMap = <int, int>{};
    if (includeAttendance) {
      final attQuery = db.selectOnly(db.coming)
        ..addColumns([db.coming.personId, db.coming.id.count()])
        ..groupBy([db.coming.personId]);
      if (dateFrom != null) attQuery.where(db.coming.dateWeek.isBiggerOrEqualValue(fmt.format(dateFrom)));
      if (dateTo != null) attQuery.where(db.coming.dateWeek.isSmallerOrEqualValue(fmt.format(dateTo)));
      if (attendanceServiceIds != null && attendanceServiceIds.isNotEmpty) {
        attQuery.where(db.coming.serviceId.isIn(attendanceServiceIds));
      }
      final attRows = await attQuery.get();
      for (var r in attRows) {
        final pId = r.read(db.coming.personId);
        if (pId != null) {
          attMap[pId] = r.read(db.coming.id.count())!;
        }
      }
    }

    // 3. Fetch Persons and merge
    final pQuery = db.select(db.persons).join([
      drift.leftOuterJoin(db.stages, db.stages.stageId.equalsExp(db.persons.stageId)),
      drift.leftOuterJoin(db.areas, db.areas.areaId.equalsExp(db.persons.areaId)),
    ]);
    if (stageId != null) pQuery.where(db.persons.stageId.equals(stageId));
    if (areaId != null) {
      final descendantIds = await db.getAreaAndDescendantIds(areaId);
      pQuery.where(db.persons.areaId.isIn(descendantIds));
    }

    // Apply visibility filters
    final user = ref.read(authServiceProvider).value;
    if (user != null && user.isAdvanced) {
      final filters = user.visibilityFilters;
      for (final type in filters.keys) {
        final values = filters[type]!;
        if (values.isEmpty) continue;

        switch (type) {
          case 'stage':
            pQuery.where(db.persons.stageId.isIn(values));
            break;
          case 'khoros':
            pQuery.where(db.persons.khorosId.isIn(values));
            break;
          case 'area':
            final descendants = <int>[];
            for (final id in values) descendants.addAll(await db.getAreaAndDescendantIds(id));
            pQuery.where(db.persons.areaId.isIn(descendants));
            break;
          case 'father':
            pQuery.where(db.persons.fatherId.isIn(values));
            break;
          case 'gender':
            final genders = values.map((v) => v == 1 ? 'ذكر' : 'أنثى').toList();
            pQuery.where(db.persons.jenderName.isIn(genders));
            break;
        }
      }
    }

    final pRows = await pQuery.get();
    final results = <PersonPointsDTO>[];

    for (var r in pRows) {
      final person = r.readTable(db.persons);
      final pid = person.personId;
      final tPts = tayoMap[pid] ?? 0;
      final aPts = attMap[pid] ?? 0;
      final total = tPts + aPts;

      if (total > 0) {
        final stage = r.readTableOrNull(db.stages);
        final area = r.readTableOrNull(db.areas);
        results.add(PersonPointsDTO(
          personId: pid,
          personName: person.personName ?? 'غير معروف',
          stageName: stage?.stageName,
          areaName: area?.areaName,
          totalPoints: total,
          tayoPoints: tPts,
          attendancePoints: aPts,
          cardPoints: cardBreakdownMap[pid] ?? {},
        ));
      }
    }

    if (ascending) {
      results.sort((a, b) => a.totalPoints.compareTo(b.totalPoints));
    } else {
      results.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    }

    return results;
  }

  /// Get recent point log entries for display
  Future<List<PointLogDTO>> getPointLogs({
    int? personId,
    int? limit,
    int? offset,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? stageId,
    int? areaId,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final fmt = DateFormat('yyyy-MM-dd');

    final query = db.select(db.personTayoPoints).join([
      drift.leftOuterJoin(db.persons, db.persons.personId.equalsExp(db.personTayoPoints.personId)),
      drift.leftOuterJoin(db.tayoCards, db.tayoCards.cardId.equalsExp(db.personTayoPoints.cardId)),
    ]);

    if (personId != null) query.where(db.personTayoPoints.personId.equals(personId));
    if (stageId != null) query.where(db.persons.stageId.equals(stageId));
    if (areaId != null) {
      final descendantIds = await db.getAreaAndDescendantIds(areaId);
      query.where(db.persons.areaId.isIn(descendantIds));
    }
    if (dateFrom != null) query.where(db.personTayoPoints.awardDate.isBiggerOrEqualValue(fmt.format(dateFrom)));
    if (dateTo != null) query.where(db.personTayoPoints.awardDate.isSmallerOrEqualValue(fmt.format(dateTo)));

    // Apply visibility filters
    final user = ref.read(authServiceProvider).value;
    if (user != null && user.isAdvanced) {
      final filters = user.visibilityFilters;
      for (final type in filters.keys) {
        final values = filters[type]!;
        if (values.isEmpty) continue;

        switch (type) {
          case 'stage':
            query.where(db.persons.stageId.isIn(values));
            break;
          case 'khoros':
            query.where(db.persons.khorosId.isIn(values));
            break;
          case 'area':
            final descendants = <int>[];
            for (final id in values) descendants.addAll(await db.getAreaAndDescendantIds(id));
            query.where(db.persons.areaId.isIn(descendants));
            break;
          case 'father':
            query.where(db.persons.fatherId.isIn(values));
            break;
          case 'gender':
            final genders = values.map((v) => v == 1 ? 'ذكر' : 'أنثى').toList();
            query.where(db.persons.jenderName.isIn(genders));
            break;
        }
      }
    }

    query.orderBy([drift.OrderingTerm.desc(db.personTayoPoints.id)]);
    if (limit != null) query.limit(limit, offset: offset);

    final rows = await query.get();
    return rows.map((row) {
      final pt = row.readTable(db.personTayoPoints);
      final person = row.readTableOrNull(db.persons);
      final card = row.readTableOrNull(db.tayoCards);
      return PointLogDTO(
        id: pt.id,
        personId: pt.personId ?? 0,
        personName: person?.personName ?? 'غير معروف',
        cardName: card?.cardName,
        points: pt.points ?? 0,
        date: pt.awardDate ?? '',
        isAttendance: pt.isAttendance ?? false,
        notes: pt.notes,
      );
    }).toList();
  }
}
