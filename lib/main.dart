import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/routes/app_router.dart';
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

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
    ],
  );

  // Eagerly load all providers before running the app to ensure data is ready on first frame
  await container.read(settingsProvider.notifier).loadSettings();
  await container.read(labelProvider.notifier).loadLabels();
  await container.read(projectProvider.notifier).loadProjects();
  await container.read(taskProvider.notifier).loadTasksForDate(DateTime.now());
  await container.read(taskProvider.notifier).loadUnscheduledTasks();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CarpeDiemApp(),
    ),
  );
}

class CarpeDiemApp extends ConsumerWidget {
  const CarpeDiemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch settings state to trigger rebuilds on settings changes
    final settings = ref.watch(settingsProvider);

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
        locale: settings.firstDayOfWeek == DateTime.monday
            ? const Locale('en', 'GB')
            : const Locale('en', 'US'),
        builder: (context, child) {
          return GlobalShortcuts(child: child!);
        },
      ),
    );
  }
}
