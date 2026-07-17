import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_sync_utils.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/dialogs/create_tags_prompt_dialog.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_autocomplete_text_field.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_highlighting_controller.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_picker.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/blocker_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/priority_picker.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/widgets/date_picker_button.dart';
import 'package:carpe_diem/features/common/presentation/providers/window_title_provider.dart';

class EditTaskDialog extends ConsumerStatefulWidget {
  final Task task;
  const EditTaskDialog({super.key, required this.task});

  @override
  ConsumerState<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends ConsumerState<EditTaskDialog> {
  late final TagHighlightingController _nameController;
  final _descController = TextEditingController();
  late Priority _priority;
  DateTime? _scheduledDate;
  DateTime? _deadline;
  String? _selectedProjectId;
  String? _blockedById;
  List<Task> _projectTasks = [];
  List<String> _selectedLabelIds = [];
  List<String> _inheritedLabelIds = [];
  List<String> _selectedTagIds = [];
  List<String> _previousParsedIds = [];
  late WindowTitleNotifier _windowTitleNotifier;
  final MenuController _projectMenuController = MenuController();

  @override
  void initState() {
    super.initState();
    _descController.text = widget.task.description ?? '';
    _priority = widget.task.priority;
    _scheduledDate = widget.task.scheduledDate;
    _deadline = widget.task.deadline;
    _selectedProjectId = widget.task.projectId;
    _blockedById = widget.task.blockedById;
    _selectedLabelIds = List.from(widget.task.labelIds);
    _selectedTagIds = List.from(widget.task.tagIds);

    final initialTags = TagParser.parseTags(widget.task.title);
    _previousParsedIds = ref
        .read(tagProvider)
        .tags
        .where((t) => initialTags.contains(t.name.toLowerCase()))
        .map((t) => t.id)
        .toList();

    _nameController = TagHighlightingController(
      text: widget.task.title,
      getExistingTagNames: () => ref.read(tagProvider).tags.map((t) => t.name).toList(),
    );
    _nameController.addListener(_onTitleChanged);

    if (_selectedProjectId != null) _loadProjectDetails();

    _windowTitleNotifier = ref.read(windowTitleProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _windowTitleNotifier.pushSubtitle('Editing: ${widget.task.title}');
    });
  }

  void _onTitleChanged() {
    final newTagIds = TagSyncUtils.syncTitleToPicker(
      text: _nameController.text,
      allTags: ref.read(tagProvider).tags,
      currentSelectedIds: _selectedTagIds,
      previousParsedIds: _previousParsedIds,
      mode: ref.read(settingsProvider).tagAbsorption,
    );

    final parsedNames = TagParser.parseTags(_nameController.text);
    _previousParsedIds = ref
        .read(tagProvider)
        .tags
        .where((t) => parsedNames.contains(t.name.toLowerCase()))
        .map((t) => t.id)
        .toList();

    final set1 = Set.from(_selectedTagIds);
    final set2 = Set.from(newTagIds);
    if (set1.length != set2.length || !set1.containsAll(set2)) {
      setState(() {
        _selectedTagIds = newTagIds;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTitleChanged);
    _nameController.dispose();
    _descController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _windowTitleNotifier.popSubtitle();
    });
    super.dispose();
  }

  Future<void> _loadProjectDetails({bool overwriteDeadline = false}) async {
    if (_selectedProjectId == null) {
      setState(() {
        _projectTasks = [];
        _blockedById = null;
        _inheritedLabelIds = [];
      });
      return;
    }
    final tasks = await ref.read(taskProvider.notifier).getTasksForProject(_selectedProjectId!);
    if (!mounted) return;
    final project = ref.read(projectProvider).getById(_selectedProjectId!);
    final settings = ref.read(settingsProvider);
    setState(() {
      _projectTasks = tasks;
      _inheritedLabelIds = project?.labelIds ?? [];
      if (overwriteDeadline && settings.inheritProjectDeadline && project?.deadline != null) {
        _deadline = project?.deadline;
      }
    });
  }

  DateTime get _maxDate => DateTime.now().add(Duration(days: ref.read(settingsProvider).maxPlanningDays));

