import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ribbon_controller.dart';
import 'ribbon_models.dart';

class RibbonTabsBar extends ConsumerWidget {
  final List<RibbonTab> tabs;
  final ValueChanged<RibbonTabId> onTabSelected;

  const RibbonTabsBar({
    super.key,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTabId = ref.watch(ribbonActiveTabProvider);
    final isCollapsed = ref.watch(ribbonCollapsedProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Microsoft Office 365 Tab Header colors
    final barBackground = isDark ? const Color(0xFF0F172A) : const Color(0xFF102A43);
    final activeTabBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final activeTextColor = isDark ? Colors.white : const Color(0xFF0F2445);
    final activeIconColor = const Color(0xFF2563EB);
    final inactiveTextColor = const Color(0xFFCBD5E1);
    final inactiveIconColor = const Color(0xFF94A3B8);

    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: barBackground,
        border: Border(
          bottom: BorderSide(
            color: activeTabBg,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // "ملف" (File) Tab Button
          _buildFileTabButton(context, ref, activeTabId, isDark),

          const SizedBox(width: 4),

          // Main Horizontal Ribbon Tabs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: tabs.map((tab) {
                  final isActive = tab.id == activeTabId;

                  return Container(
                    margin: const EdgeInsets.only(left: 2, right: 2, top: 3),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        onTap: () => onTabSelected(tab.id),
                        hoverColor: Colors.white.withOpacity(0.08),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isActive ? activeTabBg : Colors.transparent,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            border: isActive
                                ? const Border(
                                    top: BorderSide(color: Color(0xFF2563EB), width: 3.0),
                                    left: BorderSide(color: Color(0xFFCBD5E1), width: 0.8),
                                    right: BorderSide(color: Color(0xFFCBD5E1), width: 0.8),
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tab.icon,
                                size: 15,
                                color: isActive ? activeIconColor : inactiveIconColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tab.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                  color: isActive ? activeTextColor : inactiveTextColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (tab.badgeCount != null && tab.badgeCount! > 0) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${tab.badgeCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Collapse / Expand Ribbon Button (Ctrl+F1)
          Tooltip(
            message: isCollapsed ? 'توسيع شريط الأدوات (Ctrl+F1)' : 'طي شريط الأدوات (Ctrl+F1)',
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                ref.read(ribbonCollapsedProvider.notifier).toggle();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  isCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTabButton(
    BuildContext context,
    WidgetRef ref,
    RibbonTabId activeTabId,
    bool isDark,
  ) {
    final isFileActive = activeTabId == RibbonTabId.file;

    return Container(
      margin: const EdgeInsets.only(top: 3, right: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          onTap: () => onTabSelected(RibbonTabId.file),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFileActive ? const Color(0xFF1D4ED8) : const Color(0xFF2563EB),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              border: isFileActive
                  ? const Border(
                      top: BorderSide(color: Color(0xFF93C5FD), width: 3.0),
                    )
                  : null,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_shared_rounded, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'ملف',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
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
