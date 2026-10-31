import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart';
import '../database/database_provider.dart';
import '../sync/server_connection_service.dart';
import '../models/data_visibility_scope.dart';

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
  final DataVisibilityScope dataVisibilityScope;

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
    this.dataVisibilityScope = const DataVisibilityScope(),
  });

  String get sessionSignature => jsonEncode([
    id,
    username,
    canPersons,
    canStages,
    canAreas,
    canFathers,
    canReports,
    canUsers,
    canAbsence,
    canMaintenance,
    canIdCard,
    canTayo,
    canTransfer,
    canServices,
    canKhoros,
    canBehavior,
    isAdvanced,
    dataVisibilityScope.fingerprint,
    _canonicalUserData(granularPermissions),
    _canonicalUserData(visibilityFilters),
    [...visibleUserIds]..sort(),
  ]);

  factory User.fromServerJson(Map<String, dynamic> json) {
    final rawGranular =
        json['granularPermissions'] ?? json['GranularPermissions'];
    final granular = <String, Map<String, bool>>{};
    if (rawGranular is Map) {
      rawGranular.forEach((k, v) {
        if (v is Map) {
          final featureKey = _normalizePermissionFeatureKey(k.toString());
          granular[featureKey] = {
            'add': v['add'] == true,
            'edit': v['edit'] == true,
            'delete': v['delete'] == true,
          };
        }
      });
    }

    final rawFilters = json['visibilityFilters'] ?? json['VisibilityFilters'];
    final filters = <String, List<int>>{};
    if (rawFilters is Map) {
      rawFilters.forEach((k, v) {
        if (v is List) {
          filters[k.toString()] = v
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .toList();
        }
      });
    }

    final rawVisibleUsers = json['visibleUserIds'] ?? json['VisibleUserIds'];
    final visibleUsers = rawVisibleUsers is List
        ? rawVisibleUsers.map((e) => int.tryParse(e.toString()) ?? 0).toList()
        : (filters['user'] ?? <int>[]);

    return User(
      id: (json['id'] ?? json['Id'] ?? 0) as int,
      username: (json['username'] ?? json['Username'] ?? '').toString(),
      canPersons: json['canPersons'] == true,
      canStages: json['canStages'] == true,
      canAreas: json['canAreas'] == true,
      canFathers: json['canFathers'] == true,
      canReports: json['canReports'] == true,
      canUsers: json['canUsers'] == true,
      canAbsence: json['canAbsence'] == true,
      canMaintenance: json['canMaintenance'] == true,
      canIdCard: json['canIdCard'] == true,
      canTayo: json['canTayo'] == true,
      canTransfer: json['canTransfer'] == true,
      canServices: json['canServices'] == true,
      canKhoros: json['canKhoros'] == true,
      canBehavior: json['canBehavior'] == true,
      isAdvanced: json['isAdvanced'] == true,
      granularPermissions: granular,
      visibilityFilters: filters,
      visibleUserIds: visibleUsers,
      dataVisibilityScope: DataVisibilityScope.fromJson(
        json['dataVisibilityScope'],
      ),
    );
  }
}

Object? _canonicalUserData(Object? value) {
  if (value is Map<String, dynamic>) {
    final keys = value.keys.toList()..sort();
    return {for (final key in keys) key: _canonicalUserData(value[key])};
  }
  if (value is List<int>) return [...value]..sort();
  return value;
}

String _normalizePermissionFeatureKey(String key) {
  return key == 'absence' ? 'attendance' : key;
}

@riverpod
class AuthService extends _$AuthService {
  @override
  FutureOr<User?> build() async {
    ref.watch(
      serverConfigProvider.select((c) => (c.isServerMode, c.normalizedBaseUrl)),
    );
    ref.listen(serverConfigProvider.select((c) => c.jwtToken), (
      previous,
      next,
    ) {
      if (previous != null && next == null) state = const AsyncValue.data(null);
    });
    return null;
  }

