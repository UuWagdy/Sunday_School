import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/persons_repository.dart';
import 'ribbon_bus.dart';
import 'ribbon_controller.dart';
import 'ribbon_models.dart';

class RibbonSearchDialog extends ConsumerStatefulWidget {
  final VoidCallback? onOpenInfo;
  final VoidCallback? onLogout;

  const RibbonSearchDialog({
    super.key,
    this.onOpenInfo,
    this.onLogout,
  });

  static Future<void> show(BuildContext context, {VoidCallback? onOpenInfo, VoidCallback? onLogout}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => RibbonSearchDialog(onOpenInfo: onOpenInfo, onLogout: onLogout),
    );
  }

  @override
  ConsumerState<RibbonSearchDialog> createState() => _RibbonSearchDialogState();
}

class _RibbonSearchDialogState extends ConsumerState<RibbonSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<PersonListDTO> _matchingPersons = [];
  bool _isSearching = false;

  final List<_QuickCommandItem> _allCommands = [
    _QuickCommandItem(
      title: 'تسجيل حضور سريع',
      subtitle: 'الانتقال لشاشة الحضور والتركيز على إدخال الكود/الاسم',
      icon: Icons.how_to_reg_rounded,
      color: Colors.green,
      category: 'الغياب والافتقاد',
      tabId: RibbonTabId.attendance,
      command: RibbonCommand.focusQuickAttendance,
    ),
    _QuickCommandItem(
      title: 'تسجيل انصراف (بمفرده - الافتراضي)',
      subtitle: 'تفعيل وضع الانصراف الفوري بمفرده واستبعاد الأتوبيس',
      icon: Icons.directions_walk_rounded,
      color: Colors.teal,
      category: 'الغياب والافتقاد',
      tabId: RibbonTabId.attendance,
      command: RibbonCommand.setCheckoutAlone,
    ),
    _QuickCommandItem(
      title: 'تسجيل انصراف (أتوبيس)',
      subtitle: 'تسجيل انصراف عادي عبر خط الأتوبيس',
      icon: Icons.directions_bus_rounded,
      color: Colors.indigo,
      category: 'الغياب والافتقاد',
      tabId: RibbonTabId.attendance,
      command: RibbonCommand.setCheckoutBus,
    ),
    _QuickCommandItem(
      title: 'تسجيل انصراف (ولي أمر)',
      subtitle: 'تسجيل انصراف للأهل واستبعاد من الأتوبيس',
      icon: Icons.family_restroom_rounded,
      color: Colors.orange,
      category: 'الغياب والافتقاد',
      tabId: RibbonTabId.attendance,
      command: RibbonCommand.setCheckoutParent,
    ),
    _QuickCommandItem(
      title: 'ماسح الباركود / QR الحضور',
      subtitle: 'فتح الكاميرا لقراءة بطاقات الحضور فوراً',
      icon: Icons.qr_code_scanner_rounded,
      color: Colors.indigo,
      category: 'الغياب والافتقاد',
      tabId: RibbonTabId.attendance,
      command: RibbonCommand.openQrScanner,
    ),
    _QuickCommandItem(
      title: 'حصر المتغيبين (أسبوعين متتاليين)',
      subtitle: 'تصفية قائمة الطلاب المتغيبين لأسبوعين',
      icon: Icons.person_off_rounded,
      color: Colors.red,
      category: 'الغياب والافتقاد',
      tabId: RibbonTabId.attendance,
      command: RibbonCommand.filterAbsent2Weeks,
    ),
    _QuickCommandItem(
      title: 'كشف الأتوبيسات وخطوط السير',
      subtitle: 'متابعة ركاب الأتوبيس وتحديث الكشوفات اليومية',
      icon: Icons.directions_bus_filled_rounded,
      color: Colors.blue,
      category: 'الغياب والافتقاد',
      tabId: RibbonTabId.attendance,
      command: RibbonCommand.reloadAttendance,
    ),
    _QuickCommandItem(
      title: 'سجل الافتقاد والزيارات',
      subtitle: 'متابعة زيارات الخدام والتكليفات',
      icon: Icons.volunteer_activism_rounded,
      color: Colors.pink,
      category: 'الغياب والافتقاد',
      tabId: RibbonTabId.attendance,
      command: RibbonCommand.openVisitationSheet,
    ),
    _QuickCommandItem(
      title: 'إضافة مخدوم جديد',
      subtitle: 'تسجيل بيانات طفل أو شاب جديد في السجلات',
      icon: Icons.person_add_alt_1_rounded,
      color: Colors.blue,
      category: 'المخدومين',
      tabId: RibbonTabId.students,
      command: RibbonCommand.addNewPerson,
    ),
    _QuickCommandItem(
      title: 'إصدار وطباعة كارنيهات',
      subtitle: 'مصمم بطاقات الهوية والكارنيهات مع QR Code',
      icon: Icons.badge_rounded,
      color: Colors.deepPurple,
      category: 'المخدومين',
      tabId: RibbonTabId.students,
      command: RibbonCommand.openIdCardScreen,
    ),
    _QuickCommandItem(
      title: 'تصدير سجل المخدومين إلى Excel',
      subtitle: 'تصدير قوائم وبيانات التواصل إلى ملف إكسيل',
      icon: Icons.table_view_rounded,
      color: Colors.green.shade700,
      category: 'المخدومين',
      tabId: RibbonTabId.students,
      command: RibbonCommand.exportPersonsExcel,
    ),
    _QuickCommandItem(
      title: 'اجتماعات الخدام وتوزيع الفصول',
      subtitle: 'محاضر اجتماعات الخدام والمسؤوليات',
      icon: Icons.groups_3_rounded,
      color: Colors.indigo,
      category: 'الخدام والأسر',
      tabId: RibbonTabId.servants,
      command: RibbonCommand.openMeetingsScreen,
    ),
    _QuickCommandItem(
      title: 'سجل آباء الاعتراف والكهنة',
      subtitle: 'إدارة كهنة الكنيسة ومتابعة اعترافات المخدومين',
      icon: Icons.church_rounded,
      color: Colors.brown,
      category: 'الخدام والأسر',
      tabId: RibbonTabId.servants,
      command: RibbonCommand.openFathersScreen,
    ),
    _QuickCommandItem(
      title: 'سجل الخوارس والألحان الكنسية',
      subtitle: 'توزيع الشمامسة ومجموعات الألحان',
      icon: Icons.library_music_rounded,
      color: Colors.amber.shade900,
      category: 'الخدام والأسر',
      tabId: RibbonTabId.servants,
      command: RibbonCommand.openKhorosScreen,
    ),
    _QuickCommandItem(
      title: 'تقييم السلوك والانضباط',
      subtitle: 'رصد درجات السلوك الإيجابي والسلبي أسبوعياً',
      icon: Icons.thumbs_up_down_rounded,
      color: Colors.deepOrange,
      category: 'الأنشطة والمسابقات',
      tabId: RibbonTabId.activities,
      command: RibbonCommand.openBehaviorScreen,
    ),
    _QuickCommandItem(
      title: 'بنك النقاط والطايو (الجوائز)',
      subtitle: 'شراء الجوائز واستبدال نقاط المواظبة',
      icon: Icons.card_giftcard_rounded,
      color: Colors.purple,
      category: 'الأنشطة والمسابقات',
      tabId: RibbonTabId.activities,
      command: RibbonCommand.openTayoScreen,
    ),
    _QuickCommandItem(
      title: 'الصندوق الشهري والاشتراكات',
      subtitle: 'سداد الاشتراكات الشهرية والتبرعات',
      icon: Icons.savings_rounded,
      color: Colors.teal,
      category: 'الأنشطة والمسابقات',
      tabId: RibbonTabId.activities,
      command: RibbonCommand.openMonthlyFundScreen,
    ),
    _QuickCommandItem(
      title: 'سجل التقارير الشامل والشهادات',
      subtitle: 'تقارير المواظبة وتوليد شهادات التقدير',
      icon: Icons.assignment_rounded,
      color: Colors.blueGrey,
      category: 'الشهادات والتقارير',
      tabId: RibbonTabId.reports,
      command: RibbonCommand.openReportsScreen,
    ),
    _QuickCommandItem(
      title: 'النسخ الاحتياطي لقاعدة البيانات',
      subtitle: 'حفظ نسخة احتياطية آمنة من جميع بيانات الخدمة',
      icon: Icons.backup_rounded,
      color: Colors.blue,
      category: 'ملف والنظام',
      tabId: RibbonTabId.file,
      command: RibbonCommand.triggerQuickBackup,
    ),
    _QuickCommandItem(
      title: 'صيانة وتفريغ النظام',
      subtitle: 'إصلاح قاعدة البيانات، الأرشفة، والتهيئة',
      icon: Icons.settings_suggest_rounded,
      color: Colors.blueGrey,
      category: 'ملف والنظام',
      tabId: RibbonTabId.file,
      command: RibbonCommand.openMaintenanceScreen,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onQueryChanged(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _matchingPersons = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await ref.read(personsRepositoryProvider.notifier).fetchPersons(
            search: trimmed,
            limit: 10,
            includeServices: false,
          );
      if (mounted) {
        setState(() {
          _matchingPersons = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _executeCommand(_QuickCommandItem item) {
    Navigator.of(context).pop();
    ref.read(ribbonActiveTabProvider.notifier).setTab(item.tabId);
    if (item.command != null) {
      ref.read(ribbonCommandBusProvider.notifier).emit(item.command!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredCommands = query.isEmpty
        ? _allCommands.take(6).toList()
        : _allCommands.where((cmd) {
            return cmd.title.toLowerCase().contains(query) ||
                cmd.subtitle.toLowerCase().contains(query) ||
                cmd.category.toLowerCase().contains(query);
          }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.indigo.shade100, width: 1.5),
        ),
        elevation: 24,
        backgroundColor: Colors.white,
        child: Container(
          width: 620,
          constraints: const BoxConstraints(maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input Header (Office 365 Tell Me Bar)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: _onQueryChanged,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'ابحث عن خادم، مخدوم، أو اكتب أمراً سريعاً... (Alt + Q)',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                      ),
                    ),
                    if (_isSearching)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                        },
                      ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'ESC للإغلاق',
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Results List View
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    // --- Person Search Results ---
                    if (_matchingPersons.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, size: 16, color: Colors.indigo),
                            const SizedBox(width: 6),
                            const Text(
                              'نتائج المخدومين والخدام:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo),
                            ),
                            const Spacer(),
                            Text(
                              '${_matchingPersons.length} نتيجة',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      ..._matchingPersons.map((p) {
                        return ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade50,
                            foregroundColor: Theme.of(context).primaryColor,
                            radius: 16,
                            child: Text(
                              p.name.isNotEmpty ? p.name[0] : '؟',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          title: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            'كود: ${p.id} • المرحلة: ${p.stageName.isEmpty ? 'عام' : p.stageName} • المنطقة: ${p.areaName.isEmpty ? '-' : p.areaName}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.how_to_reg_rounded, size: 18, color: Colors.green),
                                tooltip: 'تسجيل حضور فوري',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  ref.read(ribbonActiveTabProvider.notifier).setTab(RibbonTabId.attendance);
                                  ref.read(ribbonCommandBusProvider.notifier).emit(RibbonCommand.focusQuickAttendance, p);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.badge_rounded, size: 18, color: Colors.deepPurple),
                                tooltip: 'إصدار كارنيه',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  ref.read(ribbonActiveTabProvider.notifier).setTab(RibbonTabId.students);
                                  ref.read(ribbonCommandBusProvider.notifier).emit(RibbonCommand.openIdCardScreen, p);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            ref.read(ribbonActiveTabProvider.notifier).setTab(RibbonTabId.attendance);
                            ref.read(ribbonCommandBusProvider.notifier).emit(RibbonCommand.focusQuickAttendance, p);
                          },
                        );
                      }),
                      const Divider(height: 16),
                    ],

                    // --- Quick Commands & Tools ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text(
                            query.isEmpty ? 'الأوامر السريعة والأدوات المقترحة:' : 'الأدوات والأوامر المطابقة:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    if (filteredCommands.isEmpty && _matchingPersons.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'لم يتم العثور على أوامر أو نتائج مطابقة لـ "$query"',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredCommands.map((cmd) {
                        return ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          hoverColor: Colors.indigo.shade50.withOpacity(0.5),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cmd.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(cmd.icon, size: 20, color: cmd.color),
                          ),
                          title: Row(
                            children: [
                              Text(
                                cmd.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  cmd.category,
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            cmd.subtitle,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: Colors.grey),
                          onTap: () => _executeCommand(cmd),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickCommandItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String category;
  final RibbonTabId tabId;
  final RibbonCommand? command;

  const _QuickCommandItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
    required this.tabId,
    this.command,
  });
}
