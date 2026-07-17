import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card_context_menu.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_hierarchy_indicator.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';

class KanbanCard extends ConsumerWidget {
  final TaskNode node;
  final ProjectNotifier projectNotifier;
  final void Function(Task task, Offset localPosition, RenderBox renderBox) onContextMenu;
  final void Function(Task task) onEdit;
  final FocusNode? focusNode;

  const KanbanCard({
    super.key,
    required this.node,
    required this.projectNotifier,
    required this.onContextMenu,
    required this.onEdit,
    this.focusNode,
  });

  Task get task => node.task;
  int get depth => node.depth;
  bool get isOverdue => task.isOverdue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            settings.showHashtagInTitle ? task.title : TagParser.hideHashtagSymbols(task.title),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _wrapHierarchy(context, ref, task, projectNotifier, isOverdue: isOverdue),
      ),
      child: _wrapHierarchy(context, ref, task, projectNotifier, isOverdue: isOverdue),
    );
  }

  Widget _wrapHierarchy(
    BuildContext context,
    WidgetRef ref,
    Task task,
    ProjectNotifier projectNotifier, {
    bool isOverdue = false,
  }) {
    final card = _buildTaskCard(context, ref, task, projectNotifier, isOverdue: isOverdue);
    return TaskHierarchyIndicator(depth: depth, child: card);
  }

  TaskCard _buildTaskCard(
    BuildContext context,
    WidgetRef ref,
    Task task,
    ProjectNotifier projectNotifier, {
    bool isOverdue = false,
  }) {
    final taskNotifier = ref.read(taskProvider.notifier);
    return TaskCard(
      key: ValueKey(task.id),
      task: task,
      project: task.projectId != null ? projectNotifier.getById(task.projectId!) : null,
      isOverdue: isOverdue,
      useTimer: false,
      leading: Container(),
      focusNode: focusNode,
      onToggle: (_) => taskNotifier.toggleComplete(task),
      onTap: () => onEdit(task),
      onContextMenu: (localPosition, renderBox) =>
          showTaskCardContextMenu(context, ref, task, localPosition, renderBox),
    );
  }
}
