import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart';
import '../database/database_provider.dart';

part 'auth_service.g.dart';

class User {
  final int id;
  final String username;
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
  final Map<String, Map<String, bool>> granularPermissions;
  final Map<String, List<int>> visibilityFilters;
  final List<int> visibleUserIds;
  
  User({
    required this.id,
    required this.username,
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

@riverpod
class AuthService extends _$AuthService {
  @override
  FutureOr<User?> build() async {
    return null;
  }

  Future<bool> login(String userName, String password) async {
    state = const AsyncValue.loading();
    
    try {
      final db = ref.read(appDatabaseProvider);
      
      // Look up user in the Pass table
      final query = db.select(db.pass)..where((t) => t.personName.equals(userName));
      final user = await query.getSingleOrNull();

      if (user != null && user.passWord == password) {
        state = AsyncValue.data(User(
          id: user.passId,
          username: user.personName ?? '',
          canPersons: user.canPersons ?? false,
          canStages: user.canStages ?? false,
          canAreas: user.canAreas ?? false,
          canFathers: user.canFathers ?? false,
          canReports: user.canReports ?? false,
          canUsers: user.canUsers ?? false,
          canAbsence: user.canAbsence ?? false,
          canMaintenance: user.canMaintenance ?? false,
          canIdCard: user.canIdCard ?? false,
          canTayo: user.canTayo ?? false,
          canTransfer: user.canTransfer ?? false,
          canServices: user.canServices ?? false,
          canKhoros: user.canKhoros ?? false,
          canBehavior: user.canBehavior ?? false,
          isAdvanced: user.isAdvanced ?? false,
          granularPermissions: await _fetchGranularPermissions(db, user.passId),
          visibilityFilters: await _fetchVisibilityFilters(db, user.passId),
          visibleUserIds: await _fetchVisibilityFilters(db, user.passId).then((m) => m['user'] ?? []),
        ));
        return true;
      } else {
        state = const AsyncValue.data(null);
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
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

  void logout() {
    state = const AsyncValue.data(null);
  }

  /// Refreshes the current user's data from the database without clearing the session.
  Future<void> refreshUser() async {
    final currentUser = state.value;
    if (currentUser == null) return;

    try {
      final db = ref.read(appDatabaseProvider);
      final query = db.select(db.pass)..where((t) => t.passId.equals(currentUser.id));
      final userRow = await query.getSingleOrNull();

      if (userRow != null) {
        state = AsyncValue.data(User(
          id: userRow.passId,
          username: userRow.personName ?? '',
          canPersons: userRow.canPersons ?? false,
          canStages: userRow.canStages ?? false,
          canAreas: userRow.canAreas ?? false,
          canFathers: userRow.canFathers ?? false,
          canReports: userRow.canReports ?? false,
          canUsers: userRow.canUsers ?? false,
          canAbsence: userRow.canAbsence ?? false,
          canMaintenance: userRow.canMaintenance ?? false,
          canIdCard: userRow.canIdCard ?? false,
          canTayo: userRow.canTayo ?? false,
          canTransfer: userRow.canTransfer ?? false,
          canServices: userRow.canServices ?? false,
          canKhoros: userRow.canKhoros ?? false,
          canBehavior: userRow.canBehavior ?? false,
          isAdvanced: userRow.isAdvanced ?? false,
          granularPermissions: await _fetchGranularPermissions(db, userRow.passId),
          visibilityFilters: await _fetchVisibilityFilters(db, userRow.passId),
          visibleUserIds: await _fetchVisibilityFilters(db, userRow.passId).then((m) => m['user'] ?? []),
        ));
      }
    } catch (e) {
      // ignore
    }
  }
}

@riverpod
Future<List<User>> allUsers(Ref ref) async {
  try {
    final db = ref.watch(appDatabaseProvider);
    // Explicitly watch auth state so we rebuild when it changes
    final authState = ref.watch(authServiceProvider);
    
    final users = await db.select(db.pass).get();
    
    final list = users.map((u) => User(
      id: u.passId,
      username: u.personName ?? '',
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
    )).toList();

    final currentUser = authState.value;
    if (currentUser != null && currentUser.isAdvanced) {
      final allowedIds = currentUser.visibilityFilters['user'];
      if (allowedIds != null && allowedIds.isNotEmpty) {
        return list.where((u) => allowedIds.contains(u.id) || u.id == currentUser.id).toList();
      }
    }
    return list;
  } catch (e, st) {
    print('Error fetching users: $e');
    print(st);
    rethrow;
  }
}
