import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/task_card_context_menu.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/add_task_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/edit_task_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubtasksListSection extends ConsumerWidget {
  final Task parentTask;
  final DateTime? scheduledDate;
  final String? projectId;

  const SubtasksListSection({
    super.key,
    required this.parentTask,
    this.scheduledDate,
    this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTasks = ref.watch(taskProvider).tasks;
    final subtasks = allTasks
        .where((t) => t.parentId == parentTask.id)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtasks', style: Theme.of(context).textTheme.labelLarge),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AddTaskDialog(
                    initialDate: scheduledDate,
                    initialProjectId: projectId,
                    initialParentId: parentTask.id,
                  ),
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
        if (subtasks.isEmpty)
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
        else
          Column(
            children: [
              for (final subtask in subtasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: TaskCard(
                    task: subtask,
                    project: subtask.projectId != null
                        ? ref.watch(projectProvider).getById(subtask.projectId!)
                        : null,
                    useTimer: false,
                    onToggle: (_) {
                      ref.read(taskProvider.notifier).toggleComplete(subtask);
                    },
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => EditTaskDialog(task: subtask),
                      );
                    },
                    onContextMenu: (localPosition, renderBox) {
                      showTaskCardContextMenu(
                        context,
                        ref,
                        subtask,
                        allTasks,
                        localPosition,
                        renderBox,
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
