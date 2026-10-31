import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../database/database_provider.dart';
import '../services/auth_service.dart';
import '../sync/data_change_coordinator.dart';
import '../sync/data_change_domains.dart';
import 'dart:convert';
import '../models/data_visibility_scope.dart';

part 'users_repository.g.dart';

class UserModel {
  final int id;
  final String username;
  final String password;
  final bool canPersons;
  final bool canStages;
  final bool canAreas;
  final bool canFathers;
  final bool canReports;
  final bool canUsers;
  final bool canAbsence;
  final bool canMaintenance;
  final bool canIdCard;
  final bool canTayo;
  final bool canTransfer;
  final bool canServices;
  final bool canKhoros;
  final bool canBehavior;
  final bool isAdvanced;
  // Granular permissions: { 'persons': { 'add': true, 'edit': false, 'delete': false }, ... }
  final Map<String, Map<String, bool>> granularPermissions;
  // Visibility filters: { 'stage': [1, 2], 'service': [5], ... }
  final Map<String, List<int>> visibilityFilters;
  // User ID visibility
  final List<int> visibleUserIds;
  final DataVisibilityScope dataVisibilityScope;

  UserModel({
    required this.id,
    required this.username,
    required this.password,
    this.canPersons = false,
    this.canStages = false,
    this.canAreas = false,
    this.canFathers = false,
    this.canReports = false,
    this.canUsers = false,
    this.canAbsence = false,
    this.canMaintenance = false,
    this.canIdCard = false,
    this.canTayo = false,
    this.canTransfer = false,
    this.canServices = false,
    this.canKhoros = false,
    this.canBehavior = false,
    this.isAdvanced = false,
    this.granularPermissions = const {},
    this.visibilityFilters = const {},
    this.visibleUserIds = const [],
    this.dataVisibilityScope = const DataVisibilityScope(),
  });
}

String _normalizePermissionFeatureKey(String key) {
  return key == 'absence' ? 'attendance' : key;
}

@Riverpod(keepAlive: true)
class UsersRepository extends _$UsersRepository {
  @override
  FutureOr<List<UserModel>> build() async {
    ref.watch(domainRevisionProvider(DataDomain.access));

    // Watch auth service but skip manual refresh invalidation logic by checking state
    final auth = ref.watch(authServiceProvider);
    if (auth.isLoading && !auth.hasValue) return [];

    return _fetchUsers();
  }

  Future<List<UserModel>> _fetchUsers() async {
    final db = ref.read(appDatabaseProvider);
    final users = await db.select(db.pass).get();

    // Four reads for the entire list, independent of the number of users.
    final permissions = await db.select(db.userPermissionsExt).get();
    final filters = await db.select(db.userVisibilityFilters).get();
    final scopes = await (db.select(
      db.settings,
    )..where((t) => t.settingKey.like('user_data_scope_%'))).get();
    final permissionsByUser = <int, List<UserPermissionsExtData>>{};
    final filtersByUser = <int, List<UserVisibilityFilter>>{};
    for (final row in permissions) {
      permissionsByUser.putIfAbsent(row.userId, () => []).add(row);
    }
    for (final row in filters) {
      filtersByUser.putIfAbsent(row.userId, () => []).add(row);
    }
    final scopesByKey = {for (final row in scopes) row.settingKey: row};
    final List<UserModel> list = [];
    for (final u in users) {
      final granularPerms = _mapGranularPermissions(
        permissionsByUser[u.passId] ?? [],
      );
      final visFilters = _mapVisibilityFilters(filtersByUser[u.passId] ?? []);
      final scopeRow = scopesByKey[DataVisibilityScope.storageKey(u.passId)];

      list.add(
        UserModel(
          id: u.passId,
          username: u.personName ?? '',
          password: u.passWord ?? '',
          canPersons: u.canPersons ?? false,
          canStages: u.canStages ?? false,
          canAreas: u.canAreas ?? false,
          canFathers: u.canFathers ?? false,
          canReports: u.canReports ?? false,
          canUsers: u.canUsers ?? false,
          canAbsence: u.canAbsence ?? false,
          canMaintenance: u.canMaintenance ?? false,
          canIdCard: u.canIdCard ?? false,
          canTayo: u.canTayo ?? false,
          canTransfer: u.canTransfer ?? false,
          canServices: u.canServices ?? false,
          canKhoros: u.canKhoros ?? false,
          canBehavior: u.canBehavior ?? false,
          isAdvanced: u.isAdvanced ?? false,
          granularPermissions: granularPerms,
          visibilityFilters: visFilters,
          visibleUserIds: visFilters['user'] ?? [],
          dataVisibilityScope: scopeRow == null
              ? DataVisibilityScope.fromLegacy(visFilters)
              : DataVisibilityScope.decode(scopeRow.settingValue),
        ),
      );
    }

    // Apply visibility filtering if the current user is not a super-admin (or has filters)
    final currentUser = ref.read(authServiceProvider).value;
    if (currentUser != null && currentUser.isAdvanced) {
      final allowedIds = currentUser.visibilityFilters['user'];
      if (allowedIds != null && allowedIds.isNotEmpty) {
        // Only show users whose IDs are in the allowed list, OR show the user themselves
        return list
            .where((u) => allowedIds.contains(u.id) || u.id == currentUser.id)
            .toList();
      }
    }

    return list;
  }

