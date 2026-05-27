import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/common/delete_dialog.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/blocker_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/priority_picker.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/common/sized_dialog.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carpe_diem/features/common/presentation/widgets/date_picker_button.dart';
import 'package:carpe_diem/features/common/presentation/providers/window_title_provider.dart';
import 'package:provider/provider.dart';

class EditTaskDialog extends StatefulWidget {
  final Task task;
  const EditTaskDialog({super.key, required this.task});

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  late Priority _priority;
  DateTime? _scheduledDate;
  DateTime? _deadline;
  String? _selectedProjectId;
  String? _blockedById;
  List<Task> _projectTasks = [];
  List<String> _selectedLabelIds = [];
  List<String> _inheritedLabelIds = [];
  late WindowTitleProvider _windowTitleProvider;
  final MenuController _projectMenuController = MenuController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.task.title;
    _descController.text = widget.task.description ?? '';
    _priority = widget.task.priority;
    _scheduledDate = widget.task.scheduledDate;
    _deadline = widget.task.deadline;
    _selectedProjectId = widget.task.projectId;
    _blockedById = widget.task.blockedById;
    _selectedLabelIds = List.from(widget.task.labelIds);
    if (_selectedProjectId != null) _loadProjectDetails();

    _windowTitleProvider = context.read<WindowTitleProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _windowTitleProvider.pushSubtitle('Editing: ${widget.task.title}');
    });
  }

  @override
  void dispose() {
    _windowTitleProvider.popSubtitle();
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
    final tasks = await context.read<TaskProvider>().getTasksForProject(_selectedProjectId!);
    if (!mounted) return;
    final project = context.read<ProjectProvider>().getById(_selectedProjectId!);
    final settings = context.read<SettingsProvider>();
    setState(() {
      _projectTasks = tasks;
      _inheritedLabelIds = project?.labelIds ?? [];
      if (overwriteDeadline && settings.inheritProjectDeadline && project?.deadline != null) {
        _deadline = project!.deadline;
      }
    });
  }

  DateTime get _maxDate => DateTime.now().add(Duration(days: context.read<SettingsProvider>().maxPlanningDays));

  @override
  Widget build(BuildContext context) {
    final projects = context
        .read<ProjectProvider>()
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
                  context.read<TaskProvider>().deleteTask(widget.task);
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
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Task name'),
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

  void _submit() {
    if (_nameController.text.trim().isEmpty) return;
    context.read<TaskProvider>().updateTask(
      widget.task.copyWith(
        title: _nameController.text.trim(),
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
      ),
    );
    Navigator.of(context).pop();
  }
}
