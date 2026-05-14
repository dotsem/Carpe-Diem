import 'package:carpe_diem/core/utils/color_utils.dart';
import 'package:carpe_diem/ui/dialogs/add_project_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/data/models/priority.dart';
import 'package:carpe_diem/data/models/project.dart';
import 'package:carpe_diem/providers/project_provider.dart';

import 'package:carpe_diem/providers/window_title_provider.dart';
import 'package:carpe_diem/routes/keys.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != oldWidget.child) {
      _dismissPopups();
    }
  }

  void _dismissPopups() {
    final state = shellNavigatorKey.currentState;
    if (state != null) {
      // Use popUntil to clear all dialogues/menus and return to the base route
      state.popUntil((route) => route.isFirst);
    }
  }

  void _updateWindowTitle(BuildContext context, String path) {
    final titleProvider = context.read<WindowTitleProvider>();

    if (path == '/') {
      titleProvider.updateTitle(subtitle: 'Today');
    } else if (path == '/tasks') {
      titleProvider.updateTitle(subtitle: 'Backlog');
    } else if (path == '/projects') {
      titleProvider.updateTitle(subtitle: 'All Projects');
    } else if (path == '/settings') {
      titleProvider.updateTitle(subtitle: 'Settings');
    } else if (path.startsWith('/projects/')) {
      // Handled by ProjectDetailScreen to include project name
    } else {
      titleProvider.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 900;
    final currentPath = GoRouterState.of(context).uri.toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateWindowTitle(context, currentPath);
    });

    return Scaffold(
      drawer: isMobile
          ? Drawer(
              width: 280,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: _SideNav(currentPath: currentPath, isMobile: true),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) ...[
            SizedBox(width: 220, child: _SideNav(currentPath: currentPath, isMobile: false)),
            VerticalDivider(width: 1),
          ],
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
                  child: widget.child,
                ),
                if (isMobile)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final String currentPath;
  final bool isMobile;

  const _SideNav({required this.currentPath, required this.isMobile});

  void _navigateTo(BuildContext context, String path) {
    context.go(path);
    if (isMobile) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', width: 32),
                SizedBox(width: 8),
                Text(
                  'Carpe Diem',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
          _NavItem(
            icon: Icons.today_rounded,
            label: 'Today',
            shortcutHint: 'T',
            isSelected: currentPath == '/',
            onTap: () => _navigateTo(context, '/'),
          ),
          _NavItem(
            icon: Icons.inbox_rounded,
            label: 'Backlog',
            shortcutHint: 'B',
            isSelected: currentPath == '/tasks',
            onTap: () => _navigateTo(context, '/tasks'),
          ),
          _NavItem(
            icon: Icons.history_rounded,
            label: 'History',
            shortcutHint: 'Y',
            isSelected: currentPath == '/history',
            onTap: () => _navigateTo(context, '/history'),
          ),
          _NavItem(
            icon: Icons.folder_rounded,
            label: 'All Projects',
            shortcutHint: 'P',
            isSelected: currentPath == '/projects',
            onTap: () => _navigateTo(context, '/projects'),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
          Consumer<ProjectProvider>(
            builder: (context, projectProvider, child) {
              final projects = projectProvider.projects.where((p) => p.isActive).toList()
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
                return ElevatedButton(
                  onPressed: () => showDialog(context: context, builder: (context) => AddProjectDialog()),
                  child: Text('Create a project'),
                );
              }

              return Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  itemCount: priorities.length,
                  itemBuilder: (context, pIndex) {
                    final priority = priorities[pIndex];
                    final groupProjects = groups[priority]!;

                    return Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Stack(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: groupProjects.map((project) {
                                final isSelected = currentPath.startsWith('/projects/${project.id}');
                                return _NavItem(
                                  icon: Icons.circle,
                                  iconColor: project.color.themeDependentColor(context),
                                  iconSize: 12,
                                  label: project.name,
                                  isSelected: isSelected,
                                  onTap: () => _navigateTo(context, '/projects/${project.id}'),
                                  outerPadding: EdgeInsets.only(right: 12, top: 2, bottom: 2),
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
                ),
              );
            },
          ),
          Divider(height: 1),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isSelected: currentPath == '/settings',
            onTap: () => _navigateTo(context, '/settings'),
            outerPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsets? outerPadding;
  final String? shortcutHint;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.iconColor,
    this.iconSize = 20,
    this.outerPadding,
    this.shortcutHint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: outerPadding ?? EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? (isSelected ? AppColors.accent : Theme.of(context).colorScheme.onSurfaceVariant),
                  size: iconSize,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (shortcutHint != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      shortcutHint!,

                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
