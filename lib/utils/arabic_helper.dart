import 'package:drift/drift.dart' as drift;

/// Normalizes Arabic text in-memory for Google-like search matching.
/// - maps: أ, إ, آ, ا -> ا
/// - maps: ة, ه -> ه (at the end of words or generally)
/// - maps: ي, ى -> ي
/// - removes Arabic diacritics
String normalizeArabic(String input) {
  var text = input;
  
  // Normalize Alif
  text = text.replaceAll(RegExp(r'[أإآا]'), 'ا');
  
  // Normalize Yeh / Alef Maksura
  text = text.replaceAll(RegExp(r'[يى]'), 'ي');
  
  // Normalize Teh Marbuta / Heh
  text = text.replaceAll('ة', 'ه');
  
  // Remove diacritics (harakat)
  text = text.replaceAll(RegExp(r'[\u064B-\u065F]'), '');
  
  return text.trim().toLowerCase();
}

/// Normalizes a Drift SQL string expression for Google-like Arabic database search.
/// Generates nested SQLite REPLACE calls at runtime.
drift.Expression<String> normalizeArabicSql(drift.Expression<String> expr) {
  var current = expr;
  
  // Map of replacements to apply in SQLite
  final replacements = {
    'أ': 'ا',
    'إ': 'ا',
    'آ': 'ا',
    'ة': 'ه',
    'ى': 'ي',
  };
  
  for (final entry in replacements.entries) {
    current = drift.FunctionCallExpression<String>('REPLACE', [
      current,
      drift.Variable<String>(entry.key),
      drift.Variable<String>(entry.value),
    ]);
  }
  
  return current;
}
