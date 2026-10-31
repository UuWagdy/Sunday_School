import 'package:flutter/material.dart';

class AttendanceNotesDialogResult {
  final String? attendanceNotes;
  final String? checkoutNotes;
  final String? checkoutType; // 'parent' or 'bus'

  const AttendanceNotesDialogResult({
    this.attendanceNotes,
    this.checkoutNotes,
    this.checkoutType,
  });
}

class AttendanceNotesDialog extends StatefulWidget {
  final String personName;
  final int personId;
  final String? initialAttendanceNotes;
  final String? initialCheckoutNotes;
  final String? initialCheckoutType;
  final bool isPresent;
  final bool isCheckoutDone;

  const AttendanceNotesDialog({
    super.key,
    required this.personName,
    required this.personId,
    this.initialAttendanceNotes,
    this.initialCheckoutNotes,
    this.initialCheckoutType,
    this.isPresent = true,
    this.isCheckoutDone = false,
  });

  static Future<AttendanceNotesDialogResult?> show(
    BuildContext context, {
    required String personName,
    required int personId,
    String? initialAttendanceNotes,
    String? initialCheckoutNotes,
    String? initialCheckoutType,
    bool isPresent = true,
    bool isCheckoutDone = false,
  }) {
    return showDialog<AttendanceNotesDialogResult>(
      context: context,
      builder: (context) => AttendanceNotesDialog(
        personName: personName,
        personId: personId,
        initialAttendanceNotes: initialAttendanceNotes,
        initialCheckoutNotes: initialCheckoutNotes,
        initialCheckoutType: initialCheckoutType,
        isPresent: isPresent,
        isCheckoutDone: isCheckoutDone,
      ),
    );
  }

  @override
  State<AttendanceNotesDialog> createState() => _AttendanceNotesDialogState();
}

class _AttendanceNotesDialogState extends State<AttendanceNotesDialog> {
  late final TextEditingController _attendanceNotesController;
  late final TextEditingController _checkoutNotesController;
  late String _checkoutType;
  String? _checkoutError;

  @override
  void initState() {
    super.initState();
    _attendanceNotesController = TextEditingController(
      text: widget.initialAttendanceNotes ?? '',
    );
    _checkoutNotesController = TextEditingController(
      text: widget.initialCheckoutNotes ?? '',
    );
    final type = widget.initialCheckoutType?.toLowerCase();
    if (type == 'parent') {
      _checkoutType = 'parent';
    } else if (type == 'other') {
      _checkoutType = 'other';
    } else if (type == 'bus') {
      _checkoutType = 'bus';
    } else {
      _checkoutType = 'alone';
    }
  }

  @override
  void dispose() {
    _attendanceNotesController.dispose();
    _checkoutNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.note_alt_rounded, color: theme.primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.personName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'كود الطالب: ${widget.personId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Attendance Notes Field
                const Text(
                  'ملاحظات الحضور',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _attendanceNotesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'اكتب ملاحظات الحضور هنا...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.login_rounded, size: 18, color: Colors.green),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                // Checkout Notes Field
                Row(
                  children: [
                    const Text(
                      'ملاحظات / سبب الانصراف',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (_checkoutType == 'other') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.purple.shade300),
                        ),
                        child: Text(
                          'مطلوب كتابة السبب *',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _checkoutNotesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: _checkoutType == 'other'
                        ? 'اكتب سبب الانصراف هنا (إجباري عند اختيار آخر)...'
                        : 'اكتب ملاحظات الانصراف هنا...',
                    hintStyle: TextStyle(
                      color: _checkoutType == 'other' ? Colors.purple.shade300 : Colors.grey.shade400,
                      fontSize: 12,
                    ),
                    errorText: _checkoutError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: _checkoutType == 'other'
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.purple.shade700, width: 1.8),
                          )
                        : null,
                    prefixIcon: Icon(
                      _checkoutType == 'other' ? Icons.alt_route_rounded : Icons.logout_rounded,
                      size: 18,
                      color: _checkoutType == 'other' ? Colors.purple.shade700 : Colors.red,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) {
                    if (_checkoutError != null && val.trim().isNotEmpty) {
                      setState(() => _checkoutError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Dismissal Type Section (Bus vs Parent)
                const Text(
                  'طريقة الانصراف (المسار):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'alone',
                        groupValue: _checkoutType,
                        dense: true,
                        activeColor: Colors.teal.shade700,
                        title: Row(
                          children: [
                            Icon(Icons.directions_walk_rounded, size: 18, color: Colors.teal.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'انصراف بمفرده (الافتراضي)',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(right: 26, top: 4),
                          child: Text(
                            '💡 استبعاد الطالب تلقائياً من كشف وجدول الأتوبيس لهذا اليوم (ينصرف بمفرده)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.teal.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        onChanged: (val) => setState(() => _checkoutType = val ?? 'alone'),
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        value: 'bus',
                        groupValue: _checkoutType,
                        dense: true,
                        activeColor: theme.primaryColor,
                        title: const Row(
                          children: [
                            Icon(Icons.directions_bus_rounded, size: 18, color: Colors.indigo),
                            SizedBox(width: 8),
                            Text(
                              'أتوبيس (انصراف عادي مع الأتوبيس)',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        onChanged: (val) => setState(() => _checkoutType = val ?? 'bus'),
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        value: 'parent',
                        groupValue: _checkoutType,
                        dense: true,
                        activeColor: Colors.orange.shade800,
                        title: Row(
                          children: [
                            Icon(Icons.family_restroom_rounded, size: 18, color: Colors.orange.shade800),
                            const SizedBox(width: 8),
                            const Text(
                              'انصراف لولي الأمر (مع الأهل مباشرة)',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(right: 26, top: 4),
                          child: Text(
                            '💡 استبعاد الطالب تلقائياً من كشف وجدول الأتوبيس لهذا اليوم',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        onChanged: (val) => setState(() => _checkoutType = val ?? 'parent'),
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        value: 'other',
                        groupValue: _checkoutType,
                        dense: true,
                        activeColor: Colors.purple.shade700,
                        title: Row(
                          children: [
                            Icon(Icons.alt_route_rounded, size: 18, color: Colors.purple.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'انصراف لسبب آخر (استبعاد من الأتوبيس)',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(right: 26, top: 4),
                          child: Text(
                            '💡 استبعاد الطالب تلقائياً من كشف وجدول الأتوبيس لهذا اليوم (وينقص من الباص)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        onChanged: (val) => setState(() => _checkoutType = val ?? 'other'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (_checkoutType == 'other' &&
                  _checkoutNotesController.text.trim().isEmpty) {
                setState(() {
                  _checkoutError = 'يجب كتابة سبب الانصراف عند اختيار "آخر"!';
                });
                return;
              }
              Navigator.of(context).pop(
                AttendanceNotesDialogResult(
                  attendanceNotes: _attendanceNotesController.text.trim(),
                  checkoutNotes: _checkoutNotesController.text.trim(),
                  checkoutType: _checkoutType,
                ),
              );
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('حفظ الملاحظات', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
