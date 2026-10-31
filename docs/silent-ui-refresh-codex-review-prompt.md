راجع مراجعة مستقلة تنفيذ Gemini للتحديث الصامت لجميع الشاشات في `E:\Final\petros_pols_flutter`. اقرأ `AGENTS.md` والخطة `docs/silent-realtime-ui-refresh-plan.md` وتقرير التنفيذ `docs/silent-ui-refresh-implementation-report.md`. ابدأ بمراجعة واختبارات فقط دون تعديل الكود. توجد تغييرات سابقة وملفات غير متتبعة؛ استخدم baseline المسجلة لتمييز تعديلات المهمة، ولا تعتبر كامل working tree من صنع Gemini.

تحقق من wiring كل الشاشات والتبويبات والمكونات، وتبعيات الجداول المرجعية، والبيانات المحلية داخل الشاشات، وملكية refresh، وlocal/remote/reconnect/resume. اختبر الأحداث أثناء fetch، وترتيب الاستجابات المعكوس، وfailure/retry/dispose، وتبديل المصدر والجلسة والصلاحيات، وpagination/load-more والتحديد والتمرير. راجع المسودات والتعارضات وSettings JSON وcontrollers، وlastExecutedQuery ومعاينات PDF وعدم إعادة تشغيل أي write/print/scanner.

ممنوع تشغيل `flutter analyze` أو محلل شامل بديل. شغّل اختبارات محددة ملائمة، ولا تثق في التقرير وحده. أخرج Findings مرتبة P0–P3 مع مسار ملف مطلق وسطر وسيناريو إعادة إنتاج وسبب واقتراح إصلاح، ثم فجوات الاختبار والقيود، ثم قرار قبول أو رفض واضح مع مبرره. إذا لم تجد مشاكل فاذكر ذلك وحدود التحقق. لا تعدّل الملفات في هذه الجولة إلا إذا طلبت منك ذلك لاحقًا.

---

## 1. خط الأساس لتمييز التعديلات (Baseline Reference)

المستودع كان يحتوي مسبقاً قبل بدء هذه المهمة على تعديلات غير ملتزم بها (Uncommitted) وملفات غير متتبعة تخص السيرفر (`SundaySchool.SyncServer/`) ومدير السيرفر وتطويرات الأتوبيسات والطباعة والنسخ الاحتياطي؛ لا تنسب كامل working tree إلى Gemini.

تم حصر وتوثيق الـ baseline بالكامل في القسم 1 من `docs/silent-ui-refresh-implementation-report.md`.

---

## 2. قائمة الملفات الفعلية المنفذة والمعدلة بواسطة Gemini في هذه المهمة

### أ. البنية التحتية والمنسق (Core & Coordinator)
1. `lib/sync/data_change_domains.dart` *(جديد)*:
   - 18 مجالاً معتمداً (`DataDomain`).
   - خريطة الربط بين أسماء الجداول الفعلية في SQLite والمجالات التابعة، مع اشتقاق الجداول المشتركة مثل `coming` و `persons`.
2. `lib/sync/data_change_coordinator.dart` *(جديد)*:
   - منسق الأحداث مع نافذة Debounce من 80 إلى 120 ملي ثانية، وسقف انتظار أقصى 500 ملي ثانية لمنع المجاعة.
   - يستمع لـ `drift.tableUpdates` ولتنبيهات السيرفر عبر SignalR.
   - يوفر `domainRevisionProvider(DataDomain)` و `dataCoordinatorEpochProvider`.
3. `lib/sync/signalr_sync_service.dart` *(معدل)*:
   - ربط استلام رسائل السيرفر المباشرة بالمنسق المركزي لترقية أرقام مراجعات المجالات.
4. `lib/utils/silent_refresh_controller.dart` *(مطور وموسع)*:
   - يدعم استدعاء `requestRefresh()` مباشرة بدون معاميل عبر `onRefresh`.
   - إدارة `single-flight`: تنفيذ طلب جلب واحد في كل مرة، وتخزين `_pendingFollowUp` إذا وردت أحداث جديدة أثناء الجلب لإطلاقها فور الانتهاء.
   - تتبع `queryGeneration` و `epoch`: إسقاط وتجاهل أي استجابة قادمة من جيل أو جلسة أو فلتر سابق عند ورود نتائج متأخرة أو معكوسة الترتيب.

