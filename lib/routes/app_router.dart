import 'package:carpe_diem/features/common/presentation/shell/app_shell.dart';
import 'package:carpe_diem/features/history/presentation/screens/history_screen.dart';
import 'package:carpe_diem/features/projects/presentation/screens/project_detail_screen.dart';
import 'package:carpe_diem/features/projects/presentation/screens/projects_screen.dart';
import 'package:carpe_diem/features/settings/presentation/screens/settings_screen.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/section.dart';
import 'package:carpe_diem/features/tasks/presentation/screens/backlog_screen.dart';
import 'package:carpe_diem/features/tasks/presentation/screens/home_screen.dart';
import 'package:carpe_diem/routes/keys.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

Section? parseSettingsSection(Uri uri, Object? extra) {
  final sectionParam = uri.queryParameters['section'];
  if (sectionParam == 'filtering' || sectionParam == 'modes') {
    return Section.filteringAndModes;
  }
  if (sectionParam != null) {
    for (final section in Section.values) {
      if (section.name == sectionParam) return section;
    }
    return null;
  }
  return extra is Section ? extra : null;
}

// why: declarative route builders are verified through findMatch without
// constructing screens and their repository graphs.
// coverage:ignore-start
final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/projects',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProjectsScreen()),
        ),
        GoRoute(
          path: '/projects/:projectId',
          pageBuilder: (context, state) {
            final projectId = state.pathParameters['projectId']!;
            return NoTransitionPage(
              child: ProjectDetailScreen(projectId: projectId),
            );
          },
        ),
        GoRoute(
          path: '/tasks',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: BacklogScreen()),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HistoryScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) {
            final section = parseSettingsSection(state.uri, state.extra);
            return NoTransitionPage(
              child: SettingsScreen(
                key: ValueKey(section),
                initialSection: section,
              ),
            );
          },
        ),
      ],
    ),
  ],
);
// coverage:ignore-end
