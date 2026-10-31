import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../services/auth_service.dart';
import '../database/database.dart';
import '../database/database_provider.dart';
import '../sync/data_change_coordinator.dart';
import '../sync/data_change_domains.dart';

part 'services_repository.g.dart';

class ServiceDTO {
  final int id;
  final String name;
  final int dayOfWeek;
  final int hour;
  final int minute;
  final int? endHour;
  final int? endMinute;
  final Uint8List? logo;
  final String? checkColor;

  ServiceDTO({
    required this.id,
    required this.name,
    required this.dayOfWeek,
    required this.hour,
    required this.minute,
    this.endHour,
    this.endMinute,
    this.logo,
    this.checkColor,
  });

  /// Get the day name in Arabic
  String get dayName {
    const days = {
      1: 'الإثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد',
    };
    return days[dayOfWeek] ?? '';
  }

  /// Format time as 12-hour Arabic
  String get formattedTime => _formatTime(hour, minute);

  String get formattedEndTime {
    if (endHour == null || endMinute == null) return '-';
    return _formatTime(endHour!, endMinute!);
  }

  String _formatTime(int h, int m) {
    final period = h >= 12 ? 'م' : 'ص';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  String toString() => '$name - $dayName $formattedTime';
}

@riverpod
class ServicesRepository extends _$ServicesRepository {
  @override
  FutureOr<List<ServiceDTO>> build() async {
    ref.watch(domainRevisionProvider(DataDomain.services));
    return fetchAll();
  }

  Future<List<ServiceDTO>> fetchAll() async {
    final db = ref.read(appDatabaseProvider);
    final query = db.select(db.services);

    // Apply visibility filters
    final user = ref.read(authServiceProvider).value;
    if (user != null && user.isAdvanced) {
      final allowedIds = user.visibilityFilters['service'];
      if (allowedIds != null) {
        if (allowedIds.isEmpty) {
          query.where((t) => drift.Constant(false));
        } else {
          query.where((t) => t.serviceId.isIn(allowedIds));
        }
      }
    }

    final rows = await query.get();
    return rows.map((r) => ServiceDTO(
      id: r.serviceId,
      name: r.serviceName ?? '',
      dayOfWeek: r.dayOfWeek ?? 1,
      hour: r.hour ?? 0,
      minute: r.minute ?? 0,
      endHour: r.endHour,
      endMinute: r.endMinute,
      logo: r.logo,
      checkColor: r.checkColor,
    )).toList();
  }

  Future<bool> addService({
    required String name,
    required int dayOfWeek,
    required int hour,
    required int minute,
    int? endHour,
    int? endMinute,
    Uint8List? logo,
    String? checkColor,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await db.into(db.services).insert(ServicesCompanion(
        serviceName: drift.Value(name),
        dayOfWeek: drift.Value(dayOfWeek),
        hour: drift.Value(hour),
        minute: drift.Value(minute),
        endHour: drift.Value(endHour),
        endMinute: drift.Value(endMinute),
        logo: drift.Value(logo),
        checkColor: drift.Value(checkColor),
      ));
      if (ref.mounted) ref.invalidateSelf();
      return true;
    } catch (e) {
      print('Error adding service: $e');
      return false;
    }
  }

  Future<bool> updateService({
    required int id,
    required String name,
    required int dayOfWeek,
    required int hour,
    required int minute,
    int? endHour,
    int? endMinute,
    Uint8List? logo,
    String? checkColor,
  }) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await (db.update(db.services)..where((t) => t.serviceId.equals(id))).write(
        ServicesCompanion(
          serviceName: drift.Value(name),
          dayOfWeek: drift.Value(dayOfWeek),
          hour: drift.Value(hour),
          minute: drift.Value(minute),
          endHour: drift.Value(endHour),
          endMinute: drift.Value(endMinute),
          logo: drift.Value(logo),
          checkColor: drift.Value(checkColor),
        ),
      );
      if (ref.mounted) ref.invalidateSelf();
      return true;
    } catch (e) {
      print('Error updating service: $e');
      return false;
    }
  }

  Future<bool> deleteService(int id) async {
    try {
      final db = ref.read(appDatabaseProvider);
      await (db.delete(db.services)..where((t) => t.serviceId.equals(id))).go();
      if (ref.mounted) ref.invalidateSelf();
      return true;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }
}
