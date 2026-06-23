import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

class GroupedPdfExportResult {
  const GroupedPdfExportResult({
    required this.writtenFiles,
    required this.skippedGroups,
  });

  final List<String> writtenFiles;
  final List<String> skippedGroups;
}

class GroupedPdfExportService {
  static final RegExp _unsafeFileChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');

  static String safeFileName(String value, {String fallback = 'group'}) {
    final collapsed = value
        .trim()
        .replaceAll(_unsafeFileChars, '_')
        .replaceAll(RegExp(r'\s+'), ' ');
    final withoutTrailingDots = collapsed.replaceAll(RegExp(r'[. ]+$'), '');
    if (withoutTrailingDots.isEmpty) return fallback;
    return withoutTrailingDots.length > 80
        ? withoutTrailingDots.substring(0, 80).trim()
        : withoutTrailingDots;
  }

  static Future<String> uniquePdfPath({
    required String directoryPath,
    required String baseName,
  }) async {
    final safeBase = safeFileName(baseName);
    var candidate = p.join(directoryPath, '$safeBase.pdf');
    var index = 2;
    while (await File(candidate).exists()) {
      candidate = p.join(directoryPath, '$safeBase ($index).pdf');
      index++;
    }
    return candidate;
  }

  static Future<GroupedPdfExportResult> writeGroups<T>({
    required Map<String, List<T>> groups,
    required String directoryPath,
    required String baseName,
    required Future<Uint8List> Function(String groupName, List<T> rows)
        buildPdf,
  }) async {
    final written = <String>[];
    final skipped = <String>[];
    for (final entry in groups.entries) {
      if (entry.value.isEmpty) {
        skipped.add(entry.key);
        continue;
      }

      final path = await uniquePdfPath(
        directoryPath: directoryPath,
        baseName: '${baseName}_${safeFileName(entry.key)}',
      );
      final bytes = await buildPdf(entry.key, entry.value);
      await File(path).writeAsBytes(bytes, flush: true);
      written.add(path);
    }

    return GroupedPdfExportResult(
      writtenFiles: written,
      skippedGroups: skipped,
    );
  }
}