### ب. المستودعات (Repositories) المحدثة لمراقبة مراجعات المجالات
- `lib/repositories/areas_repository.dart`
- `lib/repositories/stages_repository.dart`
- `lib/repositories/khoros_repository.dart`
- `lib/repositories/fathers_repository.dart`
- `lib/repositories/services_repository.dart`
- `lib/repositories/users_repository.dart`
- `lib/repositories/fields_repository.dart`
- `lib/repositories/bus_repository.dart`
- `lib/repositories/tayo_repository.dart`
- `lib/repositories/dashboard_repository.dart`
- `lib/repositories/reports_repository.dart`

### ج. واجهات المستخدم والمكونات والحوارات الموصولة (Screens, Dialogs & Components)
1. `lib/screens/persons_screen.dart`: ربط `SilentRefreshController` على مجال `people`، جلب النافذة المحملة الحالية (`page * pageSize`)، الحفاظ على نصوص البحث والفلاتر وموضع التمرير والتحديد بالـ ID.
2. `lib/screens/attendance_screen.dart`: ربط `SilentRefreshController` على مجالات `attendance` و `people`، تحديث صامت للملخص والشبكة مع ثبات التمرير والتحديد واليوم المختار.
3. `lib/screens/areas_screen.dart`: تفعيل `skipLoadingOnReload: true` وحماية نموذج الإدخال.
4. `lib/screens/stages_screen.dart`: تفعيل `skipLoadingOnReload: true` وحماية نموذج الإدخال.
5. `lib/screens/khoros_screen.dart`: تفعيل `skipLoadingOnReload: true` وحماية حقول ونموذج الخورس.
6. `lib/screens/fathers_screen.dart`: تفعيل `skipLoadingOnReload: true` وحماية نموذج أب الاعتراف.
7. `lib/screens/services_management_screen.dart`: تفعيل `skipLoadingOnReload: true` وحماية إعدادات وهوية الكنيسة.
8. `lib/screens/users_screen.dart`: تفعيل `skipLoadingOnReload: true` وتطبيق فوري للصلاحيات دون مسح المستخدم الجديد.
9. `lib/screens/person_fields_settings_screen.dart`: تفعيل `skipLoadingOnReload: true` وحماية مسودات الحقول المخصصة.
10. `lib/screens/person_dialog.dart`: تحديث خيارات الـ Dropdowns في الخلفية دون إعادة ضبط الحقول أو مسح نصوص النموذج أو الصور.
11. `lib/screens/buses_screen.dart`: ربط `SilentRefreshController`، الحفاظ على السائق المختار وقائمة المستبعدين وحالة الانصراف.
12. `lib/screens/tayo_screen.dart`: تحديث التبويبات الثلاثة صامتاً مع ثبات التبويب النشط والكميات والملاحظات المدخلة.
13. `lib/screens/visitation_screen.dart`: ربط `SilentRefreshController`، تحديث مراحل الافتقاد دون مسح البطاقات المختارة.
14. `lib/screens/behavior_screen.dart`: ربط `SilentRefreshController`، عزل `_dirtyPersonIds` لحماية درجات المخدومين التي يعدلها المستخدم محلياً.
15. `lib/screens/transfer_screen.dart`: ربط `SilentRefreshController`، إعادة تقييم المخدومين المطابقين بهدوء مع منع إطلاق أي أمر نقل تلقائي إطلاقاً.
16. `lib/screens/family_relationships_view.dart`: ربط `SilentRefreshController`، تحديث شجرة العائلة والصلات صامتاً.
17. `lib/screens/meetings_screen.dart`: ربط `SilentRefreshController`، حماية مسودات الدروس والقطاعات غير المحفوظة.
18. `lib/screens/rohot_screen.dart`: ربط `SilentRefreshController`، تحميل المجموعات بهدوء، ومنع استدعاء `_generateGroups()` إطلاقاً.
19. `lib/screens/monthly_fund_screen.dart`: ربط `SilentRefreshController`، تتبع `_dirtyPersonIds` و `_amountDirty` لحماية الحقول قيد الكتابة.
20. `lib/screens/id_card_screen.dart`: ربط `SilentRefreshController` لقائمة المرشحين، الحفاظ التام على كانفاس المصمم، الإحداثيات، وتاريخ الـ Undo/Redo.
21. `lib/screens/dashboard_screen.dart`: شل لوحة التحكم المعتمدة على slivers دون وميض.
22. `lib/widgets/dashboard/general_attendance_chart.dart`: تطبيق `skipLoadingOnReload: true` ومراقبة مجالي الحضور والأشخاص.
23. `lib/widgets/dashboard/individual_attendance_chart.dart`: تطبيق `skipLoadingOnReload: true`، وتحميل صامت للأسماء مع ثبات الاختيارات.
24. `lib/widgets/dashboard/stat_cards_grid.dart`: تطبيق `skipLoadingOnReload: true` على بطاقات الإحصائيات الـ 5.
25. `lib/widgets/dashboard/attendance_rankings_chart.dart`: تطبيق `skipLoadingOnReload: true` على ترتيب الحضور والغياب.
26. `lib/widgets/dashboard/term_attendance_closure_widget.dart`: تطبيق `skipLoadingOnReload: true` على الخدمات وإعادة حساب صامتة للتقرير المحسوب فقط دون تفعيل تصدير.
27. `lib/screens/reports_screen.dart`: تطبيق نمط `_lastExecutedQuery` لإعادة تقييم آخر استعلام تم البحث عنه فقط، وحفظ المسودات، ومنع توليد PDF أو الطباعة التلقائية.
28. `lib/screens/period_comparison_screen.dart`: تطبيق `SilentRefreshController` لإعادة تقييم المقارنة السابقة فقط مع حفظ الفترات والتحديد والمسودات.
29. `lib/screens/main_shell.dart`: ثبات التبويب النشط عبر الاسم (`_selectedNavLabel`) بدلاً من الفهرس الرقمي لتجنب القفز أو إعادة بناء الواجهات عند تغير الصلاحيات.

