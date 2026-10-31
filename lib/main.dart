import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquidify/liquidify.dart';
import 'repositories/settings_repository.dart';
import 'screens/main_shell.dart';
import 'sync/server_connection_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'sync/data_change_coordinator.dart';
import 'widgets/data_scope_boundary.dart';
import 'services/database_backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServerBootstrap.ensureInitialized();
  DatabaseBackupService.automatic.start();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dataChangeCoordinatorProvider.select((_) => true));
    final programName =
        ref.watch(programNameProvider).value ??
        SettingsRepository.defaultProgramName;

    final themeState = ref.watch(themeProvider);
    final isDark = themeState.isDarkMode;
    final primaryColor = themeState.primaryColor;

    final glassOptions = AppTheme.getLiquidGlassOptions(
      isDark: isDark,
      primaryColor: primaryColor,
    );

    final app = MaterialApp(
      debugShowCheckedModeBanner: false,
      title: programName,
      themeMode: themeState.themeMode,
      theme: AppTheme.buildLightTheme(primaryColor),
      darkTheme: AppTheme.buildDarkTheme(primaryColor),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', ''), Locale('en', '')],
      locale: const Locale('ar', ''),
      home: const MainShell(),
    );
    // Includes Navigator routes/dialogs as well as tabs, so a different data
    // session cannot retain an open editor from a wider scope.
    return LiquidGlassTheme(
      options: glassOptions,
      child: DataScopeBoundary(child: app),
    );
  }
}
