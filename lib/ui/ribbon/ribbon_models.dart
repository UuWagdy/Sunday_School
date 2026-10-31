import 'package:flutter/material.dart';

enum RibbonTabId {
  file,
  home,
  students,
  servants,
  attendance,
  activities,
  reports,
}

enum RibbonSyncState {
  synced,
  syncing,
  offline,
}

class RibbonAction {
  final String id;
  final String label;
  final IconData icon;
  final String? tooltip;
  final String? shortcut;
  final bool isPrimary;
  final bool isDestructive;
  final bool isSelected;
  final bool isEnabled;
  final bool isIconOnly;
  final int? badgeCount;
  final VoidCallback? onPressed;

  const RibbonAction({
    required this.id,
    required this.label,
    required this.icon,
    this.tooltip,
    this.shortcut,
    this.isPrimary = false,
    this.isDestructive = false,
    this.isSelected = false,
    this.isEnabled = true,
    this.isIconOnly = false,
    this.badgeCount,
    this.onPressed,
  });

  RibbonAction copyWith({
    String? id,
    String? label,
    IconData? icon,
    String? tooltip,
    String? shortcut,
    bool? isPrimary,
    bool? isDestructive,
    bool? isSelected,
    bool? isEnabled,
    bool? isIconOnly,
    int? badgeCount,
    VoidCallback? onPressed,
  }) {
    return RibbonAction(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      tooltip: tooltip ?? this.tooltip,
      shortcut: shortcut ?? this.shortcut,
      isPrimary: isPrimary ?? this.isPrimary,
      isDestructive: isDestructive ?? this.isDestructive,
      isSelected: isSelected ?? this.isSelected,
      isEnabled: isEnabled ?? this.isEnabled,
      isIconOnly: isIconOnly ?? this.isIconOnly,
      badgeCount: badgeCount ?? this.badgeCount,
      onPressed: onPressed ?? this.onPressed,
    );
  }
}

class RibbonGroup {
  final String id;
  final String title;
  final List<RibbonAction> actions;

  const RibbonGroup({
    required this.id,
    required this.title,
    required this.actions,
  });
}

class RibbonTab {
  final RibbonTabId id;
  final String label;
  final IconData icon;
  final List<RibbonGroup> groups;
  final int defaultScreenIndex;
  final int? badgeCount;

  const RibbonTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.groups,
    required this.defaultScreenIndex,
    this.badgeCount,
  });
}
