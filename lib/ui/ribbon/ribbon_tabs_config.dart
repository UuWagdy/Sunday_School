import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'ribbon_bus.dart';
import 'ribbon_models.dart';

class RibbonTabsConfig {
  static List<RibbonTab> buildTabs({
    required User user,
    required void Function(int screenIndex) onNavigateToScreen,
    required void Function(RibbonCommand command, [dynamic payload])
    onSendCommand,
    required Map<String, int> screenIndices,
    required String activeQuickCheckoutType,
    required bool isCheckoutModeActive,
  }) {
    bool hasGranular(String key) {
      final perms = user.granularPermissions[key];
      return perms != null && perms.values.any((v) => v);
    }

    final List<RibbonTab> tabs = [];

    // 1. الرئيسية (Home)
    if (user.canReports) {
      tabs.add(
        RibbonTab(
          id: RibbonTabId.home,
          label: 'الرئيسية',
          icon: Icons.home_rounded,
          defaultScreenIndex: screenIndices['dashboard'] ?? 0,
          groups: [
            RibbonGroup(
              id: 'home_overview',
              title: 'نظرة عامة',
              actions: [
                RibbonAction(
                  id: 'refresh_dashboard',
                  label: 'تحديث اللوحة',
                  icon: Icons.refresh_rounded,
                  isPrimary: true,
                  tooltip: 'تحديث بيانات وإحصائيات لوحة المتابعة',
                  shortcut: 'F5',
                  onPressed: () {
                    onNavigateToScreen(screenIndices['dashboard'] ?? 0);
                  },
                ),
                RibbonAction(
                  id: 'weekly_stats',
                  label: 'الحضور الأسبوعي',
                  icon: Icons.query_stats_rounded,
                  tooltip: 'عرض رسم بياني لحضور الأسبوع الحالي',
                  onPressed: () {
                    onNavigateToScreen(screenIndices['dashboard'] ?? 0);
                  },
                ),
              ],
            ),
            RibbonGroup(
              id: 'home_quick_access',
              title: 'الوصول السريع',
              actions: [
                if (user.canAbsence)
                  RibbonAction(
                    id: 'quick_attendance',
                    label: 'تسجيل حضور سريع',
                    icon: Icons.how_to_reg_rounded,
                    tooltip: 'الانتقال لشاشة الحضور والتركيز على الإدخال',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['attendance'] ?? 0);
                      onSendCommand(RibbonCommand.focusQuickAttendance);
                    },
                  ),
                if (user.canAbsence)
                  RibbonAction(
                    id: 'quick_checkout_alone',
                    label: 'انصراف (بمفرده)',
                    icon: Icons.directions_walk_rounded,
                    tooltip: 'تفعيل وضع الانصراف بمفرده فوراً',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['attendance'] ?? 0);
                      onSendCommand(RibbonCommand.setCheckoutAlone);
                    },
                  ),
                if (user.canPersons)
                  RibbonAction(
                    id: 'quick_add_student',
                    label: 'إضافة مخدوم',
                    icon: Icons.person_add_alt_1_rounded,
                    tooltip: 'إضافة طفل أو خادم جديد في السجلات',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['persons'] ?? 0);
                      onSendCommand(RibbonCommand.addNewPerson);
                    },
                  ),
                if (hasGranular('visitation'))
                  RibbonAction(
                    id: 'quick_visitation',
                    label: 'جدول الافتقاد',
                    icon: Icons.volunteer_activism_rounded,
                    tooltip: 'متابعة جدول الزيارات الميدانية',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['visitation'] ?? 0);
                    },
                  ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. المخدومين (Students)
    if (user.canPersons ||
        user.canIdCard ||
        user.canStages ||
        user.canTransfer) {
      tabs.add(
        RibbonTab(
          id: RibbonTabId.students,
          label: 'المخدومين',
          icon: Icons.people_alt_rounded,
          defaultScreenIndex: screenIndices['persons'] ?? 0,
          groups: [
            if (user.canPersons)
              RibbonGroup(
                id: 'students_actions',
                title: 'إضافة وتسجيل',
                actions: [
                  RibbonAction(
                    id: 'new_student',
                    label: 'مخدوم جديد',
                    icon: Icons.person_add_rounded,
                    isPrimary: true,
                    tooltip: 'إضافة مخدوم جديد',
                    shortcut: 'Ctrl+N',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['persons'] ?? 0);
                      onSendCommand(RibbonCommand.addNewPerson);
                    },
                  ),
                  RibbonAction(
                    id: 'import_excel',
                    label: 'استيراد Excel',
                    icon: Icons.file_upload_rounded,
                    tooltip: 'استيراد بيانات مخدومين من ملف إكسيل',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['persons'] ?? 0);
                      onSendCommand(RibbonCommand.importPersonsExcel);
                    },
                  ),
                  RibbonAction(
                    id: 'export_excel',
                    label: 'تصدير إكسيل',
                    icon: Icons.file_download_rounded,
                    tooltip: 'تصدير قائمة المخدومين إلى Excel',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['persons'] ?? 0);
                      onSendCommand(RibbonCommand.exportPersonsExcel);
                    },
                  ),
                ],
              ),
            RibbonGroup(
              id: 'students_screens',
              title: 'السجلات والفئات',
              actions: [
                if (user.canPersons)
                  RibbonAction(
                    id: 'view_persons',
                    label: 'سجل الأشخاص',
                    icon: Icons.contacts_rounded,
                    tooltip: 'عرض وتعديل بطاقات المخدومين',
                    onPressed: () =>
                        onNavigateToScreen(screenIndices['persons'] ?? 0),
                  ),
                if (user.canStages)
                  RibbonAction(
                    id: 'view_stages',
                    label: 'المراحل الدراسية',
                    icon: Icons.school_rounded,
                    tooltip: 'إدارة وتوزيع المراحل السنية والفصول',
                    onPressed: () =>
                        onNavigateToScreen(screenIndices['stages'] ?? 0),
                  ),
                if (user.canTransfer)
                  RibbonAction(
                    id: 'view_transfer',
                    label: 'نقل المخدومين',
                    icon: Icons.swap_horiz_rounded,
                    tooltip: 'نقل المخدومين بين الفصول والمراحل',
                    onPressed: () =>
                        onNavigateToScreen(screenIndices['transfer'] ?? 0),
                  ),
              ],
            ),
            if (user.canIdCard)
              RibbonGroup(
                id: 'students_identity',
                title: 'بطاقات وهويات',
                actions: [
                  RibbonAction(
                    id: 'issue_id_card',
                    label: 'إصدار كارنيه',
                    icon: Icons.badge_rounded,
                    isPrimary: true,
                    tooltip: 'تصميم وطباعة بطاقات الهوية مع QR Code',
                    shortcut: 'Ctrl+P',
                    onPressed: () =>
                        onNavigateToScreen(screenIndices['id_card'] ?? 0),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    // 3. الخدام والأسر (Servants & Families)
    if (hasGranular('meetings') ||
        user.canFathers ||
        user.canKhoros ||
        hasGranular('rohot')) {
      tabs.add(
        RibbonTab(
          id: RibbonTabId.servants,
          label: 'الخدام والأسر',
          icon: Icons.groups_3_rounded,
          defaultScreenIndex:
              screenIndices['meetings'] ?? screenIndices['fathers'] ?? 0,
          groups: [
            if (hasGranular('meetings'))
              RibbonGroup(
                id: 'servants_meetings',
                title: 'الخدام والاجتماعات',
                actions: [
                  RibbonAction(
                    id: 'view_meetings',
                    label: 'اجتماعات الخدام',
                    icon: Icons.groups_3_rounded,
                    isPrimary: true,
                    tooltip: 'سجل اجتماعات الخدام، التحضير وتوزيع المسؤوليات',
                    onPressed: () =>
                        onNavigateToScreen(screenIndices['meetings'] ?? 0),
                  ),
                ],
              ),
            if (user.canFathers)
              RibbonGroup(
                id: 'servants_fathers',
                title: 'الآباء والاعتراف',
                actions: [
                  RibbonAction(
                    id: 'view_fathers',
                    label: 'آباء الاعتراف',
                    icon: Icons.church_rounded,
                    tooltip: 'قائمة الآباء الكهنة ومتابعة اعترافات المخدومين',
                    onPressed: () =>
                        onNavigateToScreen(screenIndices['fathers'] ?? 0),
                  ),
                ],
              ),
            if (user.canKhoros || hasGranular('rohot'))
              RibbonGroup(
                id: 'servants_groups',
                title: 'الخوارس والرهوط',
                actions: [
                  if (user.canKhoros)
                    RibbonAction(
                      id: 'view_khoros',
                      label: 'الخوارس والألحان',
                      icon: Icons.library_music_rounded,
                      tooltip: 'سجل الخوارس الكنسية ومجموعات الألحان',
                      onPressed: () =>
                          onNavigateToScreen(screenIndices['khoros'] ?? 0),
                    ),
                  if (hasGranular('rohot'))
                    RibbonAction(
                      id: 'view_rohot',
                      label: 'الرهوط الكشفية',
                      icon: Icons.diversity_3_rounded,
                      tooltip: 'إدارة الرهوط والأنشطة الكشفية',
                      onPressed: () =>
                          onNavigateToScreen(screenIndices['rohot'] ?? 0),
                    ),
                ],
              ),
          ],
        ),
      );
    }

    // 4. الغياب والافتقاد (Attendance & Visitation)
    if (user.canAbsence || hasGranular('visitation') || hasGranular('buses')) {
      final isAloneCheckoutActive =
          isCheckoutModeActive && activeQuickCheckoutType == 'alone';
      final isBusCheckoutActive =
          isCheckoutModeActive && activeQuickCheckoutType == 'bus';
      final isParentCheckoutActive =
          isCheckoutModeActive && activeQuickCheckoutType == 'parent';

      tabs.add(
        RibbonTab(
          id: RibbonTabId.attendance,
          label: 'الغياب والافتقاد',
          icon: Icons.how_to_reg_rounded,
          defaultScreenIndex: screenIndices['attendance'] ?? 0,
          groups: [
            if (user.canAbsence)
              RibbonGroup(
                id: 'attendance_intake',
                title: 'أخذ الحضور والانصراف',
                actions: [
                  RibbonAction(
                    id: 'scanner_qr',
                    label: 'ماسح QR',
                    icon: Icons.qr_code_scanner_rounded,
                    isPrimary: true,
                    tooltip: 'تشغيل ماسح الباركود وQR السريع للحضور',
                    shortcut: 'F3',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['attendance'] ?? 0);
                      onSendCommand(RibbonCommand.openQrScanner);
                    },
                  ),
                  RibbonAction(
                    id: 'manual_attendance',
                    label: 'حضور سريع',
                    icon: Icons.how_to_reg_rounded,
                    isSelected: !isCheckoutModeActive,
                    tooltip: 'تسجيل حضور سريع بالاسم أو الكود',
                    shortcut: 'F2',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['attendance'] ?? 0);
                      onSendCommand(RibbonCommand.focusQuickAttendance);
                    },
                  ),
                  RibbonAction(
                    id: 'checkout_alone',
                    label: 'انصراف (بمفرده)',
                    icon: Icons.directions_walk_rounded,
                    isSelected: isAloneCheckoutActive,
                    tooltip:
                        'تسجيل انصراف بمفرده (الافتراضي - مستبعد من الأتوبيس)',
                    shortcut: 'F4',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['attendance'] ?? 0);
                      onSendCommand(RibbonCommand.setCheckoutAlone);
                    },
                  ),
                  RibbonAction(
                    id: 'checkout_bus',
                    label: 'انصراف (أتوبيس)',
                    icon: Icons.directions_bus_rounded,
                    isSelected: isBusCheckoutActive,
                    tooltip: 'تسجيل انصراف مع خط الأتوبيس',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['attendance'] ?? 0);
                      onSendCommand(RibbonCommand.setCheckoutBus);
                    },
                  ),
                  RibbonAction(
                    id: 'checkout_parent',
                    label: 'انصراف (أهل)',
                    icon: Icons.family_restroom_rounded,
                    isSelected: isParentCheckoutActive,
                    tooltip: 'تسجيل انصراف لولي الأمر مباشرة',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['attendance'] ?? 0);
                      onSendCommand(RibbonCommand.setCheckoutParent);
                    },
                  ),
                  RibbonAction(
                    id: 'checkout_all',
                    label: 'انصراف الكل',
                    icon: Icons.groups_rounded,
                    isDestructive: true,
                    tooltip: 'تسجيل انصراف لجميع من حضر ولم ينصرف اليوم',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['attendance'] ?? 0);
                      onSendCommand(RibbonCommand.checkoutAll);
                    },
                  ),
                ],
              ),
            if (user.canAbsence)
              RibbonGroup(
                id: 'attendance_absence',
                title: 'حصر الغياب',
                actions: [
                  RibbonAction(
                    id: 'absent_2weeks',
                    label: 'غياب أسبوعين',
                    icon: Icons.person_off_rounded,
                    tooltip: 'حصر المخدومين المتغيبين لأسبوعين متتاليين',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['attendance'] ?? 0);
                      onSendCommand(RibbonCommand.filterAbsent2Weeks);
                    },
                  ),
                  RibbonAction(
                    id: 'absent_month',
                    label: 'غياب شهر',
                    icon: Icons.event_busy_rounded,
                    tooltip: 'حصر المتغيبين لمدة شهر متتالي',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['attendance'] ?? 0);
                      onSendCommand(RibbonCommand.filterAbsentMonth);
                    },
                  ),
                  RibbonAction(
                    id: 'reset_filters',
                    label: 'عرض الكل',
                    icon: Icons.clear_all_rounded,
                    tooltip: 'إعادة ضبط فلاتر الحضور وعرض الكل',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['attendance'] ?? 0);
                      onSendCommand(RibbonCommand.filterReset);
                    },
                  ),
                ],
              ),
            if (hasGranular('visitation'))
              RibbonGroup(
                id: 'attendance_visitation',
                title: 'الافتقاد والزيارات',
                actions: [
                  RibbonAction(
                    id: 'view_visitation',
                    label: 'سجل الافتقاد',
                    icon: Icons.volunteer_activism_rounded,
                    isPrimary: true,
                    tooltip: 'الانتقال لجدول الزيارات وتكليفات الخدام',
                    onPressed: () =>
                        onNavigateToScreen(screenIndices['visitation'] ?? 0),
                  ),
                ],
              ),
            if (hasGranular('buses'))
              RibbonGroup(
                id: 'attendance_buses',
                title: 'الأتوبيسات وخطوط السير',
                actions: [
                  RibbonAction(
                    id: 'view_buses',
                    label: 'كشف الأتوبيس',
                    icon: Icons.directions_bus_filled_rounded,
                    tooltip: 'متابعة خطوط السير والركاب والمستبعدين',
                    onPressed: () =>
                        onNavigateToScreen(screenIndices['buses'] ?? 0),
                  ),
                  RibbonAction(
                    id: 'refresh_buses',
                    label: 'تحديث الكشوفات',
                    icon: Icons.sync_rounded,
                    tooltip: 'تحديث ركاب الأتوبيسات بعد الحضور والانصراف',
                    onPressed: () {
                      onNavigateToScreen(screenIndices['buses'] ?? 0);
                      onSendCommand(RibbonCommand.reloadAttendance);
                    },
                  ),
                ],
              ),
          ],
        ),
      );
    }

    // 5. الأنشطة والمسابقات (Activities)
    if (user.canBehavior || user.canTayo || hasGranular('monthlyFund')) {
      tabs.add(
        RibbonTab(
          id: RibbonTabId.activities,
          label: 'الأنشطة والمسابقات',
          icon: Icons.card_giftcard_rounded,
          defaultScreenIndex:
              screenIndices['behavior'] ?? screenIndices['tayo'] ?? 0,
          groups: [
            if (user.canBehavior)
              RibbonGroup(
                id: 'activities_behavior',
                title: 'السلوك والتقييم',
                actions: [
                  RibbonAction(
                    id: 'view_behavior',
                    label: 'تقييم السلوك',
                    icon: Icons.thumbs_up_down_rounded,
                    isPrimary: true,
                    tooltip: 'رصد السلوك الإيجابي والسلبي ومتابعة الانضباط',
                    onPressed: () =>
                        onNavigateToScreen(screenIndices['behavior'] ?? 0),
                  ),
                ],
              ),
            if (user.canTayo)
              RibbonGroup(
                id: 'activities_tayo',
                title: 'بنك النقاط والجوائز',
                actions: [
                  RibbonAction(
                    id: 'view_tayo',
                    label: 'الطايو والجوائز',
                    icon: Icons.card_giftcard_rounded,
                    tooltip: 'إدارة متجر الطايو واستبدال نقاط التميز',
                    onPressed: () =>
                        onNavigateToScreen(screenIndices['tayo'] ?? 0),
                  ),
                ],
              ),
            if (hasGranular('monthlyFund'))
              RibbonGroup(
                id: 'activities_fund',
                title: 'الاشتراكات والماليات',
                actions: [
                  RibbonAction(
                    id: 'view_monthly_fund',
                    label: 'الصندوق الشهري',
                    icon: Icons.savings_rounded,
                    tooltip: 'تحصيل الاشتراكات والمصروفات الشهرية',
                    onPressed: () =>
                        onNavigateToScreen(screenIndices['monthly_fund'] ?? 0),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    // 6. الشهادات والتقارير (Reports)
    if (user.canReports) {
      tabs.add(
        RibbonTab(
          id: RibbonTabId.reports,
          label: 'الشهادات والتقارير',
          icon: Icons.assessment_rounded,
          defaultScreenIndex:
              screenIndices['reports'] ?? screenIndices['dashboard'] ?? 0,
          groups: [
            RibbonGroup(
              id: 'reports_general',
              title: 'التقارير الشاملة',
              actions: [
                RibbonAction(
                  id: 'view_reports',
                  label: 'سجل التقارير',
                  icon: Icons.assignment_rounded,
                  isPrimary: true,
                  tooltip: 'سجل التقارير المتقدمة للخدمة والمخدومين',
                  onPressed: () =>
                      onNavigateToScreen(screenIndices['reports'] ?? 0),
                ),
                RibbonAction(
                  id: 'view_dashboard_reports',
                  label: 'لوحة الإحصائيات',
                  icon: Icons.analytics_rounded,
                  tooltip: 'الرسوم البيانية والتحليلات المقارنة',
                  onPressed: () =>
                      onNavigateToScreen(screenIndices['dashboard'] ?? 0),
                ),
              ],
            ),
            RibbonGroup(
              id: 'reports_export',
              title: 'تصدير وطباعة',
              actions: [
                RibbonAction(
                  id: 'export_report_excel',
                  label: 'تصدير إكسيل',
                  icon: Icons.table_view_rounded,
                  tooltip: 'تصدير التقارير إلى جداول Excel',
                  onPressed: () {
                    onNavigateToScreen(screenIndices['reports'] ?? 0);
                    onSendCommand(RibbonCommand.exportReportsExcel);
                  },
                ),
                RibbonAction(
                  id: 'print_report_pdf',
                  label: 'طباعة كروت وشهادات',
                  icon: Icons.print_rounded,
                  tooltip: 'طباعة الشهادات وكروت المتابعة PDF',
                  onPressed: () {
                    onNavigateToScreen(screenIndices['reports'] ?? 0);
                    onSendCommand(RibbonCommand.printReportsPdf);
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    return tabs;
  }

  static RibbonTab buildFileTab({
    required User user,
    required void Function(int screenIndex) onNavigateToScreen,
    required void Function(RibbonCommand command) onSendCommand,
    required VoidCallback onOpenInfo,
    required VoidCallback onLogout,
    required Map<String, int> screenIndices,
  }) {
    return RibbonTab(
      id: RibbonTabId.file,
      label: 'ملف',
      icon: Icons.folder_shared_rounded,
      defaultScreenIndex:
          screenIndices['services'] ?? screenIndices['users'] ?? 0,
      groups: [
        RibbonGroup(
          id: 'file_church_settings',
          title: 'إدارة الكنيسة والخدمات',
          actions: [
            if (user.canServices)
              RibbonAction(
                id: 'file_services',
                label: 'إدارة الخدمات',
                icon: Icons.miscellaneous_services_rounded,
                isPrimary: true,
                tooltip: 'إعدادات الخدمات وأيام الاجتماعات',
                onPressed: () =>
                    onNavigateToScreen(screenIndices['services'] ?? 0),
              ),
            if (user.canUsers)
              RibbonAction(
                id: 'file_users',
                label: 'المستخدمين والصلاحيات',
                icon: Icons.admin_panel_settings_rounded,
                tooltip: 'إدارة حسابات الخدام ومستويات الوصول',
                onPressed: () =>
                    onNavigateToScreen(screenIndices['users'] ?? 0),
              ),
            if (user.canAreas)
              RibbonAction(
                id: 'file_areas',
                label: 'المناطق الجغرافية',
                icon: Icons.map_rounded,
                tooltip: 'تقسيم المناطق والشوارع لتسهيل الافتقاد',
                onPressed: () =>
                    onNavigateToScreen(screenIndices['areas'] ?? 0),
              ),
            if (user.canMaintenance)
              RibbonAction(
                id: 'file_maintenance',
                label: 'صيانة النظام',
                icon: Icons.settings_suggest_rounded,
                tooltip: 'أدوات تهيئة وصيانة وتفريغ قاعدة البيانات',
                onPressed: () =>
                    onNavigateToScreen(screenIndices['maintenance'] ?? 0),
              ),
          ],
        ),
        RibbonGroup(
          id: 'file_backup',
          title: 'النسخ الاحتياطي',
          actions: [
            RibbonAction(
              id: 'file_backup_now',
              label: 'نسخ احتياطي فوري',
              icon: Icons.backup_rounded,
              isPrimary: true,
              tooltip: 'حفظ نسخة احتياطية فورية من بيانات البرنامج',
              onPressed: () => onSendCommand(RibbonCommand.triggerQuickBackup),
            ),
          ],
        ),
        RibbonGroup(
          id: 'file_app_info',
          title: 'النظام والجلسة',
          actions: [
            RibbonAction(
              id: 'file_info',
              label: 'حول البرنامج',
              icon: Icons.info_outline_rounded,
              tooltip: 'بيانات الإصدار وفريق التطوير',
              onPressed: onOpenInfo,
            ),
            RibbonAction(
              id: 'file_logout',
              label: 'تسجيل خروج',
              icon: Icons.logout_rounded,
              isDestructive: true,
              tooltip: 'إنهاء الجلسة والعودة لشاشة الدخول',
              onPressed: onLogout,
            ),
          ],
        ),
      ],
    );
  }
}
