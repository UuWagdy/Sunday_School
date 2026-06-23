import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../database/database_provider.dart';
import '../services/auth_service.dart';

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
  });
}

String _normalizePermissionFeatureKey(String key) {
  return key == 'absence' ? 'attendance' : key;
}

@Riverpod(keepAlive: true)
class UsersRepository extends _$UsersRepository {
  @override
  FutureOr<List<UserModel>> build() async {
    // Watch database changes
    ref.watch(appDatabaseProvider);
    
    // Watch auth service but skip manual refresh invalidation logic by checking state
    final auth = ref.watch(authServiceProvider);
    if (auth.isLoading && !auth.hasValue) return []; 
    
    return _fetchUsers();
  }

  Future<List<UserModel>> _fetchUsers() async {
    final db = ref.read(appDatabaseProvider);
    final users = await db.select(db.pass).get();
    
    final List<UserModel> list = [];
    for (final u in users) {
      final granularPerms = await _fetchGranularPermissions(db, u.passId);
      final visFilters = await _fetchVisibilityFilters(db, u.passId);

      list.add(UserModel(
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
      ));
    }

    // Apply visibility filtering if the current user is not a super-admin (or has filters)
    final currentUser = ref.read(authServiceProvider).value;
    if (currentUser != null && currentUser.isAdvanced) {
      final allowedIds = currentUser.visibilityFilters['user'];
      if (allowedIds != null && allowedIds.isNotEmpty) {
        // Only show users whose IDs are in the allowed list, OR show the user themselves
        return list.where((u) => allowedIds.contains(u.id) || u.id == currentUser.id).toList();
      }
    }

    return list;
  }

  Future<Map<String, Map<String, bool>>> _fetchGranularPermissions(AppDatabase db, int userId) async {
    final permissions = await (db.select(db.userPermissionsExt)..where((t) => t.userId.equals(userId))).get();
    final map = <String, Map<String, bool>>{};
    for (final p in permissions) {
      final featureKey = _normalizePermissionFeatureKey(p.featureKey);
      final current = map[featureKey] ?? const {'add': false, 'edit': false, 'delete': false};
      map[featureKey] = {
        'add': current['add']! || p.canAdd,
        'edit': current['edit']! || p.canEdit,
        'delete': current['delete']! || p.canDelete,
      };
    }
    return map;
  }

  Future<Map<String, List<int>>> _fetchVisibilityFilters(AppDatabase db, int userId) async {
    final filters = await (db.select(db.userVisibilityFilters)..where((t) => t.userId.equals(userId))).get();
    final map = <String, List<int>>{};
    for (final f in filters) {
      map.putIfAbsent(f.filterType, () => []).add(f.valueId);
    }
    return map;
  }
  Future<bool> addUser(String username, String password, {
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
  }) async {
    final db = ref.read(appDatabaseProvider);
    
    // Check if user already exists
    final exists = await (db.select(db.pass)..where((t) => t.personName.equals(username))).getSingleOrNull();
    if (exists != null) return false;

    await db.transaction(() async {
      final userId = await db.into(db.pass).insert(PassCompanion.insert(
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
      ));

      // Save granular permissions
      for (final feature in granularPermissions.keys) {
        final p = granularPermissions[feature]!;
        await db.into(db.userPermissionsExt).insert(UserPermissionsExtCompanion.insert(
          userId: userId,
          featureKey: feature,
          canAdd: drift.Value(p['add'] ?? false),
          canEdit: drift.Value(p['edit'] ?? false),
          canDelete: drift.Value(p['delete'] ?? false),
        ));
      }

      // Save visibility filters
      for (final type in visibilityFilters.keys) {
        for (final valId in visibilityFilters[type]!) {
          await db.into(db.userVisibilityFilters).insert(UserVisibilityFiltersCompanion.insert(
            userId: userId,
            filterType: type,
            valueId: valId,
          ));
        }
      }
    });

    ref.invalidateSelf();
    return true;
  }
  Future<bool> updateUser(int id, String newUsername, String newPassword, {
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
  }) async {
    final db = ref.read(appDatabaseProvider);
    
    // Check if new username already exists for a different ID
    final exists = await (db.select(db.pass)..where((t) => t.personName.equals(newUsername) & t.passId.isNotValue(id))).getSingleOrNull();
    if (exists != null) return false;

    await db.transaction(() async {
      await (db.update(db.pass)..where((t) => t.passId.equals(id))).write(PassCompanion(
        personName: drift.Value(newUsername),
        passWord: drift.Value(newPassword),
        canPersons: canPersons != null ? drift.Value(canPersons) : const drift.Value.absent(),
        canStages: canStages != null ? drift.Value(canStages) : const drift.Value.absent(),
        canAreas: canAreas != null ? drift.Value(canAreas) : const drift.Value.absent(),
        canFathers: canFathers != null ? drift.Value(canFathers) : const drift.Value.absent(),
        canReports: canReports != null ? drift.Value(canReports) : const drift.Value.absent(),
        canUsers: canUsers != null ? drift.Value(canUsers) : const drift.Value.absent(),
        canAbsence: canAbsence != null ? drift.Value(canAbsence) : const drift.Value.absent(),
        canMaintenance: canMaintenance != null ? drift.Value(canMaintenance) : const drift.Value.absent(),
        canIdCard: canIdCard != null ? drift.Value(canIdCard) : const drift.Value.absent(),
        canTayo: canTayo != null ? drift.Value(canTayo) : const drift.Value.absent(),
        canTransfer: canTransfer != null ? drift.Value(canTransfer) : const drift.Value.absent(),
        canServices: canServices != null ? drift.Value(canServices) : const drift.Value.absent(),
        canKhoros: canKhoros != null ? drift.Value(canKhoros) : const drift.Value.absent(),
        canBehavior: canBehavior != null ? drift.Value(canBehavior) : const drift.Value.absent(),
        isAdvanced: isAdvanced != null ? drift.Value(isAdvanced) : const drift.Value.absent(),
      ));

      if (granularPermissions != null) {
        await (db.delete(db.userPermissionsExt)..where((t) => t.userId.equals(id))).go();
        for (final feature in granularPermissions.keys) {
          final p = granularPermissions[feature]!;
          await db.into(db.userPermissionsExt).insert(UserPermissionsExtCompanion.insert(
            userId: id,
            featureKey: feature,
            canAdd: drift.Value(p['add'] ?? false),
            canEdit: drift.Value(p['edit'] ?? false),
            canDelete: drift.Value(p['delete'] ?? false),
          ));
        }
      }

      if (visibilityFilters != null) {
        await (db.delete(db.userVisibilityFilters)..where((t) => t.userId.equals(id))).go();
        for (final type in visibilityFilters.keys) {
          for (final valId in visibilityFilters[type]!) {
            await db.into(db.userVisibilityFilters).insert(UserVisibilityFiltersCompanion.insert(
              userId: id,
              filterType: type,
              valueId: valId,
            ));
          }
        }
      }
    });

    ref.invalidateSelf();
    return true;
  }

  Future<bool> deleteUser(int id) async {
    final db = ref.read(appDatabaseProvider);
    await (db.delete(db.pass)..where((t) => t.passId.equals(id))).go();
    ref.invalidateSelf();
    return true;
  }
}
