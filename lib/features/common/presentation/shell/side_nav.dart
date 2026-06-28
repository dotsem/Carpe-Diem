import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
import 'package:carpe_diem/features/common/presentation/widgets/navigation_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/color_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/dialogs/add_project_dialog.dart';
import 'package:carpe_diem/features/common/presentation/shell/undo_redo_panel.dart';

class SideNav extends ConsumerWidget {
  final String currentPath;
  final bool isMobile;

  const SideNav({super.key, required this.currentPath, required this.isMobile});

  void _navigateTo(BuildContext context, String path) {
    context.go(path);
    if (isMobile) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', width: 32),
                const SizedBox(width: 8),
                Text(
                  'Carpe Diem',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          NavigationItem(
            icon: Icons.today_rounded,
            label: 'Today',
            shortcutHint: TodayKeys.upper,
            isSelected: currentPath == '/',
            onTap: () => _navigateTo(context, '/'),
          ),
          NavigationItem(
            icon: Icons.inbox_rounded,
            label: 'Backlog',
            shortcutHint: BacklogKeys.upper,
            isSelected: currentPath == '/tasks',
            onTap: () => _navigateTo(context, '/tasks'),
          ),
          NavigationItem(
            icon: Icons.history_rounded,
            label: 'History',
            shortcutHint: HistoryKeys.upper,
            isSelected: currentPath == '/history',
            onTap: () => _navigateTo(context, '/history'),
          ),
          NavigationItem(
            icon: Icons.folder_rounded,
            label: 'All Projects',
            shortcutHint: ProjectsKeys.upper,
            isSelected: currentPath == '/projects',
            onTap: () => _navigateTo(context, '/projects'),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PROJECTS',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          Expanded(
            child: ProjectList(currentPath: currentPath, onProjectSelected: (path) => _navigateTo(context, path)),
          ),
          const Divider(height: 1),
          const UndoRedoPanel(),
          NavigationItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isSelected: currentPath == '/settings',
            onTap: () => _navigateTo(context, '/settings'),
            outerPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class ProjectList extends ConsumerWidget {
  final String currentPath;
  final ValueChanged<String> onProjectSelected;

  const ProjectList({super.key, required this.currentPath, required this.onProjectSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectState = ref.watch(projectProvider);
    final projects = projectState.projects.where((p) => p.isActive).toList()
      ..sort((a, b) {
        final pComp = b.priority.index.compareTo(a.priority.index);
        if (pComp != 0) return pComp;
        return a.name.compareTo(b.name);
      });

    final groups = <Priority, List<Project>>{};
    for (final project in projects) {
      groups.putIfAbsent(project.priority, () => []).add(project);
    }

    final priorities = groups.keys.toList()..sort((a, b) => b.index.compareTo(a.index));

    if (projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => showDialog(context: context, builder: (context) => const AddProjectDialog()),
            icon: const Icon(Icons.add),
            label: const Text('Create a project'),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: priorities.length,
      itemBuilder: (context, pIndex) {
        final priority = priorities[pIndex];
        final groupProjects = groups[priority]!;

        return Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: groupProjects.map((project) {
                    final isSelected = currentPath.startsWith('/projects/${project.id}');
                    return NavigationItem(
                      icon: Icons.circle,
                      iconColor: project.color.themeDependentColor(context),
                      iconSize: 12,
                      label: project.name,
                      isSelected: isSelected,
                      onTap: () => onProjectSelected('/projects/${project.id}'),
                      outerPadding: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
                    );
                  }).toList(),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: Container(
                  decoration: BoxDecoration(color: priority.color, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
