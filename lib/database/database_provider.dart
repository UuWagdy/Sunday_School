import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../sync/dotnet_postgres_executor.dart';
import '../sync/server_connection_service.dart';
import 'database.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final modeAndUrl = ref.watch(
    serverConfigProvider.select((c) => (c.isServerMode, c.normalizedBaseUrl)),
  );
  final isServerMode = modeAndUrl.$1;

  final AppDatabase db;
  if (isServerMode) {
    db = AppDatabase.forTesting(
      DotNetPostgresQueryExecutor(
        getConfig: () => ref.read(serverConfigProvider),
        onUnauthorized: () {
          if (ref.mounted) {
            unawaited(
              ref.read(serverConfigProvider.notifier).setJwtToken(null),
            );
          }
        },
      ),
    );
    // PostgreSQL applies the authenticated user's scope at the server boundary.
    db.visibilityContext.applyLocally = false;
  } else {
    db = AppDatabase();
  }

  ref.onDispose(db.close);
  return db;
}
