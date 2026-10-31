import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

Future<void> createSqliteBackup(String source, String target) =>
    compute(_snapshot, (source, target));
void _snapshot((String, String) paths) {
  if (!File(paths.$1).existsSync()) {
    throw StateError('قاعدة البيانات المحلية غير موجودة.');
  }
  final source = sqlite3.open(paths.$1, mode: OpenMode.readWrite);
  try {
    source.execute('PRAGMA busy_timeout = 10000');
    source.execute('VACUUM INTO ?', [paths.$2]);
  } finally {
    source.dispose();
  }
  final copy = sqlite3.open(paths.$2, mode: OpenMode.readOnly);
  try {
    if (copy.select('PRAGMA quick_check').first.values.first != 'ok') {
      throw StateError('فشل التحقق من سلامة النسخة.');
    }
  } finally {
    copy.dispose();
  }
}
