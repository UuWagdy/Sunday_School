import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RibbonCommand {
  // --- Attendance & Checkout (الغياب والانصراف) ---
  openQrScanner,
  focusQuickAttendance,
  setCheckoutAlone,      // انصراف بمفرده (الافتراضي)
  setCheckoutBus,        // انصراف أتوبيس
  setCheckoutParent,     // انصراف ولي أمر
  checkoutAll,           // انصراف الكل
  filterAbsent2Weeks,    // حصر غياب أسبوعين
  filterAbsentMonth,     // حصر غياب شهر
  filterReset,           // إعادة ضبط / عرض الكل
  reloadAttendance,      // تحديث بيانات الحضور
  openVisitationSheet,   // سجل الافتقاد

  // --- Students (المخدومين) ---
  addNewPerson,          // مخدوم جديد
  importPersonsExcel,    // استيراد من Excel
  exportPersonsExcel,    // تصدير إكسيل
  openIdCardScreen,      // إصدار كارنيه
  openStagesScreen,      // المراحل
  openTransferScreen,    // نقل المخدومين

  // --- Servants & Families (الخدام والأسر) ---
  openMeetingsScreen,    // اجتماعات الخدام
  openFathersScreen,     // آباء الاعتراف
  openKhorosScreen,      // الخوارس
  openRohotScreen,       // الرهوط

  // --- Activities (الأنشطة) ---
  openBehaviorScreen,    // تقييم السلوك
  openTayoScreen,        // بنك النقاط والطايو
  openMonthlyFundScreen, // الصندوق الشهري

  // --- Reports (التقارير) ---
  openReportsScreen,     // سجل التقارير الشامل
  openDashboardScreen,   // لوحة المتابعة
  exportReportsExcel,    // تصدير تقرير إكسيل
  printReportsPdf,       // طباعة تقرير PDF

  // --- File & System (ملف والنظام) ---
  openServicesScreen,    // إدارة الخدمات
  openUsersScreen,       // المستخدمين والصلاحيات
  openAreasScreen,       // المناطق
  openMaintenanceScreen, // صيانة النظام
  triggerQuickBackup,    // نسخ احتياطي فوري
}

class RibbonCommandEvent {
  final RibbonCommand command;
  final dynamic payload;
  final DateTime timestamp;

  RibbonCommandEvent(this.command, [this.payload])
      : timestamp = DateTime.now();
}

class RibbonCommandNotifier extends Notifier<RibbonCommandEvent?> {
  @override
  RibbonCommandEvent? build() => null;

  void emit(RibbonCommand command, [dynamic payload]) {
    state = RibbonCommandEvent(command, payload);
  }

  void setEvent(RibbonCommandEvent? event) {
    state = event;
  }
}

final ribbonCommandBusProvider =
    NotifierProvider<RibbonCommandNotifier, RibbonCommandEvent?>(RibbonCommandNotifier.new);
