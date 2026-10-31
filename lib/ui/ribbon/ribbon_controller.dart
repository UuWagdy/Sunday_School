import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ribbon_models.dart';

class RibbonActiveTabNotifier extends Notifier<RibbonTabId> {
  @override
  RibbonTabId build() => RibbonTabId.home;

  void setTab(RibbonTabId tab) => state = tab;
}

final ribbonActiveTabProvider =
    NotifierProvider<RibbonActiveTabNotifier, RibbonTabId>(RibbonActiveTabNotifier.new);

class RibbonCollapsedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setCollapsed(bool val) => state = val;
}

final ribbonCollapsedProvider =
    NotifierProvider<RibbonCollapsedNotifier, bool>(RibbonCollapsedNotifier.new);

class RibbonAutoSaveNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final ribbonAutoSaveProvider =
    NotifierProvider<RibbonAutoSaveNotifier, bool>(RibbonAutoSaveNotifier.new);

class RibbonSyncStatusNotifier extends Notifier<RibbonSyncState> {
  @override
  RibbonSyncState build() => RibbonSyncState.synced;

  void setStatus(RibbonSyncState status) => state = status;
}

final ribbonSyncStatusProvider =
    NotifierProvider<RibbonSyncStatusNotifier, RibbonSyncState>(RibbonSyncStatusNotifier.new);
