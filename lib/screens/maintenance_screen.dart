import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_backup_service.dart';
import '../database/database_provider.dart';
import '../repositories/persons_repository.dart';
import '../repositories/areas_repository.dart';
import '../repositories/stages_repository.dart';
import '../repositories/fathers_repository.dart';
import '../repositories/users_repository.dart';
import '../services/auth_service.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  /// Invalidates all data providers so the UI refreshes with fresh data
  void _invalidateAllProviders(WidgetRef ref) {
    ref.invalidate(personsRepositoryProvider);
    ref.invalidate(areasRepositoryProvider);
    ref.invalidate(stagesRepositoryProvider);
    ref.invalidate(fathersRepositoryProvider);
    ref.invalidate(usersRepositoryProvider);
    ref.invalidate(allUsersProvider);
    ref.invalidate(authServiceProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: isMobile ? 16 : 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildMaintenanceCard(
                      context, isMobile: isMobile,
                      title: 'نسخ احتياطي لقاعدة البيانات',
                      subtitle: 'قم بحفظ نسخة من جميع البيانات الحالية في ملف للرجوع إليها لاحقاً.',
                      icon: Icons.backup_outlined,
                      color: Colors.blue,
                      buttonText: 'إنشاء نسخة',
                      onPressed: () => _handleBackup(context),
                    ),
                    const SizedBox(height: 12),
                    _buildMaintenanceCard(
                      context, isMobile: isMobile,
                      title: 'استعادة قاعدة البيانات',
                      subtitle: 'تحذير: سيتم استبدال جميع البيانات الحالية بالبيانات المختارة.',
                      icon: Icons.settings_backup_restore_outlined,
                      color: Colors.orange,
                      buttonText: 'استعادة',
                      onPressed: () => _handleRestore(context, ref),
                    ),
                    const SizedBox(height: 12),
                    _buildMaintenanceCard(
                      context, isMobile: isMobile,
                      title: 'ضبط المصنع',
                      subtitle: 'تحذير: سيتم مسح جميع البيانات نهائياً (باستثناء حسابات المستخدمين).',
                      icon: Icons.delete_forever_outlined,
                      color: Colors.red,
                      buttonText: 'مسح',
                      onPressed: () => _handleFactoryReset(context, ref),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صيانة النظام',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        Text(
          'إدارة قواعد البيانات والنسخ الاحتياطي',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMaintenanceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String buttonText,
    required VoidCallback onPressed,
    bool isMobile = false,
  }) {
    final iconWidget = Container(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: isMobile ? 24 : 32),
    );

    final textWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: isMobile ? 12 : 13)),
      ],
    );

    final buttonWidget = SizedBox(
      width: isMobile ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.play_arrow_rounded, size: 18),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 10 : 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: isMobile
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [iconWidget, const SizedBox(width: 12), Expanded(child: textWidget)]),
                const SizedBox(height: 12),
                buttonWidget,
              ])
            : Row(children: [
                iconWidget,
                const SizedBox(width: 20),
                Expanded(child: textWidget),
                const SizedBox(width: 16),
                buttonWidget,
              ]),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return FutureBuilder<String>(
      future: DatabaseBackupService.getDatabasePath(),
      builder: (context, snapshot) {
        return Card(
          color: Colors.grey[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('مسار قاعدة البيانات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      Text(
                        snapshot.data ?? 'جاري التحميل...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 10, fontFeatures: const [FontFeature.tabularFigures()]),
                        textDirection: TextDirection.ltr,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBackup(BuildContext context) async {
    try {
      final path = await DatabaseBackupService.backupDatabase();
      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء النسخة الاحتياطية بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء النسخة الاحتياطية: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الاستعادة'),
          content: const Text('هل أنت متأكد؟ سيتم استبدال جميع البيانات الحالية بالبيانات الموجودة في الملف المختار. يوصى بعمل نسخة احتياطية أولاً.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('استعادة الآن'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        final ok = await DatabaseBackupService.restoreDatabase(ref);
        if (ok && context.mounted) {
          _invalidateAllProviders(ref);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تمت استعادة البيانات بنجاح. سيتم تطبيق التحديثات تلقائياً.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل استعادة البيانات: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleFactoryReset(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد مسح البيانات (ضبط المصنع)'),
          content: const Text('هل أنت متأكد؟ سيتم حذف جميع البيانات نهائياً (باستثناء حسابات المستخدمين وصلاحياتهم). لا يمكن التراجع عن هذا الإجراء.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('نعم، امسح البيانات'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseBackupService.factoryReset(ref);
        if (context.mounted) {
          _invalidateAllProviders(ref);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم مسح جميع البيانات بنجاح والحفاظ على حسابات المستخدمين'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ أثناء ضبط المصنع: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
