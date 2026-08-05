import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/planning_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/labels_and_tags_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/placement_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/projects_and_blockers_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_sync_utils.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/dialogs/create_tags_prompt_dialog.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_autocomplete_text_field.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_highlighting_controller.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/widgets/parent_task_link.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/widgets/subtasks_list_section.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/sticky_footer_layout.dart';

class TaskFormPanel extends ConsumerStatefulWidget {
  final Task? initialTask;
  final DateTime? initialDate;
  final String? initialProjectId;
  final String? initialParentId;

  const TaskFormPanel({super.key, this.initialTask, this.initialDate, this.initialProjectId, this.initialParentId});

  @override
  ConsumerState<TaskFormPanel> createState() => _TaskFormPanelState();
}

class _TaskFormPanelState extends ConsumerState<TaskFormPanel> {
  late final TagHighlightingController _titleController;
  final _descController = TextEditingController();
  TaskPlacement? _placement;
  DateTime? _scheduledDate;
  DateTime? _deadline;
  String? _selectedProjectId;
  String? _blockedById;
  String? _parentId;
  List<Task> _projectTasks = [];
  List<String> _selectedLabelIds = [];
  List<String> _inheritedLabelIds = [];
  List<String> _selectedTagIds = [];
  List<String> _previousParsedIds = [];
  String? _titleError;
  final MenuController _projectMenuController = MenuController();
  final MenuController _blockerMenuController = MenuController();

  bool get isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;

    if (task != null) {
      _descController.text = task.description ?? '';
      _placement = task.isUrgent ? TaskPlacement.urgent : null;
      _scheduledDate = task.scheduledDate;
      _deadline = task.deadline;
      _selectedProjectId = task.projectId;
      _blockedById = task.blockedById;
      _parentId = task.parentId;
      _selectedLabelIds = List.from(task.labelIds);
      _selectedTagIds = List.from(task.tagIds);

      final initialTags = TagParser.parseTags(task.title);
      _previousParsedIds = ref
          .read(tagProvider)
          .tags
          .where((t) => initialTags.contains(t.name.toLowerCase()))
          .map((t) => t.id)
          .toList();

      _titleController = TagHighlightingController(
        text: task.title,
        getExistingTagNames: () => ref.read(tagProvider).tags.map((t) => t.name).toList(),
      );
    } else {
      _scheduledDate = widget.initialDate;
      _selectedProjectId = widget.initialProjectId;
      _placement = TaskPlacement.bottom;
      _parentId = widget.initialParentId;

      _titleController = TagHighlightingController(
        getExistingTagNames: () => ref.read(tagProvider).tags.map((t) => t.name).toList(),
      );
    }

