import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carpe_diem/features/common/presentation/providers/window_title_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/side_nav.dart';
import 'package:carpe_diem/routes/keys.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/core/utils/toast_utils.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
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
      // Handled by ProjectDetailScreen to include project name
    } else {
      titleNotifier.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UndoRedoState>(undoRedoProvider, (previous, next) {
      if (next.isProcessing) return;

      final opType = next.lastOperationType;
      if (opType == UndoRedoOperationType.none) return;

      if (opType == UndoRedoOperationType.execute && next.canUndo) {
        if (next.undoDescription != null) {
          ToastUtils.showUndoable(
            next.undoDescription!,
            () => ref.read(undoRedoProvider.notifier).undo(),
            context: context,
          );
        }
      } else if (opType == UndoRedoOperationType.redo && next.canUndo) {
        if (next.undoDescription != null) {
          ToastUtils.showUndoable(
            'Redone: ${next.undoDescription}',
            () => ref.read(undoRedoProvider.notifier).undo(),
            context: context,
          );
        }
      } else if (opType == UndoRedoOperationType.undo) {
        if (next.redoDescription != null) {
          ToastUtils.showSuccess(
            'Undone: ${next.redoDescription}',
            context: context,
          );
        }
      }
    });

    final width = MediaQuery.sizeOf(context).width;

    final isMobile = width < 900;
    final currentPath = GoRouterState.of(context).uri.toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateWindowTitle(ref, currentPath);
    });

    return Scaffold(
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
            SizedBox(width: 220, child: SideNav(currentPath: currentPath, isMobile: false)),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: currentPath == '/settings' ? 0 : (isMobile ? 16 : 32),
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
