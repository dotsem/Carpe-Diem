import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/searchable_dropdown.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter/material.dart';

class BlockerPicker extends StatelessWidget {
  final List<Task> availableTasks;
  final String? selectedBlockerId;
  final String? currentTaskId;
  final Function(String?) onChanged;
  final bool borderless;

  const BlockerPicker({
    super.key,
    required this.availableTasks,
    required this.onChanged,
    this.selectedBlockerId,
    this.currentTaskId,
    this.borderless = false,
  });

  bool _wouldCreateCycle(String candidateId) {
    if (currentTaskId == null) return false;
    final taskMap = {for (final t in availableTasks) t.id: t};
    var current = taskMap[candidateId];
    final visited = <String>{};
    while (current != null && current.blockedById != null) {
      if (visited.contains(current.id)) return true;
      visited.add(current.id);
      if (current.blockedById == currentTaskId) return true;
      current = taskMap[current.blockedById];
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final selectableTasks = availableTasks
        .where((t) => !t.isCompleted)
        .where((t) => t.id != currentTaskId)
        .where((t) => !_wouldCreateCycle(t.id))
        .toList();

    final selectedTask = selectedBlockerId == null
        ? null
        : availableTasks.where((t) => t.id == selectedBlockerId).firstOrNull;

    return SearchableDropdown<Task>(
      borderless: borderless,
      items: selectableTasks,
      selectedItem: selectedTask,
      onChanged: (task) => onChanged(task?.id),
      nameGetter: (t) => t?.title ?? 'No blocker',
      hintText: 'Blocked by',
      searchHint: 'Search tasks...',
      emptyText: 'No tasks available',
      leadingBuilder: (t) {
        if (t == null) {
          return Icon(
            Icons.block,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
        }
        return Icon(
          Icons.task_alt,
          size: 14,
          color: t.isUrgent
              ? AppColors.error
              : Theme.of(context).colorScheme.onSurfaceVariant,
        );
      },
      prefixIcon: Icon(
        selectedTask != null ? Icons.lock : Icons.lock_open_outlined,
        size: 16,
        color: selectedTask != null
            ? AppColors.accent
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

