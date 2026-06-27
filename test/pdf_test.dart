import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/services/attendance_grid_pdf_generator.dart';
import 'package:petros_pols_flutter/services/attendance_report_service.dart';
import 'package:petros_pols_flutter/repositories/attendance_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const printingChannel = MethodChannel('net.nfet.printing');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(printingChannel, (call) async {
      return 1;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(printingChannel, null);
  });

  test(
    'generate grid pdf',
    () async {
      final data = [
        AttendanceDTO(personId: 1, personName: 'Test Person', dateWeek: '2024-03-15')
      ];
      await AttendanceGridPdfGenerator.generateAndPrintGridPDF(
        data: data,
        title: 'Test Grid',
        headerData: {'Test': 'Value'},
        sortingCriteria: [],
        columns: [{'id': 'name', 'title': 'Name'}],
      );
    },
    skip: 'Requires native printing integration outside flutter_test.',
  );

  test(
    'generate list pdf',
    () async {
      final data = [
        AttendanceDTO(personId: 1, personName: 'Test Person', dateWeek: '2024-03-15')
      ];
      await AttendanceReportService.generateAndPrintPDF(
        data: data,
        sortingCriteria: [],
        columns: [{'id': 'name', 'title': 'Name'}],
      );
    },
    skip: 'Requires native printing integration outside flutter_test.',
  );
}
