import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../database/database_provider.dart';

part 'users_repository.g.dart';

class UserModel {
  final int id;
  final String username;
  final String password;

  UserModel({required this.id, required this.username, required this.password});
}

@riverpod
class UsersRepository extends _$UsersRepository {
  @override
  FutureOr<List<UserModel>> build() async {
    return _fetchUsers();
  }

  Future<List<UserModel>> _fetchUsers() async {
    final db = ref.read(appDatabaseProvider);
    final users = await db.select(db.pass).get();
    return users.map((u) => UserModel(
      id: u.passId ?? 0, 
      username: u.personName ?? '',
      password: u.passWord ?? '',
    )).toList();
  }

  Future<bool> addUser(String username, String password) async {
    final db = ref.read(appDatabaseProvider);
    
    // Check if user already exists
    final exists = await (db.select(db.pass)..where((t) => t.personName.equals(username))).getSingleOrNull();
    if (exists != null) return false;

    await db.into(db.pass).insert(PassCompanion.insert(
      personName: drift.Value(username),
      passWord: drift.Value(password),
    ));
    ref.invalidateSelf();
    return true;
  }

  Future<bool> updateUser(int id, String newUsername, String newPassword) async {
    final db = ref.read(appDatabaseProvider);
    
    // Check if new username already exists for a different ID
    final exists = await (db.select(db.pass)..where((t) => t.personName.equals(newUsername) & t.passId.isNotValue(id))).getSingleOrNull();
    if (exists != null) return false;

    await (db.update(db.pass)..where((t) => t.passId.equals(id))).write(PassCompanion(
      personName: drift.Value(newUsername),
      passWord: drift.Value(newPassword),
    ));
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
