import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
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
              color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.undo_rounded),
                  onPressed: state.canUndo ? () => ref.read(undoRedoProvider.notifier).undo() : null,
                  tooltip: 'Undo',
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.redo_rounded),
                  onPressed: state.canRedo ? () => ref.read(undoRedoProvider.notifier).redo() : null,
                  tooltip: 'Redo',
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () {
                    showDialog(context: context, builder: (context) => const ActionHistoryDialog());
                  },
                  tooltip: 'Action History',
                  style: IconButton.styleFrom(foregroundColor: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActionHistoryDialog extends ConsumerWidget {
  const ActionHistoryDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final undoRedoState = ref.watch(undoRedoProvider);
    final theme = Theme.of(context);

    final undoStack = undoRedoState.undoStack;
    final redoStack = undoRedoState.redoStack;

    final timeline = [...undoStack, ...redoStack.reversed];

    return SizedDialog(
      title: 'Action History',
      showDefaultActions: false,
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      child: SizedBox(
        width: 450,
        height: 300,
        child: timeline.isEmpty
            ? const Center(child: Text('No action history available'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: timeline.length,
                itemBuilder: (context, index) {
                  final cmd = timeline[index];
                  final isApplied = index < undoStack.length;

                  final tooltipMessage = isApplied
                      ? (index == undoStack.length - 1 ? 'Current state' : 'Revert to this action')
                      : 'Apply up to this action';

                  return Tooltip(
                    message: tooltipMessage,
                    child: Opacity(
                      opacity: isApplied ? 1.0 : 0.5,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onTap: undoRedoState.isProcessing
                            ? null
                            : () => ref.read(undoRedoProvider.notifier).jumpTo(cmd),
                        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                        leading: Icon(
                          isApplied ? Icons.check_circle_outline_rounded : Icons.history_rounded,
                          color: isApplied ? AppColors.accent : theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          cmd.description,
                          style: TextStyle(
                            decoration: isApplied ? null : TextDecoration.lineThrough,
                            fontWeight: isApplied ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        trailing: Text(
                          isApplied ? 'Applied' : 'Undone',
                          style: TextStyle(
                            fontSize: 11,
                            color: isApplied ? AppColors.accent : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
