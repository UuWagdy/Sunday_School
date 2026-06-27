import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/models/card_template.dart';
import 'package:petros_pols_flutter/models/pdf_export_options.dart';
import 'package:petros_pols_flutter/repositories/attendance_repository.dart';
import 'package:petros_pols_flutter/repositories/persons_repository.dart';
import 'package:petros_pols_flutter/services/attendance_grid_pdf_generator.dart';
import 'package:petros_pols_flutter/services/attendance_report_service.dart';
import 'package:petros_pols_flutter/services/id_card_pdf_generator.dart';
import 'package:petros_pols_flutter/services/person_report_service.dart';
import 'package:petros_pols_flutter/services/pdf_generation_task.dart';

Future<void> _slowPdfTask(List<Object?> message) async {
  final reporter = PdfGenerationReporter(message[0] as SendPort);
  await Future<void>.delayed(const Duration(seconds: 5));
  reporter.complete(Uint8List.fromList([1]));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final person = PersonListDTO(
    id: 1,
    name: 'اختبار',
    stageName: 'المرحلة',
    khorosName: 'الخورس',
    areaName: 'المنطقة',
    phone: '123',
    mobile: '456',
    streetName: 'العنوان',
    fatherName: 'الأب',
  );

  final attendance = AttendanceDTO(
    id: 1,
    personId: 1,
    personName: 'اختبار',
    dateWeek: '2026-06-11',
    stageName: 'المرحلة',
    areaName: 'المنطقة',
  );

  test('generates person report in a background isolate', () async {
    final persons = List.generate(
      12,
      (index) => PersonListDTO(
        id: index + 1,
        name: 'اختبار ${index + 1}',
        stageName: person.stageName,
        khorosName: person.khorosName,
        areaName: person.areaName,
        phone: person.phone,
        mobile: person.mobile,
        streetName: person.streetName,
        fatherName: person.fatherName,
      ),
    );
    final task = await PersonReportService.startPDFGeneration(
      data: persons,
      sortingCriteria: const ['name'],
      columns: const [
        {'id': 'name', 'title': 'الاسم'},
      ],
    );
    final updates = <PdfGenerationProgress>[];
    final subscription = task.progress.listen(updates.add);
    final bytes = await task.result;
    await subscription.cancel();

    expect(bytes, isNotEmpty);
    expect(updates, isNotEmpty);
    expect(updates.first.current, 1);
    expect(updates.last.current, persons.length);
    expect(updates.last.total, persons.length);
  });

  test('generates attendance reports in a background isolate', () async {
    final listBytes = await AttendanceReportService.generatePDF(
      data: [attendance],
      sortingCriteria: const ['name'],
      columns: const [
        {'id': 'name', 'title': 'الاسم'},
      ],
    );
    final gridBytes = await AttendanceGridPdfGenerator.generateGridPDF(
      data: [attendance],
      title: 'الحضور',
      headerData: const {},
      sortingCriteria: const ['name'],
      columns: const [
        {'id': 'name', 'title': 'الاسم'},
      ],
    );

    expect(listBytes, isNotEmpty);
    expect(gridBytes, isNotEmpty);
  });

  test('pdf export options resolve orientation and stretch font size', () {
    const forcedLandscape = PdfExportOptions(
      orientation: PdfPageOrientationOption.landscape,
      stretchToFit: true,
    );
    const noStretch = PdfExportOptions(stretchToFit: false);

    expect(forcedLandscape.pageFormatForColumnCount(1).width, greaterThan(500));
    expect(
      forcedLandscape.fittedFontSize(
        16,
        baseSize: 8,
        comfortableColumnCount: 8,
      ),
      lessThan(8),
    );
    expect(
      noStretch.fittedFontSize(16, baseSize: 8, comfortableColumnCount: 8),
      8,
    );
  });

  test('generates ID cards with a transparent background image', () async {
    final logo = await rootBundle.load('assets/logo.png');
    final imageBytes = logo.buffer.asUint8List(
      logo.offsetInBytes,
      logo.lengthInBytes,
    );
    final persons = List.generate(
      11,
      (index) => PersonListDTO(
        id: index + 1,
        name: 'اختبار ${index + 1}',
        stageName: person.stageName,
        khorosName: person.khorosName,
        areaName: person.areaName,
        phone: person.phone,
        mobile: person.mobile,
        streetName: person.streetName,
        fatherName: person.fatherName,
      ),
    );
    final bytes = await IdCardPdfGenerator.generateCards(
      persons: persons,
      logoBytes: imageBytes,
      visibleFields: const {
        'name': true,
        'code': true,
        'stage': true,
        'area': true,
      },
      codeType: 'qr',
      cardsPerRow: 2,
      cardsPerCol: 5,
      printBackSide: true,
      backgroundBytes: imageBytes,
      backgroundOpacity: 0.25,
      backBackgroundBytes: imageBytes,
      backBackgroundOpacity: 0.35,
    );

    expect(bytes, isNotEmpty);
  });

  test('generates designed ID cards with template barcode options', () async {
    final template = CardTemplate.defaults().copyWith(
      barcode: const CardBarcodeElement(
        type: CardCodeType.qr,
        x: 0.62,
        y: 0.62,
        width: 0.18,
        height: 0.18,
        backgroundMode: CardBarcodeBackgroundMode.transparent,
      ),
      fixedTexts: const [
        CardFixedTextElement(
          text: 'خدمة ابتدائي',
          x: 0.08,
          y: 0.04,
          width: 0.60,
          height: 0.10,
        ),
      ],
    );

    final bytes = await IdCardPdfGenerator.generateCards(
      persons: [person],
      visibleFields: const {
        'name': true,
        'code': true,
      },
      codeType: 'barcode',
      cardsPerRow: 2,
      cardsPerCol: 5,
      template: template,
    );

    expect(bytes, isNotEmpty);
  });

  test('cancels a running PDF isolate', () async {
    final task = await PdfGenerationTask.start(_slowPdfTask, null);
    task.cancel();

    await expectLater(
      task.result,
      throwsA(isA<PdfGenerationCancelledException>()),
    );
  });
}
