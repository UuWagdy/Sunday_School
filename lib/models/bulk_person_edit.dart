import 'package:drift/drift.dart';

/// A missing value leaves a field unchanged; a present null clears it.
/// Keep those types through the dialog boundary instead of a dynamic map.
class BulkPersonEdit {
  final Value<int?> stageId, khorosId, areaId, fatherId, day, month, year;
  final Value<String?> streetName, phone, mobile, jenderName, rohot, leader;
  final List<int>? serviceIds;
  final Map<int, String>? customValues;

  const BulkPersonEdit({
    this.stageId = const Value.absent(),
    this.khorosId = const Value.absent(),
    this.areaId = const Value.absent(),
    this.fatherId = const Value.absent(),
    this.day = const Value.absent(),
    this.month = const Value.absent(),
    this.year = const Value.absent(),
    this.streetName = const Value.absent(),
    this.phone = const Value.absent(),
    this.mobile = const Value.absent(),
    this.jenderName = const Value.absent(),
    this.rohot = const Value.absent(),
    this.leader = const Value.absent(),
    this.serviceIds,
    this.customValues,
  });
}
