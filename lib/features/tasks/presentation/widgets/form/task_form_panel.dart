import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/planning_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/labels_and_tags_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/placement_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/projects_and_blockers_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/task_form_shortcuts.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/utils/task_form_delete_handler.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/utils/task_form_details_loader.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/utils/task_form_submit_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_sync_utils.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_autocomplete_text_field.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_highlighting_controller.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/widgets/parent_task_link.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/widgets/subtasks_list_section.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/sticky_footer_layout.dart';

class TaskFormPanel extends ConsumerStatefulWidget {
  final Task? initialTask;
  final DateTime? initialDate;
  final String? initialProjectId;
  final String? initialParentId;

  const TaskFormPanel({
    super.key,
    this.initialTask,
    this.initialDate,
    this.initialProjectId,
    this.initialParentId,
  });

  @override
  ConsumerState<TaskFormPanel> createState() => _TaskFormPanelState();
}

class _TaskFormPanelState extends ConsumerState<TaskFormPanel> {
  late final TagHighlightingController _titleController;
  final _descController = TextEditingController();
  TaskPlacement? _placement;
  DateTime? _scheduledDate, _deadline;
  String? _selectedProjectId, _blockedById, _parentId, _titleError;
  List<Task> _projectTasks = [];
  List<String> _selectedLabelIds = [],
      _inheritedLabelIds = [],
      _selectedTagIds = [],
      _previousParsedIds = [];
  final MenuController _projectMenuController = MenuController(),
      _blockerMenuController = MenuController();

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
        getExistingTagNames: () =>
            ref.read(tagProvider).tags.map((t) => t.name).toList(),
      );
    } else {
      _scheduledDate = widget.initialDate;
      _selectedProjectId = widget.initialProjectId;
      _placement = TaskPlacement.bottom;
      _parentId = widget.initialParentId;

      _titleController = TagHighlightingController(
        getExistingTagNames: () =>
            ref.read(tagProvider).tags.map((t) => t.name).toList(),
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
    final details = await TaskFormDetailsLoader.loadDetails(
      ref: ref,
      isEditing: isEditing,
      parentId: _parentId,
      currentProjectId: _selectedProjectId,
      currentScheduledDate: _scheduledDate,
      currentDeadline: _deadline,
    );

    if (!mounted || details == null) return;

    setState(() {
      _selectedProjectId = details.selectedProjectId;
      _scheduledDate = details.scheduledDate;
      _deadline = details.deadline;
      _projectTasks = details.projectTasks;
      _inheritedLabelIds = details.inheritedLabelIds;
      if (_selectedProjectId == null) {
        _blockedById = null;
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
    final projects = ref
        .watch(projectProvider)
        .projects
        .where((p) => p.isActive)
        .toList();

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
          TextButton(
            onPressed: () => ref.read(rightSidebarProvider.notifier).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _submit,
            child: Text(isEditing ? 'Save Changes' : 'Create Task'),
          ),
        ],
      ),
      child: TaskFormShortcuts(
        onPlacementChanged: (p) => setState(() => _placement = p),
        projectMenuController: _projectMenuController,
        onSubmit: _submit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_parentId != null) ...[
              ParentTaskLink(parentId: _parentId!),
              const SizedBox(height: 8),
            ],
            TagAutocompleteTextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Task name',
                errorText: _titleError,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              onTagSelected: (tag) {
                if (!ref.read(settingsProvider).keepTagsInTitle &&
                    !_selectedTagIds.contains(tag.id)) {
                  setState(() => _selectedTagIds.add(tag.id));
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            PlacementSection(
              placement: _placement,
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
              onLabelsSelected: (ids) =>
                  setState(() => _selectedLabelIds = ids),
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
    TaskFormDeleteHandler.confirmAndDelete(
      context: context,
      ref: ref,
      task: widget.initialTask,
    );
  }

  Future<void> _submit() async {
    final rawTitle = _titleController.text.trim();
    if (rawTitle.isEmpty) {
      setState(() => _titleError = 'Task name is required');
      return;
    }

    await TaskFormSubmitHandler.submit(
      context: context,
      ref: ref,
      rawTitle: rawTitle,
      description: _descController.text,
      scheduledDate: _scheduledDate,
      deadline: _deadline,
      blockedById: _blockedById,
      selectedProjectId: _selectedProjectId,
      parentId: _parentId,
      selectedLabelIds: _selectedLabelIds,
      selectedTagIds: _selectedTagIds,
      placement: _placement ?? TaskPlacement.bottom,
      initialTask: widget.initialTask,
    );
  }
}
