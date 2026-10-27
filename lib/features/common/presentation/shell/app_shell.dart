import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carpe_diem/core/theme/app_breakpoints.dart';
import 'package:carpe_diem/features/settings/presentation/constants/settings_constants.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/window_title_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/side_nav.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_container.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/routes/keys.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/action_toast_handler.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _sidebarKey = GlobalKey();

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != oldWidget.child) {
      _dismissPopups();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(rightSidebarProvider.notifier).close();
        }
      });
    }
  }

  void _dismissPopups() {
    final state = shellNavigatorKey.currentState;
    if (state != null) {
      state.popUntil((route) => route.isFirst);
    }
  }

  void _updateWindowTitle(WidgetRef ref, String path) {
    final titleNotifier = ref.read(windowTitleProvider.notifier);

    if (path == '/') {
      titleNotifier.updateTitle(subtitle: 'Today');
    } else if (path == '/tasks') {
      titleNotifier.updateTitle(subtitle: 'Backlog');
    } else if (path == '/projects') {
      titleNotifier.updateTitle(subtitle: 'All Projects');
    } else if (path == '/settings') {
      titleNotifier.updateTitle(subtitle: 'Settings');
    } else if (path.startsWith('/projects/')) {
      // Handled by ProjectDetailScreen
    } else {
      titleNotifier.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UndoRedoState>(undoRedoProvider, (previous, next) {
      ActionToastHandler.handleUndoRedoStateChange(ref, context, next);
    });

    final isMobile = context.isMobile;
    final settings = ref.watch(settingsProvider);
    final isDocked =
        !isMobile &&
        settings.rightPanelPresentation == RightPanelPresentation.docked &&
        context.isScreenAtLeast(AppBreakpoint.lg);

    final currentPath = GoRouterState.of(context).uri.toString();
    final rightSidebarState = ref.watch(rightSidebarProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateWindowTitle(ref, currentPath);
    });

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? Drawer(
              width: 280,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: SideNav(currentPath: currentPath, isMobile: true),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) ...[
            SizedBox(
              width: 220,
              child: SideNav(currentPath: currentPath, isMobile: false),
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: currentPath == '/settings'
                        ? 0
                        : (isMobile ? 16 : 32),
                  ),
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
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.8),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!isDocked && rightSidebarState.isOpen) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          ref.read(rightSidebarProvider.notifier).close(),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: isMobile ? 320 : 420,
                    child: Material(
                      elevation: 16,
                      color: Theme.of(context).colorScheme.surface,
                      child: RightSidebarContainer(key: _sidebarKey),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isDocked && rightSidebarState.isOpen) ...[
            const VerticalDivider(width: 1),
            SizedBox(
              width: 420,
              child: RightSidebarContainer(key: _sidebarKey),
            ),
          ],
        ],
      ),
    );
  }
}