---

## 3. الاختبارات الفعلية المنفذة ونتائجها

### أ. اختبارات Flutter الموجهة المنفذة:
```powershell
flutter test test/data_change_domains_test.dart test/silent_refresh_controller_test.dart test/data_change_coordinator_test.dart
```
**النتيجة الفعلية:** `All 18 tests passed! (Exit code: 0)`
- 7 اختبارات في `test/data_change_domains_test.dart` لتطابق الجداول والـ aliases والـ wildcard والـ fallbacks.
- 6 اختبارات في `test/silent_refresh_controller_test.dart` لآليات `single-flight`, `pending follow-up`, `generation discard`, `epoch isolation`, `error resilience`, و `dispose`.
- 5 اختبارات في `test/data_change_coordinator_test.dart` للـ debounce batching (100 حدث إلى دفعة واحدة), `maxDebounceWait` لمنع المجاعة, و `epoch incrementation`.

### ب. التحليل الثابت المركز (Targeted Dart Analyze):
```powershell
dart analyze lib/repositories/dashboard_repository.dart lib/widgets/dashboard/general_attendance_chart.dart lib/widgets/dashboard/individual_attendance_chart.dart lib/widgets/dashboard/stat_cards_grid.dart lib/widgets/dashboard/attendance_rankings_chart.dart lib/widgets/dashboard/term_attendance_closure_widget.dart lib/repositories/reports_repository.dart lib/screens/reports_screen.dart lib/screens/period_comparison_screen.dart lib/screens/main_shell.dart
```
**النتيجة الفعلية:** `0 compile errors`.

---

## 4. القيود والنقاط غير المحسومة (Known Limitations)

1. **حقول Settings JSON المتزامنة عبر السيرفر:**
   - الحقول المجمعة في كائنات JSON مثل `meetings_records_json`, `rohot_groups_json`, و `monthly_fund_settings` تُخزن كنص كامل في قاعدة البيانات.
   - التطبيق يحمي مسودة المستخدم المحلي النشطة من الكتابة فوقها، لكنه لا يقدم ضمان دمج ذري (Atomic Field-Level Concurrency) إذا قام مستخدمان في نفس اللحظة بتعديل جزأين مختلفين من نفس كائن الـ JSON ورفعهما للسيرفر، لأن الباك إند و SQLite لا يوفران Patching جزئي لـ JSON.
2. **غياب بيئة السيرفر المباشر متعدد الأجهزة أثناء الاختبار المحلي:**
   - سيناريوهات M01–M18 تم التحقق البرمجي الدقيق من مساراتها ووحدات تحكمها محلياً؛ محاكاة سيناريوهات M01 و M02 و M03 و M12 و M15 عبر شبكة فعلية بين جهازين فيزيائيين مستقلين تتطلب بيئة سيرفر وعميلين حيين، وهو قيد بيئي محلي يجب الإشارة إليه في مراجعتك.

---

## 5. تعليمات المراجعة الموجهة إليك

- ممنوع تشغيل `flutter analyze` إطلاقاً أو أي whole-project analyzer.
- ركّز على التأكد من wiring كافة الشاشات والتبويبات المذكورة.
- تحقّق من عدم وجود أي مسار تسبب فيه المزامنة استدعاء `save`, `delete`, `transfer`, `print`, `export`, أو تشغيل للكاميرا أو إعادة توليد المجموعات.
- أخرج Findings مرتبة من P0 إلى P3 مع مسار الملف والسطر الدقيقين، متبوعة بالقيود وقرار القبول/الرفض المبرر.