    _titleController.addListener(_onTitleChanged);
    _loadProjectDetails();
  }

  void _onTitleChanged() {
    if (_titleError != null && _titleController.text.trim().isNotEmpty) {
      setState(() => _titleError = null);
    }

    final newTagIds = TagSyncUtils.syncTitleToPicker(
      text: _titleController.text,
      allTags: ref.read(tagProvider).tags,
      currentSelectedIds: _selectedTagIds,
      previousParsedIds: _previousParsedIds,
      mode: ref.read(settingsProvider).tagAbsorption,
    );

    final parsedNames = TagParser.parseTags(_titleController.text);
    _previousParsedIds = ref
        .read(tagProvider)
        .tags
        .where((t) => parsedNames.contains(t.name.toLowerCase()))
        .map((t) => t.id)
        .toList();

    final set1 = Set.from(_selectedTagIds);
    final set2 = Set.from(newTagIds);
    if (set1.length != set2.length || !set1.containsAll(set2)) {
      setState(() => _selectedTagIds = newTagIds);
    }
  }

  Future<void> _loadProjectDetails() async {
    final settings = ref.read(settingsProvider);
    List<String> parentLabelIds = [];

    if (!isEditing && _parentId != null) {
      Task? parentTask = ref.read(taskProvider).getById(_parentId!);
      if (parentTask == null) {
        final repo = ref.read(taskRepositoryProvider);
        parentTask = await repo.getById(_parentId!);
      }
      if (parentTask != null) {
        _selectedProjectId ??= parentTask.projectId;
        _scheduledDate ??= parentTask.scheduledDate;
        _deadline ??= parentTask.deadline;
        parentLabelIds = parentTask.labelIds;
      }
    }

    if (!isEditing && _selectedProjectId == null && _parentId == null) {
      _selectedProjectId = settings.defaultProjectId;
    }

    if (_selectedProjectId == null) {
      if (!mounted) return;
      setState(() {
        _projectTasks = [];
        _blockedById = null;
        _inheritedLabelIds = parentLabelIds.toSet().toList();
      });
      return;
    }

    final tasks = await ref.read(taskProvider.notifier).getTasksForProject(_selectedProjectId!);
    if (!mounted) return;
    final project = ref.read(projectProvider).getById(_selectedProjectId!);
    final combinedInheritedLabels = <String>{...?project?.labelIds, ...parentLabelIds}.toList();

    setState(() {
      _projectTasks = tasks;
      _inheritedLabelIds = combinedInheritedLabels;
      if (!isEditing && settings.inheritProjectDeadline && project?.deadline != null) {
        _deadline ??= project?.deadline;
      }
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectProvider).projects.where((p) => p.isActive).toList();

    return StickyFooterLayout(
      footer: Row(
        children: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete Task',
              style: IconButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: _onDelete,
            ),
          const Spacer(),
          TextButton(onPressed: () => ref.read(rightSidebarProvider.notifier).close(), child: const Text('Cancel')),
          const SizedBox(width: 8),
          FilledButton(onPressed: _submit, child: Text(isEditing ? 'Save Changes' : 'Create Task')),
        ],
      ),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(AppKeyBindings.digit1, control: true): () =>
              setState(() => _placement = TaskPlacement.bottom),
          const SingleActivator(AppKeyBindings.digit1, meta: true): () =>
              setState(() => _placement = TaskPlacement.bottom),
          const SingleActivator(AppKeyBindings.digit2, control: true): () =>
              setState(() => _placement = TaskPlacement.middle),
          const SingleActivator(AppKeyBindings.digit2, meta: true): () =>
              setState(() => _placement = TaskPlacement.middle),
          const SingleActivator(AppKeyBindings.digit3, control: true): () =>
              setState(() => _placement = TaskPlacement.top),
          const SingleActivator(AppKeyBindings.digit3, meta: true): () =>
              setState(() => _placement = TaskPlacement.top),
          const SingleActivator(AppKeyBindings.digit4, control: true): () =>
              setState(() => _placement = TaskPlacement.urgent),
          const SingleActivator(AppKeyBindings.digit4, meta: true): () =>
              setState(() => _placement = TaskPlacement.urgent),
          SingleActivator(ProjectsKeys.keyboardKey, control: true): () {
            if (_projectMenuController.isOpen) {
              _projectMenuController.close();
            } else {
              _projectMenuController.open();
            }
          },
          SingleActivator(ProjectsKeys.keyboardKey, meta: true): () {
            if (_projectMenuController.isOpen) {
              _projectMenuController.close();
            } else {
              _projectMenuController.open();
            }
          },
          const SingleActivator(AppKeyBindings.enter, control: true): _submit,
          const SingleActivator(AppKeyBindings.enter, meta: true): _submit,
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_parentId != null) ...[ParentTaskLink(parentId: _parentId!), const SizedBox(height: 8)],
            TagAutocompleteTextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Task name',
                errorText: _titleError,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              onTagSelected: (tag) {
                if (!ref.read(settingsProvider).keepTagsInTitle) {
                  setState(() {
                    if (!_selectedTagIds.contains(tag.id)) {
                      _selectedTagIds.add(tag.id);
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(hintText: 'Description (optional)'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            PlacementSection(
              placement: _placement ?? TaskPlacement.bottom,
              onChanged: (p) => setState(() => _placement = p),
            ),

            ProjectsAndBlockersSection(
              projects: projects,
              availableTasks: _projectTasks,
              currentTaskId: widget.initialTask?.id,
              selectedBlockerId: _blockedById,
              selectedProjectId: _selectedProjectId,
              projectMenuController: _projectMenuController,
              blockerMenuController: _blockerMenuController,
              onChangedProject: (id) {
                setState(() => _selectedProjectId = id);
                _loadProjectDetails();
              },
              onChangedBlockers: (id) => setState(() => _blockedById = id),
            ),
            PlanningSection(
              scheduledDate: _scheduledDate,
              onScheduledChanged: (d) => setState(() => _scheduledDate = d),
              deadline: _deadline,
              onDeadlineChanged: (d) => setState(() => _deadline = d),
              maxPlanningDays: ref.read(settingsProvider).maxPlanningDays,
            ),

            CategorizationSection(
              selectedLabelIds: _selectedLabelIds,
              inheritedLabelIds: _inheritedLabelIds,
              onLabelsSelected: (ids) => setState(() => _selectedLabelIds = ids),
              selectedTagIds: _selectedTagIds,
              onTagsSelected: (ids) => setState(() => _selectedTagIds = ids),
            ),
            if (isEditing && _parentId == null) ...[
              const SizedBox(height: 16),
              SubtasksListSection(parentTask: widget.initialTask!),
            ],
          ],
        ),
      ),
    );
  }

  void _onDelete() {
    final task = widget.initialTask;
    if (task == null) return;
    final subtasks = ref.read(taskProvider).tasks.where((t) => t.parentId == task.id).toList();
    final message = subtasks.isEmpty
        ? 'Are you sure you want to delete this task?'
        : 'Are you sure you want to delete this task and its ${subtasks.length} subtask${subtasks.length > 1 ? 's' : ''}?';

    showDialog(
      context: context,
      builder: (ctx) => DeleteDialog(
        title: 'Delete Task',
        message: message,
        onConfirm: () {
          Navigator.of(ctx).pop();
          ref.read(taskProvider.notifier).deleteTask(task);
          ref.read(rightSidebarProvider.notifier).close();
        },
      ),
    );
  }

  Future<void> _submit() async {
    final rawTitle = _titleController.text.trim();
    if (rawTitle.isEmpty) {
      setState(() => _titleError = 'Task name is required');
      return;
    }

    final parsedTagNames = TagParser.parseTags(rawTitle);
    final existingTags = ref.read(tagProvider).tags;
    final existingNamesSet = existingTags.map((t) => t.name.toLowerCase()).toSet();
    final newTagNames = parsedTagNames.where((name) => !existingNamesSet.contains(name.toLowerCase())).toList();

    List<String> finalTagIds = List.from(_selectedTagIds);
    final List<String> tagsToStrip = [];

    if (newTagNames.isNotEmpty) {
      final result = await showDialog<CreateTagsPromptResult>(
        context: context,
        builder: (_) => CreateTagsPromptDialog(newTagNames: newTagNames),
      );

      if (result == null || result == CreateTagsPromptResult.cancel) {
        return;
      }

      if (result == CreateTagsPromptResult.createAndSave) {
        for (final name in newTagNames) {
          final newTag = await ref.read(tagProvider.notifier).addTag(name);
          finalTagIds.add(newTag.id);
        }
      } else if (result == CreateTagsPromptResult.saveWithoutTags) {
        tagsToStrip.addAll(newTagNames);
      }
    }

    final settings = ref.read(settingsProvider);
    var titleToSave = settings.keepTagsInTitle ? rawTitle : TagParser.stripTags(rawTitle);
    if (settings.keepTagsInTitle && tagsToStrip.isNotEmpty) {
      titleToSave = TagParser.stripSpecificTags(titleToSave, tagsToStrip);
    }

    if (isEditing) {
      final task = widget.initialTask!;
      ref
          .read(taskProvider.notifier)
          .updateTask(
            task.copyWith(
              title: titleToSave,
              description: _descController.text.trim().isEmpty ? "" : _descController.text.trim(),
              scheduledDate: _scheduledDate,
              clearScheduledDate: _scheduledDate == null,
              deadline: _deadline,
              clearDeadline: _deadline == null,
              blockedById: _blockedById,
              clearBlockedBy: _blockedById == null,
              projectId: _selectedProjectId,
              labelIds: _selectedLabelIds,
              tagIds: finalTagIds,
              isUrgent: _placement == TaskPlacement.urgent,
            ),
          );
    } else {
      ref
          .read(taskProvider.notifier)
          .addTask(
            title: titleToSave,
            description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
            scheduledDate: _scheduledDate,
            projectId: _selectedProjectId,
            placement: _placement ?? TaskPlacement.bottom,
            deadline: _deadline,
            blockedById: _blockedById,
            parentId: _parentId,
            labelIds: _selectedLabelIds,
            tagIds: finalTagIds,
          );
    }

    ref.read(rightSidebarProvider.notifier).close();
  }
}