  Map<String, Map<String, bool>> _mapGranularPermissions(
    List<UserPermissionsExtData> permissions,
  ) {
    final map = <String, Map<String, bool>>{};
    for (final p in permissions) {
      final featureKey = _normalizePermissionFeatureKey(p.featureKey);
      final current =
          map[featureKey] ??
          const {'add': false, 'edit': false, 'delete': false};
      map[featureKey] = {
        'add': current['add']! || p.canAdd,
        'edit': current['edit']! || p.canEdit,
        'delete': current['delete']! || p.canDelete,
      };
    }
    return map;
  }

  Map<String, List<int>> _mapVisibilityFilters(
    List<UserVisibilityFilter> filters,
  ) {
    final map = <String, List<int>>{};
    for (final f in filters) {
      map.putIfAbsent(f.filterType, () => []).add(f.valueId);
    }
    return map;
  }

  Future<bool> addUser(
    String username,
    String password, {
    bool canPersons = false,
    bool canStages = false,
    bool canAreas = false,
    bool canFathers = false,
    bool canReports = false,
    bool canUsers = false,
    bool canAbsence = false,
    bool canMaintenance = false,
    bool canIdCard = false,
    bool canTayo = false,
    bool canTransfer = false,
    bool canServices = false,
    bool canKhoros = false,
    bool canBehavior = false,
    bool isAdvanced = false,
    Map<String, Map<String, bool>> granularPermissions = const {},
    Map<String, List<int>> visibilityFilters = const {},
    DataVisibilityScope dataVisibilityScope = const DataVisibilityScope(),
  }) async {
    final db = ref.read(appDatabaseProvider);

    // Check if user already exists
    final exists = await (db.select(
      db.pass,
    )..where((t) => t.personName.equals(username))).getSingleOrNull();
    if (exists != null) return false;

    await db.transaction(() async {
      final userId = await db
          .into(db.pass)
          .insert(
            PassCompanion.insert(
              personName: drift.Value(username),
              passWord: drift.Value(password),
              canPersons: drift.Value(canPersons),
              canStages: drift.Value(canStages),
              canAreas: drift.Value(canAreas),
              canFathers: drift.Value(canFathers),
              canReports: drift.Value(canReports),
              canUsers: drift.Value(canUsers),
              canAbsence: drift.Value(canAbsence),
              canMaintenance: drift.Value(canMaintenance),
              canIdCard: drift.Value(canIdCard),
              canTayo: drift.Value(canTayo),
              canTransfer: drift.Value(canTransfer),
              canServices: drift.Value(canServices),
              canKhoros: drift.Value(canKhoros),
              canBehavior: drift.Value(canBehavior),
              isAdvanced: drift.Value(isAdvanced),
            ),
          );

      // Save granular permissions
      await db
          .into(db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion(
              settingKey: drift.Value(DataVisibilityScope.storageKey(userId)),
              settingValue: drift.Value(
                jsonEncode(dataVisibilityScope.toJson()),
              ),
            ),
          );
      await db.batch((batch) {
        batch.insertAll(db.userPermissionsExt, [
          for (final feature in granularPermissions.keys)
            UserPermissionsExtCompanion.insert(
              userId: userId,
              featureKey: feature,
              canAdd: drift.Value(
                granularPermissions[feature]!['add'] ?? false,
              ),
              canEdit: drift.Value(
                granularPermissions[feature]!['edit'] ?? false,
              ),
              canDelete: drift.Value(
                granularPermissions[feature]!['delete'] ?? false,
              ),
            ),
        ]);
        batch.insertAll(db.userVisibilityFilters, [
          for (final entry in visibilityFilters.entries)
            for (final value in entry.value)
              UserVisibilityFiltersCompanion.insert(
                userId: userId,
                filterType: entry.key,
                valueId: value,
              ),
        ]);
      });
    });

    if (ref.mounted) ref.invalidateSelf();
    return true;
  }

