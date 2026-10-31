import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/settings_repository.dart';

class ThemeState {
  final ThemeMode themeMode;
  final Color primaryColor;

  const ThemeState({
    required this.themeMode,
    required this.primaryColor,
  });

  bool get isDarkMode => themeMode == ThemeMode.dark;

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? primaryColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const String _themeModeKey = 'app_theme_mode';
  static const String _primaryColorKey = 'app_primary_color';
  static const Color defaultPrimary = Color(0xFF1A237E);

  @override
  ThemeState build() {
    Future.microtask(() => _loadSettings());
    return const ThemeState(
      themeMode: ThemeMode.light,
      primaryColor: defaultPrimary,
    );
  }

  static Color? parseHexColor(String? hexString) {
    if (hexString == null || hexString.trim().isEmpty) return null;
    var hex = hexString.replaceAll('#', '').replaceAll('0x', '').trim();
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length == 8) {
      final val = int.tryParse(hex, radix: 16);
      if (val != null) {
        return Color(val);
      }
    }
    return null;
  }

  static String colorToHex(Color color) {
    return '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_themeModeKey);
      final colorStr = prefs.getString(_primaryColorKey);

      ThemeMode loadedMode = state.themeMode;
      Color loadedColor = state.primaryColor;

      if (modeStr != null) {
        if (modeStr == 'dark') loadedMode = ThemeMode.dark;
        if (modeStr == 'light') loadedMode = ThemeMode.light;
      } else {
        try {
          final dbMode = await ref.read(settingsRepositoryProvider).getSetting('theme_mode');
          if (dbMode == 'dark') loadedMode = ThemeMode.dark;
          if (dbMode == 'light') loadedMode = ThemeMode.light;
        } catch (_) {}
      }

      if (colorStr != null) {
        final parsed = parseHexColor(colorStr);
        if (parsed != null) loadedColor = parsed;
      } else {
        try {
          final dbColor = await ref.read(settingsRepositoryProvider).getSetting('theme_primary_color');
          final parsed = parseHexColor(dbColor);
          if (parsed != null) loadedColor = parsed;
        } catch (_) {}
      }

      state = state.copyWith(themeMode: loadedMode, primaryColor: loadedColor);
    } catch (_) {}
  }

  Future<void> toggleThemeMode() async {
    final newMode = state.isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final modeStr = mode == ThemeMode.dark ? 'dark' : 'light';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, modeStr);
      await ref.read(settingsRepositoryProvider).saveSetting('theme_mode', modeStr);
    } catch (_) {}
  }

  Future<void> setPrimaryColor(Color color) async {
    state = state.copyWith(primaryColor: color);
    final hex = colorToHex(color);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_primaryColorKey, hex);
      await ref.read(settingsRepositoryProvider).saveSetting('theme_primary_color', hex);
    } catch (_) {}
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);
