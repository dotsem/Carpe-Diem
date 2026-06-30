import 'package:carpe_diem/features/tasks/presentation/providers/selected_date_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_layout.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/kanban/kanban_board.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_list_view.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card_context_menu.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/add_task_dialog.dart';

class HomePlannerPane extends ConsumerWidget {
  final Map<String, FocusNode> itemFocusNodes;
  final ValueChanged<List<String>> onOrderedIdsChanged;
  final ValueChanged<Task> onEdit;

  const HomePlannerPane({
    super.key,
    required this.itemFocusNodes,
    required this.onOrderedIdsChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final provider = ref.watch(taskProvider);
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final projectState = ref.watch(projectProvider);
    final filter = ref.watch(filterProvider).activeFilter;
    final settings = ref.watch(settingsProvider);
    final showActiveOnly = settings.showActiveProjectsOnly;
    final isToday = selectedDate.isToday;

    final overdue = provider.overdueTasks.where((t) {
      final project = t.projectId != null ? projectState.getById(t.projectId!) : null;
      if (showActiveOnly && project != null && !project.isActive) return false;
      return filter.applyToTask(t, project?.labelIds ?? []);
    }).toList();

    final allTasks = provider.tasks.where((t) {
      final project = t.projectId != null ? projectState.getById(t.projectId!) : null;
      if (showActiveOnly && project != null && !project.isActive) return false;
      return filter.applyToTask(t, project?.labelIds ?? []);
    }).toList();

    if (settings.getTaskLayout() == TaskLayout.kanban) {
      return KanbanBoard(
        tasks: [...(isToday ? overdue : []), ...allTasks],
        onStatusChange: (task, status) => ref.read(taskProvider.notifier).updateTaskStatus(task, status),
        onContextMenu: (task, pos, box) => showTaskCardContextMenu(context, ref, task, pos, box),
        onEdit: onEdit,
        itemFocusNodes: itemFocusNodes,
        onOrderedIdsChanged: onOrderedIdsChanged,
      );
    }

    return TaskListView(
      tasks: allTasks,
      overdueTasks: isToday ? overdue : [],
      onContextMenu: (ctx, task, pos, box) => showTaskCardContextMenu(ctx, ref, task, pos, box),
      trailingBuilder: (ctx, task) => _taskTrailing(ctx, ref, task),
      onOrderedIdsChanged: onOrderedIdsChanged,
      itemFocusNodes: itemFocusNodes,
      onEdit: onEdit,
      emptyPlaceholder: _buildEmptyState(context, ref, isToday),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, bool isToday) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            isToday ? 'No tasks for today' : 'No tasks scheduled',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => _showAddTask(context, ref), child: const Text('Add your first task')),
        ],
      ),
    );
  }

  Widget _taskTrailing(BuildContext context, WidgetRef ref, Task task) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(
          builder: (buttonContext) {
            return IconButton(
              icon: const Icon(Icons.more_vert, size: 18),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              onPressed: () {
                final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
                const localPosition = Offset.zero;
                showTaskCardContextMenu(context, ref, task, localPosition, renderBox);
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddTask(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(initialDate: ref.read(selectedDateProvider)),
    );
  }
}