  Future<bool> updateUser(
    int id,
    String newUsername,
    String newPassword, {
    bool? canPersons,
    bool? canStages,
    bool? canAreas,
    bool? canFathers,
    bool? canReports,
    bool? canUsers,
    bool? canAbsence,
    bool? canMaintenance,
    bool? canIdCard,
    bool? canTayo,
    bool? canTransfer,
    bool? canServices,
    bool? canKhoros,
    bool? canBehavior,
    bool? isAdvanced,
    Map<String, Map<String, bool>>? granularPermissions,
    Map<String, List<int>>? visibilityFilters,
    DataVisibilityScope? dataVisibilityScope,
  }) async {
    final db = ref.read(appDatabaseProvider);

    // Check if new username already exists for a different ID
    final exists =
        await (db.select(db.pass)..where(
              (t) => t.personName.equals(newUsername) & t.passId.isNotValue(id),
            ))
            .getSingleOrNull();
    if (exists != null) return false;

    await db.transaction(() async {
      if (dataVisibilityScope != null) {
        await db
            .into(db.settings)
            .insertOnConflictUpdate(
              SettingsCompanion(
                settingKey: drift.Value(DataVisibilityScope.storageKey(id)),
                settingValue: drift.Value(
                  jsonEncode(dataVisibilityScope.toJson()),
                ),
              ),
            );
      }
      await (db.update(db.pass)..where((t) => t.passId.equals(id))).write(
        PassCompanion(
          personName: drift.Value(newUsername),
          passWord: drift.Value(newPassword),
          canPersons: canPersons != null
              ? drift.Value(canPersons)
              : const drift.Value.absent(),
          canStages: canStages != null
              ? drift.Value(canStages)
              : const drift.Value.absent(),
          canAreas: canAreas != null
              ? drift.Value(canAreas)
              : const drift.Value.absent(),
          canFathers: canFathers != null
              ? drift.Value(canFathers)
              : const drift.Value.absent(),
          canReports: canReports != null
              ? drift.Value(canReports)
              : const drift.Value.absent(),
          canUsers: canUsers != null
              ? drift.Value(canUsers)
              : const drift.Value.absent(),
          canAbsence: canAbsence != null
              ? drift.Value(canAbsence)
              : const drift.Value.absent(),
          canMaintenance: canMaintenance != null
              ? drift.Value(canMaintenance)
              : const drift.Value.absent(),
          canIdCard: canIdCard != null
              ? drift.Value(canIdCard)
              : const drift.Value.absent(),
          canTayo: canTayo != null
              ? drift.Value(canTayo)
              : const drift.Value.absent(),
          canTransfer: canTransfer != null
              ? drift.Value(canTransfer)
              : const drift.Value.absent(),
          canServices: canServices != null
              ? drift.Value(canServices)
              : const drift.Value.absent(),
          canKhoros: canKhoros != null
              ? drift.Value(canKhoros)
              : const drift.Value.absent(),
          canBehavior: canBehavior != null
              ? drift.Value(canBehavior)
              : const drift.Value.absent(),
          isAdvanced: isAdvanced != null
              ? drift.Value(isAdvanced)
              : const drift.Value.absent(),
        ),
      );

      await db.batch((batch) {
        if (granularPermissions != null) {
          batch.deleteWhere(db.userPermissionsExt, (t) => t.userId.equals(id));
          batch.insertAll(db.userPermissionsExt, [
            for (final entry in granularPermissions.entries)
              UserPermissionsExtCompanion.insert(
                userId: id,
                featureKey: entry.key,
                canAdd: drift.Value(entry.value['add'] ?? false),
                canEdit: drift.Value(entry.value['edit'] ?? false),
                canDelete: drift.Value(entry.value['delete'] ?? false),
              ),
          ]);
        }
        if (visibilityFilters != null) {
          batch.deleteWhere(
            db.userVisibilityFilters,
            (t) => t.userId.equals(id),
          );
          batch.insertAll(db.userVisibilityFilters, [
            for (final entry in visibilityFilters.entries)
              for (final value in entry.value)
                UserVisibilityFiltersCompanion.insert(
                  userId: id,
                  filterType: entry.key,
                  valueId: value,
                ),
          ]);
        }
      });
    });

    if (ref.mounted) ref.invalidateSelf();
    return true;
  }

  Future<bool> deleteUser(int id) async {
    final db = ref.read(appDatabaseProvider);
    await (db.delete(db.pass)..where((t) => t.passId.equals(id))).go();
    if (ref.mounted) ref.invalidateSelf();
    return true;
  }
}
