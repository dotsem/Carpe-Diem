import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/sticky_footer_layout.dart';
import 'package:carpe_diem/features/common/presentation/widgets/entity_timestamps_info.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_sync_utils.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_highlighting_controller.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/coordinated_menu_controller.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/categorization_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/placement_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/projects_and_blockers_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/scheduling_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/subtasks_list_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/task_basics_section.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/sections/task_form_footer.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/task_form_shortcuts.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/utils/task_form_delete_handler.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/utils/task_form_details_loader.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/form/utils/task_form_submit_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskFormPanel extends ConsumerStatefulWidget {
  final Task? initialTask;
  final DateTime? initialDate;
  final String? initialProjectId;
  final String? initialParentId;
  final List<String>? initialLabelIds;

  const TaskFormPanel({
    super.key,
    this.initialTask,
    this.initialDate,
    this.initialProjectId,
    this.initialParentId,
    this.initialLabelIds,
  });

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
  String? _titleError;
  List<Task> _projectTasks = [];
  List<String> _selectedLabelIds = [];
  List<String> _inheritedLabelIds = [];
  List<String> _selectedTagIds = [];
  List<String> _previousParsedIds = [];
  final _menus = TaskFormMenuControllers();

  bool get isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TagHighlightingController(
      text: task?.title,
      getExistingTagNames: () =>
          ref.read(tagProvider).tags.map((t) => t.name).toList(),
    );

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

      _previousParsedIds = TagSyncUtils.parsedTagIds(
        task.title,
        ref.read(tagProvider).tags,
      );
    } else {
      _scheduledDate = widget.initialDate;
      _selectedProjectId = widget.initialProjectId;
      _placement = TaskPlacement.bottom;
      _parentId = widget.initialParentId;
      _selectedLabelIds = widget.initialLabelIds != null
          ? List.from(widget.initialLabelIds!)
          : [];
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

    _previousParsedIds = TagSyncUtils.parsedTagIds(
      _titleController.text,
      ref.read(tagProvider).tags,
    );

    final set1 = Set<String>.from(_selectedTagIds);
    final set2 = Set<String>.from(newTagIds);
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
      footer: TaskFormFooter(
        isEditing: isEditing,
        onDelete: _onDelete,
        onSubmit: _submit,
      ),
      child: TaskFormShortcuts(
        onPlacementChanged: (p) => setState(() => _placement = p),
        projectMenuController: _menus.project,
        blockerMenuController: _menus.blocker,
        labelMenuController: _menus.label,
        tagMenuController: _menus.tag,
        onAddSubtask: widget.initialTask != null ? _onAddSubtask : null,
        onSubmit: _submit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskBasicsSection(
              parentId: _parentId,
              onClearParent: () => setState(() => _parentId = null),
              titleController: _titleController,
              descController: _descController,
              titleError: _titleError,
              onTagSelected: (tag) {
                if (!ref.read(settingsProvider).keepTagsInTitle &&
                    !_selectedTagIds.contains(tag.id)) {
                  setState(() => _selectedTagIds.add(tag.id));
                }
              },
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
              projectMenuController: _menus.project,
              blockerMenuController: _menus.blocker,
              onChangedProject: (id) {
                setState(() => _selectedProjectId = id);
                _loadProjectDetails();
              },
              onChangedBlockers: (id) => setState(() => _blockedById = id),
            ),
            SchedulingSection(
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
              labelMenuController: _menus.label,
              tagMenuController: _menus.tag,
            ),
            if (isEditing && _parentId == null) ...[
              const SizedBox(height: 16),
              SubtasksListSection(parentTask: widget.initialTask!),
            ],
            if (isEditing && widget.initialTask != null)
              EntityTimestampsInfo(
                createdAt: widget.initialTask!.createdAt,
                updatedAt: widget.initialTask!.updatedAt,
              ),
          ],
        ),
      ),
    );
  }

  void _onAddSubtask() {
    if (widget.initialTask == null) return;
    context.openRightSidebar(
      AddTaskPanel(
        initialDate: _scheduledDate ?? widget.initialTask!.scheduledDate,
        initialProjectId: _selectedProjectId ?? widget.initialTask!.projectId,
        initialParentId: widget.initialTask!.id,
      ),
      ref,
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
      placement: _placement,
      initialTask: widget.initialTask,
    );
  }
}
