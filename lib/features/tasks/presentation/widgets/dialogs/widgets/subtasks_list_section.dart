import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/task_card_context_menu.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubtasksListSection extends ConsumerWidget {
  final Task parentTask;
  final DateTime? scheduledDate;
  final String? projectId;

  const SubtasksListSection({super.key, required this.parentTask, this.scheduledDate, this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtasksAsync = ref.watch(subtasksProvider(parentTask.id));
    final subtasks = subtasksAsync.valueOrNull ?? [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final completedEarlier = subtasks.where((t) {
      if (!t.isCompleted) return false;
      if (t.completedAt != null) {
        final compDate = DateTime(t.completedAt!.year, t.completedAt!.month, t.completedAt!.day);
        return compDate.isBefore(today);
      }
      if (t.scheduledDate != null) {
        return t.scheduledDate!.isBefore(today);
      }
      return false;
    }).toList();

    final activeSubtasks = subtasks.where((t) => !completedEarlier.contains(t)).toList();

    final collapsedSet = ref.watch(collapsedSubtasksProvider);
    final isCollapsed = collapsedSet.contains(parentTask.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () {
                ref.read(collapsedSubtasksProvider.notifier).toggleCollapse(parentTask.id);
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCollapsed ? Icons.chevron_right : Icons.expand_more,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text('Subtasks', style: Theme.of(context).textTheme.labelLarge),
                    if (subtasks.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${subtasks.where((t) => t.isCompleted).length}/${subtasks.length})',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                context.openRightSidebar(
                  AddTaskPanel(
                    initialDate: scheduledDate ?? parentTask.scheduledDate,
                    initialProjectId: projectId ?? parentTask.projectId,
                    initialParentId: parentTask.id,
                  ),
                  ref,
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Subtask'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!isCollapsed) ...[
          if (activeSubtasks.isEmpty && completedEarlier.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'No subtasks yet',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else ...[
            if (activeSubtasks.isNotEmpty)
              Column(
                children: [
                  for (final subtask in activeSubtasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: TaskCard(
                        compactOverride: true,
                        task: subtask,
                        project: subtask.projectId != null
                            ? ref.watch(projectProvider).getById(subtask.projectId!)
                            : null,
                        useTimer: false,
                        onToggle: (_) {
                          ref.read(taskProvider.notifier).toggleComplete(subtask);
                        },
                        onTap: () {
                          context.openRightSidebar(EditTaskPanel(subtask.id), ref);
                        },
                        onContextMenu: (localPosition, renderBox) {
                          showTaskCardContextMenu(context, ref, subtask, subtasks, localPosition, renderBox);
                        },
                        hideProjectInfo: true,
                      ),
                    ),
                ],
              ),
            if (completedEarlier.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '${completedEarlier.length} ${completedEarlier.length == 1 ? 'task' : 'tasks'} already completed earlier',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
          ],
        ],
      ],
    );
  }
}
