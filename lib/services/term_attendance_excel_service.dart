import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../repositories/term_attendance_repository.dart';

class TermAttendanceExcelService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  static Future<String?> exportReport(
    TermAttendanceReport report, {
    bool includeKhorosName = false,
    bool includeKhorosCode = false,
    bool includeStageName = false,
    bool includeStageCode = false,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['تقفيل حضور الترم'];
    excel.delete('Sheet1');

    sheet.appendRow([
      TextCellValue('تقفيل حضور الترم'),
      TextCellValue(
        'من ${_dateFormat.format(report.startDate)} إلى ${_dateFormat.format(report.endDate)}',
      ),
      TextCellValue('درجة الحضور من ${_formatNumber(report.maxGrade)}'),
      TextCellValue('درجة اليوم من ${_formatNumber(report.dayMaxGrade)}'),
      if (report.addBehavior) TextCellValue('مضاف إليها السلوك'),
    ]);
    sheet.appendRow([
      TextCellValue('الخدمات'),
      TextCellValue(
        report.services.map((service) => service.serviceName ?? '').join('، '),
      ),
    ]);
    sheet.appendRow([]);

    final headers = [
      TextCellValue('كود الطالب'),
      TextCellValue('اسم الطالب'),
      if (includeStageCode) TextCellValue('كود المرحلة'),
      if (includeStageName) TextCellValue('اسم المرحلة'),
      if (includeKhorosCode) TextCellValue('كود الخورس'),
      if (includeKhorosName) TextCellValue('اسم الخورس'),
      ...report.meetings.map(
        (meeting) => TextCellValue(_meetingLabel(meeting)),
      ),
      TextCellValue('الحضور'),
      TextCellValue('مجموع النقاط'),
    ];
    if (report.addBehavior) {
      headers.add(TextCellValue('متوسط السلوك'));
    }
    headers.add(TextCellValue('المجموع'));
    sheet.appendRow(headers);

    for (final student in report.students) {
      final row = <CellValue>[
        IntCellValue(student.personId),
        TextCellValue(student.personName),
        if (includeStageCode)
          student.stageId != null
              ? IntCellValue(student.stageId!)
              : TextCellValue(''),
        if (includeStageName) TextCellValue(student.stageName),
        if (includeKhorosCode)
          student.khorosId != null
              ? IntCellValue(student.khorosId!)
              : TextCellValue(''),
        if (includeKhorosName) TextCellValue(student.khorosName),
        ...report.meetings.map((meeting) {
          if (!student.serviceIds.contains(meeting.serviceId)) {
            return TextCellValue('');
          }
          final attended = student.attendedKeys.contains(meeting.key);
          if (attended) {
            final pt = student.dailyPoints[meeting.key] ?? 0;
            return TextCellValue('✓ ($pt/${_formatNumber(report.dayMaxGrade)})');
          }
          return TextCellValue('');
        }),
        TextCellValue('${_formatNumber(_roundGrade(student.attendanceGrade))} (${_formatNumber(_roundGrade(student.attendancePercentage))}%)'),
        IntCellValue(student.totalDailyPoints),
      ];
      if (report.addBehavior) {
        row.add(DoubleCellValue(_roundGrade(student.averageBehavior)));
      }
      row.add(DoubleCellValue(_roundGrade(student.grade)));
      sheet.appendRow(row);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('تعذر إنشاء ملف الإكسل');
    }

    final fileName =
        'term_attendance_${_dateFormat.format(report.startDate)}_${_dateFormat.format(report.endDate)}.xlsx';
    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان حفظ ملف تقفيل حضور الترم',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      bytes: Uint8List.fromList(bytes),
    );

    if (outputFile != null) {
      final file = File(outputFile);
      if (!await file.exists()) {
        await file.writeAsBytes(bytes);
      }
    }
    return outputFile;
  }

  static String _meetingLabel(TermAttendanceMeeting meeting) {
    return '${_dateFormat.format(meeting.date)}\n${meeting.serviceName}';
  }

  static double _roundGrade(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  static String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}
