import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_picker.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_sync_utils.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/dialogs/create_tags_prompt_dialog.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_autocomplete_text_field.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_highlighting_controller.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_picker.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/blocker_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/priority_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/date_picker_button.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_picker.dart';
import 'package:carpe_diem/features/common/presentation/providers/window_title_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';

class AddTaskDialog extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final String? initialProjectId;

  const AddTaskDialog({super.key, this.initialDate, this.initialProjectId});

  @override
  ConsumerState<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  late final TagHighlightingController _titleController;
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedProjectId;
  Priority _priority = Priority.none;
  DateTime? _deadline;
  String? _blockedById;
  List<Task> _projectTasks = [];
  List<String> _selectedLabelIds = [];
  List<String> _inheritedLabelIds = [];
  List<String> _selectedTagIds = [];
  late WindowTitleNotifier _windowTitleNotifier;
  final MenuController _projectMenuController = MenuController();

  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _selectedDate = widget.initialDate;
    _selectedProjectId = widget.initialProjectId ?? settings.defaultProjectId;
    _priority = Priority.fromName(settings.defaultPriority) ?? Priority.none;

    _titleController = TagHighlightingController(
      getExistingTagNames: () => ref.read(tagProvider).tags.map((t) => t.name).toList(),
    );
    _titleController.addListener(_onTitleChanged);

    if (_selectedProjectId != null) _loadProjectDetails();

    _windowTitleNotifier = ref.read(windowTitleProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _windowTitleNotifier.pushSubtitle('New Task');
    });
  }

  void _onTitleChanged() {
    if (_isSyncing) return;
    _isSyncing = true;
    final newTagIds = TagSyncUtils.syncTitleToPicker(
      _titleController.text,
      ref.read(tagProvider).tags,
    );
    final set1 = Set.from(_selectedTagIds);
    final set2 = Set.from(newTagIds);
    if (set1.length != set2.length || !set1.containsAll(set2)) {
      setState(() {
        _selectedTagIds = newTagIds;
      });
    }
    _isSyncing = false;
  }

  Future<void> _loadProjectDetails() async {
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
      if (settings.inheritProjectDeadline && project?.deadline != null) {
        _deadline = project?.deadline;
      }
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _descController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _windowTitleNotifier.popSubtitle();
    });
    super.dispose();
  }
  DateTime get _maxDate => DateTime.now().add(Duration(days: ref.read(settingsProvider).maxPlanningDays));

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectProvider).projects.where((p) => p.isActive).toList();

    return AppShortcutRegistrar(
      shortcuts: taskDialogShortcutEntries,
      child: SizedDialog(
        title: 'New Task',
        onSubmit: _submit,
        onCancel: () => Navigator.of(context).pop(),
        submitText: 'Add Task',
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
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Task title'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
                      label: 'Schedule date',
                      date: _selectedDate,
                      lastDate: _maxDate,
                      onChanged: (d) => setState(() => _selectedDate = d),
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
                        _loadProjectDetails();
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
              const SizedBox(height: 12),
              TagPicker(
                selectedTagIds: _selectedTagIds,
                onSelected: (ids) {
                  if (_isSyncing) return;
                  _isSyncing = true;

                  final added = ids.firstWhere((id) => !_selectedTagIds.contains(id), orElse: () => '');
                  final removed = _selectedTagIds.firstWhere((id) => !ids.contains(id), orElse: () => '');

                  var currentText = _titleController.text;
                  if (added.isNotEmpty) {
                    final tag = ref.read(tagProvider).getById(added);
                    if (tag != null) {
                      currentText = TagSyncUtils.addTagToText(currentText, tag.name);
                    }
                  } else if (removed.isNotEmpty) {
                    final tag = ref.read(tagProvider).getById(removed);
                    if (tag != null) {
                      currentText = TagSyncUtils.removeTagFromText(currentText, tag.name);
                    }
                  }

                  _titleController.text = currentText;
                  _titleController.selection = TextSelection.fromPosition(
                    TextPosition(offset: currentText.length),
                  );

                  setState(() {
                    _selectedTagIds = ids;
                  });
                  _isSyncing = false;
                },
              ),

              const SizedBox(height: 16),
              Text('Deadline', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              DatePickerButton(
                label: 'Deadline',
                date: _deadline,
                firstDate: DateTime.now(),
                onChanged: (d) => setState(() => _deadline = d),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final rawTitle = _titleController.text.trim();
    if (rawTitle.isEmpty) return;

    final parsedTagNames = TagParser.parseTags(rawTitle);
    final existingTags = ref.read(tagProvider).tags;
    final existingNamesSet = existingTags.map((t) => t.name.toLowerCase()).toSet();

    final newTagNames = parsedTagNames
        .where((name) => !existingNamesSet.contains(name.toLowerCase()))
        .toList();

    List<String> finalTagIds = List.from(_selectedTagIds);

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
      }
    }

    final cleanTitle = TagParser.stripTags(rawTitle);

    ref.read(taskProvider.notifier).addTask(
          title: cleanTitle,
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          scheduledDate: _selectedDate,
          projectId: _selectedProjectId,
          priority: _priority,
          deadline: _deadline,
          blockedById: _blockedById,
          labelIds: _selectedLabelIds,
          tagIds: finalTagIds,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
