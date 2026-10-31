import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../dialogs/server_connection_dialog.dart';
import 'ribbon_controller.dart';
import 'ribbon_models.dart';
import 'ribbon_search_dialog.dart';

class RibbonTitleBar extends ConsumerWidget {
  final String programName;
  final VoidCallback onOpenInfo;
  final VoidCallback onLogout;

  const RibbonTitleBar({
    super.key,
    required this.programName,
    required this.onOpenInfo,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).value;
    final autoSave = ref.watch(ribbonAutoSaveProvider);
    final syncState = ref.watch(ribbonSyncStatusProvider);

    // Microsoft Word Title Bar Styling (Modern Fluent Navy/Dark Glass)
    final backgroundColor = const Color(0xFF102A43); // Deep Office Word Indigo/Navy
    final foregroundColor = Colors.white;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // --- Right (RTL): App Logo + Program Title + Server Connection Status ---
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                programName,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              const ServerConnectionStatusButton(
                compact: true,
                darkBackground: true,
              ),
            ],
          ),

          const SizedBox(width: 16),

          // --- Middle: Office 365 Tell Me / Search Bar (Alt + Q) ---
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      RibbonSearchDialog.show(
                        context,
                        onOpenInfo: onOpenInfo,
                        onLogout: onLogout,
                      );
                    },
                    child: Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 15,
                            color: foregroundColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'بحث أو ما تريد أن تفعله... (Alt + Q)',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: foregroundColor.withOpacity(0.65),
                                fontWeight: FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Alt+Q',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: foregroundColor.withOpacity(0.75),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // --- Left (RTL): AutoSave, Sync, Connection Settings, Info, User Account ---
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Word AutoSave Switch
              Tooltip(
                message: 'الحفظ التلقائي للبيانات والتغييرات (AutoSave)',
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    ref.read(ribbonAutoSaveProvider.notifier).toggle();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'حفظ تلقائي',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: foregroundColor.withOpacity(0.85),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 26,
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: autoSave ? const Color(0xFF10B981) : Colors.white.withOpacity(0.2),
                          ),
                          child: Align(
                            alignment: autoSave ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.all(1),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Cloud Sync Status Indicator (Clickable -> Opens ServerConnectionDialog)
              Tooltip(
                message: syncState == RibbonSyncState.synced
                    ? 'متزامن ومحفوظ — اضغط لإعدادات الاتصال بالسيرفر'
                    : (syncState == RibbonSyncState.syncing ? 'جارٍ المزامنة الفورية...' : 'غير متصل بالسيرفر — اضغط لإعدادات الاتصال'),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => ServerConnectionDialog.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: syncState == RibbonSyncState.synced
                                ? const Color(0xFF10B981)
                                : (syncState == RibbonSyncState.syncing
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          syncState == RibbonSyncState.synced ? 'محفوظ' : 'مزامنة',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: foregroundColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Server Connection Settings Icon Button
              IconButton(
                icon: const Icon(Icons.settings_ethernet_rounded, size: 16),
                color: foregroundColor.withOpacity(0.9),
                tooltip: 'إعدادات الاتصال بالسيرفر والمزامنة (.NET + PostgreSQL + SignalR)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => ServerConnectionDialog.show(context),
              ),

              // Info & Help button
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, size: 16),
                color: foregroundColor.withOpacity(0.85),
                tooltip: 'حول البرنامج والإصدار',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onOpenInfo,
              ),

              const SizedBox(width: 4),

              // User Profile Pill with Account Menu
              if (user != null)
                PopupMenuButton<String>(
                  tooltip: 'ملف الخادم والحساب',
                  offset: const Offset(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white,
                  onSelected: (val) {
                    if (val == 'logout') {
                      onLogout();
                    } else if (val == 'info') {
                      onOpenInfo();
                    } else if (val == 'server') {
                      ServerConnectionDialog.show(context);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              user.username.isNotEmpty ? user.username[0] : '؟',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.username,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                ),
                                Text(
                                  user.isAdvanced ? 'مشرف رئيسي (Admin)' : 'خادم معتمد',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'server',
                      child: Row(
                        children: [
                          Icon(Icons.settings_ethernet_rounded, size: 18, color: Color(0xFF1A237E)),
                          SizedBox(width: 8),
                          Text('إعدادات الاتصال بالسيرفر والمزامنة', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'info',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text('حول البرنامج وفريق التطوير', style: TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('تسجيل الخروج', style: TextStyle(fontSize: 12.5, color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: const Color(0xFF3B82F6),
                          child: Text(
                            user.username.isNotEmpty ? user.username[0] : 'U',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.username,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: foregroundColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: foregroundColor.withOpacity(0.7)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
