import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/action_toast_handler.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UndoRedoPanel extends ConsumerWidget {
  const UndoRedoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(undoRedoProvider);
    final hasActions = state.canUndo || state.canRedo;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: hasActions ? 56.0 : 0.0,
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Container(
            height: 56.0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh.withValues(
                alpha: 0.5,
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.undo_rounded),
                  onPressed: state.canUndo
                      ? () => ref.read(undoRedoProvider.notifier).undo()
                      : null,
                  tooltip: 'Undo',
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    disabledForegroundColor: theme.colorScheme.onSurface
                        .withValues(alpha: 0.3),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.redo_rounded),
                  onPressed: state.canRedo
                      ? () => ref.read(undoRedoProvider.notifier).redo()
                      : null,
                  tooltip: 'Redo',
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    disabledForegroundColor: theme.colorScheme.onSurface
                        .withValues(alpha: 0.3),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () {
                    ref
                        .read(rightSidebarProvider.notifier)
                        .open(const ActionHistoryPanel());
                  },
                  tooltip: 'Action History',
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
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

class ActionHistoryPanelWidget extends ConsumerWidget {
  const ActionHistoryPanelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final undoRedoState = ref.watch(undoRedoProvider);
    final theme = Theme.of(context);

    final undoStack = undoRedoState.undoStack;
    final redoStack = undoRedoState.redoStack;

    final timeline = [...redoStack, ...undoStack.reversed];

    if (timeline.isEmpty) {
      return const Center(child: Text('No action history available'));
    }

    final hasRedo = redoStack.isNotEmpty;
    final itemCount = timeline.length + (hasRedo ? 1 : 0);
    final dividerIndex = redoStack.length;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (hasRedo && index == dividerIndex) {
          return const _CurrentStateDivider();
        }

        final cmdIndex = hasRedo && index > dividerIndex ? index - 1 : index;
        final cmd = timeline[cmdIndex];
        final isApplied = cmdIndex >= redoStack.length;
        final isCurrent = isApplied && (cmd == undoStack.lastOrNull);

        final actionData = ActionToastHandler.resolveExecuteToastData(cmd: cmd);
        final actionColor = actionData.primaryColor ?? AppColors.info;

        final tooltipMessage = isApplied
            ? (isCurrent ? 'Current state' : 'Revert to this action')
            : 'Apply up to this action';

        return Tooltip(
          message: tooltipMessage,
          child: Opacity(
            opacity: isApplied ? 1.0 : 0.5,
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                onTap: undoRedoState.isProcessing || isCurrent
                    ? null
                    : () => ref.read(undoRedoProvider.notifier).jumpTo(cmd),
                hoverColor: isCurrent
                    ? Colors.transparent
                    : theme.colorScheme.primary.withValues(alpha: 0.08),
                leading: Icon(
                  actionData.icon,
                  color: isApplied
                      ? actionColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  cmd.description,
                  style: TextStyle(
                    decoration: isApplied ? null : TextDecoration.lineThrough,
                    fontWeight: isApplied ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                subtitle: actionData.subtitle != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_off_outlined,
                            size: 11,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              actionData.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCurrent) ...[
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: actionColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Text(
                      isApplied ? 'Applied' : 'Undone',
                      style: TextStyle(
                        fontSize: 11,
                        color: isApplied
                            ? actionColor
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CurrentStateDivider extends StatelessWidget {
  const _CurrentStateDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: color.withValues(alpha: 0.25), thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Current state',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: color.withValues(alpha: 0.25), thickness: 1),
          ),
        ],
      ),
    );
  }
}
