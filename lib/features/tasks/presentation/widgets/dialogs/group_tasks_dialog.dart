import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/searchable_dropdown.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_picker.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/actions/task_hierarchy_actions.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupTasksDialog extends ConsumerStatefulWidget {
  final List<String> taskIds;

  const GroupTasksDialog({super.key, required this.taskIds});

  @override
  ConsumerState<GroupTasksDialog> createState() => _GroupTasksDialogState();
}

class _GroupTasksDialogState extends ConsumerState<GroupTasksDialog> {
  int _selectedTab = 0;
  final _titleController = TextEditingController();
  String? _selectedParentId;
  String? _selectedProjectId;
  String? _error;
  bool _initializedProject = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _initProjectIfNeeded(List<Task> validTasks) {
    if (_initializedProject) return;
    _initializedProject = true;
    final projectIds = validTasks
        .map((t) => t.projectId)
        .whereType<String>()
        .toSet();
    if (projectIds.length == 1) {
      _selectedProjectId = projectIds.first;
    }
  }

  Future<void> _submit(List<String> validIds) async {
    final notifier = ref.read(taskProvider.notifier);

    if (validIds.isEmpty) {
      setState(() => _error = 'No eligible tasks to group');
      return;
    }

    if (_selectedTab == 0) {
      final title = _titleController.text.trim();
      if (title.isEmpty) {
        setState(() => _error = 'Please enter a title');
        return;
      }

      await notifier.createParentWithSubtasks(
        title: title,
        childTaskIds: validIds,
        projectId: _selectedProjectId,
      );
    } else {
      if (_selectedParentId == null) {
        setState(() => _error = 'Please select a parent task');
        return;
      }

      await notifier.reparentTasks(
        taskIds: validIds,
        newParentId: _selectedParentId,
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);
    final allTasks = taskState.allTasks;
    final projects = ref.watch(projectProvider).projects;

    final selectedTasks = allTasks
        .where((t) => widget.taskIds.contains(t.id))
        .toList();

    final tasksWithSubtasks = selectedTasks
        .where((t) => allTasks.any((c) => c.parentId == t.id))
        .toList();

    final validTasks = selectedTasks
        .where((t) => !allTasks.any((c) => c.parentId == t.id))
        .toList();

    final validIds = validTasks.map((t) => t.id).toList();
    _initProjectIfNeeded(validTasks);

    final distinctProjects = validTasks.map((t) => t.projectId).toSet();
    final hasMixedProjects = distinctProjects.length > 1;
    final selectedTasksProject = validTasks.firstOrNull?.projectId;

    final eligibleParents = allTasks.where((t) {
      if (widget.taskIds.contains(t.id)) {
        return false;
      }
      // Selected projects can never be cross project.
      if (t.projectId != selectedTasksProject) {
        return false;
      }
      return t.parentId == null;
    }).toList();

    final selectedParent = eligibleParents
        .where((t) => t.id == _selectedParentId)
        .firstOrNull;

    final selectedParentProject = selectedParent?.projectId != null
        ? projects.where((p) => p.id == selectedParent!.projectId).firstOrNull
        : null;

    return SizedDialog(
      maxWidth: 480,
      title: 'Group Tasks',
      onSubmit: validIds.isEmpty ? null : () => _submit(validIds),
      submitText: _selectedTab == 0 ? 'Create & Group' : 'Move to Parent',
      onCancel: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tasksWithSubtasks.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${tasksWithSubtasks.length} task${tasksWithSubtasks.length > 1 ? "s" : ""} already ${tasksWithSubtasks.length > 1 ? "have" : "has"} subtasks and cannot be nested.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('New Parent'),
                icon: Icon(Icons.add_circle_outline, size: 16),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Existing Parent'),
                icon: Icon(Icons.subdirectory_arrow_right, size: 16),
              ),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (set) {
              setState(() {
                _selectedTab = set.first;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_selectedTab == 0) ...[
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Parent Task Title',
                hintText: 'e.g. Brainstorming Project',
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(validIds),
            ),
            const SizedBox(height: 12),
            ProjectPicker(
              projects: projects,
              selectedProjectId: _selectedProjectId,
              onChanged: (id) => setState(() => _selectedProjectId = id),
            ),
            if (hasMixedProjects)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Tasks currently belong to different projects. Grouping will align all subtasks to this project.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${validIds.length} task${validIds.length != 1 ? "s" : ""} will be grouped as subtasks under this new task.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            SearchableDropdown<Task>(
              items: eligibleParents,
              selectedItem: selectedParent,
              onChanged: (t) => setState(() {
                _selectedParentId = t?.id;
                _error = null;
              }),
              nameGetter: (t) => t != null
                  ? TagParser.hideHashtagSymbols(t.title)
                  : 'Select parent task...',
              hintText: 'Select parent task',
              searchHint: 'Search tasks...',
              emptyText: 'No eligible parent tasks found',
            ),
            if (selectedParentProject == null) ...[
              const SizedBox(height: 6),
              Text(
                'Parent has no project. Subtasks will be moved to Inbox.',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${validIds.length} task${validIds.length != 1 ? "s" : ""} will become subtasks of the selected task.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
