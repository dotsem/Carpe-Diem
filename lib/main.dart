import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/settings/data/repositories/settings_repository.dart';
import 'package:carpe_diem/features/labels/data/repositories/label_repository.dart';
import 'package:carpe_diem/features/projects/data/repositories/project_repository.dart';
import 'package:carpe_diem/features/tasks/data/repositories/task_repository.dart';
import 'package:carpe_diem/features/history/data/repositories/history_repository.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/routes/app_router.dart';
import 'package:carpe_diem/features/common/presentation/providers/window_title_provider.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
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
  final dbHelper = DatabaseHelper();
  final database = await dbHelper.database;

  runApp(CarpeDiemApp(database: database));
}

class CarpeDiemApp extends StatelessWidget {
  final Database database;

  const CarpeDiemApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    final settingsRepo = SettingsRepository(database);
    final labelRepo = LabelRepository(database);
    final projectRepo = ProjectRepository(database);
    final taskRepo = TaskRepository(database);
    final historyRepo = HistoryRepository(database);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(settingsRepo)..loadSettings()),
        ChangeNotifierProvider(create: (_) => LabelProvider(labelRepo)..loadLabels()),
        ChangeNotifierProxyProvider<SettingsProvider, TaskProvider>(
          create: (context) => TaskProvider(
            taskRepo: taskRepo,
            projectRepo: projectRepo,
            historyRepo: historyRepo,
            settingsProvider: context.read<SettingsProvider>(),
          ),
          update: (context, settings, taskProvider) {
            final provider =
                taskProvider ??
                TaskProvider(
                  taskRepo: taskRepo,
                  projectRepo: projectRepo,
                  historyRepo: historyRepo,
                  settingsProvider: settings,
                );
            provider.refreshLayout();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ProjectProvider(projectRepo)..loadProjects()),
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
