import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ribbon_controller.dart';
import 'ribbon_models.dart';

class RibbonCommandShelf extends ConsumerWidget {
  final RibbonTab? activeTab;

  const RibbonCommandShelf({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(ribbonCollapsedProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Fluent Office Command Shelf colors
    final shelfBackground = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      height: isCollapsed ? 0 : 62,
      child: isCollapsed
          ? const SizedBox.shrink()
          : Container(
              decoration: BoxDecoration(
                color: shelfBackground,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: activeTab == null || activeTab!.groups.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد أدوات متاحة لهذا التبويب',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < activeTab!.groups.length; i++) ...[
                            _buildGroupWidget(context, activeTab!.groups[i]),
                            if (i < activeTab!.groups.length - 1)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
                                child: VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  color: borderColor,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildGroupWidget(BuildContext context, RibbonGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Group Action Buttons
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: group.actions.map((action) => _buildActionButton(context, action)).toList(),
          ),
        ),
        // Word 365 Group Label at the bottom
        Container(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            group.title,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, RibbonAction action) {
    final tooltipText = StringBuffer(action.label);
    if (action.tooltip != null) {
      tooltipText.write(' - ${action.tooltip}');
    }
    if (action.shortcut != null) {
      tooltipText.write(' (${action.shortcut})');
    }

    final isSelected = action.isSelected;
    final isPrimary = action.isPrimary;
    final isDestructive = action.isDestructive;

    Color iconColor;
    Color textColor;
    Color? bgColor;
    Border? border;

    if (isSelected) {
      bgColor = isPrimary
          ? const Color(0xFFDBEAFE)
          : (isDestructive ? Colors.red.shade50 : const Color(0xFFCCFBF1));
      iconColor = isPrimary
          ? const Color(0xFF1D4ED8)
          : (isDestructive ? Colors.red.shade700 : const Color(0xFF0F766E));
      textColor = iconColor;
      border = Border.all(color: iconColor.withOpacity(0.5), width: 1.0);
    } else if (isPrimary) {
      iconColor = const Color(0xFF1D4ED8);
      textColor = const Color(0xFF0F172A);
      bgColor = Colors.white;
      border = Border.all(color: const Color(0xFF93C5FD), width: 0.9);
    } else if (isDestructive) {
      iconColor = const Color(0xFFDC2626);
      textColor = const Color(0xFF991B1B);
    } else {
      iconColor = const Color(0xFF334155);
      textColor = const Color(0xFF1E293B);
    }

    // Icon-Only Mode (Space Saving)
    if (action.isIconOnly) {
      return Tooltip(
        message: tooltipText.toString(),
        waitDuration: const Duration(milliseconds: 300),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: action.isEnabled ? action.onPressed : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 32,
              height: 34,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: bgColor ?? Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: border,
              ),
              child: Opacity(
                opacity: action.isEnabled ? 1.0 : 0.45,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(action.icon, size: 18, color: iconColor),
                    if (action.badgeCount != null && action.badgeCount! > 0)
                      Positioned(
                        top: -3,
                        left: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${action.badgeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Compact Label + Icon Mode
    return Tooltip(
      message: tooltipText.toString(),
      waitDuration: const Duration(milliseconds: 350),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: action.isEnabled ? action.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: bgColor ?? Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: border,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: iconColor.withOpacity(0.18),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Opacity(
              opacity: action.isEnabled ? 1.0 : 0.45,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        action.icon,
                        size: 17,
                        color: iconColor,
                      ),
                      if (action.badgeCount != null && action.badgeCount! > 0)
                        Positioned(
                          top: -3,
                          left: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${action.badgeCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: isSelected || isPrimary ? FontWeight.w800 : FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
