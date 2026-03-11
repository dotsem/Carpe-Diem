import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/ui/widgets/chip/small_chip.dart';
import 'package:carpe_diem/ui/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/ui/widgets/task_hierarchy_indicator.dart';
import 'package:provider/provider.dart';

class TaskListView extends StatelessWidget {
  final List<Task> tasks;
  final List<Task> overdueTasks;
  final Widget Function(BuildContext, Task)? trailingBuilder;
  final void Function(BuildContext, Task, Offset, RenderBox)? onContextMenu;
  final EdgeInsets padding;
  final bool showDateGroupHeaders;
  final Widget? emptyPlaceholder;
  final bool showScheduleDate;
  final String? searchQuery;

  const TaskListView({
    super.key,
    required this.tasks,
    this.overdueTasks = const [],
    this.trailingBuilder,
    this.onContextMenu,
    this.padding = const EdgeInsets.fromLTRB(32, 16, 32, 32),
    this.showDateGroupHeaders = true,
    this.emptyPlaceholder,
    this.showScheduleDate = false,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final projectProvider = context.read<ProjectProvider>();
    final taskProvider = context.read<TaskProvider>();

    bool isOverdue(Task t) {
      if (t.deadline != null) {
        return t.deadline!.isBefore(today) && !t.isCompleted;
      }
      return t.scheduledDate != null && t.scheduledDate!.isBefore(today) && !t.isCompleted;
    }

    final allTasksMap = <String, Task>{};
    for (final t in tasks) {
      allTasksMap[t.id] = t;
    }
    for (final t in overdueTasks) {
      allTasksMap[t.id] = t;
    }

    var allTasks = allTasksMap.values.toList();
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      allTasks = FuzzySearchUtils.search<Task>(
        query: searchQuery!,
        items: allTasks,
        itemToString: (t) => '${t.title} ${t.description ?? ''}',
      );
    } else {
      allTasks.sort((a, b) {
        if (a.priority != b.priority) return b.priority.index.compareTo(a.priority.index);
        if (a.deadline != b.deadline) {
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    }

    final inProgressCategory = allTasks.where((t) => t.status.isInProgress).toList();
    final overdueCategory = allTasks.where((t) => t.status.isTodo && isOverdue(t)).toList();
    final todoCategory = allTasks.where((t) => t.status.isTodo && !isOverdue(t)).toList();
    final doneCategory = allTasks.where((t) => t.status.isDone).toList();

    if (inProgressCategory.isEmpty && overdueCategory.isEmpty && todoCategory.isEmpty && doneCategory.isEmpty) {
      return _buildEmptyState(context);
    }

    bool isFirstTask = true;
    Widget buildCard(Task task, bool taskIsOverdue, {int depth = 0}) {
      final autofocus = isFirstTask;
      isFirstTask = false;
      return _buildTaskCard(
        context,
        task,
        projectProvider,
        taskProvider,
        taskIsOverdue,
        showScheduleDate,
        autofocus,
        depth: depth,
      );
    }

    List<Widget> buildHierarchy(List<Task> categoryTasks, bool Function(Task) overdueFn) {
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        return categoryTasks.map((t) => buildCard(t, overdueFn(t))).toList();
      }
      final flattened = TaskHierarchyUtils.buildHierarchy(categoryTasks);
      return flattened.map((t) => buildCard(t.task, overdueFn(t.task), depth: t.depth)).toList();
    }

    return ListView(
      padding: padding,
      children: [
        if (inProgressCategory.isNotEmpty) ...[
          _buildHeader(context, 'In Progress', color: AppColors.accent, amount: inProgressCategory.length),
          const SizedBox(height: 8),
          ...buildHierarchy(inProgressCategory, isOverdue),
          const SizedBox(height: 20),
        ],
        if (overdueCategory.isNotEmpty) ...[
          _buildHeader(context, 'Overdue', color: AppColors.error, amount: overdueCategory.length),
          const SizedBox(height: 8),
          ...buildHierarchy(overdueCategory, (_) => true),
          const SizedBox(height: 20),
        ],
        if (todoCategory.isNotEmpty) ...[
          _buildHeader(context, 'Todo', amount: todoCategory.length, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          ...buildHierarchy(todoCategory, (_) => false),
        ],
        if (doneCategory.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildHeader(context, 'Done', color: AppColors.textSecondary, amount: doneCategory.length),
          const SizedBox(height: 8),
          ...buildHierarchy(doneCategory, (_) => false),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String title, {Color? color, int? amount}) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        SmallChip(
          color: color?.withValues(alpha: 0.15) ?? Colors.transparent,
          borderRadius: 10,
          child: Text(
            '${amount ?? tasks.length}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    Task task,
    ProjectProvider projectProvider,
    TaskProvider taskProvider,
    bool taskIsOverdue,
    bool showScheduleDate,
    bool autofocus, {
    int depth = 0,
  }) {
    final card = TaskCard(
      key: ValueKey(task.id),
      task: task,
      project: task.projectId != null ? projectProvider.getById(task.projectId!) : null,
      isOverdue: taskIsOverdue,
      autofocus: autofocus,
      onToggle: (_) => taskProvider.toggleComplete(task),
      onTap: () {},
      showScheduleDate: showScheduleDate,
      onContextMenu: onContextMenu != null ? (pos, box) => onContextMenu!(context, task, pos, box) : null,
      trailing: trailingBuilder?.call(context, task),
    );

    return TaskHierarchyIndicator(depth: depth, child: card);
  }

  Widget _buildEmptyState(BuildContext context) {
    if (emptyPlaceholder != null) return emptyPlaceholder!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('No tasks found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}
