import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../repositories/areas_repository.dart';
import '../../repositories/attendance_repository.dart';
import '../../repositories/fathers_repository.dart';
import '../../repositories/khoros_repository.dart';
import '../../repositories/persons_repository.dart';
import '../../repositories/services_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/stages_repository.dart';
import '../../repositories/tayo_repository.dart';
import '../../repositories/users_repository.dart';
import '../../services/auth_service.dart';
import '../../sync/server_config.dart';
import '../../sync/server_connection_service.dart';
import '../../sync/signalr_sync_service.dart';

/// Reusable button/badge that opens [ServerConnectionDialog] and shows live
/// connection status (Local SQLite vs .NET + PostgreSQL + SignalR).
class ServerConnectionStatusButton extends ConsumerWidget {
  final bool compact;
  final bool darkBackground;

  const ServerConnectionStatusButton({
    super.key,
    this.compact = false,
    this.darkBackground = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(serverConfigProvider);
    final signalRState = ref.watch(signalRSyncProvider);

    final Color dotColor;
    final String statusLabel;
    final String tooltipText;

    if (!cfg.isServerMode) {
      dotColor = const Color(0xFF60A5FA); // Blue for Local SQLite
      statusLabel = 'محلي (SQLite)';
      tooltipText =
          'وضع التشغيل: قاعدة بيانات محلية (SQLite) — اضغط لإعدادات الاتصال بالسيرفر';
    } else {
      switch (signalRState) {
        case SignalRConnectionStatus.connected:
          dotColor = const Color(0xFF10B981); // Emerald Green
          statusLabel = 'متصل بالسيرفر (SignalR)';
          tooltipText =
              'متصل بسيرفر .NET + PostgreSQL والمزامنة الفورية نشطة (${cfg.normalizedBaseUrl})';
        case SignalRConnectionStatus.connecting:
        case SignalRConnectionStatus.reconnecting:
          dotColor = const Color(0xFFF59E0B); // Amber
          statusLabel = 'جارٍ الاتصال بالسيرفر...';
          tooltipText =
              'جارٍ الاتصال بسيرفر المزامنة (${cfg.normalizedBaseUrl})';
        case SignalRConnectionStatus.error:
        case SignalRConnectionStatus.disconnected:
          dotColor = const Color(0xFFEF4444); // Red
          statusLabel = 'السيرفر غير متصل';
          tooltipText =
              'تعذر الاتصال بسيرفر المزامنة (${cfg.normalizedBaseUrl}) — اضغط للتحقق من الإعدادات';
      }
    }

    final fgColor = darkBackground ? Colors.white : const Color(0xFF1A237E);

    if (compact) {
      return Tooltip(
        message: tooltipText,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => ServerConnectionDialog.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: darkBackground
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFF1A237E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dotColor.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  cfg.isServerMode ? Icons.dns_rounded : Icons.storage_rounded,
                  size: 14,
                  color: fgColor.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: fgColor.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.settings_ethernet_rounded,
                  size: 13,
                  color: fgColor.withValues(alpha: 0.75),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: tooltipText,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => ServerConnectionDialog.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: darkBackground
                  ? Colors.white.withValues(alpha: 0.14)
                  : const Color(0xFF1A237E).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: darkBackground
                    ? Colors.white.withValues(alpha: 0.28)
                    : const Color(0xFF1A237E).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.settings_ethernet_rounded, size: 18, color: fgColor),
                const SizedBox(width: 8),
                Text(
                  'إعدادات الاتصال والسيرفر ($statusLabel)',
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ServerConnectionDialog extends ConsumerStatefulWidget {
  const ServerConnectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const ServerConnectionDialog(),
    );
  }

  @override
  ConsumerState<ServerConnectionDialog> createState() =>
      _ServerConnectionDialogState();
}

class _ServerConnectionDialogState
    extends ConsumerState<ServerConnectionDialog> {
  late bool _isServerMode;
  late TextEditingController _urlController;
  bool _isTesting = false;
  bool _isSaving = false;
  bool _isUploadingDb = false;
  ServerHealthResult? _healthResult;
  Map<String, String> _discoveredUrls = {};

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(serverConfigProvider);
    _isServerMode = cfg.isServerMode;
    _urlController = TextEditingController(text: cfg.normalizedBaseUrl);
    _loadDiscoveredServerInfo();
  }

  Future<void> _loadDiscoveredServerInfo() async {
    final info = await ServerBootstrap.readServerInfoFile();
    if (mounted && info.isNotEmpty) {
      setState(() => _discoveredUrls = info);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _healthResult = null;
    });

    final result = await ref
        .read(serverConfigProvider.notifier)
        .testConnection(_urlController.text.trim());

    if (mounted) {
      setState(() {
        _isTesting = false;
        _healthResult = result;
      });
    }
  }

  void _refreshAllDataProviders() {
    ref.invalidate(appDatabaseProvider);
    ref.invalidate(allUsersProvider);
    ref.invalidate(programNameProvider);
    ref.invalidate(personsRepositoryProvider);
    ref.invalidate(attendanceRepositoryProvider);
    ref.invalidate(areasRepositoryProvider);
    ref.invalidate(stagesRepositoryProvider);
    ref.invalidate(fathersRepositoryProvider);
    ref.invalidate(servicesRepositoryProvider);
    ref.invalidate(khorosRepositoryProvider);
    ref.invalidate(tayoRepositoryProvider);
    ref.invalidate(usersRepositoryProvider);
  }

  Future<void> _saveAndConnect() async {
    setState(() => _isSaving = true);
    try {
      final url = _urlController.text.trim();
      if (_isServerMode) {
        final health = await ref
            .read(serverConfigProvider.notifier)
            .testConnection(url);
        if (!health.ok) {
          if (mounted) {
            setState(() {
              _healthResult = health;
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  health.errorMessage ??
                      'تعذر الاتصال بالسيرفر، تأكد من تشغيل SundaySchoolServerManager',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      await ref
          .read(serverConfigProvider.notifier)
          .updateSettings(
            isServerMode: _isServerMode,
            serverUrl: url.isEmpty ? 'http://127.0.0.1:5050' : url,
          );

      if (_isServerMode && ref.read(serverConfigProvider).jwtToken != null) {
        await ref.read(signalRSyncProvider.notifier).connect();
      }

      _refreshAllDataProviders();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isServerMode
                  ? 'تم حفظ السيرفر. سجّل الدخول لتشغيل البيانات والمزامنة.'
                  : 'تم التبديل إلى قاعدة البيانات المحلية (SQLite) بنجاح.',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadLocalDbToPostgres() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('رفع قاعدة البيانات المحلية إلى PostgreSQL'),
          content: const Text(
            'سيتم رفع جميع البيانات الموجودة في ملف SQLite المحلي على هذا الجهاز إلى قاعدة بيانات PostgreSQL على السيرفر ومزامنتها فوراً مع جميع الأجهزة المتصلة.\n\nهل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نعم، ارفع البيانات الآن'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isUploadingDb = true);
    try {
      // Save URL first so upload uses the entered URL
      await ref
          .read(serverConfigProvider.notifier)
          .updateSettings(
            isServerMode: _isServerMode,
            serverUrl: _urlController.text.trim(),
          );
      final res = await ref
          .read(serverConfigProvider.notifier)
          .uploadLocalSqliteToServer(clearExisting: false);
      _refreshAllDataProviders();

      if (mounted) {
        final rows = res['rowsImported'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم رفع البيانات إلى PostgreSQL بنجاح ($rows سجل) وإشعار جميع الأجهزة عبر SignalR!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل رفع البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingDb = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signalRState = ref.watch(signalRSyncProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.settings_ethernet_rounded,
                        color: primaryColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إعدادات الاتصال والسيرفر والمزامنة',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Flutter > Dart Logic > .NET 8 > PostgreSQL > SignalR',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(height: 26),

                // Mode Selection Cards
                const Text(
                  'وضع تشغيل قاعدة البيانات:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeOption(
                        selected: _isServerMode,
                        icon: Icons.dns_rounded,
                        title: 'سيرفر مركزي (.NET + PostgreSQL)',
                        subtitle:
                            'مزامنة فورية لحظية بين جميع الأجهزة عبر SignalR',
                        onTap: () => setState(() => _isServerMode = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModeOption(
                        selected: !_isServerMode,
                        icon: Icons.storage_rounded,
                        title: 'قاعدة بيانات محلية (SQLite)',
                        subtitle: 'تشغيل منفرد على هذا الجهاز فقط بدون سيرفر',
                        onTap: () => setState(() => _isServerMode = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Server URL Input
                Text(
                  'عنوان السيرفر (Server URL):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: _isServerMode ? Colors.black87 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _urlController,
                    enabled: _isServerMode,
                    decoration: InputDecoration(
                      hintText: 'http://192.168.1.100:5050',
                      prefixIcon: const Icon(Icons.link_rounded),
                      suffixIcon: IconButton(
                        tooltip: 'استعادة العنوان الافتراضي',
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        onPressed: _isServerMode
                            ? () => setState(
                                () => _urlController.text =
                                    'http://127.0.0.1:5050',
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // Quick Fill Discovered URLs
                if (_isServerMode) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.computer, size: 15),
                        label: const Text(
                          'نفس الجهاز (127.0.0.1:5050)',
                          style: TextStyle(fontSize: 11.5),
                        ),
                        onPressed: () {
                          setState(
                            () => _urlController.text = 'http://127.0.0.1:5050',
                          );
                        },
                      ),
                      if (_discoveredUrls['LAN_URL'] != null)
                        ActionChip(
                          avatar: const Icon(Icons.lan_outlined, size: 15),
                          label: Text(
                            'الشبكة المحلية (${_discoveredUrls['LAN_URL']})',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          onPressed: () {
                            setState(
                              () => _urlController.text =
                                  _discoveredUrls['LAN_URL']!,
                            );
                          },
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Test Connection & Live SignalR Status Row
                if (_isServerMode) ...[
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.network_check_rounded, size: 18),
                        label: const Text('اختبار الاتصال بالسيرفر'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _buildSignalRStatusBadge(signalRState)),
                    ],
                  ),
                ],

                // Health Test Result Banner
                if (_healthResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _healthResult!.ok
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _healthResult!.ok
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _healthResult!.ok
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          color: _healthResult!.ok
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _healthResult!.ok
                                ? 'متصل بنجاح! محرك البيانات: ${_healthResult!.engine} (${_healthResult!.database}) — زمن الاستجابة: ${_healthResult!.latencyMs}ms'
                                : (_healthResult!.errorMessage ??
                                      'فشل الاتصال بالسيرفر'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _healthResult!.ok
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Upload Local SQLite to PostgreSQL Card
                if (_isServerMode) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_upload_outlined,
                          color: Color(0xFF1A237E),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'نقل البيانات المحلية إلى السيرفر (PostgreSQL)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              Text(
                                'رفع بيانات SQLite الحالية على هذا الجهاز إلى قاعدة بيانات PostgreSQL',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _isUploadingDb
                              ? null
                              : _uploadLocalDbToPostgres,
                          icon: _isUploadingDb
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file_rounded, size: 17),
                          label: const Text('رفع الآن'),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                // Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAndConnect,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        _isServerMode
                            ? 'حفظ واتصال بالسيرفر الآن'
                            : 'حفظ والتشغيل محلياً',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primaryColor : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? primaryColor : Colors.grey.shade600,
                ),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color: selected ? primaryColor : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: selected ? primaryColor : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalRStatusBadge(SignalRConnectionStatus status) {
    final Color color;
    final String text;
    switch (status) {
      case SignalRConnectionStatus.connected:
        color = const Color(0xFF10B981);
        text = 'SignalR: متصل (مزامنة فورية)';
      case SignalRConnectionStatus.connecting:
      case SignalRConnectionStatus.reconnecting:
        color = const Color(0xFFF59E0B);
        text = 'SignalR: جارٍ الاتصال...';
      case SignalRConnectionStatus.error:
      case SignalRConnectionStatus.disconnected:
        color = Colors.grey.shade600;
        text = 'SignalR: غير متصل حالياً';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
