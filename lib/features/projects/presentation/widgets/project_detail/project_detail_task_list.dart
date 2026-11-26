import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/task_card_context_menu.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Task list of the project detail screen, with loading and empty states.
class ProjectDetailTaskList extends ConsumerWidget {
  final Project project;
  final List<Task> allTasks;
  final List<Task> filteredTasks;
  final bool isLoading;
  final String searchQuery;
  final String? highlightedTaskId;
  final Map<String, FocusNode> itemFocusNodes;
  final Set<String> selectedTaskIds;
  final ValueChanged<List<String>> onOrderedIdsChanged;
  final VoidCallback onClearSelection;
  final ValueChanged<Task> onSelectedChanged;

  const ProjectDetailTaskList({
    required this.project,
    required this.allTasks,
    required this.filteredTasks,
    required this.isLoading,
    required this.searchQuery,
    required this.highlightedTaskId,
    required this.itemFocusNodes,
    required this.selectedTaskIds,
    required this.onOrderedIdsChanged,
    required this.onClearSelection,
    required this.onSelectedChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final mutedStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return TaskListView(
      tasks: filteredTasks,
      asParentContainers: true,
      padding: const EdgeInsets.symmetric(vertical: 24),
      onContextMenu: (ctx, task, pos, box) =>
          showTaskCardContextMenu(ctx, ref, task, filteredTasks, pos, box),
      emptyPlaceholder: Center(
        child: allTasks.isEmpty
            ? Text('No tasks in this project', style: mutedStyle)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('All tasks hidden by filters', style: mutedStyle),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        ref.read(filterProvider.notifier).clearFilter(),
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
      ),
      onOrderedIdsChanged: onOrderedIdsChanged,
      highlightedTaskId: highlightedTaskId,
      itemFocusNodes: itemFocusNodes,
      searchQuery: searchQuery,
      enablePlanShortcut: true,
      showScheduleDate: true,
      selectionMode: true,
      selectedTaskIds: selectedTaskIds,
      onClearSelection: onClearSelection,
      onSelectedChanged: onSelectedChanged,
      onEdit: (task) => context.openRightSidebar(EditTaskPanel(task.id)),
      isReadOnly: !project.isActive,
      initialDoneExpanded: !project.isActive,
    );
  }
}