  Future<bool> login(String userName, String password) async {
    state = const AsyncValue.loading();

    try {
      final serverCfg = ref.read(serverConfigProvider);
      if (serverCfg.isServerMode) {
        final uri = Uri.parse('${serverCfg.normalizedBaseUrl}/api/auth/login');
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'X-Device-Id': serverCfg.deviceId,
              },
              body: jsonEncode({
                'username': userName,
                'password': password,
                'deviceId': serverCfg.deviceId,
              }),
            )
            .timeout(const Duration(seconds: 12));

        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final isSuccess =
            decoded is Map<String, dynamic> &&
            (decoded['ok'] == true ||
                decoded['Ok'] == true ||
                decoded['success'] == true ||
                decoded['Success'] == true);

        if (response.statusCode == 200 && isSuccess && decoded['user'] is Map) {
          final token = decoded['token']?.toString();
          await ref.read(serverConfigProvider.notifier).setJwtToken(token);
          final userObj = User.fromServerJson(
            Map<String, dynamic>.from(decoded['user'] as Map),
          );
          state = AsyncValue.data(userObj);
          return true;
        } else {
          state = const AsyncValue.data(null);
          return false;
        }
      }

      final db = ref.read(appDatabaseProvider);

      // Look up user in the Pass table
      final query = db.select(db.pass)
        ..where((t) => t.personName.equals(userName));
      final user = await query.getSingleOrNull();

