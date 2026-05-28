import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_picker.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/blocker_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedProjectId;
  Priority _priority = Priority.none;
  DateTime? _deadline;
  String? _blockedById;
  List<Task> _projectTasks = [];
  List<String> _selectedLabelIds = [];
  List<String> _inheritedLabelIds = [];
  late WindowTitleNotifier _windowTitleNotifier;
  final MenuController _projectMenuController = MenuController();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _selectedDate = widget.initialDate;
    _selectedProjectId = widget.initialProjectId ?? settings.defaultProjectId;
    _priority = Priority.fromName(settings.defaultPriority) ?? Priority.none;

    if (_selectedProjectId != null) _loadProjectDetails();

    _windowTitleNotifier = ref.read(windowTitleProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _windowTitleNotifier.pushSubtitle('New Task');
    });
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
            const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
                setState(() => _priority = Priority.none),
            const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
                setState(() => _priority = Priority.low),
            const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
                setState(() => _priority = Priority.medium),
            const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
                setState(() => _priority = Priority.high),
            const SingleActivator(LogicalKeyboardKey.digit5, control: true): () =>
                setState(() => _priority = Priority.urgent),
            const SingleActivator(LogicalKeyboardKey.keyP, control: true): () => _projectMenuController.open(),
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
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

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    ref.read(taskProvider.notifier).addTask(
      title: title,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      scheduledDate: _selectedDate,
      projectId: _selectedProjectId,
      priority: _priority,
      deadline: _deadline,
      blockedById: _blockedById,
      labelIds: _selectedLabelIds,
    );
    Navigator.of(context).pop();
  }
}
