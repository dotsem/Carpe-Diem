import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/ui/shortcuts/app_shortcuts.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/data/models/priority.dart';
import 'package:carpe_diem/data/models/project.dart';
import 'package:carpe_diem/providers/project_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 900;
    final currentPath = GoRouterState.of(context).uri.toString();

    return Scaffold(
      drawer: isMobile
          ? Drawer(
              width: 280,
              backgroundColor: AppColors.background,
              child: _SideNav(currentPath: currentPath, isMobile: true),
            )
          : null,
      body: GlobalShortcuts(
        child: Row(
          children: [
            if (!isMobile) ...[
              SizedBox(width: 220, child: _SideNav(currentPath: currentPath, isMobile: false)),
              const VerticalDivider(width: 1),
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
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surface.withValues(alpha: 0.8),
                            foregroundColor: AppColors.text,
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
      color: AppColors.background,
      child: Column(
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', width: 48),
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
            icon: Icons.folder_rounded,
            label: 'All Projects',
            shortcutHint: 'P',
            isSelected: currentPath == '/projects',
            onTap: () => _navigateTo(context, '/projects'),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'PROJECTS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ProjectProvider>(
              builder: (context, projectProvider, child) {
                final projects = List.of(projectProvider.projects)
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
                                return _NavItem(
                                  icon: Icons.circle,
                                  iconColor: project.color,
                                  iconSize: 12,
                                  label: project.name,
                                  isSelected: isSelected,
                                  onTap: () => _navigateTo(context, '/projects/${project.id}'),
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
              },
            ),
          ),
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
      padding: outerPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? (isSelected ? AppColors.accent : AppColors.textSecondary),
                  size: iconSize,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (shortcutHint != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      shortcutHint!,

                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
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