      if (user != null && user.passWord == password) {
        state = AsyncValue.data(
          User(
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
            isAdvanced: user.isAdvanced,
            dataVisibilityScope: await _fetchDataScope(db, user.passId),
            granularPermissions: await _fetchGranularPermissions(
              db,
              user.passId,
            ),
            visibilityFilters: await _fetchVisibilityFilters(db, user.passId),
            visibleUserIds: await _fetchVisibilityFilters(
              db,
              user.passId,
            ).then((m) => m['user'] ?? []),
          ),
        );
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

  Future<Map<String, Map<String, bool>>> _fetchGranularPermissions(
    AppDatabase db,
    int userId,
  ) async {
    final permissions = await (db.select(
      db.userPermissionsExt,
    )..where((t) => t.userId.equals(userId))).get();
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

  Future<Map<String, List<int>>> _fetchVisibilityFilters(
    AppDatabase db,
    int userId,
  ) async {
    final filters = await (db.select(
      db.userVisibilityFilters,
    )..where((t) => t.userId.equals(userId))).get();
    final map = <String, List<int>>{};
    for (final f in filters) {
      map.putIfAbsent(f.filterType, () => []).add(f.valueId);
    }
    return map;
  }

  Future<DataVisibilityScope> _fetchDataScope(
    AppDatabase db,
    int userId,
  ) async {
    final row =
        await (db.select(db.settings)..where(
              (t) =>
                  t.settingKey.equals(DataVisibilityScope.storageKey(userId)),
            ))
            .getSingleOrNull();
    return row == null
        ? DataVisibilityScope.fromLegacy(
            await _fetchVisibilityFilters(db, userId),
          )
        : DataVisibilityScope.decode(row.settingValue);
  }

  void logout() {
    state = const AsyncValue.data(null);
    if (ref.read(serverConfigProvider).isServerMode) {
      unawaited(ref.read(serverConfigProvider.notifier).setJwtToken(null));
    }
  }

  Future<void>? _refreshInFlight;
  bool _refreshRequested = false;

  /// Coalesce concurrent sync events and only publish changed session data.
  Future<void> refreshUser() {
    if (!ref.mounted) return Future.value();
    if (_refreshInFlight != null) {
      _refreshRequested = true;
      return _refreshInFlight!;
    }
    final completion = Completer<void>();
    _refreshInFlight = completion.future;
    unawaited(() async {
      try {
        do {
          _refreshRequested = false;
          await _refreshUserOnce();
        } while (_refreshRequested && ref.mounted);
      } finally {
        _refreshInFlight = null;
        completion.complete();
      }
    }());
    return completion.future;
  }

  Future<void> _refreshUserOnce() async {
    if (!ref.mounted) return;
    final currentUser = state.value;
    if (currentUser == null) return;
    final db = ref.read(appDatabaseProvider);
    bool stillCurrent() =>
        ref.mounted &&
        identical(state.value, currentUser) &&
        identical(ref.read(appDatabaseProvider), db);
    try {
      final userRow = await (db.select(
        db.pass,
      )..where((t) => t.passId.equals(currentUser.id))).getSingleOrNull();
      if (!stillCurrent()) return;
      if (userRow == null) {
        logout();
        return;
      }
      final permissionsFuture = _fetchGranularPermissions(db, userRow.passId);
      final filtersFuture = _fetchVisibilityFilters(db, userRow.passId);
      final scopeFuture =
          (db.select(db.settings)..where(
                (t) => t.settingKey.equals(
                  DataVisibilityScope.storageKey(userRow.passId),
                ),
              ))
              .getSingleOrNull();
      final results = await Future.wait<dynamic>([
        permissionsFuture,
        filtersFuture,
        scopeFuture,
      ]);
      if (!stillCurrent()) return;
      final permissions = results[0] as Map<String, Map<String, bool>>;
      final filters = results[1] as Map<String, List<int>>;
      final scope = results[2] as Setting?;
      final updated = User(
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
        isAdvanced: userRow.isAdvanced,
        dataVisibilityScope: scope == null
            ? DataVisibilityScope.fromLegacy(filters)
            : DataVisibilityScope.decode(scope.settingValue),
        granularPermissions: permissions,
        visibilityFilters: filters,
        visibleUserIds: filters['user'] ?? [],
      );
      if (updated.sessionSignature != currentUser.sessionSignature) {
        state = AsyncValue.data(updated);
      }
    } catch (error) {
      // Preserve the active session on a transient read failure. Sync/reconnect
      // will request another refresh; an explicit logout still clears it.
    }
  }
}

// A failed initial load stays actionable instead of repeatedly replacing the
// username field with Riverpod's automatic retry/loading cycle.
Duration? _noLoginUsersRetry(int retryCount, Object error) => null;

@Riverpod(retry: _noLoginUsersRetry)
Future<List<User>> allUsers(Ref ref) async {
  try {
    // This public endpoint only depends on the data source, not JWT changes.
    final source = ref.watch(
      serverConfigProvider.select((c) => (c.isServerMode, c.normalizedBaseUrl)),
    );
    if (source.$1) {
      final response = await http
          .get(Uri.parse('${source.$2}/api/auth/users'))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) throw StateError('تعذر تحميل المستخدمين');
      final rows = jsonDecode(utf8.decode(response.bodyBytes));
      if (rows is! List) throw StateError('استجابة قائمة المستخدمين غير صحيحة');
      return rows
          .whereType<Map>()
          .map((r) => User.fromServerJson(Map<String, dynamic>.from(r)))
          .toList();
    }
    final db = ref.watch(appDatabaseProvider);
    // Explicitly watch auth state so we rebuild when it changes
    final authState = ref.watch(authServiceProvider);

    final users = await db.select(db.pass).get();

    final list = users
        .map(
          (u) => User(
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
            isAdvanced: u.isAdvanced,
          ),
        )
        .toList();

    final currentUser = authState.value;
    if (currentUser != null && currentUser.isAdvanced) {
      final allowedIds = currentUser.visibilityFilters['user'];
      if (allowedIds != null && allowedIds.isNotEmpty) {
        return list
            .where((u) => allowedIds.contains(u.id) || u.id == currentUser.id)
            .toList();
      }
    }
    return list;
  } catch (e, st) {
    print('Error fetching users: $e');
    print(st);
    rethrow;
  }
}
