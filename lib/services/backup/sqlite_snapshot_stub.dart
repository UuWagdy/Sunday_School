Future<void> createSqliteBackup(String source, String target) async {
  throw UnsupportedError('Local SQLite snapshot is not supported on Web.');
}

Future<void> ensureSchemaCompatibility(String dbPath) async {
  // No-op on Web / Server mode
}
