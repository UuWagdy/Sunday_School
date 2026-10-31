import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ribbon_controller.dart';
import 'ribbon_models.dart';

class RibbonMobileBar extends ConsumerWidget {
  final List<RibbonTab> tabs;
  final RibbonTab? activeTab;
  final ValueChanged<RibbonTabId> onTabSelected;

  const RibbonMobileBar({
    super.key,
    required this.tabs,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTabId = ref.watch(ribbonActiveTabProvider);
    final theme = Theme.of(context);

    // All actions in the active tab flattened for mobile chips
    final flattenedActions = activeTab?.groups.expand((g) => g.actions).toList() ?? [];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B365D), // Navy header
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tier 1: Scrollable Pill Tabs (الصف العلوي للتبويبات الرئيسية)
          SizedBox(
            height: 44,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  // File Pill Tab
                  _buildFilePill(context, activeTabId == RibbonTabId.file),
                  const SizedBox(width: 6),
                  // Other Pill Tabs
                  ...tabs.map((tab) {
                    final isActive = tab.id == activeTabId;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: InkWell(
                        onTap: () => onTabSelected(tab.id),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tab.icon,
                                size: 14,
                                color: isActive ? theme.primaryColor : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tab.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                  color: isActive ? theme.primaryColor : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Tier 2: Scrollable Action Chips (الصف السفلي لرقاقات العمليات السريعة)
          if (flattenedActions.isNotEmpty)
            Container(
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), // Light shelf background
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: flattenedActions.map((action) {
                    final isSelected = action.isSelected;
                    final isPrimary = action.isPrimary;
                    final isDestructive = action.isDestructive;

                    Color chipColor = Colors.white;
                    Color textColor = const Color(0xFF1E293B);
                    Color iconColor = const Color(0xFF475569);
                    BorderSide borderSide = const BorderSide(color: Color(0xFFCBD5E1));

                    if (isSelected) {
                      chipColor = isPrimary
                          ? const Color(0xFFDBEAFE)
                          : (isDestructive ? Colors.red.shade100 : const Color(0xFFCCFBF1));
                      textColor = isPrimary
                          ? const Color(0xFF1D4ED8)
                          : (isDestructive ? Colors.red.shade800 : const Color(0xFF0F766E));
                      iconColor = textColor;
                      borderSide = BorderSide(color: textColor, width: 1.2);
                    } else if (isPrimary) {
                      chipColor = const Color(0xFFEFF6FF);
                      textColor = const Color(0xFF1D4ED8);
                      iconColor = textColor;
                      borderSide = const BorderSide(color: Color(0xFF93C5FD));
                    } else if (isDestructive) {
                      textColor = Colors.red.shade700;
                      iconColor = textColor;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ActionChip(
                        onPressed: action.isEnabled ? action.onPressed : null,
                        avatar: Icon(action.icon, size: 15, color: iconColor),
                        label: Text(
                          action.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected || isPrimary ? FontWeight.bold : FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        backgroundColor: chipColor,
                        side: borderSide,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilePill(BuildContext context, bool isActive) {
    return InkWell(
      onTap: () => onTabSelected(RibbonTabId.file),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.white : const Color(0xFF3B82F6),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_shared_rounded,
              size: 14,
              color: isActive ? const Color(0xFF1D4ED8) : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              'ملف',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF1D4ED8) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
