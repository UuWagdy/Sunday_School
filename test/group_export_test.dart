import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/services/grouped_pdf_export_service.dart';

void main() {
  test('safeFileName preserves Arabic text and removes unsafe characters', () {
    expect(
      GroupedPdfExportService.safeFileName('مرحلة/أولى:اختبار*'),
      'مرحلة_أولى_اختبار_',
    );
    expect(GroupedPdfExportService.safeFileName('   ...   '), 'group');
  });

  test('writeGroups skips empty groups', () async {
    final tempDir = await Directory.systemTemp.createTemp('group_pdf_export_');
    addTearDown(() => tempDir.delete(recursive: true));

    final result = await GroupedPdfExportService.writeGroups<int>(
      groups: {
        'filled': [1],
        'empty': [],
      },
      directoryPath: tempDir.path,
      baseName: 'Report',
      buildPdf: (_, __) async => Uint8List.fromList([1, 2, 3]),
    );

    expect(result.writtenFiles, hasLength(1));
    expect(result.skippedGroups, ['empty']);
  });
}
