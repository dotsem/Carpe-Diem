import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/searchable_dropdown.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/subtask_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockerPicker extends ConsumerWidget {
  final List<Task> availableTasks;
  final String? selectedBlockerId;
  final String? currentTaskId;
  final Function(String?) onChanged;
  final bool borderless;
  final MenuController? menuController;

  const BlockerPicker({
    super.key,
    required this.availableTasks,
    required this.onChanged,
    this.selectedBlockerId,
    this.currentTaskId,
    this.borderless = false,
    this.menuController,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final selectableTasks = availableTasks
        .where((t) => !t.isCompleted)
        .where((t) => t.id != currentTaskId)
        .where((t) => !_wouldCreateCycle(t.id))
        .toList();

    final selectedTask = selectedBlockerId == null
        ? null
        : (availableTasks.where((t) => t.id == selectedBlockerId).firstOrNull ??
              ref.watch(taskByIdProvider(selectedBlockerId!)).valueOrNull);

    final items =
        selectedTask != null && !selectableTasks.contains(selectedTask)
        ? [selectedTask, ...selectableTasks]
        : selectableTasks;

    return SearchableDropdown<Task>(
      borderless: borderless,
      menuController: menuController,
      items: items,
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
        if (t.isCompleted) {
          return const Icon(
            Icons.lock_open_outlined,
            size: 14,
            color: AppColors.success,
          );
        }
        return Icon(
          Icons.lock_outline,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
      },
    );
  }
}
