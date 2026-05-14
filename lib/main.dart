import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/data/database/database_helper.dart';
import 'package:carpe_diem/providers/label_provider.dart';
import 'package:carpe_diem/providers/settings_provider.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/providers/filter_provider.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/routes/app_router.dart';
import 'package:carpe_diem/providers/window_title_provider.dart';
import 'package:carpe_diem/ui/shortcuts/app_shortcuts.dart';
import 'package:toastification/toastification.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await windowManager.ensureInitialized();
  } catch (e) {
    debugPrint('WindowManager initialization failed: $e');
  }
  await DatabaseHelper.initialize();

  runApp(const CarpeDiemApp());
}

class CarpeDiemApp extends StatelessWidget {
  const CarpeDiemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => LabelProvider()..loadLabels()),
        ChangeNotifierProxyProvider<SettingsProvider, TaskProvider>(
          create: (context) => TaskProvider(context.read<SettingsProvider>()),
          update: (_, settings, taskProvider) {
            final provider = taskProvider ?? TaskProvider(settings);
            provider.refreshLayout();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ProjectProvider()..loadProjects()),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
        ChangeNotifierProvider(create: (_) => WindowTitleProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ToastificationWrapper(
            child: MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: true, // Leave this on true!
              theme: AppTheme.light(null),
              darkTheme: AppTheme.dark(null),
              themeMode: settings.themeMode,
              routerConfig: appRouter,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              supportedLocales: const [Locale('en', 'US'), Locale('en', 'GB')],
              locale: settings.firstDayOfWeek == DateTime.monday ? const Locale('en', 'GB') : const Locale('en', 'US'),
              builder: (context, child) {
                return GlobalShortcuts(child: child!);
              },
            ),
          );
        },
      ),
    );
  }
}
