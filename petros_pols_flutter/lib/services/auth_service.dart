import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database.dart';
import '../database/database_provider.dart';

part 'auth_service.g.dart';

class User {
  final int id;
  final String username;
  
  User({required this.id, required this.username});
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
        state = AsyncValue.data(User(id: user.passId ?? 0, username: user.personName ?? ''));
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

  void logout() {
    state = const AsyncValue.data(null);
  }
}

@riverpod
Future<List<User>> allUsers(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  final users = await db.select(db.pass).get();
  return users.map((u) => User(id: u.passId ?? 0, username: u.personName ?? '')).toList();
}