  @override
  Widget build(BuildContext context) {
    final projects = ref
        .watch(projectProvider)
        .projects
        .where((p) => p.isActive || p.id == widget.task.projectId)
        .toList();

    return AppShortcutRegistrar(
      shortcuts: taskDialogShortcutEntries,
      child: SizedDialog(
        title: 'Edit Task',
        onSubmit: _submit,
        submitText: 'Save Changes',
        actions: [
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => DeleteDialog(
                title: 'Delete Task',
                message: 'Are you sure you want to delete this task?',
                onConfirm: () {
                  Navigator.of(context).pop();
                  ref.read(taskProvider.notifier).deleteTask(widget.task);
                },
              ),
            ),
            icon: const Icon(Icons.delete),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            label: const Text("Delete"),
          ),
        ],
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(AppKeyBindings.digit1, control: true): () =>
                setState(() => _priority = Priority.none),
            const SingleActivator(AppKeyBindings.digit2, control: true): () => setState(() => _priority = Priority.low),
            const SingleActivator(AppKeyBindings.digit3, control: true): () =>
                setState(() => _priority = Priority.medium),
            const SingleActivator(AppKeyBindings.digit4, control: true): () =>
                setState(() => _priority = Priority.high),
            const SingleActivator(AppKeyBindings.digit5, control: true): () =>
                setState(() => _priority = Priority.urgent),
            const SingleActivator(ProjectsKeys.keyboardKey, control: true): () => _projectMenuController.open(),
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TagAutocompleteTextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Task name'),
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
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(hintText: 'Description (optional)'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text('Priority', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              PriorityPicker(selected: _priority, onChanged: (p) => setState(() => _priority = p)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DatePickerButton(
                      label: 'Schedule Date',
                      date: _scheduledDate,
                      onChanged: (d) => setState(() => _scheduledDate = d),
                      lastDate: _maxDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProjectPicker(
                      projects: projects,
                      selectedProjectId: _selectedProjectId,
                      menuController: _projectMenuController,
                      onChanged: (id) {
                        setState(() => _selectedProjectId = id);
                        _loadProjectDetails(overwriteDeadline: true);
                      },
                    ),
                  ),
                ],
              ),
              if (_selectedProjectId != null) ...[
                const SizedBox(height: 12),
                BlockerPicker(
                  availableTasks: _projectTasks,
                  selectedBlockerId: _blockedById,
                  currentTaskId: widget.task.id,
                  onChanged: (id) {
                    setState(() {
                      _blockedById = id;
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),
              Text('Labels', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              LabelPicker(
                selectedLabelIds: _selectedLabelIds,
                inheritedLabelIds: _inheritedLabelIds,
                onSelected: (ids) => setState(() => _selectedLabelIds = ids),
              ),
              const SizedBox(height: 16),
              Text('Tags', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TagPicker(
                selectedTagIds: _selectedTagIds,
                onSelected: (ids) {
                  final newText = TagSyncUtils.syncPickerToTitle(
                    currentText: _nameController.text,
                    oldSelectedIds: _selectedTagIds,
                    newSelectedIds: ids,
                    allTags: ref.read(tagProvider).tags,
                  );
                  _nameController.text = newText;
                  setState(() {
                    _selectedTagIds = ids;
                  });
                },
              ),
              const SizedBox(height: 12),
              DatePickerButton(
                label: 'Deadline (Optional)',
                date: _deadline,
                onChanged: (d) => setState(() => _deadline = d),
                firstDate: widget.task.createdAt,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final rawTitle = _nameController.text.trim();
    if (rawTitle.isEmpty) return;

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

    ref
        .read(taskProvider.notifier)
        .updateTask(
          widget.task.copyWith(
            title: titleToSave,
            description: _descController.text.trim().isEmpty ? "" : _descController.text.trim(),
            priority: _priority,
            scheduledDate: _scheduledDate,
            clearScheduledDate: _scheduledDate == null,
            deadline: _deadline,
            clearDeadline: _deadline == null,
            blockedById: _blockedById,
            clearBlockedBy: _blockedById == null,
            projectId: _selectedProjectId,
            labelIds: _selectedLabelIds,
            tagIds: finalTagIds,
          ),
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
