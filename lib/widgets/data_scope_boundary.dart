import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import '../services/auth_service.dart';
import '../repositories/persons_repository.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/areas_repository.dart';
import '../repositories/stages_repository.dart';
import '../repositories/khoros_repository.dart';
import '../repositories/fathers_repository.dart';
import '../repositories/services_repository.dart';
import '../repositories/users_repository.dart';
import '../repositories/fields_repository.dart';
import '../repositories/documents_repository.dart';
import '../repositories/family_repository.dart';
import '../repositories/bus_repository.dart';
import '../repositories/tayo_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/reports_repository.dart';
import '../repositories/period_comparison_repository.dart';
import 'dashboard/general_attendance_chart.dart';

/// Ordinary data revisions preserve widgets and cached snapshots. A change of
/// identity, database or access scope gets a separate data container so previous
/// AsyncValues from a wider scope can never flash in the new session.
class DataScopeBoundary extends ConsumerWidget {
  final Widget child;
  const DataScopeBoundary({super.key, required this.child});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).value;
    final db = ref.watch(appDatabaseProvider);
    return _SessionDataScope(
      key: ValueKey((db, user?.id, user?.dataVisibilityScope.fingerprint)),
      child: child,
    );
  }
}

class _SessionDataScope extends StatefulWidget {
  final Widget child;
  const _SessionDataScope({super.key, required this.child});
  @override
  State<_SessionDataScope> createState() => _SessionDataScopeState();
}

class _SessionDataScopeState extends State<_SessionDataScope> {
  // Stable override factories: changing the selected tab does not rebuild stores.
  late final _overrides = [
    personsRepositoryProvider.overrideWith(PersonsRepository.new),
    attendanceRepositoryProvider.overrideWith(AttendanceRepository.new),
    areasRepositoryProvider.overrideWith(AreasRepository.new),
    stagesRepositoryProvider.overrideWith(StagesRepository.new),
    khorosRepositoryProvider.overrideWith(KhorosRepository.new),
    fathersRepositoryProvider.overrideWith(FathersRepository.new),
    servicesRepositoryProvider.overrideWith(ServicesRepository.new),
    usersRepositoryProvider.overrideWith(UsersRepository.new),
    fieldsRepositoryProvider.overrideWith(FieldsRepository.new),
    documentsRepositoryProvider.overrideWith(DocumentsRepository.new),
    familyRepositoryProvider.overrideWith2((_) => FamilyRepository()),
    busRepositoryProvider.overrideWith(BusRepository.new),
    tayoRepositoryProvider.overrideWith(TayoRepository.new),
    periodComparisonRepositoryProvider.overrideWith(
      PeriodComparisonRepository.new,
    ),
    generalAttendanceTrendProvider.overrideWith(
      (ref, a) => generalAttendanceTrend(
        ref,
        groupBy: a.groupBy,
        filterYear: a.filterYear,
        filterMonth: a.filterMonth,
        serviceId: a.serviceId,
        status: a.status,
      ),
    ),
    individualAttendanceTrendProvider.overrideWith(
      (ref, a) => individualAttendanceTrend(
        ref,
        personId: a.personId,
        groupBy: a.groupBy,
        filterYear: a.filterYear,
        filterMonth: a.filterMonth,
        serviceId: a.serviceId,
        status: a.status,
      ),
    ),
    attendanceRankingsProvider.overrideWith(
      (ref, a) => attendanceRankings(
        ref,
        stageId: a.stageId,
        areaId: a.areaId,
        fatherId: a.fatherId,
        dateFrom: a.dateFrom,
        dateTo: a.dateTo,
        serviceId: a.serviceId,
        sortCriteria: a.sortCriteria,
        limit: a.limit,
        offset: a.offset,
      ),
    ),
    totalPersonsProvider.overrideWith(scopedPersonsCount),
    demographicAreasProvider.overrideWith(demographicAreas),
    demographicStagesProvider.overrideWith(demographicStages),
    demographicFathersProvider.overrideWith(demographicFathers),
    demographicGenderProvider.overrideWith(demographicGender),
    demographicFirstNamesProvider.overrideWith(demographicFirstNames),
    personsReportProvider.overrideWith(
      (ref, a) => personsReport(ref, stageId: a.stageId, areaId: a.areaId),
    ),
    attendanceReportProvider.overrideWith(
      (ref, a) =>
          attendanceReport(ref, month: a.month, year: a.year, status: a.status),
    ),
    stageStatisticsProvider.overrideWith(stageStatistics),
  ];
  @override
  Widget build(BuildContext context) =>
      ProviderScope(overrides: _overrides, child: widget.child);
}
