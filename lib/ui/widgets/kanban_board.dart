import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/ui/widgets/chip/small_chip.dart';
import 'package:carpe_diem/ui/widgets/context_menu/task_card_context_menu.dart';
import 'package:carpe_diem/ui/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/data/models/task_status.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:provider/provider.dart';

class KanbanBoard extends StatelessWidget {
  final List<Task> tasks;
  final ProjectProvider projectProvider;
  final void Function(Task task, TaskStatus status) onStatusChange;
  final void Function(Task task, Offset localPosition, RenderBox renderBox) onContextMenu;
  final void Function(Task task) onEdit;

  const KanbanBoard({
    super.key,
    required this.tasks,
    required this.projectProvider,
    required this.onStatusChange,
    required this.onContextMenu,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final todo = tasks.where((t) => t.status.isTodo).toList();
    final inProgress = tasks.where((t) => t.status.isInProgress).toList();
    final done = tasks.where((t) => t.status.isDone).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KanbanColumn(
            title: 'Todo',
            titleColor: AppColors.text,
            tasks: todo,
            acceptedStatus: TaskStatus.todo,
            projectProvider: projectProvider,
            onStatusChange: onStatusChange,
            onContextMenu: onContextMenu,
            onEdit: onEdit,
          ),
          const SizedBox(width: 16),
          _KanbanColumn(
            title: 'In Progress',
            titleColor: AppColors.accent,
            tasks: inProgress,
            acceptedStatus: TaskStatus.inProgress,
            projectProvider: projectProvider,
            onStatusChange: onStatusChange,
            onContextMenu: onContextMenu,
            onEdit: onEdit,
          ),
          const SizedBox(width: 16),
          _KanbanColumn(
            title: 'Done',
            titleColor: AppColors.success,
            tasks: done,
            acceptedStatus: TaskStatus.done,
            projectProvider: projectProvider,
            onStatusChange: onStatusChange,
            onContextMenu: onContextMenu,
            onEdit: onEdit,
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color titleColor;
  final List<Task> tasks;
  final TaskStatus acceptedStatus;
  final ProjectProvider projectProvider;
  final void Function(Task task, TaskStatus status) onStatusChange;
  final void Function(Task task, Offset localPosition, RenderBox renderBox) onContextMenu;
  final void Function(Task task) onEdit;

  const _KanbanColumn({
    required this.title,
    required this.titleColor,
    required this.tasks,
    required this.acceptedStatus,
    required this.projectProvider,
    required this.onStatusChange,
    required this.onContextMenu,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DragTarget<Task>(
        onWillAcceptWithDetails: (details) => details.data.status != acceptedStatus,
        onAcceptWithDetails: (details) => onStatusChange(details.data, acceptedStatus),
        builder: (context, candidateData, rejectedData) {
          final isHighlighted = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isHighlighted ? titleColor.withValues(alpha: 0.1) : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHighlighted ? titleColor.withValues(alpha: 0.4) : AppColors.surfaceLight,
                width: isHighlighted ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor),
                      ),
                      const SizedBox(width: 8),
                      SmallChip(
                        borderRadius: 10,
                        color: titleColor.withValues(alpha: 0.15),
                        child: Text(
                          '${tasks.length}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: titleColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Drop tasks here',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) => _KanbanCard(
                            key: ValueKey(tasks[index].id),
                            task: tasks[index],
                            project: projectProvider,
                            onContextMenu: onContextMenu,
                            onEdit: onEdit,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  final Task task;
  final ProjectProvider project;
  final void Function(Task task, Offset localPosition, RenderBox renderBox) onContextMenu;
  final void Function(Task task) onEdit;

  const _KanbanCard({
    super.key,
    required this.task,
    required this.project,
    required this.onContextMenu,
    required this.onEdit,
  });

  bool get isOverdue {
    if (task.scheduledDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return task.scheduledDate!.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
          child: Text(task.title, style: const TextStyle(color: AppColors.text, fontSize: 14)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTaskCard(context, task, project, context.read<TaskProvider>(), isOverdue: isOverdue),
      ),
      child: _buildTaskCard(context, task, project, context.read<TaskProvider>(), isOverdue: isOverdue),
    );
  }

  TaskCard _buildTaskCard(
    BuildContext context,
    Task task,
    ProjectProvider projectProvider,
    TaskProvider provider, {
    bool isOverdue = false,
  }) {
    return TaskCard(
      key: ValueKey(task.id),
      task: task,
      project: task.projectId != null ? projectProvider.getById(task.projectId!) : null,
      isOverdue: isOverdue,
      useTimer: false,
      onToggle: () => provider.toggleComplete(task),
      onTap: () => onEdit(task),
      onContextMenu: (localPosition, renderBox) => showTaskCardContextMenu(context, task, localPosition, renderBox),
    );
  }
}
