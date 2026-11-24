import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/actions/task_hierarchy_actions.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/flutter_ext/searchable_dropdown/multi_select_searchable_dropdown.dart';
import 'package:carpe_diem/flutter_ext/shortcut_hint_badge.dart';
import 'package:carpe_diem/flutter_ext/split_button_half.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddSubtaskButton extends ConsumerStatefulWidget {
  final Task parentTask;
  final DateTime? scheduledDate;
  final String? projectId;

  const AddSubtaskButton({
    required this.parentTask,
    super.key,
    this.scheduledDate,
    this.projectId,
  });

  @override
  ConsumerState<AddSubtaskButton> createState() => _AddSubtaskButtonState();
}

class _AddSubtaskButtonState extends ConsumerState<AddSubtaskButton> {
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        SplitButtonHalf(
          side: SplitSide.leading,
          onPressed: () => context.openRightSidebar(
            AddTaskPanel(
              initialDate:
                  widget.scheduledDate ?? widget.parentTask.scheduledDate,
              initialProjectId: widget.projectId ?? widget.parentTask.projectId,
              initialParentId: widget.parentTask.id,
            ),
            ref,
          ),
          icon: const Icon(Icons.add, size: 16),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Text('Add Subtask'),
              ShortcutHintBadge(label: 'Ctrl + ${SubtaskKeys.upper}'),
            ],
          ),
        ),
        MultiSelectSearchableDropdown<Task>(
          items: candidates,
          selectedIds: selectedIds.toList(),
          idGetter: (t) => t.id,
          nameGetter: (t) => TagParser.hideHashtagSymbols(t.title),
          searchHint: 'Search tasks in project...',
          allowAdd: false,
          menuWidth: 280,
          anchorBuilder: (context, controller) {
            return Tooltip(
              message: 'Link existing tasks',
              child: SplitButtonHalf(
                side: SplitSide.trailing,
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                child: const Icon(Icons.link, size: 18),
              ),
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
                  .reparentTasks(
                    taskIds: added,
                    newParentId: widget.parentTask.id,
                  );
            }
            if (removed.isNotEmpty) {
              ref
                  .read(taskProvider.notifier)
                  .reparentTasks(taskIds: removed, newParentId: null);
            }
          },
        ),
      ],
    );
  }
}
