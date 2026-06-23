import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/persons_repository.dart';

class ExcelExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  static Future<String?> exportAttendanceList({
    required List<AttendanceDTO> data,
    required List<Map<String, String>> columns,
    Map<String, String>? headerData,
    Map<int, int>? serviceMinsMap,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['تقرير حضور القائمة'];
    excel.delete('Sheet1');

    // 1. Write Header Info (e.g. Filter Status, Khoros, Stage...)
    if (headerData != null && headerData.isNotEmpty) {
      sheet.appendRow([TextCellValue('معلومات التصفية')]);
      headerData.forEach((key, val) {
        sheet.appendRow([TextCellValue(key), TextCellValue(val)]);
      });
      sheet.appendRow([]);
    }

    // 2. Add Table Headers
    final headers = [
      TextCellValue('م'),
      ...columns.map((col) => TextCellValue(col['title']!)),
    ];
    sheet.appendRow(headers);

    // 3. Add Data Rows
    for (int i = 0; i < data.length; i++) {
      final r = data[i];
      final row = [
        IntCellValue(i + 1),
        ...columns.map((col) {
          switch (col['id']) {
            case 'name':
              return TextCellValue(r.personName ?? '');
            case 'id':
              return IntCellValue(r.personId ?? 0);
            case 'area':
              return TextCellValue(r.areaName ?? '');
            case 'stage':
              return TextCellValue(r.stageName ?? '');
            case 'father':
              return TextCellValue(r.fatherName ?? '');
            case 'mobile':
              return TextCellValue(r.mobile ?? '');
            case 'phone':
              return TextCellValue(r.phone ?? '');
            case 'address':
              return TextCellValue(r.address ?? '');
            case 'date':
              return TextCellValue(r.dateWeek ?? '');
            case 'points':
              return IntCellValue(r.point ?? 0);
            case 'time':
              return TextCellValue(r.attendTime ?? '');
            case 'checkout':
              return TextCellValue(r.checkoutTime ?? '');
            case 'earlyLate':
              if (r.serviceId != null &&
                  r.attendTime != null &&
                  serviceMinsMap != null &&
                  serviceMinsMap.containsKey(r.serviceId)) {
                try {
                  final parts = r.attendTime!.split(' ');
                  if (parts.length >= 2) {
                    final timeParts = parts[0].split(':');
                    int h = int.parse(timeParts[0]);
                    final int m = int.parse(timeParts[1]);
                    final isPm = parts[1] == 'م';
                    if (isPm && h < 12) h += 12;
                    if (!isPm && h == 12) h = 0;

                    final attendMins = h * 60 + m;
                    final serviceMins = serviceMinsMap[r.serviceId]!;
                    final diff = attendMins - serviceMins;

                    if (diff > 0) return TextCellValue('تأخير ${diff} ق');
                    if (diff < 0) return TextCellValue('تبكير ${diff.abs()} ق');
                    return TextCellValue('-');
                  }
                } catch (_) {}
              }
              return TextCellValue('');
            case 'service':
              return TextCellValue(r.serviceName ?? '');
            case 'visitNotes':
              return TextCellValue(r.visitNotes ?? '');
            default:
              return TextCellValue('');
          }
        }),
      ];
      sheet.appendRow(row);
    }

    return _saveExcelFile(excel, 'attendance_list');
  }

  static Future<String?> exportAttendanceGrid({
    required List<AttendanceDTO> data,
    required List<Map<String, String>> columns,
    required List<String> dates,
    Map<String, String>? headerData,
    Map<int, int>? serviceMinsMap,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['تقرير حضور الشبكة'];
    excel.delete('Sheet1');

    // 1. Write Header Info
    if (headerData != null && headerData.isNotEmpty) {
      sheet.appendRow([TextCellValue('معلومات التصفية')]);
      headerData.forEach((key, val) {
        sheet.appendRow([TextCellValue(key), TextCellValue(val)]);
      });
      sheet.appendRow([]);
    }

    // 2. Extract unique persons and map their attendance
    final Map<int, AttendanceDTO> personsMap = {};
    final Map<int, Set<String>> attendanceMap = {};

    for (var r in data) {
      if (r.personId != null) {
        if (!personsMap.containsKey(r.personId!)) {
          personsMap[r.personId!] = r;
        }
        if (!attendanceMap.containsKey(r.personId!)) {
          attendanceMap[r.personId!] = {};
        }
        if (r.dateWeek != null && r.id != null) {
          final s = r.serviceName?.trim() ?? '';
          attendanceMap[r.personId!]!.add('${r.dateWeek!}|$s');
        }
      }
    }
    final personIds = personsMap.keys.toList();

    // 3. Add Table Headers
    final headers = [
      TextCellValue('م'),
      ...columns.map((col) => TextCellValue(col['title']!)),
      ...dates.map((d) => TextCellValue(d.replaceAll('|', ' - '))),
      TextCellValue('الإجمالي'),
    ];
    sheet.appendRow(headers);

    // 4. Data Rows and calculation of totals
    final Map<String, int> dateTotals = {};
    int grandTotal = 0;

    for (int i = 0; i < personIds.length; i++) {
      final pid = personIds[i];
      final personRec = personsMap[pid]!;
      final atts = attendanceMap[pid]!;
      grandTotal += atts.length;

      final row = [
        IntCellValue(i + 1),
        ...columns.map((col) {
          String txt = '';
          switch (col['id']) {
            case 'name':
              txt = personRec.personName ?? '';
              break;
            case 'id':
              txt = personRec.personId?.toString() ?? '';
              break;
            case 'area':
              txt = personRec.areaName ?? '';
              break;
            case 'stage':
              txt = personRec.stageName ?? '';
              break;
            case 'father':
              txt = personRec.fatherName ?? '';
              break;
            case 'mobile':
              txt = personRec.mobile ?? '';
              break;
            case 'phone':
              txt = personRec.phone ?? '';
              break;
            case 'street':
            case 'address':
              txt = personRec.address ?? '';
              break;
            case 'date':
              txt = personRec.dateWeek ?? '';
              break;
            case 'points':
              txt = personRec.point?.toString() ?? '';
              break;
            case 'time':
              txt = personRec.attendTime ?? '';
              break;
            case 'checkout':
              txt = personRec.checkoutTime ?? '';
              break;
            case 'service':
              txt = personRec.serviceName ?? '';
              break;
            case 'visitNotes':
              txt = personRec.visitNotes ?? '';
              break;
          }
          return TextCellValue(txt);
        }),
        ...dates.map((d) {
          final attended = atts.contains(d);
          if (attended) {
            dateTotals[d] = (dateTotals[d] ?? 0) + 1;
            return TextCellValue('✓');
          }
          return TextCellValue('');
        }),
        IntCellValue(atts.length),
      ];
      sheet.appendRow(row);
    }

    // 5. Add Totals Row
    final totalsRow = [
      TextCellValue('الإجمالي'),
      ...columns.map((_) => TextCellValue('')),
      ...dates.map((d) => IntCellValue(dateTotals[d] ?? 0)),
      IntCellValue(grandTotal),
    ];
    sheet.appendRow(totalsRow);

    return _saveExcelFile(excel, 'attendance_grid');
  }

  static Future<String?> exportPersonsList({
    required List<PersonListDTO> data,
    required List<Map<String, String>> columns,
    Map<String, String>? headerData,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['تقرير قائمة الأشخاص'];
    excel.delete('Sheet1');

    // 1. Write Header Info
    if (headerData != null && headerData.isNotEmpty) {
      sheet.appendRow([TextCellValue('معلومات التصفية')]);
      headerData.forEach((key, val) {
        sheet.appendRow([TextCellValue(key), TextCellValue(val)]);
      });
      sheet.appendRow([]);
    }

    // 2. Add Table Headers
    final headers = [
      TextCellValue('م'),
      ...columns.map((col) => TextCellValue(col['title']!)),
    ];
    sheet.appendRow(headers);

    // 3. Add Data Rows
    for (int i = 0; i < data.length; i++) {
      final r = data[i];
      final row = [
        IntCellValue(i + 1),
        ...columns.map((col) {
          switch (col['id']) {
            case 'name':
              return TextCellValue(r.name);
            case 'id':
              return IntCellValue(r.id);
            case 'area':
              return TextCellValue(r.areaName);
            case 'stage':
              return TextCellValue(r.stageName);
            case 'father':
              return TextCellValue(r.fatherName);
            case 'khoros':
              return TextCellValue(r.khorosName);
            case 'mobile':
              return TextCellValue(r.mobile);
            case 'phone':
              return TextCellValue(r.phone);
            case 'address':
              return TextCellValue(r.streetName);
            case 'gender':
              return TextCellValue(r.jenderName ?? '');
            case 'birthday':
              return TextCellValue(
                (r.day != null && r.month != null)
                    ? '${r.year ?? ""}-${r.month}-${r.day}'
                    : '',
              );
            case 'relationship':
              return TextCellValue(r.relationship ?? '');
            default:
              return TextCellValue('');
          }
        }),
      ];
      sheet.appendRow(row);
    }

    return _saveExcelFile(excel, 'persons_list');
  }

  static Future<String?> _saveExcelFile(Excel excel, String baseName) async {
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('تعذر إنشاء ملف الإكسل');
    }

    final formattedDate = _dateFormat.format(DateTime.now());
    final fileName = '${baseName}_$formattedDate.xlsx';

    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان حفظ ملف الإكسل',
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
}
