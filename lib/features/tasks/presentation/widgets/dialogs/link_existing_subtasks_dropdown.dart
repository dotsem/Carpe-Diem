import 'package:carpe_diem/features/common/presentation/widgets/multi_select_searchable_dropdown.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/actions/task_hierarchy_actions.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LinkExistingSubtasksDropdown extends ConsumerStatefulWidget {
  final Task parentTask;

  const LinkExistingSubtasksDropdown({super.key, required this.parentTask});

  @override
  ConsumerState<LinkExistingSubtasksDropdown> createState() =>
      _LinkExistingSubtasksDropdownState();
}

class _LinkExistingSubtasksDropdownState
    extends ConsumerState<LinkExistingSubtasksDropdown> {
  Set<String>? _optimisticSelectedIds;

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(taskProvider).allTasks;

    final currentSubtasks = allTasks
        .where((t) => t.parentId == widget.parentTask.id)
        .toList();
    final actualSelectedIds = currentSubtasks.map((t) => t.id).toSet();

    final selectedIds = _optimisticSelectedIds ?? actualSelectedIds;

    final candidates = allTasks.where((t) {
      if (t.id == widget.parentTask.id) return false;
      // Only show tasks from the same project
      if (t.projectId != widget.parentTask.projectId) return false;
      // Must not belong to another parent
      if (t.parentId != null && t.parentId != widget.parentTask.id) {
        return false;
      }
      // Must not have subtasks of their own
      if (allTasks.any((c) => c.parentId == t.id)) return false;
      return true;
    }).toList();

    return MultiSelectSearchableDropdown<Task>(
      items: candidates,
      selectedIds: selectedIds.toList(),
      idGetter: (t) => t.id,
      nameGetter: (t) => TagParser.hideHashtagSymbols(t.title),
      searchHint: 'Search tasks in project...',
      allowAdd: false,
      menuWidth: 280,
      anchorBuilder: (context, controller) {
        return IconButton(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(Icons.link, size: 18),
          tooltip: 'Link existing tasks',
          visualDensity: VisualDensity.compact,
        );
      },
      onChanged: (newIds) {
        final newSet = newIds.toSet();
        final added = newSet.difference(selectedIds).toList();
        final removed = selectedIds.difference(newSet).toList();

        setState(() {
          _optimisticSelectedIds = newSet;
        });

        if (added.isNotEmpty) {
          ref
              .read(taskProvider.notifier)
              .reparentTasks(taskIds: added, newParentId: widget.parentTask.id);
        }
        if (removed.isNotEmpty) {
          ref
              .read(taskProvider.notifier)
              .reparentTasks(taskIds: removed, newParentId: null);
        }
      },
    );
  }
}
